# Release checklist

Both `main` and `rice` are active. These are separate editions, not old and new versions.

## Common requirements

- [ ] Build from a fresh checkout on a supported macOS release.
- [ ] Test an empty library and selecting a folder through the picker.
- [ ] Test root-level and nested wallpaper folders, search, color filters, favorites, and multiple displays.
- [ ] Test resizing, fullscreen, Dock icon, and inspector layout.
- [ ] Review source and icon ownership. Choose and add a license before public distribution.
- [ ] Replace local ad hoc code signing with an appropriate distribution identity.
- [ ] Package, notarize, and verify installation on a second Mac.
- [ ] Write privacy and installation documentation for users unfamiliar with Swift or Homebrew.
- [ ] Use GitHub Releases only after running a clean install test.

## Core edition

- [ ] Launch with Ghostty and Matugen absent.
- [ ] Wallpaper selection and application must work without any terminal-related permissions.
- [ ] Verify that optional apps cannot block wallpaper application.

## Rice edition

- [ ] Validate dependency prompts when Ghostty or Matugen is missing.
- [ ] Verify generation of Ghostty colors and reload on a clean, consenting test machine.
- [ ] Fix the visible Ghostty application menu flash.
- [ ] Avoid unannounced focus stealing and clearly explain Accessibility permissions.
- [ ] Verify Accessibility trust and reload behavior after signing and upgrading.

Do not call either branch release-ready while the corresponding unchecked items remain.
