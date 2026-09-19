# Mark's config stuff

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

### Windows / Git Bash

Ansible can't run as a controller on Windows, so `workstation.yml` is the Linux
entry point only. `windows/bootstrap-gitbash.sh` is the Windows one — run it
once from Git Bash:

```
./windows/bootstrap-gitbash.sh
```

It mirrors `roles/dotfiles`: assert the sources exist, back up anything that
isn't already a symlink, then link. It links a deliberate subset — `.bashrc`,
`.inputrc`, and `nvim` to `AppData/Local/nvim`, which is where Neovim looks on
Windows. The rest of `config_links` is left out until each one has actually
been tried here. It also writes a `~/.bash_profile` if none exists, because Git
Bash starts as a login shell and would otherwise never read `~/.bashrc`.

`.inputrc` is what makes the command line vi-mode, and it works unchanged under
Git Bash: its one conditional picks the mode indicator on `$TERM`, not on the
OS, so mintty takes the same DECSCUSR cursor-shape branch a Linux terminal
emulator does — beam for insert, block for command.

`~/.gitconfig` is generated rather than linked, exactly as `roles/dotfiles`
does it and for the same reason — the rendered file carries the real email
address, so linking it would write that address back into this public repo. The
script renders the playbook's own `templates/gitconfig.j2` rather than keeping
a second copy of it, and reassembles the address from `workstation.yml` the way
the `gitemail` var does. There is no Jinja in a bash script, so it fills in the
one expression that template uses and stops with a named error if the template
ever grows another.

Real symlinks, not copies, so `~/.bashrc` *is* the repo file and `git pull` is
the update mechanism. Windows only lets an ordinary user create those with
Developer Mode on (Settings > System > For developers), so the script checks up
front and stops with that instruction rather than silently falling back to
copying, which is what MSYS does by default.

`.bashrc` keys the few genuine differences — `sdn`, `PNPM_HOME`, and where
git-prompt/git-completion live — off `$machine`, which `uname -s` sets to
`windows` for MINGW, MSYS and Cygwin alike.

`.gitattributes` pins the whole repo to LF. Git for Windows ships
`core.autocrlf=true` in its system config, and since `~/.bashrc` is a symlink
straight into this working tree, a CRLF checkout is the copy bash actually runs
— and bash chokes on the `\r`.

### What gets installed

`roles/arch-workstation` and `roles/ubuntu-workstation` install the CLI
toolchain and the GUI applications. The playbook also sets bash as the login
shell — CachyOS ships fish, and `.bashrc`/`.inputrc` assume bash.

Neovim's config requires 0.12 for `vim.pack` and refuses to load below it.
Plugins are pre-installed by a headless run at the end of the dotfiles role,
pinned by `config_files/nvim/nvim-pack-lock.json`, and updated separately with
`:lua vim.pack.update()`.

### Security

The playbook writes `/etc/sysctl.d/99-hardening.conf` and installs two
reporting tools per OS family: `fwupd` plus `arch-audit` on Arch, `fwupd` plus
`debsecan` on Debian. Both only report, which is why installing them
unattended is safe — neither changes anything until run by hand.

```
fwupdmgr refresh && fwupdmgr get-updates   # UEFI/SSD/dock firmware
arch-audit -u                              # Arch
debsecan --suite <codename> --only-fixed   # Debian
```

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
