#!/bin/bash
# Copy this machine's XFCE keyboard shortcuts and panel layout back into the
# repo. Run after changing bindings or the panel, then `git diff` to see what
# moved.
#
# The live files win, so push repo-side edits out first with
# `ansible-playbook workstation.yml --tags xfce`, or they get overwritten.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XFCONF="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
PANEL="$HOME/.config/xfce4/panel"

for f in xfce4-keyboard-shortcuts.xml xfce4-panel.xml; do
  if [ ! -f "$XFCONF/$f" ]; then
    echo "xfce4/capture.sh: no $XFCONF/$f -- nothing to capture" >&2
    exit 1
  fi
done

# Stop the daemon so unflushed changes are on disk before we read them.
pkill -x xfconfd || true

cp "$XFCONF/xfce4-keyboard-shortcuts.xml" "$HERE/xfce4-keyboard-shortcuts.xml"

# The panel file is a template in the repo: genmon stores its command as an
# absolute path and nothing expands ~ in an xfconf value, so $HOME goes back in
# as the playbook's {{ home }}. panel-volatile.sed says what else is dropped.
sed -e "s|$HOME|{{ home }}|g" -f "$HERE/panel-volatile.sed" \
  "$XFCONF/xfce4-panel.xml" > "$HERE/xfce4-panel.xml.j2"

# Plugins that predate xfconf keep their settings in <name>-<id>.rc, where the
# id is the plugin-N number in the panel file -- so these only make sense
# alongside the xfce4-panel.xml captured above. Cleared first so a plugin
# removed from the panel doesn't leave its rc behind in the repo.
rm -f "$HERE"/panel/*.rc
mkdir -p "$HERE/panel"
# The dir only exists once some plugin has written an rc into it.
if [ -d "$PANEL" ]; then
  find "$PANEL" -maxdepth 1 -name '*.rc' -exec cp -t "$HERE/panel" {} +
fi

echo "xfce4/capture.sh: captured -- review with git diff"
