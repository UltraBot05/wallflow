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

Run `./Scripts/build-app.sh` on a Mac with the Xcode Command Line Tools installed. Test an empty library, a folder containing images at its root, nested folders, search, color filters, favorites, multiple displays and full screen. Both editions compile in GitHub Actions and have been exercised on an Apple Silicon development Mac. Additional device testing is welcome.

## Releases

Keep editions independent and identifiable. Never publish a Mac app with ad hoc signing as a polished distribution release. Decide a code-signing and notarization process, install/upgrade behavior, licensing and user documentation first.

## Repeatable local builds

Run `./Scripts/verify-repo.sh` to catch source separation and tracked-file mistakes.

`./Scripts/build-app.sh` refuses to overwrite an existing build by default. To rebuild, quit the edition first, then run `./Scripts/build-app.sh --replace`. The old build is saved as a ZIP under `dist/.wallflow-backups/` before replacement.

Use `./Scripts/signing-info.sh` to see the signing identity. With a compatible code-signing certificate already available, set `WALLFLOW_CODESIGN_IDENTITY` to its name or fingerprint when building. Ad hoc signing (`-`) is for local development only and may invalidate Accessibility approval after each rebuild. The build script cannot create or trust a signing identity automatically.

Local source builds are not notarized distribution builds. The `--replace` flag only affects the ignored `dist` directory, not the installed app in `~/Applications`.
