# Reproducible Android 17 setup

After syncing the manifest, run from the Android source root:

```bash
bash vendor/valkyos/build/setup-valkyos.sh "$PWD"
```

The script:

1. verifies and applies the `frameworks/av` libheif compatibility patch;
2. (frameworks/native is a ValkyOS fork since November 2026: the Sensors
   permission and the Android 16 `SurfaceComposerClient` ABI bridge are already
   in it, so the script no longer patches it);
3. makes the Motorola camera helper (`libmot_chi_desktop_helper.so`) load
   LineageOS `libgui_buffer_shim_vendor` instead of `libgui_vendor`, restoring
   the Android 15/16 `BufferItemConsumer` ABI (the original blob is verified by
   SHA-256 first; needs `patchelf`);
4. installs the pinned OpenEUICC Maven dependencies from Maven Central;
5. hides the historical OpenEUICC template so Soong sees one definition;
6. verifies every patch and downloaded file by SHA-256.

It can be run again safely. Already applied patches and valid dependencies are
verified instead of being applied or downloaded twice.

The manifest pins frameworks/av to the exact revision expected by this
script. Any revision mismatch stops the operation.

This directory intentionally contains no signing keys or other secrets.
