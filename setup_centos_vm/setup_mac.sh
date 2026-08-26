#!/usr/bin/env bash
#
# setup_mac.sh — fire-and-forget, idempotent macOS setup.
#
# Usage:  bash setup_mac.sh
#
# Design rules:
#   * Idempotent: safe to re-run any number of times. Steps that are
#     already in place are skipped; nothing is duplicated or overwritten
#     unless it changed.
#   * No system-level input remapping, no Karabiner edits, no sudo.
#     Everything lives inside app config directories, so the trackpad /
#     input stack is never touched.
#   * Each step is a function that returns 0 if it changed something,
#     1 if it was already done, and anything else on failure.
#
# Adding a step: write a function, then register it in STEPS below.

set -euo pipefail

LOG_PREFIX="[setup-mac]"

say()  { printf '%s %s\n' "$LOG_PREFIX" "$*"; }
warn() { printf '%s WARN: %s\n' "$LOG_PREFIX" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_PREFIX" "$*" >&2; exit 1; }

# ---------------------------------------------------------------- steps

FF_ADDON_URL="https://addons.mozilla.org/firefox/downloads/latest/force-ctrl-click-to-new-tab/"
FF_ADDON_ID="{12d4646d-7768-476e-a668-e309a6700e25}"   # fallback if the manifest can't be read
FF_ADDON_NAME="Force Ctrl+Click to New Tab"

# Print the default Firefox profile dir under the given base dir, or fail.
find_firefox_profile() {
  local base="$1" ini="$base/profiles.ini" path="" candidate
  ini="$base/profiles.ini"

  if [ -f "$ini" ]; then
    path="$(awk -F= '
      /^\[/      { if (default_found && dir != "") { print dir; exit }
                   default_found = 0; dir = ""; next }
      /^Default=1$/ { default_found = 1; next }
      /^Path=/    { dir = substr($0, 6); next }
      END         { if (default_found && dir != "") print dir }
    ' "$ini")" || true
  fi

  if [ -z "$path" ]; then
    candidate="$(ls -dt "$base"/Profiles/*.default* 2>/dev/null | head -1)"
    [ -n "$candidate" ] || candidate="$(ls -dt "$base"/Profiles/* 2>/dev/null | head -1)"
    [ -n "$candidate" ] || return 1
    path="$candidate"
  elif [ "${path#/}" = "$path" ]; then
    path="$base/$path"
  fi

  [ -d "$path" ] || return 1
  printf '%s' "$path"
}

install_firefox_ctrl_click_addon() {
  local base profile ext_dir tmp_dir tmp_xpi target id
  base="$HOME/Library/Application Support/Firefox"
  [ -d "$base" ] || die "Firefox is not installed (no $base). Install it, launch it once, then re-run."
  profile="$(find_firefox_profile "$base")" || die "No Firefox profile found. Launch Firefox once, then re-run."
  ext_dir="$profile/extensions"
  mkdir -p "$ext_dir"

  if pgrep -x firefox >/dev/null 2>&1 || pgrep -x Firefox >/dev/null 2>&1; then
    warn "Firefox is running; the add-on loads after a full quit and relaunch (Cmd+Q)."
  fi

  tmp_dir="$(mktemp -d)"
  if curl -fsSL -o "$tmp_dir/addon.xpi" "$FF_ADDON_URL"; then
    tmp_xpi="$tmp_dir/addon.xpi"
  else
    rm -rf "$tmp_dir"
    die "Failed to download $FF_ADDON_URL"
  fi

  id="$(unzip -p "$tmp_xpi" manifest.json 2>/dev/null | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')" || true
  [ -n "$id" ] || id="$FF_ADDON_ID"

  target="$ext_dir/$id.xpi"
  if [ -f "$target" ] && cmp -s "$tmp_xpi" "$target"; then
    say "$FF_ADDON_NAME is already installed and up to date."
    rm -rf "$tmp_dir"
    return 1
  fi

  cp "$tmp_xpi" "$target"
  rm -rf "$tmp_dir"
  say "Installed $FF_ADDON_NAME -> $target"
  say "Quit Firefox fully (Cmd+Q) and relaunch it for the add-on to load."
  return 0
}

# --------------------------------------------------------------- runner

declare -a STEPS=(
  "Firefox add-on: $FF_ADDON_NAME (Ctrl/Cmd+Click opens links in a new tab)|install_firefox_ctrl_click_addon"
)

main() {
  local changed=0 skipped=0 name fn rc
  if [ "${SETUP_MAC_SKIP_DARWIN_CHECK:-0}" != 1 ]; then
    [ "$(uname -s)" = "Darwin" ] || die "This script is for macOS only."
  fi
  say "Starting macOS setup ($(date '+%Y-%m-%d %H:%M'))"
  for entry in "${STEPS[@]}"; do
    name="${entry%%|*}"
    fn="${entry#*|}"
    say "==> $name"
    if "$fn"; then
      changed=$((changed + 1))
    else
      rc=$?
      case "$rc" in
        1) skipped=$((skipped + 1)); say "    already done, skipped" ;;
        *) die "step '$name' failed (rc=$rc)" ;;
      esac
    fi
  done
  say "Done: $changed changed, $skipped skipped."
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
