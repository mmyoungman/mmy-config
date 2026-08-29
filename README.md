# Mark's config stuff

Dotfiles and workstation setup, managed with Ansible. One `config_files/`
directory is the single source of truth; the playbook symlinks it into `$HOME`
so an edit is live immediately and a `git pull` picks up a change made on
another machine.

Arch and Debian families are both supported — the roles are routed by
`ansible_facts['os_family']`, so the same command works on either.

### How to set up a workstation

1. Install ansible

2. Clone this repo

3. `cd` into the repo dir

4. Run the ansible playbook
```
ansible-playbook workstation.yml --ask-become-pass
```

temporary fix for newer ubuntu versions:
```
ANSIBLE_BECOME_EXE=sudo.ws ansible-playbook workstation.yml --ask-become-pass
```

### Dotfiles

`roles/dotfiles` backs up anything that isn't already a symlink, then links
`config_files/` into `$HOME`. The backup uses `--backup=numbered`, so a second
backup on the same date bumps the older one aside rather than clobbering it.

After the first run every destination is a symlink, which is what makes the
role idempotent: it only backs up again if something has replaced a link with a
real file.

`~/.gitconfig` is the exception — it is templated rather than linked, so the
email address is assembled at run time instead of being committed.

A `config_links` entry may carry its own `dir` to be linked from somewhere
other than `config_files_dir`. Nothing in this repo uses it; it exists so a
separate playbook can add machine-specific files without a second role call.

### What gets installed

`roles/arch-workstation` and `roles/ubuntu-workstation` install the CLI
toolchain and the GUI applications. The playbook also sets bash as the login
shell — CachyOS ships fish, and `.bashrc`/`.inputrc` assume bash.

Neovim's config requires 0.12 for `vim.pack` and refuses to load below it.
Plugins are pre-installed by a headless run at the end of the dotfiles role,
pinned by `config_files/nvim/nvim-pack-lock.json`, and updated separately with
`:lua vim.pack.update()`.

### XFCE keyboard shortcuts

The shortcuts live in `config_files/xfce4/xfce4-keyboard-shortcuts.xml`. They
are copied rather than symlinked, because xfconfd rewrites the file on exit and
would replace a symlink with a real file.

Push the repo's shortcuts out to this machine (no `--ask-become-pass` needed;
these tasks only touch `$HOME`):
```
ansible-playbook workstation.yml --tags xfce
```

Pull this machine's shortcuts back into the repo, after changing bindings in
the XFCE settings GUI:
```
config_files/xfce4/capture.sh
```

Both stop xfconfd so it cannot flush stale settings over the new file. New
bindings take effect after logging out and back in.

### archive/

Old configs kept for reference, not used by the playbook — Windows 10 keyboard
and shell tweaks from before this was Ansible-managed.
