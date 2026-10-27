#!/usr/bin/env nu

export const LOCK_FILE_NAME: string = "iso-manager.lock"

def get-lock [iso_path: path] {
    let path: path = $iso_path | path join $LOCK_FILE_NAME | path expand
    if ($path | path type) != "file" {
        touch $path
    }
    return (open $path | from toml)
}

def save-lock [iso_path: path, lock: record] {
    let path: path = $iso_path | path join $LOCK_FILE_NAME | path expand
    $lock | to toml | save --force $path
}

export def main [--path: path] {
    help main
}

export def "main list" [--path: path] {
    let lock = get-lock $path
    print $lock
}

export def "main sync" [--path: path] {
    let lock = get-lock $path
}

export def "main add" [file: path, url: string, --path: path] {
    let lock = get-lock $path

    save-lock $path $lock
    main sync --path $path
}

export def "main remove" [file: path, --path: path] {
    let lock = get-lock $path

    save-lock $path $lock
    main sync --path $path
}
