#!/usr/bin/env bash
#
# The Windows counterpart to `ansible-playbook workstation.yml`.
#
# Ansible cannot run as a controller on Windows, so roles/dotfiles cannot put
# these files in place here. This does the same job for the subset that makes
# sense under Git Bash, and deliberately mirrors that role step for step --
# assert the sources exist, back up anything real, then link -- so the two stay
# recognisably the same thing.
#
# Real symlinks, not copies: the point is that ~/.bashrc *is* the repo file, so
# an edit is a tracked edit and `git pull` is the update mechanism.
set -euo pipefail

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *)
        echo "bootstrap-gitbash.sh: this is the Windows path." >&2
        echo "On Linux use: ansible-playbook workstation.yml --ask-become-pass" >&2
        exit 1
        ;;
esac

repo=$(cd -- "$(dirname -- "$0")" && pwd)
config_files_dir="$repo/config_files"

# Only what is known to work under Git Bash. tmux, .xprofile, .ideavimrc and
# the VS Code settings are linked by workstation.yml on Linux but left out here
# until each has actually been tried on Windows -- a link is a claim that the
# file works, and a broken one is worse than an absent one.
#
# .inputrc is the vi-mode command line (editing-mode vi, plus the ciw/diw and
# yn/yl bindings). Its one platform-dependent branch picks the mode indicator
# on $TERM rather than on the OS, and Git Bash's mintty is an xterm, so it
# takes the same DECSCUSR cursor-shape branch a Linux terminal emulator does.
#
# nvim's config dir is $LOCALAPPDATA\nvim on Windows, not ~/.config/nvim.
config_links="
.bashrc|.bashrc
.inputrc|.inputrc
nvim|AppData/Local/nvim
"

# Before anything is moved or linked, for the reason roles/dotfiles gives: ln
# will cheerfully create a link to a path that does not exist and report
# success, and nothing notices until something tries to use it.
missing=""
while IFS='|' read -r src dest; do
    [ -n "$src" ] || continue
    [ -e "$config_files_dir/$src" ] || missing="$missing $src"
done <<EOF
$config_links
EOF
if [ -n "$missing" ]; then
    echo "bootstrap-gitbash.sh: missing under $config_files_dir, so these links" >&2
    echo "would dangle:$missing. The checkout is behind, or a submodule was" >&2
    echo "never initialised." >&2
    exit 1
fi

# Fail here, under a name that says so, rather than 'succeeding' into a pile of
# copies. Creating a symlink on Windows needs SeCreateSymbolicLinkPrivilege,
# which an ordinary user only has once Developer Mode is on; without it MSYS
# silently falls back to copying, and a copied ~/.bashrc drifts from the repo
# the moment either side is edited -- which is the one thing this script exists
# to prevent. nativestrict turns that fallback into an error we can catch.
probe=$(mktemp -d)
trap 'rm -rf -- "$probe"' EXIT
if ! MSYS=winsymlinks:nativestrict ln -s -- "$probe" "$probe/link" 2>/dev/null ||
    [ ! -L "$probe/link" ]; then
    cat >&2 <<'EOF'
bootstrap-gitbash.sh: cannot create symlinks on this machine.

Windows only lets an ordinary user create them with Developer Mode on:
  Settings > System > For developers > Developer mode

Turn it on, open a new Git Bash, and re-run this script. (Running it from an
elevated shell also works, but then the links are owned by the elevated user.)
EOF
    exit 1
fi
rm -rf -- "$probe"
trap - EXIT

# Git Bash starts as a login shell, which reads ~/.bash_profile and never
# ~/.bashrc. /etc/profile.d/bash_profile.sh would generate this same file on the
# next shell, but only after printing a red "This looks like an incorrect setup"
# warning -- so write it now. Generated rather than linked from config_files:
# a ~/.bash_profile on Linux would suppress ~/.profile, which Debian and Ubuntu
# both use, and that is a real behaviour change for no gain.
if [ ! -e "$HOME/.bash_profile" ] && [ ! -e "$HOME/.bash_login" ] &&
    [ ! -e "$HOME/.profile" ]; then
    cat > "$HOME/.bash_profile" <<'EOF'
# Written by mmy-config/bootstrap-gitbash.sh. Git Bash is a login shell, so
# something has to pull in ~/.bashrc.
test -f ~/.profile && . ~/.profile
test -f ~/.bashrc && . ~/.bashrc
EOF
    echo "created  ~/.bash_profile"
fi

while IFS='|' read -r src dest; do
    [ -n "$src" ] || continue
    src_path="$config_files_dir/$src"
    dest_path="$HOME/$dest"

    if [ -L "$dest_path" ] && [ "$(readlink -- "$dest_path")" = "$src_path" ]; then
        echo "ok       ~/$dest"
        continue
    fi

    # --backup=numbered so a second backup on the same date bumps the older one
    # aside rather than clobbering it, as roles/dotfiles does. Only real files
    # are backed up; an existing symlink is just repointed below.
    if [ -e "$dest_path" ] && [ ! -L "$dest_path" ]; then
        backup="$dest_path.$(date +%F)"
        mv --backup=numbered -- "$dest_path" "$backup"
        echo "backed up ~/$dest -> $backup"
    fi

    mkdir -p -- "$(dirname -- "$dest_path")"
    # -n, not just -f: without it a re-run over an existing directory link
    # creates the link *inside* the directory it already points at, giving
    # ~/AppData/Local/nvim/nvim.
    MSYS=winsymlinks:nativestrict ln -sfn -- "$src_path" "$dest_path"
    echo "linked   ~/$dest -> $src_path"
done <<EOF
$config_links
EOF

echo
echo "Done. Open a new Git Bash window to pick up the new ~/.bashrc."
