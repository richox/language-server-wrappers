#!/bin/bash

dir0="$(cd $(dirname "$0") && pwd)"

ls_require_command() {
    command="$1"

    if [ ! -x "$(which "$command")" ]; then
        echo >&2 "error: required command not available: $command"
        return 255
    fi
    return 0
}

ls_download() {
    target_dir="$1"
    url="$2"
    axel_command="$(command -v axel)"
    wget_command="$(command -v wget)"

    if [ -n "$axel_command" ]; then
        (cd "$target_dir"; "$axel_command" -a -n 10 "$url")
    elif [ -n "$wget_command" ]; then
        (cd "$target_dir"; "$wget_command" "$url")
    else
        echo >&2 "axel/wget not found"
        return 255
    fi
    return 0
}

ls_init_wrapper() {
    ls_temp_path="$(mktemp -d)"
    set -e
    set -x
    ls_init
    init_exit_code="$?"
    rm -r -f "$ls_temp_path"

    set +x
    set +e
    return "$init_exit_code"
}

ls_data_path() {
    echo "$dir0/data/ls-$ls_lang.data"
}

ls_main() {
    if ! (cd "$(ls_data_path)" && command -v "${ls_exec_cmd[0]}"); then
        echo >&2 "warning: langserver binary not exists, running ls_init()..."
        rm -r -f "$(ls_data_path)"
        mkdir -p "$(ls_data_path)"
        if ! (cd $(ls_data_path) && ls_init_wrapper); then
            echo >&2 "error: ls_init() failed"
            return 255
        fi

        if ! (cd "$(ls_data_path)" && command -v "${ls_exec_cmd[0]}"); then
            echo >&2 "error: executable not found: ${ls_exec_cmd[0]}"
            return 255
        fi
        echo >&2 "info: ls_init() completed"
    fi

    echo >&2 "starting langserver..."
    if ! (cd "$(ls_data_path)" && "${ls_exec_cmd[@]}"); then
        echo >&2 "error: exit with non-zero: ${ls_exec_cmd[@]}"
        return 255
    fi
    return 0
}
