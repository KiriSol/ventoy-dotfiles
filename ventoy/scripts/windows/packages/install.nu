let is_admin = (is-admin)

def process-lists [path: path, action: closure] {
    ls $"($path)/*.yaml"
    | where {|file| ($file.name | path basename | str starts-with ".") == false }
    | each {|file|
        let data = open $file.name
        do $action $data
    }
}

let scoop_action = {|data|
    let global = if ($data | get -o level) == "global" { true } else { false }
    if $global and not $is_admin {
        error make {msg: "Admin rights required for global scoop install"}
    }

    if ($data | get -o bucket) != null and ($data.bucket != "main") {
        ^scoop bucket add $data.bucket
    }

    if ($data | get -o apps) != null {
        $data.apps | each {|app|
            let id = if ($data | get -o bucket) != null { $"($data.bucket)/($app)" } else { $"main/($app)" }
            let args = if $global { ["install", $id, "--global"] } else { ["install", $id] }
            ^scoop ...$args
        }
    }
}

let winget_action = {|data|
    let machine = if ($data | get -o scope) == "machine" { true } else { false }
    if $machine and not $is_admin {
        error make {msg: "Admin rights required for machine winget install"}
    }

    if ($data | get -o packages) != null {
        $data.packages | each {|pkg|
            mut args = [
                "install",
                "--id", $pkg.id,
                "--exact",
                "--silent",
                "--accept-source-agreements",
                "--accept-package-agreements"
            ]

            if $machine { $args = ($args | append ["--scope", "machine"]) }
            if ($pkg | get -o override) != null { $args = ($args | append ["--override", $pkg.override]) }

            ^winget ...$args
        }
    }
}

def main [--scoop-lists-path: path, --winget-lists-path: path, --local] {
    ["^scoop" "^winget"] | each {|cmd|
        if (which $cmd | is-empty) {
            error make {msg: $"($cmd) not found"}
        }
    }

    [$scoop_lists_path, $winget_lists_path] | each {|path|
        if ($path | path type) != "dir" {
            error make {msg: $"directory ($path) not exists"}
        }
    }

    process-lists $scoop_lists_path $scoop_action
    process-lists $winget_lists_path $winget_action
}
