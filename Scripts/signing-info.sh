#!/bin/zsh
set -euo pipefail
ROOT="${0:A:h:h}"
source "$ROOT/edition.conf"
print "Edition: $APP_NAME ($BUNDLE_ID)"
print ""
print "Available code-signing identities:"
/usr/bin/security find-identity -v -p codesigning || true
print ""
if [[ -n "${WALLFLOW_CODESIGN_IDENTITY:-}" ]]; then
  print "Build identity selected: $WALLFLOW_CODESIGN_IDENTITY"
else
  print "Build identity selected: ad hoc (-)"
fi
APP="$ROOT/dist/$APP_NAME.app"
if [[ -d "$APP" ]]; then
  print ""
  print "Current dist app:"
  /usr/bin/codesign -dv --verbose=2 "$APP" 2>&1 | /usr/bin/grep -E '^(Identifier|Authority|TeamIdentifier|Signature)=' || true
fi
print ""
print "A consistent certificate, bundle ID, and app path help preserve macOS permissions."
print "This script does not create certificates or change Accessibility settings."
