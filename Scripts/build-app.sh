#!/bin/zsh
set -euo pipefail
ROOT="${0:A:h:h}"
source "$ROOT/edition.conf"

usage() {
  cat <<'HELP'
Usage: ./Scripts/build-app.sh [OUTPUT_DIRECTORY] [--replace]

Builds a macOS .app using the Apple Swift compiler.
By default, an existing build is never overwritten.

  --replace  Back up and replace an existing build in the output directory
  --help     Show this message

Local signing is ad hoc unless WALLFLOW_CODESIGN_IDENTITY is configured.
A rebuild may require renewed macOS Accessibility approval for Rice.
HELP
}

OUT="$ROOT/dist"
OUTPUT_SET=0
REPLACE=0
while (( $# > 0 )); do
  case "$1" in
    --replace) REPLACE=1 ;;
    --help|-h) usage; exit 0 ;;
    --*) print -u2 "Unknown flag: $1"; usage >&2; exit 2 ;;
    *)
      if (( OUTPUT_SET )); then
        print -u2 "Only one output directory may be provided."
        exit 2
      fi
      OUT="$1"
      OUTPUT_SET=1
      ;;
  esac
  shift
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  print -u2 "Wallflow must be built on macOS with the Apple Swift compiler."
  exit 1
fi
if ! xcrun --find swiftc >/dev/null 2>&1; then
  print -u2 "Swift compiler not found. Run: xcode-select --install"
  exit 1
fi

mkdir -p "$OUT"
OUT="${OUT:A}"
APP="$OUT/$APP_NAME.app"
if [[ -L "$APP" ]]; then
  print -u2 "Refusing to replace a symlink: $APP"
  exit 1
fi
if [[ -e "$APP" ]] && (( ! REPLACE )); then
  print -u2 "An existing build is present: $APP"
  print -u2 "Run ./Scripts/build-app.sh --replace to back up and replace it."
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FILES=("$ROOT/Sources/Wallflow/ImageIndex.swift" "$ROOT/Sources/Wallflow/Library.swift" "$ROOT/Sources/Wallflow/Views.swift")
if [[ "$EDITION" == "rice" ]]; then
  FILES+=("$ROOT/Sources/Wallflow/RiceIntegration.swift")
fi

# Build and sign BEFORE replacing the existing application.
xcrun swiftc -Onone -parse-as-library -target "$(uname -m)-apple-macos14.0" "${FILES[@]}" -o "$TMP/Wallflow"
STAGED="$TMP/$APP_NAME.app"
mkdir -p "$STAGED/Contents/MacOS" "$STAGED/Contents/Resources"
cp "$TMP/Wallflow" "$STAGED/Contents/MacOS/Wallflow"
cp "$ROOT/Resources/AppIcon.icns" "$STAGED/Contents/Resources/AppIcon.icns"
cat > "$STAGED/Contents/Info.plist" <<PLIST
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
/usr/bin/codesign --force --sign "${WALLFLOW_CODESIGN_IDENTITY:--}" --timestamp=none "$STAGED"
/usr/bin/codesign --verify "$STAGED"
/usr/bin/plutil -lint "$STAGED/Contents/Info.plist" >/dev/null

if [[ ! -e "$APP" ]]; then
  /usr/bin/ditto "$STAGED" "$APP"
  print "Built: $APP"
  exit 0
fi

# Preserve the previous .app as a ZIP before changing any bytes.
BACKUP_DIR="$OUT/.wallflow-backups"
mkdir -p "$BACKUP_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)-$$"
BACKUP="$BACKUP_DIR/${EDITION}-${STAMP}.zip"
/usr/bin/ditto -c -k --keepParent "$APP" "$BACKUP"
PREVIOUS="$OUT/.wallflow-previous-${STAMP}.app"
/bin/mv "$APP" "$PREVIOUS"
if /usr/bin/ditto "$STAGED" "$APP"; then
  /bin/rm -rf "$PREVIOUS"
  print "Built: $APP"
  print "Previous build backed up at: $BACKUP"
else
  /bin/rm -rf "$APP"
  /bin/mv "$PREVIOUS" "$APP"
  print -u2 "Replacement failed. Previous build restored from staged copy."
  exit 1
fi
