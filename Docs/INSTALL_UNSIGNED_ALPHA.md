# Install Wallflow alpha on macOS

Wallflow is a native, open-source macOS wallpaper manager. There are two actively maintained editions:

- **Wallflow Core**: a local wallpaper library with no terminal dependencies.
- **Wallflow Rice**: requires Ghostty and Matugen and can automatically recolor Ghostty when applying a wallpaper.

## Read before downloading

These are **ad-hoc signed, unnotarized alpha builds for Apple Silicon Macs** running macOS 14 or later. They are not verified by Apple, have no automatic updater, and may contain bugs. Build from source if you prefer to inspect the code before running it. Only download from the official repository's GitHub Releases page.

macOS may block a downloaded application because its developer cannot be verified. **Do not turn off Gatekeeper or run commands that remove quarantine attributes.** If you have checked the source, download and checksum and decide you trust this build, Apple's documented option is to first attempt opening it, then visit **System Settings > Privacy & Security > Open Anyway** and confirm. This exception should only be used for software you trust. If macOS reports that the app contains malware or is damaged, do not override the warning.

Apple's instructions: https://support.apple.com/en-in/102445

## Install Core

1. Open the [releases page](https://github.com/UltraBot05/wallflow/releases) and select the Core alpha release.
2. Download the `Wallflow-Core-...-macos-arm64-unsigned.zip` asset and `SHA256SUMS.txt`.
3. Verify the ZIP checksum with `shasum -a 256 <filename.zip>` and compare with `SHA256SUMS.txt`.
4. Open the ZIP and drag **Wallflow Core.app** to Applications.
5. Open Wallflow Core and select a local folder containing your wallpapers.

Core does not need Ghostty, Matugen or Accessibility permission.

## Install Rice

1. Install [Ghostty](https://ghostty.org/) and [Matugen](https://github.com/InioX/matugen) separately.
2. Configure Matugen to generate Ghostty colors and tell Ghostty to include that output file. See [Rice setup](https://github.com/UltraBot05/wallflow/blob/rice/Docs/RICE_SETUP.md).
3. Download `Wallflow-Rice-...-macos-arm64-unsigned.zip` and verify its checksum as above.
4. Open the ZIP and drag **Wallflow Rice.app** to Applications.
5. macOS may request Accessibility permission for Wallflow Rice. The current integration uses that permission to trigger Ghostty's **Reload Configuration** menu item. Only enable it if you want that integration. Rice may need approval again after updating an unsigned build.

**Known limitation:** Rice may briefly display Ghostty's application menu when updating colors. This is tracked in [issue #1](https://github.com/UltraBot05/wallflow/issues/1).

## Build from source instead

On a Mac with Xcode Command Line Tools, clone the repo and switch to `main` for Core or `rice` for Rice, then run `./Scripts/verify-repo.sh && ./Scripts/build-app.sh`. Source builds do not bypass macOS security protections.

## Limitations

These initial archives are compiled for **arm64 (Apple Silicon)** only. They have no Apple-issued Developer ID signature. Intel Mac users should build from source with their own toolchain until universal builds are tested. Do not assume that a successful GitHub Actions build guarantees the app has been tested across every Mac or macOS version.

No warranties or Apple verification are implied by the alpha release. Source code is provided under the repository's MIT license; that license does not cover other people's wallpaper images.
