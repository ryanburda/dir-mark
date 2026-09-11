# Fish completion for markdir
# Copy to ~/.config/fish/completions/markdir.fish
# Or symlink: ln -s /path/to/markdir.fish ~/.config/fish/completions/

# Helper function: get mark characters and their directories
function __markdir_marks
    # The picker's own rows: character, directory, then the column it
    # displays -- which makes a fine completion description.
    markdir _entries 2>/dev/null | awk -F'\t' '{ d = $3; sub(/^[^ ]+ +/, "", d); print $1 "\t" d }'
end

# Disable file completion by default
complete -c markdir -f

# Subcommands
complete -c markdir -n '__fish_use_subcommand' -a set -d 'Mark a directory at a character'
complete -c markdir -n '__fish_use_subcommand' -a remove -d 'Remove a mark'
complete -c markdir -n '__fish_use_subcommand' -a get -d 'Print the directory a mark points at'
complete -c markdir -n '__fish_use_subcommand' -a pick -d 'Choose a mark with fzf and print its directory'
complete -c markdir -n '__fish_use_subcommand' -a list -d 'Every mark as "char<TAB>directory"'
complete -c markdir -n '__fish_use_subcommand' -a status -d 'Marks with a tmux session open at them, for a status line'
complete -c markdir -n '__fish_use_subcommand' -a status-init -d 'Install the tmux hooks `status` needs'
complete -c markdir -n '__fish_use_subcommand' -a help -d 'Show help message'

# Subcommand arguments
complete -c markdir -n '__fish_seen_subcommand_from remove get' -xa '(__markdir_marks)'
complete -c markdir -n '__fish_seen_subcommand_from set' -ra '(__fish_complete_directories)'
complete -c markdir -n '__fish_seen_subcommand_from status' -xa '-s --style -c --current-style'
