# ValkyOS boot animation

`config/common.mk` sets `TARGET_BOOTANIMATION` to the zip that matches the
device screen width, and LineageOS installs it (its `bootanimation.zip`
module copies a prebuilt when `TARGET_BOOTANIMATION` is set). A device tree
does not need to set anything (it may set its own `TARGET_BOOTANIMATION`).

| File | Screen width | Frames |
| --- | --- | --- |
| `bootanimation-720.zip` | 720 | 720 x 360 |
| `bootanimation-1080.zip` | 1080 (default for other widths) | 1080 x 540 |
| `bootanimation-1220.zip` | 1220 (Motorola Edge 50 Pro, `eqe`) | 1220 x 610 |
| `bootanimation-1440.zip` | 1440 | 1440 x 720 |

All: 30 FPS, `part0` (60 frames, once) and `part1` (60 frames, repeated until
Android finishes booting), logo centered on black; Android centers the frames
and fills the rest of the screen with black, so the logo stays whole on any
width. Stored without compression.

Sources: `bootanimation.tar` (the 120 frames at 1220 x 610, cut from the
original 1220 x 2712 animation made for `eqe`), `desc.txt` and
`gen-bootanimation.sh` (makes a zip for another width; based on the LineageOS
generator). `source/`: SVG sources of the logo.

Note: a generated-at-build module that replaces the LineageOS one cannot be
used, because both would install `product/media/bootanimation.zip` (Soong
"overriding commands for target" error, V45).
