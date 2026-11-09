# Build notes

ValkyOS needs **no setup script** after syncing: every change lives in the
repositories pinned by the manifest.

Until November 2026 `setup-valkyos.sh` patched the tree after `repo sync`.
Those changes now live here:

| Change | Now in |
| --- | --- |
| `media/libheif` (Android 16 vendor blobs) | ValkyOS fork `android_frameworks_av` |
| Sensors permission (GrapheneOS) and the Android 16 `SurfaceComposerClient` ABI bridge | ValkyOS fork `android_frameworks_native` |
| Vanadium overrides and WebView provider list | `vanadium-overrides/` and `overlay/ValkyOSFrameworkOverlay` (Vanadium is synced to `vendor/vanadium`) |
| Motorola camera helper (`libgui_buffer_shim_vendor`) | eqe device tree (blob fixup) and eqe vendor repository |
| Moto Camera SELinux domain (portrait) | eqe device tree and the eqe fork of `device/qcom/sepolicy_vndr` |
| OpenEUICC Maven dependencies | eqe device tree (`openeuicc/`) |

`patches/` keeps the original framework patches for reference only; nothing
applies them.

This directory intentionally contains no signing keys or other secrets.
