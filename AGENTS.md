# AGENTS.md

## Machine edits outside this repo (2026-08-27)

- You MAY edit the machine — OS-level changes, `~/.config`, `~/bin`,
  `~/.bashrc`, `/etc`, installed files, anything a `git checkout` cannot undo —
  but ONLY after asking the user and getting explicit approval for that edit.
  Ask every time; a past approval does not cover future edits.
- The preferred path is still: write the change as a file/script/module in this
  repo (e.g. `setup_mac/`, `setup_linux/`, `setup_linux_3rd_party/`) so it is
  committed, reversible, and applied by running the setup.
- Exception: creating/modifying files inside this repo's own working tree needs
  no approval.
- If you made an out-of-repo edit without asking, say so and revert it.

## Karabiner mouse / ctrl-click status (2026-08-24)

- Goal: ctrl-click opens a link in a new tab in browsers (acts as cmd-click). SOLVED 2026-08-25 via Hammerspoon eventtap, not Karabiner.
- Attempted and rejected: Karabiner complex modification `pointing_button button1 + control → button1 + left_command` scoped to browsers, plus auto-enabling pointing devices in the config (`devices: [{"identifiers": {"is_pointing_device": true}, "ignore": false}]` and `ignore_pointing_device_events_by_default: false`). This required ticking "Modify events" for the mouse in the Karabiner GUI. Result: user's mouse broke.
- Removed: that rule, the devices entries, and the flag from both `setup_mac/setup.sh` and the installed `~/.config/karabiner/karabiner.json`. Then fully uninstalled Karabiner (official `uninstall.sh`, DriverKit extension deactivated via `Karabiner-VirtualHIDDevice-Manager deactivate`); config moved to `~/.config/karabiner.disabled-20260824`. After reboot the mouse worked again.
- Reinstalled: Karabiner-Elements 16.1.0 fresh; `setup.sh` now writes keyboard-only rules (ctrl-as-cmd except terminals, F5 reload). No mouse/pointing-device config anywhere.
- Constraint for any future ctrl-click work: MUST NOT enable Karabiner mouse event modification — no "Modify events" tick for mice, no pointing-device entries, no pointing flags. That is what broke the mouse.
- Current solution: Hammerspoon eventtap. `setup_mac/hammerspoon.init.lua` (installed to `~/.hammerspoon/init.lua` by `setup.sh`) rewrites left-click events that arrive with ctrl held in a browser into cmd-clicks (down, up, and drag events). Browser list mirrors `setup.sh`'s BROWSER_COND. Needs Hammerspoon granted Accessibility and Input Monitoring in System Settings. `require("hs.ipc")` must stay in init.lua or `hs -c` cannot reach Hammerspoon.
- `setup_mac/setup.sh` is the source of truth for both the Karabiner config (regenerates `~/.config/karabiner/karabiner.json`) and the Hammerspoon config.
