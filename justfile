[windows]
set shell := ["cmd", "/c"]

alias f := fmt

@default:
    just --list

[group("dev")]
@fmt *args:
    treefmt {{ args }}

scripts-path := justfile_dir() + "/ventoy/scripts"

@iso-update:
    nu {{ scripts-path }}/iso-updater/main.nu --config {{ justfile_dir() }}/_ISO/iso-updater.toml

windows-packages-path := scripts-path + "/windows/packages"

[windows]
@windows-packages-install *args:
    nu {{ windows-packages-path }}/install.nu --scoop-lists-path {{ windows-packages-path }}/lists/scoop --winget-lists-path {{ windows-packages-path }}/lists/winget {{ args }}
