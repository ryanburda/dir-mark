#!/bin/sh
# Install dir-mark: symlink `dir-mark` into a directory on PATH.
#
#   curl -fsSL https://raw.githubusercontent.com/ryanburda/dir-mark/main/install.sh | sh
#
# Environment overrides:
#   DIR_MARK_HOME  where the repo is cloned  (default: ~/.local/share/dir-mark)
#   BIN_DIR        where symlinks are placed (default: ~/.local/bin)

set -eu

REPO_URL=https://github.com/ryanburda/dir-mark.git
DIR_MARK_HOME=${DIR_MARK_HOME:-"${XDG_DATA_HOME:-$HOME/.local/share}/dir-mark"}
BIN_DIR=${BIN_DIR:-"$HOME/.local/bin"}

die() {
    echo "install.sh: $*" >&2
    exit 1
}

command -v git > /dev/null 2>&1 || die "git is required but was not found on PATH"

# Neither is fatal: setting, removing and printing a mark need nothing but a
# shell, and only some subcommands reach for these.
command -v fzf > /dev/null 2>&1 ||
    echo "install.sh: warning: fzf was not found on PATH; 'dir-mark pick' requires it." >&2
command -v tmux > /dev/null 2>&1 ||
    echo "install.sh: warning: tmux was not found on PATH; 'dir-mark status' requires it." >&2

# Fetch (or update) the source checkout that the symlink points at.
if [ -d "$DIR_MARK_HOME/.git" ]; then
    echo "Updating existing checkout at $DIR_MARK_HOME"
    git -C "$DIR_MARK_HOME" fetch --quiet origin
    git -C "$DIR_MARK_HOME" reset --quiet --hard origin/HEAD
elif [ -e "$DIR_MARK_HOME" ]; then
    die "$DIR_MARK_HOME exists but is not a git checkout; move it aside and retry"
else
    echo "Cloning $REPO_URL into $DIR_MARK_HOME"
    mkdir -p "$(dirname "$DIR_MARK_HOME")"
    git clone --quiet "$REPO_URL" "$DIR_MARK_HOME"
fi

mkdir -p "$BIN_DIR"

src="$DIR_MARK_HOME/dir-mark"
dest="$BIN_DIR/dir-mark"

[ -f "$src" ] || die "expected $src to exist"

if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    die "$dest exists and is not a symlink; remove it and retry"
fi

chmod +x "$src"
ln -sfn "$src" "$dest"
echo "Linked $dest -> $src"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        echo
        echo "install.sh: warning: $BIN_DIR is not on your PATH."
        echo "Add this to your shell profile (e.g. ~/.zshrc) and restart your shell:"
        echo
        echo "    export PATH=\"$BIN_DIR:\$PATH\""
        ;;
esac

echo
echo "Done. Run 'dir-mark help' to see its usage."
echo "Shell completions are not installed by this script; see the Shell Completions"
echo "section of $DIR_MARK_HOME/README.md for the one-liner for your shell."
