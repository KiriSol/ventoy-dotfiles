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
    powershell -File {{ windows-packages-path }}/install.ps1 -ScoopListsPath {{ windows-packages-path }}/lists/scoop -WingetListsPath {{ windows-packages-path }}/lists/winget {{ args }}
