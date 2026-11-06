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
