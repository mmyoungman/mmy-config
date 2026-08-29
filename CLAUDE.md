# mmy-config

Ansible-managed personal dotfiles and workstation setup. `workstation.yml` is
the entrypoint; roles are routed by `ansible_facts['os_family']`, and
`ansible_facts['hostname']` is a reliable key for per-machine config because
hostnames stay stable across reinstalls.

**This repo is public.** No hostnames, ports, domains, tokens or anything
describing a specific machine's services belongs here. Server and home-network
config lives in a separate private repo, which consumes this one as a submodule
for `config_files/` and `roles/dotfiles` — so a change here reaches servers as
well as workstations.

That sharing is the reason `roles/dotfiles` takes `config_files_dir` and
`config_links` from the caller rather than hardcoding them, and why a
`config_links` entry may carry its own `dir`. Nothing in this repo uses `dir`;
don't remove it as dead code.
