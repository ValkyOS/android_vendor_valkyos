# Copyright (C) 2026 The ValkyOS Project
# SPDX-License-Identifier: Apache-2.0

# -----------------------------------------------------------------
# ValkyOS update package: same file as the LineageOS one (hard link, no extra
# space), named ValkyOS-<version>.zip instead of lineage-ValkyOS-<version>.zip.
# "brunch" / "m bacon" build both names.

VALKYOS_TARGET_PACKAGE := $(PRODUCT_OUT)/$(VALKYOS_BUILD_VERSION).zip

$(VALKYOS_TARGET_PACKAGE): $(INTERNAL_OTA_PACKAGE_TARGET)
	$(hide) ln -f $(INTERNAL_OTA_PACKAGE_TARGET) $(VALKYOS_TARGET_PACKAGE)
	$(hide) $(SHA256) $(VALKYOS_TARGET_PACKAGE) | sed "s|$(PRODUCT_OUT)/||" > $(VALKYOS_TARGET_PACKAGE).sha256sum
	@echo "Package Complete: $(VALKYOS_TARGET_PACKAGE)" >&2

.PHONY: bacon
bacon: $(VALKYOS_TARGET_PACKAGE)
