# Wallflow Core

A native wallpaper browser for macOS. Choose your own image folder, browse collections, filter by color, save favorites, and set desktop wallpapers.

**Core does not require Ghostty, Matugen, FloatPane, skhd, Homebrew, or a pre-existing wallpaper directory.**

## Requirements

- macOS 14 or later
- Swift compiler from Xcode or Apple Command Line Tools, for local source builds
- A folder of your own wallpaper images

## Local build

```sh
./Scripts/build-app.sh
open "dist/Wallflow Core.app"
```

Or install beside your other apps without overwriting existing installations:

```sh
./Scripts/install-local.sh
```

On first launch, choose a folder. Wallflow reads images from that folder and does not copy them into the repository.

## Two maintained editions

- `main`: Wallflow Core. A standalone native wallpaper manager.
- `rice`: Wallflow Rice. The same wallpaper manager with required Matugen and Ghostty integration.

Both branches are maintained. Neither is legacy. The edition-specific app bundles use different names and identifiers, so they can coexist.

## Development

The app currently builds directly with `swiftc`. See `Docs/DEVELOPMENT.md` for source structure, testing limitations and release checklist.

No personal wallpapers, generated themes, screenshots or local application data should be committed. For bug reports and planned work, use GitHub Issues after the new remote is created.

## License

A public distribution license has not been chosen yet. Do not publish binary releases until licensing and icon provenance are checked.

## Developer verification

Before pushing commits, run:

```sh
./Scripts/verify-repo.sh
./Scripts/build-app.sh --replace
```

The second command replaces only this branch's ignored `dist` build after making a backup. See [development notes](Docs/DEVELOPMENT.md), [GitHub workflow](Docs/GITHUB_WORKFLOW.md) and [release checklist](Docs/RELEASE_CHECKLIST.md).
