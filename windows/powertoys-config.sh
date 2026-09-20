#!/usr/bin/env bash
#
# Save and restore the PowerToys configuration.
#
# Deliberately not part of bootstrap-gitbash.sh, for two reasons. Restoring
# needs PowerToys stopped and this refuses rather than killing it, so wiring it
# into the bootstrap would abort an otherwise fine run over ~/.bashrc and
# ~/.gitconfig just because a tray app happened to be open. And unlike
# everything the bootstrap does, this is two-way: the config is authored in the
# PowerToys UI, so `save` is how a change gets into the repo at all.
#
# Copies, not symlinks -- the one place this repo knowingly breaks its own
# rule. PowerToys does not write through a symlink. Point default.json at a
# file in the repo and the Keyboard Manager editor still updates its own
# editorSettings.json, still shows the new remap as saved, and silently never
# writes default.json. The engine goes on running the old config and nothing
# reports a problem. That was tested here, not assumed: with a symlink in place
# a save touched editorSettings.json and left default.json's mtime untouched;
# with a real file the same save wrote both.
#
# Contents are copied byte for byte. There is no jq, node or real python in Git
# Bash (the `python` on PATH is the Microsoft Store stub), and PowerShell 5.1's
# ConvertFrom-Json/ConvertTo-Json round trip is not faithful enough to risk on a
# working config just to sort keys. See .gitattributes for the line-ending half
# of keeping diffs quiet.
set -euo pipefail

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *)
        echo "powertoys-config.sh: PowerToys is Windows-only." >&2
        exit 1
        ;;
esac

here=$(cd -- "$(dirname -- "$0")" && pwd)
repo=$(cd -- "$here/.." && pwd)
mirror="$here/powertoys"

# LOCALAPPDATA comes through as a Windows path (C:\Users\...), which bash will
# read as a string of escapes, so convert it. Falling back to ~/AppData/Local
# rather than failing: Git Bash sets HOME reliably, and a missing LOCALAPPDATA
# is not worth an error when the answer is almost certainly that.
if [ -n "${LOCALAPPDATA:-}" ]; then
    localappdata=$(cygpath -u -- "$LOCALAPPDATA")
else
    localappdata="$HOME/AppData/Local"
fi
pt_root="$localappdata/Microsoft/PowerToys"

# Paths relative to the PowerToys config root, mirrored under the same relative
# paths in windows/powertoys. Mirroring the real layout keeps this list to
# bare relative names; adding a module means adding one line here and both
# directions pick it up.
#
# editorSettings.json is not optional. It is the Keyboard Manager *editor's*
# own model, and the editor writes it and default.json together from that
# model. Restore only default.json and the engine does get the right remaps --
# until the next edit in the UI, which writes the stale model straight back
# over them.
#
# The top-level settings.json is which modules are enabled, not their settings.
# It carries powertoys_version and system_theme, so expect those two to show up
# in a diff after an update or a theme change.
pt_files="
settings.json
Keyboard Manager/default.json
Keyboard Manager/editorSettings.json
"

usage() {
    cat >&2 <<'EOF'
usage: powertoys-config.sh save|restore

  save     copy the live PowerToys config into the repo, ready to commit
  restore  copy the repo's config over the live one (PowerToys must be stopped)
EOF
    exit 1
}

# Catches the runner and every module process, not just PowerToys.exe -- the
# Keyboard Manager engine is a separate process and it is the one holding
# default.json.
powertoys_running() {
    powershell.exe -NoProfile -NonInteractive -Command \
        "if (Get-Process -Name 'PowerToys*' -ErrorAction SilentlyContinue) { 'yes' } else { 'no' }" \
        2>/dev/null | tr -d '\r\n'
}

do_save() {
    local rel src dest changed=0 missing=""

    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        [ -e "$pt_root/$rel" ] || missing="$missing
  $rel"
    done <<EOF
$pt_files
EOF
    if [ -n "$missing" ]; then
        echo "powertoys-config.sh: not found under $pt_root:$missing" >&2
        echo "Has PowerToys been run on this machine yet?" >&2
        exit 1
    fi

    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        src="$pt_root/$rel"
        dest="$mirror/$rel"

        if [ -e "$dest" ] && cmp -s -- "$src" "$dest"; then
            echo "ok       $rel"
            continue
        fi
        mkdir -p -- "$(dirname -- "$dest")"
        cp -- "$src" "$dest"
        echo "saved    $rel"
        changed=1
    done <<EOF
$pt_files
EOF

    echo
    if [ "$changed" -eq 0 ]; then
        echo "Nothing changed; the repo already matches the live config."
    else
        echo "Saved into windows/powertoys. Review and commit:"
        echo "  git -C \"$repo\" diff -- windows/powertoys"
    fi
}

do_restore() {
    local rel src dest backup missing=""

    # Before touching anything. PowerToys holds this config in memory and
    # rewrites it on exit, so restoring under a running instance gets your
    # files silently stamped back over -- the copy would report success and the
    # config would be unchanged. Refusing rather than killing it: this script
    # does not get to decide that an app the user is using should close.
    if [ "$(powertoys_running)" = "yes" ]; then
        cat >&2 <<'EOF'
powertoys-config.sh: PowerToys is running, so a restore would be undone.

It keeps this config in memory and writes it back out on exit, so anything
copied in underneath it is overwritten the moment it closes.

Quit it from the system tray (right-click the PowerToys icon > Exit), then
re-run this. Closing the Settings window is not enough -- the runner and the
Keyboard Manager engine keep going.
EOF
        exit 1
    fi

    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        [ -e "$mirror/$rel" ] || missing="$missing
  $rel"
    done <<EOF
$pt_files
EOF
    if [ -n "$missing" ]; then
        echo "powertoys-config.sh: not found under $mirror:$missing" >&2
        echo "The checkout is behind, or 'save' has never been run." >&2
        exit 1
    fi

    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        src="$mirror/$rel"
        dest="$pt_root/$rel"

        if [ -e "$dest" ] && cmp -s -- "$src" "$dest"; then
            echo "ok       $rel"
            continue
        fi

        # --backup=numbered so a second restore on the same date bumps the
        # older copy aside rather than clobbering it, as roles/dotfiles and
        # bootstrap-gitbash.sh both do.
        if [ -e "$dest" ]; then
            backup="$dest.$(date +%F)"
            mv --backup=numbered -- "$dest" "$backup"
            echo "backed up $rel -> $(basename -- "$backup")"
        fi

        mkdir -p -- "$(dirname -- "$dest")"
        cp -- "$src" "$dest"
        echo "restored $rel"
    done <<EOF
$pt_files
EOF

    echo
    echo "Done. Start PowerToys to pick it up."
}

[ $# -eq 1 ] || usage
case "$1" in
    save) do_save ;;
    restore) do_restore ;;
    *) usage ;;
esac
