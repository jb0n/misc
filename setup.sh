#!/usr/bin/env bash

# top-level setup: detect the OS and dispatch to the right setup dir.
#   mac:   setup_mac/setup.sh
#   linux: setup_linux/setup.sh (args pass through, e.g. --deepseek-apikey=...)
# anything else: it does not end well for you.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$(uname -s)" in
    Darwin)
        exec bash "$HERE/setup_mac/setup.sh" "$@"
        ;;
    Linux)
        exec bash "$HERE/setup_linux/setup.sh" "$@"
        ;;
    MINGW*|MSYS*|CYGWIN*|*_NT-*)
        echo "you are on windows. i don't do windows."
        echo "if you have wsl, run this inside wsl and pretend the last five years never happened."
        exit 1
        ;;
    *)
        echo "unknown platform: $(uname -s). good luck."
        exit 1
        ;;
esac
