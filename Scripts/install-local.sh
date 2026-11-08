#!/bin/zsh
set -euo pipefail
ROOT="${0:A:h:h}"
source "$ROOT/edition.conf"
APP="$HOME/Applications/$APP_NAME.app"
if [[ -e "$APP" ]]; then
  echo "Already installed: $APP" >&2
  echo "This installer never overwrites installed applications." >&2
  exit 1
fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
"$ROOT/Scripts/build-app.sh" "$TMP"
mkdir -p "$HOME/Applications"
/usr/bin/ditto "$TMP/$APP_NAME.app" "$APP"
echo "Installed: $APP"
echo "Open it with: open -a '$APP'"
