#!/usr/bin/env bash
# scripts/screenshots.sh — capture App Store screenshots at 2560×1600 on a Retina Mac.
#
#   bash scripts/screenshots.sh          # all five shots, one after another
#   bash scripts/screenshots.sh overlay  # just one (names below)
#
# Each shot: set the screen up as the prompt says, press Return, and after a 3-second
# countdown a 1280×800-point region is captured. On a Retina display (2× scale) that is
# 2560×1600 pixels, which is one of the sizes App Store Connect accepts for Mac apps.
# Files land in build/screenshots/. Tips: use a plain wallpaper (System Settings →
# Wallpaper), hide other windows (⌘⌥H in Shoo), and keep anything personal out of frame.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO_ROOT/build/screenshots"
mkdir -p "$OUT"

W=1280; H=800
read -r SW SH < <(osascript -e 'tell application "Finder" to get bounds of window of desktop' \
  | awk -F', ' '{print $3, $4}')

# name|anchor|instructions
SHOTS=(
  "onboarding|center|Settings → Show onboarding again. Leave the welcome window on its first page, centered."
  "privacy|center|In the onboarding window, go to the privacy page (the one that explains on-device processing)."
  "menu|topright|Click the Shoo hand icon in the menu bar so the popover is open. Keep it open with the mouse away."
  "settings|center|Open Settings from the menu and move the window to the middle of the screen."
  "overlay|center|Settings → Preview Reminder. Press Return here the moment the reminder appears."
)

capture() {
  local name="$1" anchor="$2" hint="$3" x y file
  case "$anchor" in
    topright) x=$((SW - W)); y=0 ;;
    *)        x=$(((SW - W) / 2)); y=$(((SH - H) / 2)) ;;
  esac
  file="$OUT/$name.png"
  echo
  echo "== $name =="
  echo "   $hint"
  read -r -p "   Ready? Press Return to capture in 3 seconds… "
  for i in 3 2 1; do printf '   %s\r' "$i"; sleep 1; done
  screencapture -x -R "$x,$y,$W,$H" "$file"
  local pw ph
  pw=$(sips -g pixelWidth "$file" | awk '/pixelWidth/ {print $2}')
  ph=$(sips -g pixelHeight "$file" | awk '/pixelHeight/ {print $2}')
  if [[ "$pw" == 2560 && "$ph" == 1600 ]]; then
    echo "   saved $file (2560×1600)"
  else
    echo "   saved $file but it is ${pw}×${ph}, not 2560×1600."
    echo "   Use the built-in Retina display, or set System Settings → Displays to 'Default for display', and retry."
  fi
}

if [[ $# -gt 0 ]]; then
  for want in "$@"; do
    for s in "${SHOTS[@]}"; do
      IFS='|' read -r name anchor hint <<< "$s"
      [[ "$name" == "$want" ]] && capture "$name" "$anchor" "$hint"
    done
  done
else
  for s in "${SHOTS[@]}"; do
    IFS='|' read -r name anchor hint <<< "$s"
    capture "$name" "$anchor" "$hint"
  done
fi

echo
echo "Done. Upload the PNGs in $OUT to App Store Connect → 1.0.0 → App Screenshots (Mac)."
open "$OUT"
