#compdef dir-mark
# Zsh completion for dir-mark
#
# Installation options:
# 1. Add to fpath and autoload:
#      fpath=(/path/to/completions $fpath)
#      autoload -Uz compinit && compinit
# 2. Or source directly in .zshrc:
#      source /path/to/dir-mark.zsh

_dir_mark_marks() {
    # The picker's own rows: character, directory, then the column it
    # displays -- which makes a fine completion description.
    local marks
    marks=(${(f)"$(dir-mark _entries 2>/dev/null | awk -F'\t' '{ d = $3; sub(/^[^ ]+ +/, "", d); print $1 ":" d }')"})
    _describe 'mark' marks
}

_dir_mark_commands() {
    local commands=(
        'set:Mark a directory at a character'
        'remove:Remove a mark'
        'path:Print the directory a mark points at'
        'pick:Choose a mark with fzf and print its directory'
        'list:Every mark as "char<TAB>directory"'
        'status:Marks with a tmux session open at them, for a status line'
        'help:Show help message'
    )

    _describe 'command' commands
}

_dir_mark() {
    local context state state_descr line
    typeset -A opt_args

    _arguments -C \
        '1:command:_dir_mark_commands' \
        '*::arg:->args' \
        && return 0

    case "$line[1]" in
        remove|path)
            _dir_mark_marks
            ;;
        set)
            # The character comes first and is the user's to pick; the
            # directory after it is the one being marked.
            if (( CURRENT > 2 )); then
                _files -/
            fi
            ;;
        status)
            _values -s ' ' 'status options' '-s' '--style' '-c' '--current-style'
            ;;
    esac
}

_dir_mark "$@"
