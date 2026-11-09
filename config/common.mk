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

# Recovery: ValkyOS symbol instead of the LineageOS logo, for every recovery
# density. The build copies vendor/valkyos/recovery/<density>/res over
# bootable/recovery/res-<density>. $(recovery_density) is expanded later, by
# build/make/core/Makefile, once it is known (if it were empty, the wildcard
# gives nothing and the LineageOS images stay). Made with
# recovery/hacer-logos-recovery.py from the LineageOS originals.
TARGET_PRIVATE_RES_DIRS += $(wildcard vendor/valkyos/recovery/$(recovery_density)/res)

# Boot animation (bootanimation/): ValkyOS logo on black, pre-generated for
# screen widths 720, 1080, 1220 and 1440. The one matching TARGET_SCREEN_WIDTH
# is used (1080 otherwise; the logo stays centered and whole on any width).
# LineageOS installs it through its own bootanimation.zip module. "=" keeps the
# width unexpanded until LineageOS reads TARGET_BOOTANIMATION (after the device
# configuration), and a device tree may still set its own.
VALKYOS_BOOTANIMATION_WIDTHS := 720 1080 1220 1440
TARGET_BOOTANIMATION ?= vendor/valkyos/bootanimation/bootanimation-$(if $(filter $(VALKYOS_BOOTANIMATION_WIDTHS),$(TARGET_SCREEN_WIDTH)),$(TARGET_SCREEN_WIDTH),1080).zip
