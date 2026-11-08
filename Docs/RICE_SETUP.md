# Wallflow Rice setup

This edition requires both Ghostty and Matugen. The standalone Core edition does not.

## 1. Install dependencies

Install Ghostty and Matugen from their official distribution channels. With Homebrew, check current formula availability using `brew info ghostty matugen` before installing.

## 2. Configure Matugen

Wallflow Rice expects `~/.config/matugen/config.toml` to provide a Ghostty output template. A sample template is included under `Examples/`.

For an existing setup, keep your working Matugen config. The app will call `matugen -c <config> image <wallpaper> --mode dark --source-color-index <n>`.

Make sure Ghostty loads the generated colors file via its supported `config-file` setting. Do not overwrite an existing Ghostty configuration without checking it.

## 3. Accessibility and reload

The current Rice integration uses the macOS Accessibility API to open Ghostty's Reload Configuration menu. Give the installed Wallflow Rice app Accessibility permission if prompted. macOS may not preserve approval across ad hoc signed rebuilds.

Known issue: Ghostty's menu briefly appears when reloading. This must be corrected before a stable public Rice release. No other app uses Accessibility in the Core edition.

## 4. Wallpaper library

Choose any folder containing supported local images. Existing users with `~/wallpapers` will have that folder detected automatically. Images may be placed directly in the root or organized into category subfolders.
