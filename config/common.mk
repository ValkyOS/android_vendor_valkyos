# Copyright (C) 2026 The ValkyOS Project
# SPDX-License-Identifier: Apache-2.0

$(call inherit-product, vendor/valkyos/config/version.mk)

PRODUCT_PACKAGES += \
    ValkyOSFrameworkOverlay \
    ValkyOSLineagePlatformOverlay

# ValkyOS wallpapers (wallpaper picker category "ValkyOS").
PRODUCT_PACKAGES += \
    ValkyOSWallpapers

# Sandboxed Google Play compatibility layer (GrapheneOS). GmsCompat pulls in
# GmsCompatLib and GmsCompatConfig through its required modules.
PRODUCT_PACKAGES += \
    GmsCompat

# GrapheneOS App Store (external/AppStore): trusted source for installing and
# updating sandboxed Google Play and GrapheneOS apps.
PRODUCT_PACKAGES += \
    AppStore

# Vanadium (GrapheneOS browser and WebView). The manifest places it in
# vendor/vanadium, where android.ext.adservices is visible (//vendor), so its
# Android.bp is used unchanged. ValkyOSVanadiumOverrides leaves the LineageOS
# browser (Jelly, Browser2) and WebView out, and ValkyOSFrameworkOverlay makes
# app.vanadium.webview the only WebView provider. Presigned by GrapheneOS, so
# the App Store updates it.
PRODUCT_PACKAGES += \
    TrichromeChrome \
    TrichromeWebView \
    VanadiumConfig \
    ValkyOSVanadiumOverrides

# Static overlays that must win over vendor/lineage/overlay/common (this file is
# inherited after LineageOS, so DEVICE_PACKAGE_OVERLAYS is used for priority).
DEVICE_PACKAGE_OVERLAYS += vendor/valkyos/overlay/no-rro
PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS += vendor/valkyos/overlay/no-rro

# Recovery: ValkyOS symbol instead of the LineageOS logo. The build copies these
# images over bootable/recovery/res-<density> (eqe uses xxhdpi). Made with
# recovery/hacer-logos-recovery.py from the LineageOS originals.
TARGET_PRIVATE_RES_DIRS += vendor/valkyos/recovery/res
