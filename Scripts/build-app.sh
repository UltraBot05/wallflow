#!/bin/zsh
set -euo pipefail
ROOT="${0:A:h:h}"
source "$ROOT/edition.conf"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Wallflow must be built on macOS with Apple Command Line Tools." >&2
  exit 1
fi
if ! xcrun --find swiftc >/dev/null 2>&1; then
  echo "Swift compiler not found. Run: xcode-select --install" >&2
  exit 1
fi
OUT="${1:-$ROOT/dist}"
mkdir -p "$OUT"
APP="$OUT/$APP_NAME.app"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FILES=("$ROOT/Sources/Wallflow/ImageIndex.swift" "$ROOT/Sources/Wallflow/Library.swift" "$ROOT/Sources/Wallflow/Views.swift")
if [[ "$EDITION" == "rice" ]]; then
  FILES+=("$ROOT/Sources/Wallflow/RiceIntegration.swift")
fi
xcrun swiftc -Onone -parse-as-library -target "$(uname -m)-apple-macos14.0" "${FILES[@]}" -o "$TMP/Wallflow"
mkdir -p "$TMP/$APP_NAME.app/Contents/MacOS" "$TMP/$APP_NAME.app/Contents/Resources"
cp "$TMP/Wallflow" "$TMP/$APP_NAME.app/Contents/MacOS/Wallflow"
cp "$ROOT/Resources/AppIcon.icns" "$TMP/$APP_NAME.app/Contents/Resources/AppIcon.icns"
cat > "$TMP/$APP_NAME.app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
<key>CFBundleExecutable</key><string>Wallflow</string>
<key>CFBundleName</key><string>$APP_NAME</string>
<key>CFBundleDisplayName</key><string>$APP_NAME</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
# Local developer signing. Use a stable certificate for distribution.
/usr/bin/codesign --force --sign "${WALLFLOW_CODESIGN_IDENTITY:--}" --timestamp=none "$TMP/$APP_NAME.app"
/usr/bin/codesign --verify "$TMP/$APP_NAME.app"
if [[ -e "$APP" ]]; then
  echo "Refusing to replace existing build: $APP" >&2
  echo "Remove that build explicitly or supply a different output directory." >&2
  exit 1
fi
/usr/bin/ditto "$TMP/$APP_NAME.app" "$APP"
echo "Built: $APP"
