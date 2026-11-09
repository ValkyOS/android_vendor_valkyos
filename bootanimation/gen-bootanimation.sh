#!/bin/bash -e
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod Project
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
# SPDX-FileCopyrightText: 2026 The ValkyOS Project
# SPDX-License-Identifier: Apache-2.0
#
# ValkyOS boot animation for any screen. Based on the LineageOS generator.
# Not run by the build: it was used to make bootanimation-<width>.zip, and can
# make another width (mogrify = ImageMagick, soong_zip or "zip -0 -r -D").
# bootanimation.tar holds the frames at 1220x610 (2:1, logo centered on black,
# made from the 1220x2712 eqe animation). They are resized to the screen width
# (the shorter side), so the logo keeps the same size relative to the screen;
# Android centers the frames and fills the rest with black.

PARAM_OUT=$1
PARAM_GENDIR=$2
PARAM_BOOTANIMATION_TAR=$3
PARAM_DESC_TXT=$4
PARAM_MOGRIFY=$5
PARAM_SOONG_ZIP=$6
PARAM_TARGET_SCREEN_HEIGHT=$7
PARAM_TARGET_SCREEN_WIDTH=$8
PARAM_TARGET_BOOTANIMATION_HALF_RES=$9

INTERMEDIATES=$PARAM_GENDIR/intermediates

mkdir -p "$INTERMEDIATES"

tar xfp "$PARAM_BOOTANIMATION_TAR" -C "$INTERMEDIATES"

if [ "$PARAM_TARGET_SCREEN_HEIGHT" -lt "$PARAM_TARGET_SCREEN_WIDTH" ]; then
    IMAGEWIDTH=$PARAM_TARGET_SCREEN_HEIGHT
else
    IMAGEWIDTH=$PARAM_TARGET_SCREEN_WIDTH
fi

IMAGESCALEWIDTH=$IMAGEWIDTH
IMAGESCALEHEIGHT=$(expr "$IMAGESCALEWIDTH" / 2)

if [ "$PARAM_TARGET_BOOTANIMATION_HALF_RES" = "true" ]; then
    IMAGEWIDTH="$(expr "$IMAGEWIDTH" / 2)"
fi

IMAGEHEIGHT=$(expr "$IMAGEWIDTH" / 2)
RESOLUTION="${IMAGEWIDTH}x${IMAGEHEIGHT}!"

if [ "$IMAGEWIDTH" != "1220" ]; then
    "$PARAM_MOGRIFY" -resize "$RESOLUTION" "$INTERMEDIATES"/*/*.png
fi

echo "$IMAGESCALEWIDTH $IMAGESCALEHEIGHT 30" > "$INTERMEDIATES/desc.txt"
cat "$PARAM_DESC_TXT" >> "$INTERMEDIATES/desc.txt"

"$PARAM_SOONG_ZIP" -L 0 -o "$PARAM_OUT" -C "$INTERMEDIATES" -D "$INTERMEDIATES"
