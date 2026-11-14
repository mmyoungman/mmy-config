# XFCE keyboard shortcuts and panels

`workstation.yml` copies these into place, backing up whatever was there
first. It's skipped on machines without XFCE, and changes show up after
logging out and back in. To apply it without a full run:

    ansible-playbook workstation.yml --tags xfce

`capture.sh` goes the other way, for after you've changed bindings or the
panels in the settings dialogs — review the result with `git diff`. The live
files win, so if you've edited the repo copy by hand, apply it first or it
gets overwritten.

## What's here

- `xfce4-keyboard-shortcuts.xml` — the shortcuts channel, verbatim.
- `xfce4-panel.xml.j2` — both panels: the taskbar and the auto-hiding system
  monitor at the top. Written by `capture.sh`, which is the reason not to
  hand-edit it; the script says what it rewrites and why.
- `panel-volatile.sed` — strips the recently-used lists from the panel file,
  on capture and again when the playbook compares live against repo.
- `panel/*.rc` — settings for the monitor plugins that don't use xfconf. The
  number in each filename is that plugin's id in the panel file.
- `sys-genmon.sh` — the GPU, network, memory and swap readout, linked into
  `~/.local/bin` with the rest of the dotfiles. The GPU part is AMD only: it
  reads amdgpu's sysfs files, and shows `n/a` where there is no such card.

The sensors plugin identifies chips by bus address and diskperf by device
name, so on different hardware those two need pointing at what's there,
followed by a `capture.sh` — at which point the repo describes that machine
instead.
