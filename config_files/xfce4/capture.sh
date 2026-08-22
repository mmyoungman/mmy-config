#!/bin/bash
# Copy this machine's XFCE keyboard shortcuts back into the repo. Run after
# changing bindings, then `git diff` to see what moved.
#
# The live file wins, so push repo-side edits out first with
# `ansible-playbook workstation.yml --tags xfce`, or they get overwritten.

set -euo pipefail

DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/xfce4-keyboard-shortcuts.xml"
SRC="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"

if [ ! -f "$SRC" ]; then
  echo "xfce4/capture.sh: no $SRC -- nothing to capture" >&2
  exit 1
fi

# Stop the daemon so unflushed changes are on disk before we read them.
pkill -x xfconfd || true

cp "$SRC" "$DEST"

echo "xfce4/capture.sh: captured -- review with git diff"
