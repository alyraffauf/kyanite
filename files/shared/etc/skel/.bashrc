# .bashrc
# shellcheck shell=bash

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ $PATH =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# Set up nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# Set up Homebrew environment if available
homebrew_prefix=""

if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    homebrew_prefix="/home/linuxbrew/.linuxbrew"
elif [ -x /opt/homebrew/bin/brew ]; then
    homebrew_prefix="/opt/homebrew"
fi

if [ -n "$homebrew_prefix" ]; then
    eval "$($homebrew_prefix/bin/brew shellenv)"

    if [ -d "$homebrew_prefix/opt/uutils-coreutils/libexec/uubin" ]; then
        export PATH="$homebrew_prefix/opt/uutils-coreutils/libexec/uubin:$PATH"
    fi

    if [ -d "$homebrew_prefix/opt/uutils-findutils/libexec/uubin" ]; then
        export PATH="$homebrew_prefix/opt/uutils-findutils/libexec/uubin:$PATH"
    fi
fi
unset homebrew_prefix

# Set TERM for Ghostty terminal
if [ "$TERM_PROGRAM" = "ghostty" ]; then
    export TERM=xterm-256color
fi

if command -v direnv &>/dev/null; then
    eval "$(direnv hook bash)"
fi

if command -v fzf &>/dev/null; then
    eval "$(fzf --bash)"
fi

if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash --cmd cd)"
fi
