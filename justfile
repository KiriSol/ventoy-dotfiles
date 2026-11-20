[windows]
set shell := ["cmd", "/c"]

alias f := format

@default:
    just --list

[group("dev")]
@format *args:
    treefmt {{ args }} -- {{ justfile_dir() }}

scripts-path := justfile_dir() + "/ventoy/scripts"

@iso *args:
    nu {{ scripts-path }}/iso/main.nu {{ args }} --path {{ justfile_dir() }}/_ISO

windows-packages-path := scripts-path + "/windows/packages"

[windows]
@windows-packages-install *args:
    nu {{ windows-packages-path }}/install.nu --scoop-lists-path {{ windows-packages-path }}/lists/scoop --winget-lists-path {{ windows-packages-path }}/lists/winget {{ args }}
