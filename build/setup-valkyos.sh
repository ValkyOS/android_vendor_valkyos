#!/usr/bin/env bash
# Copyright (C) 2026 The ValkyOS Project
# SPDX-License-Identifier: Apache-2.0

# Reproduce the compatibility changes required by the initial ValkyOS Android
# 17 base. The script is idempotent: an already configured tree is verified and
# left unchanged.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_DIR="$SCRIPT_DIR/patches"
ROM_ROOT="${1:-$(pwd)}"

AV_REVISION="1c5914737a1a89d0c5b3e52e8289019eab3f8cbf"
NATIVE_REVISION="a96adf2c6e62dbb22299cd83bbb9ea4bc569e985"

ZXING_AAR_URL="https://repo.maven.apache.org/maven2/com/journeyapps/zxing-android-embedded/4.3.0/zxing-android-embedded-4.3.0.aar"
ZXING_AAR_SHA256="4ab03353127c34e55cbb80fbc9a34031decbcfb1ec5e8f991944d2d494621a33"
ZXING_JAR_URL="https://repo.maven.apache.org/maven2/com/google/zxing/core/3.4.1/core-3.4.1.jar"
ZXING_JAR_SHA256="acfa30338c26267b6cab665509c2251bb96e8350bfcad89d59b949ba77011f8d"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

command -v git >/dev/null 2>&1 || fail "se necesita git"
command -v curl >/dev/null 2>&1 || fail "se necesita curl"
command -v sha256sum >/dev/null 2>&1 || fail "se necesita sha256sum"
command -v install >/dev/null 2>&1 || fail "se necesita install"
command -v python3 >/dev/null 2>&1 || fail "se necesita python3"

[[ -d "$ROM_ROOT/.repo" ]] || fail "$ROM_ROOT no es un árbol repo"

echo "== Huellas de los parches =="
(cd "$PATCH_DIR" && sha256sum -c SHA256SUMS)

apply_compat_patch() {
    local repo_path="$1"
    local expected_revision="$2"
    local patch_file="$3"
    local actual_revision

    [[ -d "$ROM_ROOT/$repo_path/.git" ]] || fail "falta $repo_path"
    actual_revision="$(git -C "$ROM_ROOT/$repo_path" rev-parse HEAD)"
    [[ "$actual_revision" == "$expected_revision" ]] ||
        fail "$repo_path está en $actual_revision; se esperaba $expected_revision"

    if git -C "$ROM_ROOT/$repo_path" apply --reverse --check "$patch_file"; then
        echo "YA_APLICADO: $repo_path"
    elif git -C "$ROM_ROOT/$repo_path" apply --check "$patch_file"; then
        git -C "$ROM_ROOT/$repo_path" apply "$patch_file"
        echo "APLICADO: $repo_path"
    else
        fail "el parche no aplica limpiamente en $repo_path"
    fi

    git -C "$ROM_ROOT/$repo_path" apply --reverse --check "$patch_file" ||
        fail "no se pudo confirmar el parche en $repo_path"
    git -C "$ROM_ROOT/$repo_path" diff --check
}

echo
echo "== Parches de compatibilidad =="
apply_compat_patch \
    "frameworks/av" \
    "$AV_REVISION" \
    "$PATCH_DIR/frameworks-av-libheif.patch"
apply_compat_patch \
    "frameworks/native" \
    "$NATIVE_REVISION" \
    "$PATCH_DIR/frameworks-native-a16-abi.patch"
# Sensors permission (GrapheneOS OTHER_SENSORS): sensors without their own
# permission require android.permission.OTHER_SENSORS; denials are reported to
# the system so it can notify the user.
apply_compat_patch \
    "frameworks/native" \
    "$NATIVE_REVISION" \
    "$PATCH_DIR/frameworks-native-sensors.patch"

# Motorola camera helper built against the Android 15/16 libgui ABI. LineageOS
# provides libgui_buffer_shim_vendor, which exports the old
# BufferItemConsumer::acquireBuffer/releaseBuffer signatures and links to the
# real libgui_vendor. A prebuilt's shared_libs list does not change DT_NEEDED,
# so the blob itself must load the shim instead of libgui_vendor directly.
CAMERA_HELPER="$ROM_ROOT/vendor/motorola/eqe/proprietary/vendor/lib64/libmot_chi_desktop_helper.so"
CAMERA_HELPER_ORIGINAL_SHA256="45534e75055029baefbee6a0ce2fa4ce0f1385fce643230f57b48ccfe68730f6"

find_patchelf() {
    if command -v patchelf >/dev/null 2>&1; then
        command -v patchelf
    elif [[ -x "$ROM_ROOT/prebuilts/extract-tools/linux-x86/bin/patchelf" ]]; then
        echo "$ROM_ROOT/prebuilts/extract-tools/linux-x86/bin/patchelf"
    else
        fail "se necesita patchelf"
    fi
}

fix_camera_helper_abi() {
    local patchelf_bin needed
    [[ -f "$CAMERA_HELPER" ]] || fail "falta $CAMERA_HELPER"
    grep -q '"libgui_buffer_shim_vendor"' "$ROM_ROOT/vendor/motorola/eqe/Android.bp" ||
        fail "vendor/motorola/eqe/Android.bp no declara libgui_buffer_shim_vendor"
    patchelf_bin="$(find_patchelf)"
    needed="$("$patchelf_bin" --print-needed "$CAMERA_HELPER")"

    if grep -qx 'libgui_buffer_shim_vendor.so' <<<"$needed" &&
       ! grep -qx 'libgui_vendor.so' <<<"$needed"; then
        echo "YA_APLICADO: camara (libgui_buffer_shim_vendor)"
        return
    fi

    printf '%s  %s\n' "$CAMERA_HELPER_ORIGINAL_SHA256" "$CAMERA_HELPER" | sha256sum -c - ||
        fail "libmot_chi_desktop_helper.so no es la version esperada"
    grep -qx 'libgui_vendor.so' <<<"$needed" ||
        fail "el helper de camara no depende de libgui_vendor.so"

    "$patchelf_bin" --replace-needed libgui_vendor.so libgui_buffer_shim_vendor.so \
        "$CAMERA_HELPER"
    needed="$("$patchelf_bin" --print-needed "$CAMERA_HELPER")"
    grep -qx 'libgui_buffer_shim_vendor.so' <<<"$needed" &&
        ! grep -qx 'libgui_vendor.so' <<<"$needed" ||
        fail "no se pudo confirmar el cambio del helper de camara"
    echo "APLICADO: camara (libgui_buffer_shim_vendor)"
}

echo
echo "== Compatibilidad de camara =="
fix_camera_helper_abi

# Moto Camera (and its Camera AI component) use ArcSoft post-processing
# (portrait/blur). On Android 17 they run as priv_app_36, so the device policy
# written for priv_app no longer applies and the camera app crashes after a
# portrait capture. Same solution as crDroid A17: a dedicated SELinux domain
# selected by package name AND the original Motorola certificate, allowed to
# find the ArcSoft service, talk to the camera HAL and read vendor_xdsp_device
# only. qDSP and /vendor/dsp stay closed.
MOTOCAMERA_APK="$ROM_ROOT/vendor/motorola/eqe/proprietary/product/priv-app/MotCamera4/MotCamera4.apk"
MOTOCAMERA_AI_APK="$ROM_ROOT/vendor/motorola/eqe/proprietary/product/app/MotCamera3AI/MotCamera3AI.apk"
MOTOCAMERA_CERT_SHA256="be8804a55e9045a580d204979f6efb15c058731aa1021b78c046feab8ae76a26"
MOTOCAMERA_SEPOLICY_DIR="$ROM_ROOT/device/motorola/eqe/sepolicy"
MOTOCAMERA_TE="$MOTOCAMERA_SEPOLICY_DIR/vendor/motocamera.te"
QCOM_XDSP_DOMAIN_TE="$ROM_ROOT/device/qcom/sepolicy_vndr/sm8550/generic/vendor/common/domain.te"
APKSIGNER_JAR="$ROM_ROOT/prebuilts/sdk/tools/linux/lib/apksigner.jar"

find_java() {
    local candidate
    if command -v java >/dev/null 2>&1; then
        command -v java
        return
    fi
    for candidate in "$ROM_ROOT"/prebuilts/jdk/jdk*/linux-x86/bin/java; do
        if [[ -x "$candidate" ]]; then
            echo "$candidate"
            return
        fi
    done
    fail "se necesita java"
}

apk_signer_sha256() {
    "$1" -jar "$APKSIGNER_JAR" verify --print-certs "$2" |
        sed -n 's/^Signer #1 certificate SHA-256 digest: //p' | head -n 1
}

install_motocamera_policy() {
    local java_bin cert_pem cert_hex
    local private_dir="$MOTOCAMERA_SEPOLICY_DIR/private"
    local public_dir="$MOTOCAMERA_SEPOLICY_DIR/public"

    for required_path in "$MOTOCAMERA_APK" "$MOTOCAMERA_AI_APK" "$APKSIGNER_JAR" \
        "$MOTOCAMERA_TE" "$QCOM_XDSP_DOMAIN_TE"; do
        [[ -f "$required_path" ]] || fail "falta $required_path"
    done

    if [[ -f "$private_dir/moto_camera_app.te" &&
          -f "$private_dir/seapp_contexts" &&
          -f "$private_dir/mac_permissions.xml" &&
          -f "$public_dir/moto_camera_app.te" ]] &&
       grep -qx -- '- moto_camera_xdsp_domain' "$QCOM_XDSP_DOMAIN_TE" &&
       grep -q 'moto_camera_xdsp_domain vendor_xdsp_device' "$MOTOCAMERA_TE"; then
        echo "YA_APLICADO: politica de Moto Camera"
        return
    fi

    for new_path in "$private_dir/moto_camera_app.te" "$private_dir/seapp_contexts" \
        "$private_dir/mac_permissions.xml" "$public_dir/moto_camera_app.te"; do
        [[ ! -e "$new_path" ]] || fail "ya existe una politica parcial: $new_path"
    done
    ! grep -q 'moto_camera_xdsp_domain' "$QCOM_XDSP_DOMAIN_TE" ||
        fail "domain.te ya contiene una excepcion xDSP parcial"
    grep -q -- '- vendor_dspservice$' "$QCOM_XDSP_DOMAIN_TE" ||
        fail "no se encontro el bloque xDSP esperado en domain.te"

    java_bin="$(find_java)"
    [[ "$(apk_signer_sha256 "$java_bin" "$MOTOCAMERA_APK")" == "$MOTOCAMERA_CERT_SHA256" ]] ||
        fail "MotCamera4 no conserva el certificado Motorola esperado"
    [[ "$(apk_signer_sha256 "$java_bin" "$MOTOCAMERA_AI_APK")" == "$MOTOCAMERA_CERT_SHA256" ]] ||
        fail "MotCamera3AI no conserva el certificado Motorola esperado"

    cert_pem="$("$java_bin" -jar "$APKSIGNER_JAR" verify --print-certs-pem "$MOTOCAMERA_APK")"
    cert_hex="$(printf '%s\n' "$cert_pem" | python3 -c '
import base64, re, sys
m = re.search(r"-----BEGIN CERTIFICATE-----\s*(.*?)\s*-----END CERTIFICATE-----", sys.stdin.read(), re.S)
print(base64.b64decode("".join(m.group(1).split())).hex() if m else "")
')"
    [[ "$cert_hex" =~ ^[0-9a-f]+$ ]] || fail "no se pudo leer el certificado de Moto Camera"
    [[ "$(python3 -c 'import hashlib, sys; print(hashlib.sha256(bytes.fromhex(sys.argv[1])).hexdigest())' "$cert_hex")" == "$MOTOCAMERA_CERT_SHA256" ]] ||
        fail "el certificado extraido no coincide con la huella esperada"

    mkdir -p "$private_dir" "$public_dir"

    cat > "$private_dir/moto_camera_app.te" <<'EOF'
# Dedicated domain for Moto Camera and its Camera AI component.
type moto_camera_app, domain;

typeattribute moto_camera_app coredomain;
typeattribute moto_camera_app moto_camera_xdsp_domain;

app_domain(moto_camera_app)
net_domain(moto_camera_app)
bluetooth_domain(moto_camera_app)

# Framework services used by the camera and its post-processing.
allow moto_camera_app {
    app_api_service
    system_api_service
    audioserver_service
    cameraserver_service
    drmserver_service
    mediadrmserver_service
    mediaextractor_service
    mediametrics_service
    mediaserver_service
    thermal_service
    gpu_service
}:service_manager find;

# Native components loaded from the APK and its private directory.
allow moto_camera_app system_linker_exec:file execute_no_trans;
allow moto_camera_app privapp_data_file:file execute;
EOF

    cat > "$private_dir/seapp_contexts" <<'EOF'
# Exact package names and the Motorola seinfo limit this domain to these two apps.
user=_app seinfo=moto_camera isPrivApp=true name=com.motorola.camera3 domain=moto_camera_app type=app_data_file levelFrom=user
user=_app seinfo=moto_camera isPrivApp=false name=com.motorola.camera3.content.ai domain=moto_camera_app type=app_data_file levelFrom=user
EOF

    cat > "$private_dir/mac_permissions.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<policy>
    <!-- Motorola MotoAndroidApp certificate, verified by SHA-256 $MOTOCAMERA_CERT_SHA256 -->
    <signer signature="$cert_hex">
        <package name="com.motorola.camera3">
            <seinfo value="moto_camera" />
        </package>
        <package name="com.motorola.camera3.content.ai">
            <seinfo value="moto_camera" />
        </package>
    </signer>
</policy>
EOF

    cat > "$public_dir/moto_camera_app.te" <<'EOF'
# Public because the Qualcomm vendor policy must see this attribute.
# Only the Motorola packages selected in seapp_contexts are members.
attribute moto_camera_xdsp_domain;
EOF

    cat > "$MOTOCAMERA_TE" <<'EOF'
# Moto Camera and Camera AI run in a dedicated domain (moto_camera_app).
# ArcSoft looks up its post-processing service, talks to the camera HAL and
# opens xDSP directly. No qDSP and no general /vendor/dsp access.
allow moto_camera_xdsp_domain vendor_hal_arcsoftpp_service:service_manager find;

binder_call(moto_camera_xdsp_domain, hal_camera_default)
binder_call(hal_camera_default, moto_camera_xdsp_domain)

allow moto_camera_xdsp_domain vendor_xdsp_device:chr_file r_file_perms;
EOF

    sed -i '0,/- vendor_dspservice$/s//&\n- moto_camera_xdsp_domain/' "$QCOM_XDSP_DOMAIN_TE"

    grep -q 'seinfo=moto_camera.*name=com.motorola.camera3 domain=moto_camera_app' \
        "$private_dir/seapp_contexts" || fail "Moto Camera no quedo en su dominio"
    grep -qx -- '- moto_camera_xdsp_domain' "$QCOM_XDSP_DOMAIN_TE" ||
        fail "no se aplico la excepcion limitada en Qualcomm"
    ! grep -Eq 'vendor_qdsp_device|adsprpcd_file' "$MOTOCAMERA_TE" ||
        fail "la politica abrio qDSP o /vendor/dsp"
    echo "APLICADO: politica de Moto Camera (dominio propio, xDSP solo lectura)"
}

echo
echo "== Moto Camera (retrato / desenfoque) =="
install_motocamera_policy

MAVEN_DIR="$ROM_ROOT/packages/apps/OpenEUICC/app-deps/maven"
[[ -d "$ROM_ROOT/packages/apps/OpenEUICC/.git" ]] || fail "falta OpenEUICC"
mkdir -p "$MAVEN_DIR"
# Stored as .template: a file named Android.bp inside vendor/valkyos would be
# parsed by Soong and duplicate the modules installed into OpenEUICC.
install -m 0644 "$SCRIPT_DIR/openeuicc/Android.bp.template" "$MAVEN_DIR/Android.bp"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

install_maven_file() {
    local url="$1"
    local expected_hash="$2"
    local filename="$3"
    local destination="$MAVEN_DIR/$filename"
    local temporary="$TEMP_DIR/$filename"

    if [[ -f "$destination" ]] &&
       printf '%s  %s\n' "$expected_hash" "$destination" | sha256sum -c - >/dev/null; then
        echo "YA_VERIFICADO: $filename"
        return
    fi

    curl --fail --location --retry 3 --proto '=https' --tlsv1.2 \
        --output "$temporary" "$url"
    printf '%s  %s\n' "$expected_hash" "$temporary" | sha256sum -c -
    install -m 0644 "$temporary" "$destination"
    echo "INSTALADO: $filename"
}

echo
echo "== Dependencias de OpenEUICC =="
install_maven_file "$ZXING_AAR_URL" "$ZXING_AAR_SHA256" \
    "zxing-android-embedded-4.3.0.aar"
install_maven_file "$ZXING_JAR_URL" "$ZXING_JAR_SHA256" \
    "core-3.4.1.jar"

HISTORICAL_TEMPLATE="$ROM_ROOT/kernel/motorola/sm7550/lineage-a17-setup/lineage-a17-repro-20260925-final/files/packages/apps/OpenEUICC/app-deps/maven/Android.bp"
if [[ -f "$HISTORICAL_TEMPLATE" ]]; then
    [[ ! -e "$HISTORICAL_TEMPLATE.template" ]] ||
        fail "existen simultáneamente la plantilla activa y la plantilla oculta"
    mv -- "$HISTORICAL_TEMPLATE" "$HISTORICAL_TEMPLATE.template"
    echo "PLANTILLA_HISTORICA=OCULTADA"
elif [[ -f "$HISTORICAL_TEMPLATE.template" ]]; then
    echo "PLANTILLA_HISTORICA=YA_OCULTA"
else
    fail "no se encontró la plantilla histórica de OpenEUICC"
fi

printf '%s  %s\n' "$ZXING_AAR_SHA256" \
    "$MAVEN_DIR/zxing-android-embedded-4.3.0.aar" | sha256sum -c -
printf '%s  %s\n' "$ZXING_JAR_SHA256" \
    "$MAVEN_DIR/core-3.4.1.jar" | sha256sum -c -

echo
echo "CONFIGURACION_VALKYOS=OK"
