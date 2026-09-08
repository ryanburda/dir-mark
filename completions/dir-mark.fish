# Fish completion for dir-mark
# Copy to ~/.config/fish/completions/dir-mark.fish
# Or symlink: ln -s /path/to/dir-mark.fish ~/.config/fish/completions/

# Helper function: get mark characters and their directories
function __dir_mark_marks
    # The picker's own rows: character, directory, then the column it
    # displays -- which makes a fine completion description.
    dir-mark _entries 2>/dev/null | awk -F'\t' '{ d = $3; sub(/^[^ ]+ +/, "", d); print $1 "\t" d }'
end

# Disable file completion by default
complete -c dir-mark -f

# Subcommands
complete -c dir-mark -n '__fish_use_subcommand' -a set -d 'Mark a directory at a character'
complete -c dir-mark -n '__fish_use_subcommand' -a remove -d 'Remove a mark'
complete -c dir-mark -n '__fish_use_subcommand' -a get -d 'Print the directory a mark points at'
complete -c dir-mark -n '__fish_use_subcommand' -a pick -d 'Choose a mark with fzf and print its directory'
complete -c dir-mark -n '__fish_use_subcommand' -a list -d 'Every mark as "char<TAB>directory"'
complete -c dir-mark -n '__fish_use_subcommand' -a status -d 'Marks with a tmux session open at them, for a status line'
complete -c dir-mark -n '__fish_use_subcommand' -a help -d 'Show help message'

# Subcommand arguments
complete -c dir-mark -n '__fish_seen_subcommand_from remove get' -xa '(__dir_mark_marks)'
complete -c dir-mark -n '__fish_seen_subcommand_from set' -ra '(__fish_complete_directories)'
complete -c dir-mark -n '__fish_seen_subcommand_from status' -xa '-s --style -c --current-style'
