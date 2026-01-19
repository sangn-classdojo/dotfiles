source_if_exists () {
    if test -r "$1"; then
        source "$1"
    fi
}

source_if_exists $HOME/.env.sh
source_if_exists $DOTFILES/zsh/history.zsh
source_if_exists $DOTFILES/zsh/git.zsh
source_if_exists ~/.fzf.zsh
source_if_exists $DOTFILES/zsh/aliases.zsh
# source_if_exists $HOME/.asdf/asdf.sh
source_if_exists /usr/local/etc/profile.d/z.sh
source_if_exists /opt/homebrew/etc/profile.d/z.sh

if type "direnv" > /dev/null; then
    eval "$(direnv hook zsh)"
fi

autoload -U zmv
autoload -U promptinit && promptinit
autoload -U colors && colors
autoload -Uz compinit && compinit -u

if test -z ${ZSH_HIGHLIGHT_DIR+x}; then
else
    source $ZSH_HIGHLIGHT_DIR/zsh-syntax-highlighting.zsh
fi

precmd() {
    source $DOTFILES/zsh/aliases.zsh
}

export VISUAL=nvim
export EDITOR=nvim
export PATH="$PATH:/usr/local/sbin:$DOTFILES/bin:$HOME/.local/bin:$DOTFILES/scripts/"

eval "$(starship init zsh)"

# VIM MODE (http://dougblack.io/words/zsh-vi-mode.html) -----------------------
# bindkey -v
bindkey '^?' backward-delete-char

# function zle-line-init zle-keymap-select {
#     VIM_PROMPT="%{$fg[yellow]%}[% NORMAL]% %{$reset_color%}"
#     RPS1="${${KEYMAP/vicmd/$VIM_PROMPT}/(main|viins)/}"
#     zle reset-prompt
# }

# zle -N zle-line-init
# zle -N zle-keymap-select
# export KEYTIMEOUT=1
# END VIM MODE ----------------------------------------------------------------

#eval "$(lua ~/bin/z.lua --init zsh)"

source ~/.api_tz_dont_delete
# Make Ctrl-a go to beginning of line, Ctrl-e go to end of line
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^R' history-incremental-search-backward
export PATH="/opt/homebrew/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(/opt/workbrew/bin/brew shellenv)"
if command -v fnm &> /dev/null; then
    # Set up fnm environment with --use-on-cd, then override the hook to use absolute path
    eval "$(/opt/homebrew/bin/fnm env --use-on-cd --shell zsh)"
    # Override the _fnm_autoload_hook to use absolute path
    _fnm_autoload_hook () {
        if [[ -f .node-version || -f .nvmrc || -f package.json ]]; then
            /opt/homebrew/bin/fnm use --log-level=quiet 2>&1 > /dev/null
        fi
    }
fi
source "$HOME/.rye/env"

# Ensure per-user TMPDIR is set and writable
if test ! -d "$HOME/.tmp"; then
    mkdir -p "$HOME/.tmp"
    chmod 700 "$HOME/.tmp"
fi
export TMPDIR="$HOME/.tmp"
export PATH="/opt/workbrew/opt/mysql-client/bin:$PATH"
export PATH="/opt/homebrew/Cellar/mysql-client/9.4.0/bin:$PATH"
