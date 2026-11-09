# Wallflow release preparation

Both `main` (Core) and `rice` (Rice) are active release branches. Build and test each separately.

## Release names and tags

Use distinct tag prefixes in the same repository:

| Edition | Branch | Example tag | Proposed asset |
| --- | --- | --- | --- |
| Core | `main` | `core-v0.6.0-alpha.1` | `Wallflow-Core.dmg` |
| Rice | `rice` | `rice-v0.6.0-alpha.1` | `Wallflow-Rice.dmg` |

The names above are a **proposal**, not existing downloads or published tags. The product README links to the shared [Releases page](https://github.com/UltraBot05/wallflow/releases) until real releases exist.

When the binaries are signed, tested, and packaged, update the edition README to link to its actual release tag. Do not use `/releases/latest` as the edition-specific link, because the repository has two independent release lines.

## Minimum checks before a public download

1. Choose a license and verify ownership or permission to distribute the app icon, screenshot thumbnails, and other visual assets.
2. Run repository verification and GitHub Actions on both branches.
3. Test Core without Ghostty or Matugen. Test Rice with both dependencies installed, and with each dependency missing.
4. Test changing wallpaper folders, search, color filters, favorites, empty folders, and fullscreen.
5. Determine stable Developer ID signing and notarization. Ad hoc local signing is not a distributable signature.
6. Test installing and upgrading each app without deleting user data.
7. Record the Accessibility behavior and the menu-flash limitation in Rice release notes, unless fixed.
8. Build a DMG or ZIP with the exact edition in the filename, then verify the packaged binary on a separate Mac or fresh user account.

## Drafting releases with GitHub CLI

Only after real signed and tested artifacts exist:

```sh
# Example, not to run yet. Replace the path with the actual signed DMG.
gh release create core-v0.6.0-alpha.1 path/to/Wallflow-Core.dmg \
  --target main --draft --prerelease \
  --title 'Wallflow Core 0.6.0 alpha 1' \
  --notes-file path/to/core-release-notes.md

gh release create rice-v0.6.0-alpha.1 path/to/Wallflow-Rice.dmg \
  --target rice --draft --prerelease \
  --title 'Wallflow Rice 0.6.0 alpha 1' \
  --notes-file path/to/rice-release-notes.md
```

The example commands create draft releases with assets. Review their targets, artifacts, descriptions, permissions, and download behavior before publishing.

Avoid automatically updating the README with a guessed release asset URL. Link to the real published tag and filename only after verifying the release.
