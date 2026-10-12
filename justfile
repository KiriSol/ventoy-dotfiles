[windows]
set shell := ["powershell", "-Command"]

alias f := fmt

@default:
    just --list

[group("dev")]
@fmt:
    treefmt

@iso-update:
    nu {{ justfile_dir() }}/ventoy/scripts/iso-updater/main.nu --config {{ justfile_dir() }}/_ISO/iso-updater.toml

[windows]
@windows-packages-install:
    {{ justfile_dir() }}/ventoy/scripts/windows/packages/install.ps1
