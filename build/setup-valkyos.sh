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

# frameworks/av (libheif) and frameworks/native (Sensors permission and the
# Android 16 ABI bridge) are ValkyOS forks since November 2026: the patches in
# build/patches are already in them and are kept only for reference.

# The Motorola camera helper (libmot_chi_desktop_helper.so) now comes already
# fixed from the eqe repositories (blob fixup in the device tree, November 2026).

# Moto Camera SELinux (portrait) now lives in the eqe repositories: the device
# tree sepolicy and the xDSP exception in the eqe fork of sepolicy_vndr.

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
