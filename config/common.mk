# Copyright (C) 2026 The ValkyOS Project
# SPDX-License-Identifier: Apache-2.0

$(call inherit-product, vendor/valkyos/config/version.mk)

# Replace the LineageOS boot animation selected by common_full_phone.
PRODUCT_PACKAGES := $(filter-out bootanimation.zip,$(PRODUCT_PACKAGES))

PRODUCT_COPY_FILES += \
    vendor/valkyos/bootanimation/bootanimation.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation.zip
