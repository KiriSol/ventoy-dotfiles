alias f := fmt

@default:
    just --list

[group("dev")]
@fmt:
    treefmt
