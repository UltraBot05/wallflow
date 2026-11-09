#!/bin/zsh
set -euo pipefail
ROOT="${0:A:h:h}"
source "$ROOT/edition.conf"

fail() { print -u2 "FAIL: $1"; exit 1 }
[[ -f "$ROOT/Resources/AppIcon.icns" ]] || fail "Missing source app icon"
[[ -f "$ROOT/Sources/Wallflow/Library.swift" ]] || fail "Missing library source"
[[ -f "$ROOT/Sources/Wallflow/Views.swift" ]] || fail "Missing UI source"
[[ -f "$ROOT/Docs/RELEASE_CHECKLIST.md" ]] || fail "Missing release checklist"

if [[ "$EDITION" == "core" ]]; then
  [[ ! -e "$ROOT/Sources/Wallflow/RiceIntegration.swift" ]] || fail "Rice integration must not exist on Core"
  if /usr/bin/grep -Eiq 'matugen|ghostty|AXUIElement|AXIsProcessTrusted' "$ROOT/Sources/Wallflow/"*.swift; then
    fail "Core source must not require external theme tools or Accessibility"
  fi
elif [[ "$EDITION" == "rice" ]]; then
  [[ -f "$ROOT/Sources/Wallflow/RiceIntegration.swift" ]] || fail "Rice integration missing"
  /usr/bin/grep -q 'checkRiceDependencies' "$ROOT/Sources/Wallflow/RiceIntegration.swift" || fail "Rice dependency check missing"
else
  fail "Unknown edition: $EDITION"
fi

if [[ -d "$ROOT/.git" ]]; then
  if git -C "$ROOT" ls-files | /usr/bin/grep -Eq '(^|/)(dist|build|wallpapers)/|\.p12$|\.dmg$|\.app/'; then
    fail "Generated build, personal wallpapers, or signing assets are tracked"
  fi
fi
print "Repository checks passed for $EDITION."
