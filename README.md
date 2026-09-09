# dir-mark

A directory bookmarking tool intended to be used with
[tmux-session-manager](https://github.com/ryanburda/tmux-session-manager)

`dir-mark` maps one printable character to one directory, the way vim marks do. That's its
whole job.

```bash
dir-mark set m ~/code/api      # m is now ~/code/api
dir-mark get m                # /home/you/code/api
cd "$(dir-mark get m)"
```

Marks are for the handful of directories you return to constantly -- the ones a fuzzy finder
makes you type a few characters of every time, when you already know exactly where you are
going. There is no ranking, no history and no decay: `m` points where you put it until you put
it somewhere else.

`get` and `pick` print a directory on stdout and nothing else, which is the whole interface to
everything downstream:

```bash
cd "$(dir-mark pick)"                  # choose one with fzf
tsm via dir-mark get m                # a tmux session at whatever m marks
tsm via dir-mark pick                  # ...or at one you choose
nvim "$(dir-mark get n)/init.lua"
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ryanburda/dir-mark/main/install.sh | sh
```

This clones the repository to `${XDG_DATA_HOME:-~/.local/share}/dir-mark` and symlinks
`dir-mark` into `~/.local/bin`. Re-run it any time to update.

`dir-mark` is bash with no dependencies: the `dir-mark` script, and the `dir-mark-status`
beside it holding everything that knows what tmux is. `fzf` is needed for `dir-mark pick` and
`tmux` for `dir-mark status`; everything else runs with a shell and `awk`.

<details>
<summary><strong style="font-size: 1.25em;">Custom Installation</strong></summary>

Two environment variables change where things land: `DIR_MARK_HOME` (where the repo is cloned)
and `BIN_DIR` (where the `dir-mark` symlink goes).

```bash
curl -fsSL https://raw.githubusercontent.com/ryanburda/dir-mark/main/install.sh \
  | DIR_MARK_HOME=~/src/dir-mark BIN_DIR=~/bin sh
```

Or manually: clone the repo, symlink `dir-mark` into a directory on your PATH.

```bash
git clone https://github.com/ryanburda/dir-mark.git ~/git/dir-mark
ln -s ~/git/dir-mark/dir-mark ~/.local/bin/dir-mark
```

Symlink `dir-mark` itself, not a copy of it: it follows the link to find `dir-mark-status` in
the checkout beside it.
</details>

<details>
<summary><strong style="font-size: 1.25em;">Shell Completions</strong></summary>

Completions cover the subcommands and the characters that are already marked, described by the
directory they point at. Paths below assume the install script's checkout location; substitute
your own if you cloned elsewhere.

**Bash**: add to `~/.bashrc`:

```bash
source ~/.local/share/dir-mark/completions/dir-mark.bash
```

**Zsh**: add to `~/.zshrc` (or rename `dir-mark.zsh` to `_dir-mark` in an existing fpath
directory):

```bash
fpath=(~/.local/share/dir-mark/completions $fpath)
autoload -Uz compinit && compinit
```

**Fish**:

```bash
ln -s ~/.local/share/dir-mark/completions/dir-mark.fish ~/.config/fish/completions/
```
</details>

<details>
<summary><strong style="font-size: 1.25em;">tmux Keybindings</strong></summary>

`dir-mark` takes the character as an argument -- it has no keypress prompt of its own. Inside
tmux that is what `command-prompt -1` is for, which reaches all three by a single keypress:

```tmux
bind-key m command-prompt -1 -p "Set mark:"    "run-shell -b \"dir-mark set '%%%'\""
bind-key M command-prompt -1 -p "Remove mark:" "run-shell -b \"dir-mark remove '%%%'\""
bind-key \' command-prompt -1 -p "Go to mark:" "run-shell -b \"tsm via dir-mark get '%%%'\""
bind-key b popup -E "tsm via dir-mark pick"
```

These ask in tmux's status line, so they need no popup: `-1` takes exactly one key and `%%%`
substitutes it with quotation marks escaped. `'` and `;` are the two keys that cannot be
answered with -- `;` is tmux's own command separator -- so do not mark at those.

The last two lines send the directory to [`tsm`][tsm], which opens a tmux session there.
Anything that takes a path works the same way; `dir-mark` itself does not know what tmux is,
apart from `status` below.

`dir-mark set` bound this way marks the directory the *session* is rooted at. To mark the
current pane's directory instead:

```tmux
bind-key m command-prompt -1 -p "Set mark:" "run-shell -b \"dir-mark set '%%%' '#{pane_current_path}'\""
```

> **Troubleshooting:** tmux's `run-shell` and `popup -E` run in a non-interactive, non-login
> shell, so `dir-mark` must be on PATH when that shell starts.
>
> - **zsh:** put your PATH setup in `~/.zshenv` (not `.zshrc`).
> - **bash:** set `BASH_ENV` to a file that configures your PATH, or use `/etc/environment`.
>
> Fallback: use the full path in the bindings, e.g.
> `run-shell -b "~/.local/share/dir-mark/dir-mark set '%%%'"`.

</details>

## Usage

```bash
dir-mark set <char> [path]     # Mark a directory (path defaults to the current directory)
dir-mark remove <char>         # Remove a mark
dir-mark get <char>            # Print the directory a mark points at
dir-mark pick                  # Choose a mark with fzf and print its directory
dir-mark list                  # Every mark as "char<TAB>directory"
dir-mark status [path]         # Marks with a tmux session open at them, for a status line
dir-mark status-init           # Install the tmux hooks `status` needs (put this in tmux.conf)
dir-mark help                  # Show help message
```

### Setting and removing

```bash
dir-mark set m                 # mark the current directory at m
dir-mark set m ~/code/api      # ...or one you name
dir-mark remove m
```

A mark is keyed by a single printable ASCII character -- any of `!` through `~`, so digits and
punctuation work as well as letters, and upper and lower case are two different marks. Setting a
character that is already set replaces it, no confirmation, the same way `m` does in vim. The
path is resolved to an absolute one with symlinks followed, so a mark keeps pointing at the same
directory whatever you were standing in when you set it.

### Reading

`get` prints one directory and nothing else, so it composes:

```bash
cd "$(dir-mark get m)"
ls "$(dir-mark get m)"
```

It exits non-zero and says nothing on stdout if the character is not marked, so
`cd "$(dir-mark get z)"` fails rather than sending you home.

`list` is the whole store, one `char<TAB>directory` line at a time, sorted by character -- for
scripts, and for looking at:

```console
$ dir-mark list
c	/home/you/.config
m	/home/you/code/api
n	/home/you/.config/nvim
```

### `dir-mark pick`

Lists the marks in fzf and prints the directory of the one you choose. `ctrl-x` removes the mark
under the cursor and rebuilds the list, which is how a mark you have stopped using gets cleaned
up without having to remember which character it was.

Backing out prints nothing and exits 0 -- the way any picker declines to answer -- so
`tsm via dir-mark pick` opens nothing when you press escape, rather than erroring.

### Status Line (`dir-mark status`)

Prints the characters of the marks that have a **tmux session open** at their directory, the
current session's styled differently. Marks with nothing open are left out, so the line stays
short and reads as "where can I already jump to":

```tmux
set -g status-right "#(dir-mark status '#{session_path}')"
```

Two flags set the styles, written without their `#[]` wrapper: `-s`/`--style` for the other open
sessions (default `dim`) and `-c`/`--current-style` for the current one (default
`fg=yellow,bold`):

```tmux
set -g status-right "#(dir-mark status '#{session_path}' -s 'fg=colour244' -c 'fg=black,bg=blue,bold')"
```

The path argument matters: tmux runs a `#()` command without a client and shares one run's
output between all of them, so `dir-mark` cannot ask which session is current and get a
per-client answer. Passing `#{session_path}` is what makes the highlight follow each client.

A status line is only redrawn every `status-interval` seconds, so a session opened or killed
elsewhere would take that long to appear. `dir-mark status-init` installs the two tmux hooks
that make it immediate, on every attached client -- put it in `tmux.conf`, where it runs once
per server:

```tmux
run-shell "dir-mark status-init"
```

It hangs a refresh off `session-created` and `session-closed`, appending to both so anything
else on them survives, and dropping the hooks a previous run left behind so re-sourcing
`tmux.conf` does not stack duplicates. It is only needed for the status line; nothing else in
`dir-mark` goes through a hook. Setting and removing a mark refresh the line on their own.

**NOTE:** if your `tmux.conf` sets `session-created` or `session-closed` with a bare
`set-hook -g`, put `run-shell "dir-mark status-init"` after it -- a later `set-hook -g` clears
what dir-mark appended.

## Storage

Marks live in `${XDG_STATE_HOME:-~/.local/state}/dir-mark/marks.json`, a flat JSON object of
character to directory:

```json
{
  "c": "/home/you/.config",
  "m": "/home/you/code/api"
}
```

It is written whole through a temp file, so an interrupted write leaves the previous marks
rather than half a file. Editing it by hand is fine; `dir-mark` reads it with `awk` rather than
`jq`, and drops any pair whose key is not a single character or whose value is empty.

Coming from `tsm`'s old `bookmark-*` subcommands, the store moves as-is -- same format, same
character-to-directory pairs:

```bash
mkdir -p ~/.local/state/dir-mark
mv ~/.local/state/tsm/bookmarks.json ~/.local/state/dir-mark/marks.json
```

`DIR_MARK_FILE` points at a different file, which is what to set for a per-project or
per-machine set of marks:

```bash
DIR_MARK_FILE=~/.config/work-marks.json dir-mark set m ~/work/api
```

## Why a separate tool

`dir-mark` used to be four subcommands inside [`tsm`][tsm], where it was the odd one out: every
other part of `tsm` is about the tmux session that follows a directory, and marks are only about
naming the directory. Pulling them apart left `tsm` with one contract -- *hand me a program that
prints a path* -- and left the marks usable from `cd`, an editor, a script, or nothing at all.

```bash
tsm via dir-mark pick
```

is the whole of the integration between them, and it is the same line anything else would use.

[tsm]: https://github.com/ryanburda/tmux-session-manager
