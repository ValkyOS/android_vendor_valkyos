# Copyright (C) 2026 The ValkyOS Project
# SPDX-License-Identifier: Apache-2.0

VALKYOS_VERSION := 1.0
VALKYOS_BUILD_TYPE ?= UNOFFICIAL
VALKYOS_BUILD_DATE := $(shell date -u +%Y%m%d)
VALKYOS_BUILD_VERSION := ValkyOS-$(VALKYOS_VERSION)-$(VALKYOS_BUILD_DATE)-$(VALKYOS_BUILD_TYPE)

PRODUCT_SYSTEM_PROPERTIES += \
    ro.valkyos.version=$(VALKYOS_VERSION) \
    ro.valkyos.build.type=$(VALKYOS_BUILD_TYPE) \
    ro.valkyos.build.date=$(VALKYOS_BUILD_DATE) \
    ro.valkyos.build.version=$(VALKYOS_BUILD_VERSION)
