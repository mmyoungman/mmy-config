#
# ~/.bashrc
#

# Nothing below is any use to a non-interactive shell, and some of it is
# actively harmful there: bash sources this file for `ssh host 'cmd'`, where
# anything written to stdout lands in the middle of an scp/rsync/sftp stream
# and breaks the transfer. Skipping also saves ~0.3s of pyenv/nvm/emsdk setup
# per remote command. Matches /etc/skel/.bashrc. Note this means PATH additions
# below do not apply to `ssh host 'cmd'`; that belongs in ~/.bash_profile.
[[ $- != *i* ]] && return

# ensure xprofile config gets applied
[ "$XDG_SESSION_TYPE" = "x11" ] && source "$HOME/.xprofile"

#stty -ixon # Disable ctrl-s and ctrl-q
#shopt -s autocd # cd into dir by typing dir name
HISTSIZE= HISTFILESIZE= # Infinite history

unameOut="$(uname -s)"
case $unameOut in
   Linux*) machine="linux";;
   Darwin*) machine="mac";;
   *)
      echo "bashrc: Unsupported OS detected!" >&2
      ;;
esac

# Use nvim, if available
#[ -f /usr/bin/nvim ] && alias vim=nvim
#[ -f /usr/bin/nvim ] && EDITOR=/usr/bin/nvim
if command -v nvim &> /dev/null; then
    export EDITOR=nvim
else
    echo "bashrc: nvim is not installed" >&2
fi

# Git stuff
source_first() {
    local label=$1 path
    shift
    for path in "$@"; do
        if [ -f "$path" ]; then
            source "$path"
            return 0
        fi
    done
    echo "bashrc: $label not found on this system - not sourced" >&2
    return 1
}

GIT_PROMPT_PATHS=(
    /usr/share/git/completion/git-prompt.sh                              # Arch, Manjaro
    /usr/lib/git-core/git-sh-prompt                                      # Debian, Ubuntu
)
if ! source_first git-prompt.sh "${GIT_PROMPT_PATHS[@]}"; then
    __git_ps1() { :; }
fi

GIT_COMPLETION_PATHS=(
    /usr/share/git/completion/git-completion.bash                              # Arch, Manjaro
    /usr/share/bash-completion/completions/git                                 # Debian, Ubuntu
)
if ! source_first git-completion.bash "${GIT_COMPLETION_PATHS[@]}"; then
    __git_complete() { :; }
fi

# Git aliases
alias gst="git status"
__git_complete gst _git_status
alias gdi="git diff"
__git_complete gdi _git_diff
alias gpl="git pull --rebase"
__git_complete gpl _git_pull
alias gph="git push"
__git_complete gph _git_push
alias gad="git add"
__git_complete gad _git_add
alias gcm="git commit"
__git_complete gcm _git_commit
alias gco="git checkout"
__git_complete gco _git_checkout
alias grb="git rebase"
__git_complete grb _git_rebase
alias glg="git log --oneline -n 20"
__git_complete glg _git_log
alias gwl="git_worktree_list" # function defined at the bottom of this file

alias ls='ls --color=auto'
alias ll='ls -l --color=auto'
alias la='ls -al --color=auto'
alias sdn='shutdown now'

alias dotnetall='dotnet clean; dotnet build; dotnet run'
alias dfe-admin='export IdpConfig=Keycloak; dotnet clean; dotnet build; trap : INT; dotnet run'
alias dfe-frontend='pnpm run build; pnpm run start'
alias dfe-data-processor='func host start --port 7071 --pause-on-error'
alias dfe-publisher='func host start --port 7072 --pause-on-error'
alias dfe-notify='dotnet clean; func host start --port 7073 --pause-on-error'
alias dfe-public-data-processor='dotnet clean; func host start --port 7074 --pause-on-error'
alias dfe-analytics='dotnet clean; func host start --port 7075 --pause-on-error'

PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;33m\]$(__git_ps1 " [%s]")\[\033[01;32m\]]\$\[\033[00m\] '

# For node version manager
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Append dirs to PATH, or prepend them with -p, skipping any already there.
# This file runs for every interactive shell and PATH is inherited by child
# shells, so a bare `PATH="$PATH:$dir"` gains another copy of $dir per nesting
# level -- a tmux pane inside a terminal was already up to three.
path_add() {
    local prepend="" dir
    [ "$1" = "-p" ] && { prepend=1; shift; }
    for dir in "$@"; do
        case ":$PATH:" in
            *":$dir:"*) continue ;;
        esac
        if [ -n "$prepend" ]; then PATH="$dir:$PATH"; else PATH="$PATH:$dir"; fi
    done
    export PATH
}

# For dotnet
if [ -x "$HOME/.dotnet/dotnet" ]; then
    export DOTNET_ROOT="$HOME/.dotnet"
    path_add "$DOTNET_ROOT"
fi

# Add .NET Core SDK tools. Global tools land here whatever the runtime layout.
path_add "$HOME/.dotnet/tools"

# Go stuff
path_add "$HOME/go/bin"

# DuckDb
path_add "$HOME/.duckdb/cli/latest"

# For emscripten/webassembly. EMSDK_QUIET rather than a redirect: the script
# announces itself on stderr, so `> /dev/null` suppresses nothing. It prepends
# its own dirs to PATH but dedupes them itself, so re-sourcing is safe.
[ -f "$HOME/projects/emsdk/emsdk_env.sh" ] &&
    EMSDK_QUIET=1 source "$HOME/projects/emsdk/emsdk_env.sh"

# FZF
#[ -f $HOME/.fzf.bash ] && source $HOME/.fzf.bash

# For pipenv, and for anything installed by hand rather than by the package
# manager. Prepended, unlike the appends above, so a hand-installed binary
# beats a distro package of the same name: the server's neovim is an AppImage there
# because Debian's /usr/bin/nvim is older than config_files/nvim requires.
path_add -p "$HOME/.local/bin"

# For pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && path_add -p "$PYENV_ROOT/bin"
if command -v pyenv &> /dev/null
then
   eval "$(pyenv init -)"
fi

# pnpm
export PNPM_HOME="/home/mark/.local/share/pnpm"
path_add -p "$PNPM_HOME"

# List git worktrees by what's in them; cd into one by number or fuzzy name.
# Aliased to gwl above.
#   gwl          list every worktree of the current repo, most recently touched first
#   gwl 3        cd into #3
#   gwl enemy    cd into the first worktree whose dir or branch matches "enemy"
git_worktree_list() {
    git rev-parse --git-common-dir >/dev/null 2>&1 || { echo "gwl: not in a git repo" >&2; return 1; }

    # Most recently touched first, keyed on tracked-file mtime, not commit date.
    local -a rows
    mapfile -t rows < <(
        git worktree list --porcelain | sed -n 's/^worktree //p' | while read -r p; do
            printf '%s\t%s\n' "$(_git_worktree_touched "$p")" "$p"
        done | sort -rn
    )

    # Count commits against whatever the main worktree has checked out.
    local main base
    main=$(dirname "$(cd "$(git rev-parse --git-common-dir)" && pwd)")
    base=$(git -C "$main" symbolic-ref --short HEAD 2>/dev/null || echo master)

    local -a paths touched
    local i
    for i in "${!rows[@]}"; do
        touched[i]=${rows[$i]%%$'\t'*}
        paths[i]=${rows[$i]#*$'\t'}
    done

    local p branch dirty ahead
    if [ $# -eq 0 ]; then
        for i in "${!paths[@]}"; do
            p=${paths[$i]}
            branch=$(git -C "$p" branch --show-current 2>/dev/null)
            [ -n "$branch" ] || branch="(detached)"
            dirty=""
            [ -n "$(git -C "$p" status --porcelain 2>/dev/null)" ] && dirty="*"
            ahead=$(git -C "$p" rev-list --count "$base..HEAD" 2>/dev/null)
            if [ "${ahead:-0}" -gt 0 ] 2>/dev/null; then ahead="+$ahead"; else ahead=""; fi
            printf '%2d  %-26.26s %-26.26s %-4s %-9s · %s\n' \
                $((i + 1)) "$(basename "$p")" "$branch" "$dirty$ahead" \
                "$(_git_worktree_ago "${touched[$i]:-0}")" \
                "$(git -C "$p" log -1 --format=%s 2>/dev/null | cut -c1-50)"
        done
        return 0
    fi

    local target=""
    if [[ $1 =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le "${#paths[@]}" ]; then
        target=${paths[$(($1 - 1))]}
    else
        for p in "${paths[@]}"; do
            branch=$(git -C "$p" branch --show-current 2>/dev/null)
            if [[ ${p,,} == *"${1,,}"* || ${branch,,} == *"${1,,}"* ]]; then target=$p; break; fi
        done
    fi

    [ -n "$target" ] || { echo "gwl: no worktree matching '$1'" >&2; return 1; }
    cd "$target" || return 1
    git log --oneline -1
}

# Newest mtime among a worktree's tracked files, as a unix timestamp.
_git_worktree_touched() {
    (cd "$1" 2>/dev/null && git ls-files -z 2>/dev/null |
        xargs -0r stat -c %Y -- 2>/dev/null | sort -rn | head -1)
}

_git_worktree_ago() {
    local s=$(($(date +%s) - $1))
    if [ "$s" -lt 60 ]; then echo "${s}s ago"
    elif [ "$s" -lt 3600 ]; then echo "$((s / 60))m ago"
    elif [ "$s" -lt 86400 ]; then echo "$((s / 3600))h ago"
    else echo "$((s / 86400))d ago"
    fi
}
