# Reproducible Android 17 setup

After syncing the manifest, run from the Android source root:

```bash
bash vendor/valkyos/build/setup-valkyos.sh "$PWD"
```

The script:

1. (frameworks/av and frameworks/native are ValkyOS forks since November 2026:
   libheif, the Sensors permission and the Android 16 `SurfaceComposerClient`
   ABI bridge are already in them, so the script no longer patches them; the
   files in `patches/` are kept for reference);
3. (the Motorola camera helper fix and the Moto Camera SELinux domain moved to
   the eqe repositories: blob fixup and sepolicy in the device tree, the fixed
   blob in the vendor repository and the xDSP exception in the eqe fork of
   device/qcom/sepolicy_vndr);
4. installs the pinned OpenEUICC Maven dependencies from Maven Central;
5. hides the historical OpenEUICC template so Soong sees one definition;
6. verifies every downloaded file by SHA-256.

It can be run again safely. Already applied patches and valid dependencies are
verified instead of being applied or downloaded twice.

The framework changes come from the ValkyOS forks pinned in the manifest.

This directory intentionally contains no signing keys or other secrets.
