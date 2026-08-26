# setup_centos_vm

Two unrelated, coexisting setups live in this directory:

| Script | Purpose | Status |
| ------ | ------- | ------ |
| `setup_centos.sh` | Bootstrap a CentOS 6.5 Vagrant VM (2021) | legacy |
| `setup_mac.sh` | Fire-and-forget, idempotent macOS setup | actively maintained |

Yes, the directory name is misleading. `setup_mac.sh` is the one that matters now.

## setup_mac.sh

Usage: copy the script to the Mac and run `bash setup_mac.sh`. Re-running is always safe:
each step either changes something, or reports "already done, skipped".

Current steps:

- **Firefox: "Force Ctrl+Click to New Tab" add-on** — makes Ctrl+Click (and Cmd+Click)
  open links in a new tab, even on sites that block the default behavior.
  Installed by downloading the signed XPI from addons.mozilla.org and dropping it into
  the default Firefox profile's `extensions/` dir. Requires Firefox 142+.
  No prompts, no sudo.

### Hard rules (read before modifying)

A past attempt to make Ctrl+Click work used Karabiner config edits and completely
broke the trackpad. We rolled it back and will not repeat that mistake:

1. NEVER add Karabiner edits, xmodmap/xinput remapping, udev rules, or anything that
   touches input devices to `setup_mac.sh`.
2. Input behavior belongs inside the app (Firefox prefs or add-ons), never at the
   system input stack.
3. The script must stay idempotent and run without sudo.

### Adding a step

1. Write a function that returns `0` if it changed something, `1` if it was already
   in place, and anything else on failure.
2. Register it in the `STEPS` array in the runner section.
