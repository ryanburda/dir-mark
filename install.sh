#!/bin/sh
# Install markdir: symlink `markdir` into a directory on PATH.
#
#   curl -fsSL https://raw.githubusercontent.com/ryanburda/markdir/main/install.sh | sh
#
# Environment overrides:
#   MARKDIR_HOME  where the repo is cloned  (default: ~/.local/share/markdir)
#   BIN_DIR       where symlinks are placed (default: ~/.local/bin)

set -eu

REPO_URL=https://github.com/ryanburda/markdir.git
MARKDIR_HOME=${MARKDIR_HOME:-"${XDG_DATA_HOME:-$HOME/.local/share}/markdir"}
BIN_DIR=${BIN_DIR:-"$HOME/.local/bin"}

die() {
    echo "install.sh: $*" >&2
    exit 1
}

command -v git > /dev/null 2>&1 || die "git is required but was not found on PATH"

# Neither is fatal: setting, removing and printing a mark need nothing but a
# shell, and only some subcommands reach for these.
command -v fzf > /dev/null 2>&1 ||
    echo "install.sh: warning: fzf was not found on PATH; 'markdir pick' requires it." >&2
command -v tmux > /dev/null 2>&1 ||
    echo "install.sh: warning: tmux was not found on PATH; 'markdir status' requires it." >&2

# Fetch (or update) the source checkout that the symlink points at.
if [ -d "$MARKDIR_HOME/.git" ]; then
    echo "Updating existing checkout at $MARKDIR_HOME"
    git -C "$MARKDIR_HOME" fetch --quiet origin
    git -C "$MARKDIR_HOME" reset --quiet --hard origin/HEAD
elif [ -e "$MARKDIR_HOME" ]; then
    die "$MARKDIR_HOME exists but is not a git checkout; move it aside and retry"
else
    echo "Cloning $REPO_URL into $MARKDIR_HOME"
    mkdir -p "$(dirname "$MARKDIR_HOME")"
    git clone --quiet "$REPO_URL" "$MARKDIR_HOME"
fi

mkdir -p "$BIN_DIR"

src="$MARKDIR_HOME/markdir"
dest="$BIN_DIR/markdir"

[ -f "$src" ] || die "expected $src to exist"

# Only markdir is linked; it follows the link back here to find its tmux half.
[ -f "$MARKDIR_HOME/markdir-status" ] || die "expected $MARKDIR_HOME/markdir-status to exist"

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
echo "Done. Run 'markdir help' to see its usage."
echo "Shell completions are not installed by this script; see the Shell Completions"
echo "section of $MARKDIR_HOME/README.md for the one-liner for your shell."
