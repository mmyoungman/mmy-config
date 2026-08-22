# XFCE keyboard shortcuts

`workstation.yml` copies this file into place, backing up whatever was there
first. It's skipped on machines without XFCE, and new bindings show up after
logging out and back in. To apply it without a full run:

    ansible-playbook workstation.yml --tags xfce

`capture.sh` goes the other way, for after you've changed bindings in the
settings dialog — review the result with `git diff`. The live file wins, so if
you've edited the repo copy by hand, apply it first or it gets overwritten.
