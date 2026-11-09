# ValkyOS vendor configuration

Common branding and product configuration for ValkyOS. The Android product
inherits `vendor/valkyos/config/common.mk`.

## Identity

- Name: ValkyOS
- Version: 1.0 (`config/version.mk`, `ro.valkyos.*` properties)
- Initial device: Motorola Edge 50 Pro (`eqe`)

## Contents

| Path | What it does |
| --- | --- |
| `bootanimation/` | Boot animation, 1220 x 2712 at 30 FPS. The device selects it with `TARGET_BOOTANIMATION := vendor/valkyos/bootanimation/bootanimation.zip`. |
| `build/` | `setup-valkyos.sh`: reproducible Android 17 setup (see `build/README.md`). |
| `overlay/LineagePlatformOverlay/` | Runtime overlay for lineage-sdk: ValkyOS instead of LineageOS in every lineage-sdk string (About phone labels, permissions), all languages. |
| `overlay/ValkyOSFrameworkOverlay/` | Runtime overlay for framework-res (priority 999): default wallpaper. LineageOS overlays become auto-generated runtime overlays with priority 0/1, so a static overlay is not enough here. |
| `overlay/no-rro/` | Static overlays: WebView provider list (Vanadium), ValkyOS names in LineageParts and the setup wizard (all languages; setup logo and color), LineageOS statistics hidden (Trust, setup wizard and the LineageParts catalog used by the Settings search) and their upload URL emptied, and the Updater (System updates) without an update server, with ValkyOS names, mark, colors and links. |
| `wallpapers/` | `ValkyOSWallpapers`: seven wallpapers in a "ValkyOS" category of the wallpaper picker (partner customization package). It overrides the LineageOS `Backgrounds` stub. |
| `tools/` | `hacer-textos-valkyos.py`: regenerates the string overlays of an app (every string with "LineageOS" or "Lineage", all languages, except names to skip). Used for lineage-sdk, SetupWizard, LineageParts (skip `anonymous_statistics_*`) and Updater (skip `header_build_version`). `hacer-lottie-bienvenida.py`: the setup wizard welcome animation with the ValkyOS symbol. |
| `recovery/` | Recovery and fastbootd header images with the ValkyOS symbol (`TARGET_PRIVATE_RES_DIRS`), made by `recovery/hacer-logos-recovery.py`. |

The LineageOS statistics overlays copy `trust_preferences.xml` (LineageParts)
and `lineage_settings_items.xml` (SetupWizard) from lineage-24.0. If LineageOS
changes those files, update the copies.
