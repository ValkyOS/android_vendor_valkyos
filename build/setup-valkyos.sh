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

AV_REVISION="937eb9047ec2f88620f1f6a4d9e407f6c869d91a"
NATIVE_REVISION="46018f54b42489de960c62c3db9de131abce43ea"

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

MAVEN_DIR="$ROM_ROOT/packages/apps/OpenEUICC/app-deps/maven"
[[ -d "$ROM_ROOT/packages/apps/OpenEUICC/.git" ]] || fail "falta OpenEUICC"
mkdir -p "$MAVEN_DIR"
install -m 0644 "$SCRIPT_DIR/openeuicc/Android.bp" "$MAVEN_DIR/Android.bp"

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
