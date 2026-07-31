#!/usr/bin/env bash

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#unfuck the doc
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.4
killall Dock


#stop dragging a window to the menu bar from filling the screen
#(System Settings > Desktop & Dock > Windows > "Drag windows to menu bar
# to fill screen"). side-edge tiling is left alone.
defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false
killall WindowManager 2>/dev/null || true


#---------------------------------------------------------------------
# homebrew
#---------------------------------------------------------------------
if command -v brew >/dev/null 2>&1; then
    echo "homebrew already installed: $(brew --version | head -1)"
else
    echo "installing homebrew (will prompt for your sudo password)..."
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

#make sure brew is on PATH for the rest of this script, fresh install or not
if ! command -v brew >/dev/null 2>&1; then
    for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [ -x "$candidate" ] && eval "$("$candidate" shellenv)" && break
    done
fi
command -v brew >/dev/null 2>&1 || { echo "brew not on PATH, bailing"; exit 1; }


#---------------------------------------------------------------------
# text editing keys (home/end, word-wise delete) via Cocoa key bindings
#---------------------------------------------------------------------
KB_DIR="$HOME/Library/KeyBindings"
KB_FILE="$KB_DIR/DefaultKeyBinding.dict"
mkdir -p "$KB_DIR"
if [ -f "$KB_FILE" ] && ! cmp -s "$HERE/DefaultKeyBinding.dict" "$KB_FILE"; then
    cp "$KB_FILE" "$KB_FILE.bak.$(date +%Y%m%d%H%M%S)"
    echo "backed up existing $KB_FILE"
fi
plutil -lint "$HERE/DefaultKeyBinding.dict" >/dev/null
cp "$HERE/DefaultKeyBinding.dict" "$KB_FILE"
echo "installed $KB_FILE (restart apps to pick it up)"


#---------------------------------------------------------------------
# ghostty
#---------------------------------------------------------------------
if [ -d "/Applications/Ghostty.app" ]; then
    echo "ghostty already installed"
else
    echo "installing ghostty..."
    brew install --cask ghostty
fi

#the config asks for Hasklig, so make sure it exists or ghostty silently
#falls back to a default font
if ls ~/Library/Fonts /Library/Fonts 2>/dev/null | grep -qi hasklig; then
    echo "hasklig already installed"
else
    echo "installing hasklig..."
    brew install --cask font-hasklig
fi

GHOSTTY_DIR="$HOME/.config/ghostty"
GHOSTTY_FILE="$GHOSTTY_DIR/config"
mkdir -p "$GHOSTTY_DIR"
if [ -f "$GHOSTTY_FILE" ] && ! cmp -s "$HERE/ghostty.config" "$GHOSTTY_FILE"; then
    cp "$GHOSTTY_FILE" "$GHOSTTY_FILE.bak.$(date +%Y%m%d%H%M%S)"
    echo "backed up existing $GHOSTTY_FILE"
fi
cp "$HERE/ghostty.config" "$GHOSTTY_FILE"
echo "installed $GHOSTTY_FILE"


#---------------------------------------------------------------------
# karabiner-elements: make ctrl work like cmd, everywhere except terminals
#
# this does NOT swap anything -- cmd keeps working exactly as it does now.
# it only translates the ctrl combos listed below into their cmd equivalents.
#---------------------------------------------------------------------
if [ -d "/Applications/Karabiner-Elements.app" ]; then
    echo "karabiner-elements already installed"
else
    echo "installing karabiner-elements (will prompt for your sudo password)..."
    brew install --cask karabiner-elements
fi

#apps that keep real ctrl. regex, so uninstalled ones are harmless.
COND='{ "type": "frontmost_application_unless", "bundle_identifiers": [
            "^com\\.apple\\.Terminal$",
            "^com\\.mitchellh\\.ghostty$",
            "^com\\.googlecode\\.iterm2$",
            "^org\\.alacritty$",
            "^net\\.kovidgoyal\\.kitty$",
            "^com\\.github\\.wez\\.wezterm$"
          ] }'

MANIPS=""
add_manip() {
    [ -n "$MANIPS" ] && MANIPS="$MANIPS,"
    MANIPS="$MANIPS$1"
}

# ctrl+<key> -> cmd+<key>. shift passes through, so ctrl-shift-z = cmd-shift-z.
map_to_cmd() {
    add_manip "$(cat <<MANIP
        {
          "type": "basic",
          "from": { "key_code": "$1",
                    "modifiers": { "mandatory": ["control"], "optional": ["shift"] } },
          "to": [ { "key_code": "$1", "modifiers": ["left_command"] } ],
          "conditions": [ $COND ]
        }
MANIP
)"
}

# ctrl+<key> -> option+<key>, for the word-wise nav/delete keys
map_to_option() {
    add_manip "$(cat <<MANIP
        {
          "type": "basic",
          "from": { "key_code": "$1",
                    "modifiers": { "mandatory": ["control"], "optional": ["shift"] } },
          "to": [ { "key_code": "$1", "modifiers": ["left_option"] } ],
          "conditions": [ $COND ]
        }
MANIP
)"
}

# a=select all  b/i/u=bold/italic/underline  c/x/v=clipboard  d=bookmark
# f=find  g=find next  l=address bar  n=new  o=open  p=print  r=reload
# s=save  t=new tab  w=close tab  y/z=redo/undo
# q is deliberately left out -- ctrl-q typos would quit apps.
for k in a b c d f g i l n o p r s t u v w x y z; do
    map_to_cmd "$k"
done

# 1-9 jump to tab N, 0 resets zoom
for k in 1 2 3 4 5 6 7 8 9 0; do
    map_to_cmd "$k"
done

# ctrl-plus / ctrl-minus zoom
for k in equal_sign hyphen; do
    map_to_cmd "$k"
done

# word-at-a-time movement and delete.
# NOTE: this takes over ctrl-left/right from Mission Control's "move a space".
# karabiner rewrites the event before the system hotkey sees it, so you do not
# need to disable anything -- but you also lose ctrl-arrow space switching.
# delete the left_arrow/right_arrow lines below if you want spaces back.
for k in left_arrow right_arrow delete_or_backspace delete_forward; do
    map_to_option "$k"
done

KARA_DIR="$HOME/.config/karabiner"
KARA_FILE="$KARA_DIR/karabiner.json"
mkdir -p "$KARA_DIR"

TMP_KARA="$(mktemp -t karabiner)"
cat > "$TMP_KARA" <<JSON
{
  "global": {
    "check_for_updates_on_startup": true,
    "show_in_menu_bar": true,
    "show_profile_name_in_menu_bar": false
  },
  "profiles": [
    {
      "name": "Default profile",
      "selected": true,
      "virtual_hid_keyboard": { "keyboard_type_v2": "ansi" },
      "complex_modifications": {
        "parameters": {},
        "rules": [
          {
            "description": "ctrl acts as cmd (alongside cmd, except in terminals)",
            "manipulators": [
$MANIPS
            ]
          }
        ]
      }
    }
  ]
}
JSON

#plutil only speaks plist, so use jq (ships in /usr/bin on modern macOS) or python3
if command -v jq >/dev/null 2>&1; then
    jq empty "$TMP_KARA" || { echo "generated karabiner.json is invalid, bailing"; exit 1; }
elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$TMP_KARA" \
        || { echo "generated karabiner.json is invalid, bailing"; exit 1; }
else
    echo "warning: no jq or python3, skipping json validation"
fi

#semantic check of the rules, once karabiner is actually installed
KARA_CLI="/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
if [ -x "$KARA_CLI" ]; then
    "$KARA_CLI" --lint-complex-modifications "$TMP_KARA" >/dev/null \
        || echo "warning: karabiner_cli did not like the rules, check them in the GUI"
fi

if [ -f "$KARA_FILE" ] && ! cmp -s "$TMP_KARA" "$KARA_FILE"; then
    cp "$KARA_FILE" "$KARA_FILE.bak.$(date +%Y%m%d%H%M%S)"
    echo "backed up existing $KARA_FILE"
fi
mv "$TMP_KARA" "$KARA_FILE"
echo "installed $KARA_FILE"

cat <<'NOTE'

karabiner needs two things granted by hand the first time -- macOS will not
let a script do either of them:

  1. open Karabiner-Elements.app. approve the driver extension when prompted
     (System Settings > General > Login Items & Extensions > Driver Extensions)
  2. System Settings > Privacy & Security > Input Monitoring
     enable karabiner_grabber and karabiner_observer
  3. reboot

after that, re-running this script just updates the mapping -- karabiner
watches karabiner.json and reloads it live.

heads up: re-running clobbers any rules you added in the karabiner GUI.
add them to this script instead (a .bak is written either way).
NOTE
