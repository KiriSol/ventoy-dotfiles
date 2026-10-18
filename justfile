[windows]
set shell := ["cmd", "/c"]

alias f := fmt

@default:
    just --list

[group("dev")]
@fmt *args:
    treefmt {{ args }}

@iso-update:
    nu {{ justfile_dir() }}/ventoy/scripts/iso-updater/main.nu --config {{ justfile_dir() }}/_ISO/iso-updater.toml

[windows]
@windows-packages-install:
    powershell -File {{ justfile_dir() }}/ventoy/scripts/windows/packages/install.ps1
