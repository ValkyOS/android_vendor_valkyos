# Reproducible Android 17 setup

After syncing the manifest, run from the Android source root:

```bash
bash vendor/valkyos/build/setup-valkyos.sh "$PWD"
```

The script:

1. verifies and applies the `frameworks/av` libheif compatibility patch;
2. verifies and applies the Android 16 `SurfaceComposerClient` ABI bridge;
3. installs the pinned OpenEUICC Maven dependencies from Maven Central;
4. hides the historical OpenEUICC template so Soong sees one definition;
5. verifies every patch and downloaded file by SHA-256.

It can be run again safely. Already applied patches and valid dependencies are
verified instead of being applied or downloaded twice.

The manifest pins the two framework repositories to the exact revisions
expected by this script. Any revision mismatch stops the operation.

This directory intentionally contains no signing keys or other secrets.
