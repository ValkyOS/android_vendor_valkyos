# Copyright (C) 2026 The ValkyOS Project
# SPDX-License-Identifier: Apache-2.0

$(call inherit-product, vendor/valkyos/config/version.mk)

PRODUCT_PACKAGES += \
    ValkyOSLineagePlatformOverlay

# Sandboxed Google Play compatibility layer (GrapheneOS). GmsCompat pulls in
# GmsCompatLib and GmsCompatConfig through its required modules.
PRODUCT_PACKAGES += \
    GmsCompat

# GrapheneOS App Store (external/AppStore): trusted source for installing and
# updating sandboxed Google Play and GrapheneOS apps.
PRODUCT_PACKAGES += \
    AppStore

# Vanadium (GrapheneOS browser and WebView, external/vanadium). Replaces the
# LineageOS browser (Jelly) and WebView: setup-valkyos.sh adds the overrides to
# external/vanadium/Android.bp and the overlay below makes app.vanadium.webview
# the only WebView provider. Presigned by GrapheneOS, so the App Store updates it.
PRODUCT_PACKAGES += \
    TrichromeChrome \
    TrichromeWebView \
    VanadiumConfig

# Static overlays that must win over vendor/lineage/overlay/common (this file is
# inherited after LineageOS, so DEVICE_PACKAGE_OVERLAYS is used for priority).
DEVICE_PACKAGE_OVERLAYS += vendor/valkyos/overlay/no-rro
PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS += vendor/valkyos/overlay/no-rro
