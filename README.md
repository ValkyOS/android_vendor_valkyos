# ValkyOS vendor configuration

Common branding and product configuration for ValkyOS.

## Initial identity

- Name: ValkyOS
- Version: 1.0
- Boot animation: 1220 x 2712 at 30 FPS
- Initial device: Motorola Edge 50 Pro (`eqe`)

The Android product inherits `vendor/valkyos/config/common.mk` for the ValkyOS
version properties.

The device BoardConfig selects the generated animation through LineageOS's
supported variable:

```make
TARGET_BOOTANIMATION := vendor/valkyos/bootanimation/bootanimation.zip
```

The compatibility patches and OpenEUICC dependencies required by the initial
Android 17 base are reproduced by `build/setup-valkyos.sh`. See
`build/README.md`.
