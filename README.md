# ValkyOS vendor configuration

Common branding and product configuration for ValkyOS.

## Initial identity

- Name: ValkyOS
- Version: 1.0
- Boot animation: 1220 x 2712 at 30 FPS
- Initial device: Motorola Edge 50 Pro (`eqe`)

The Android product must inherit `vendor/valkyos/config/common.mk`.

The generated `bootanimation.zip` is installed in
`$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation.zip` so it takes precedence over
the base system animation without replacing LineageOS source files.
