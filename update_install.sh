#!/bin/bash

DIR="${0%/*}"
cd "$DIR"
DIR="$(pwd)"

part1="$(cat "$DIR/install.sh" | sed -n '1,/EOT/p')"
part2="$(cat "$DIR/install.sh" | sed -n '/^EOT/,$p')"

function create_new_install() {
    echo "$part1"
    sed -e 's/\$/\\\$/g' fast_cd_menu.sh
    echo "$part2"
}

create_new_install > "$DIR/install.sh"
chmod a+x "$DIR/install.sh"

