# Bash completion for dir-mark
# Source this file in your .bashrc:
#   source /path/to/dir-mark.bash
# Or copy to /etc/bash_completion.d/dir-mark

_dir_mark_chars() {
    # Every mark as "char<TAB>directory"; the character is the first field.
    dir-mark list 2>/dev/null | cut -f1
}

_dir_mark_completions() {
    local cur cmd subcmds
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    cmd="${COMP_WORDS[1]}"

    subcmds="set remove get pick list status help"

    # Completing the subcommand itself
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=($(compgen -W "$subcmds" -- "$cur"))
        return 0
    fi

    # Completing an argument to a subcommand
    case "$cmd" in
        remove|get)
            COMPREPLY=($(compgen -W "$(_dir_mark_chars)" -- "$cur"))
            return 0
            ;;
        set)
            # The character comes first and is the user's to pick; the
            # directory after it is the one being marked.
            if [ "$COMP_CWORD" -gt 2 ]; then
                COMPREPLY=($(compgen -d -- "$cur"))
            fi
            return 0
            ;;
        status)
            COMPREPLY=($(compgen -W "-s --style -c --current-style" -- "$cur"))
            return 0
            ;;
    esac
}

complete -F _dir_mark_completions dir-mark
