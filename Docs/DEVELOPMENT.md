# Development

## Branch policy

`main` and `rice` are both active release lines. Keep common gallery fixes and security improvements synchronized across branches. Cherry-pick or merge shared commits deliberately and test both editions after any common change.

## Source layout

- `Sources/Wallflow/ImageIndex.swift`: image thumbnails, dominant color classification, shared models
- `Sources/Wallflow/Library.swift`: user-selected folders, scanning, favorites, wallpaper application
- `Sources/Wallflow/Views.swift`: native SwiftUI window, gallery, inspector
- `Sources/Wallflow/RiceIntegration.swift`: present only on the `rice` branch
- `Resources/AppIcon.icns`: app icon
- `Scripts/build-app.sh`: local macOS build
- `Scripts/install-local.sh`: non-overwriting install

## Source vs personal data

Track source, scripts, documentation and owned artwork. Never track `~/wallpapers`, actual wallpaper images, `~/.config/wallflow` runtime JSON, user preferences, Ghostty's config, generated Matugen palettes, private signing keys or locally built `.app` bundles.

## Build verification

Run `./Scripts/build-app.sh` on a Mac with the Xcode Command Line Tools installed. Test an empty library, a folder containing images at its root, nested folders, search, color filters, favorites, multiple displays and full screen. This source was restructured outside macOS and needs a real Apple SDK compile before publishing.

## Releases

Keep editions independent and identifiable. Never publish a Mac app with ad hoc signing as a polished distribution release. Decide a code-signing and notarization process, install/upgrade behavior, licensing and user documentation first.
