# Wallflow Rice 0.6.0 alpha 1

First developer alpha for Wallflow Rice, the native wallpaper manager with required Ghostty and Matugen integration.

## Included

- Wallpaper gallery, local collections, search, filters, favorites, and native wallpaper application
- Matugen palette generation from the selected wallpaper
- Ghostty configuration reload after a wallpaper change
- Separate app identity from Wallflow Core

## Requirements

macOS 14 or later, Ghostty, Matugen, a working Ghostty color template in Matugen, and Accessibility approval for the current Ghostty reload implementation. Source builds require Apple Command Line Tools or Xcode.

## Known issue

The Accessibility-based Ghostty reload briefly opens the Ghostty application menu. This is tracked in [issue #1](https://github.com/UltraBot05/wallflow/issues/1). Ad hoc signing may cause permission approval to be lost after rebuilding.

## Distribution status

This is a private **draft release** for source review and release preparation. No signed or notarized application binary is included yet. The source archives provided by GitHub are not one-click macOS applications.

## Remaining before public distribution

- Remove menu flash or document its implications for alpha testers
- Stabilize signing and verify Accessibility behavior
- Confirm rights to redistribute bundled icon and screenshots
- Package, Developer ID sign, notarize, and test a downloadable macOS app

See the `rice` branch and `Docs/RICE_SETUP.md` for source instructions.
