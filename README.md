<div align="center">
  <img src="Docs/Brand/wallflow-icon.png" width="92" alt="Wallflow icon">
  <h1>Wallflow Rice</h1>
  <p><strong>Your wallpaper. Your terminal. One palette.</strong></p>
  <p>A native macOS wallpaper library with Matugen color generation and Ghostty integration.</p>
  <p>
    <a href="https://github.com/UltraBot05/wallflow/releases"><strong>Releases</strong></a>
    &nbsp;&middot;&nbsp;
    <a href="https://github.com/UltraBot05/wallflow/tree/main">Wallflow Core</a>
    &nbsp;&middot;&nbsp;
    <a href="https://github.com/UltraBot05/wallflow/issues/1">Known reload issue</a>
  </p>
  <p>
    <img alt="Rice build status" src="https://github.com/UltraBot05/wallflow/actions/workflows/build.yml/badge.svg?branch=rice">
    &nbsp; Swift + SwiftUI &nbsp; | &nbsp; macOS 14+
  </p>
</div>

![Wallflow Rice gallery with wallpaper and dynamic terminal color settings](Docs/Screenshots/wallflow-rice.png)

<sub>Wallflow Rice on macOS. Screenshot from a development build.</sub>

## Wallpaper browsing, with color coordination

Rice brings the same image-first wallpaper browser as Core, then coordinates your Ghostty terminal palette with the wallpaper you apply.

- **Browse your own files.** Search, collections, color filters, dark-only filtering, and favorites.
- **Apply wallpapers natively.** Preview and set the desktop image from the gallery.
- **Generate colors.** Use Matugen to create a palette from the selected wallpaper.
- **Reload Ghostty.** Apply the generated terminal colors when the wallpaper changes.
- **Keep both editions.** Rice and Core use separate app identities and are both actively maintained.

## Requirements

| | Wallflow Rice |
| --- | --- |
| macOS | 14 or newer |
| [Ghostty](https://ghostty.org/) | **Required** |
| [Matugen](https://github.com/InioX/matugen) | **Required** |
| Matugen Ghostty output template | **Required for recoloring** |
| Accessibility permission | Currently needed for the Ghostty menu reload |

If you just want wallpaper management without those dependencies, choose **[Wallflow Core](https://github.com/UltraBot05/wallflow/tree/main)**.

## Download and install

**[View GitHub Releases](https://github.com/UltraBot05/wallflow/releases)**

Signed, downloadable builds are being prepared. In the meantime, build from source:

```sh
git clone https://github.com/UltraBot05/wallflow.git
cd wallflow
git switch rice
./Scripts/verify-repo.sh
./Scripts/build-app.sh
open "dist/Wallflow Rice.app"
```

Source builds require Xcode or Apple Command Line Tools. See **[Rice setup](Docs/RICE_SETUP.md)** for installing Ghostty and Matugen, linking the generated Ghostty colors, and granting access to the current local build.

## How it works

1. Select your local wallpaper folder.
2. Choose a wallpaper and click **Set Desktop Wallpaper**.
3. Wallflow uses Matugen to generate a matching palette.
4. Rice requests a Ghostty configuration reload so the new colors take effect.

**Known issue:** the current reload method briefly opens Ghostty's application menu and requires Accessibility permission. It works in local testing, but it is not yet a silent integration. **[Follow issue #1](https://github.com/UltraBot05/wallflow/issues/1)**.

## Two active editions

| | **Core** (`main`) | **Rice** (`rice`) |
| --- | --- | --- |
| Wallpaper gallery and native application | Yes | Yes |
| Matugen and Ghostty required | No | Yes |
| Automatic terminal recoloring | No | Yes |
| Ongoing development | Active | Active |

The Rice branch is not a legacy or experimental archive. Shared UI changes and fixes are maintained across both editions.

## Privacy and development

Your images stay in their chosen folder. Rice invokes locally installed tools and uses macOS Accessibility to request a Ghostty reload. It does not need you to commit wallpapers, generated palettes, or private settings to Git.

- [Rice setup](Docs/RICE_SETUP.md)
- [Development notes](Docs/DEVELOPMENT.md)
- [Privacy notes](Docs/PRIVACY.md)
- [Release preparation](Docs/RELEASE_GUIDE.md)
- [Issues](https://github.com/UltraBot05/wallflow/issues)

**License:** [MIT](LICENSE). See [asset and third-party rights](Docs/ASSET_RIGHTS.md).
