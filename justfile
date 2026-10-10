[windows]
set shell := ["powershell", "-Command"]

alias f := fmt

@default:
    just --list

[group("dev")]
@fmt:
    treefmt

[group("setup")]
[windows]
@windows-packages-install:
    {{ justfile_dir() }}/ventoy/scripts/windows/packages/install.ps1
