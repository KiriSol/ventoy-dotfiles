[windows]
set shell := ["cmd", "/c"]

alias f := fmt

@default:
    just --list

[group("dev")]
@fmt *args:
    treefmt {{ args }}

scripts-path := justfile_dir() + "/ventoy/scripts"

@iso *args:
    nu {{ scripts-path }}/iso-manager/main.nu --path {{ justfile_dir() }}/_ISO {{ args }}

windows-packages-path := scripts-path + "/windows/packages"

[windows]
@windows-packages-install *args:
    nu {{ windows-packages-path }}/install.nu --scoop-lists-path {{ windows-packages-path }}/lists/scoop --winget-lists-path {{ windows-packages-path }}/lists/winget {{ args }}
