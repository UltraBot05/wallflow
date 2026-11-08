# Data handling

Wallflow Core uses a folder chosen by the user and Apple's desktop wallpaper API. It does not upload images. It stores favorites and color index data locally in `~/.config/wallflow` and remembers the chosen folder in application preferences.

Wallflow Rice invokes a locally installed Matugen binary and uses macOS Accessibility to ask Ghostty to reload its configuration. Rice's Accessibility behavior and possible menu flash must be disclosed and improved before public release.

These statements describe this source snapshot. Recheck them whenever functionality changes.
