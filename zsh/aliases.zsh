# ALIASES ---------------------------------------------------------------------
alias unmount_all_and_exit='unmount_all && exit'
alias d=docker
alias dc=docker-compose
alias dkill="pgrep \"Docker\" | xargs kill -9"
alias hcat='highlight -O ansi'

alias v='nvim -w ~/.vimlog "$@"'
alias vi='nvim -w ~/.vimlog "$@"'
alias vim='nvim -w ~/.vimlog "$@"'

alias zn='vim $NOTES_DIR/$(date +"%Y%m%d%H%M.md")'

alias ta='tmux attach -t'

alias l='eza -lah'
alias ls=eza
alias sl=eza
alias ll='eza -la --sort=modified --reverse'
alias llatr="eza -la -smod -r"
alias c='clear'
alias s='source ~/.zshrc'
alias h=heroku
alias jj='pbpaste | jsonpp | pbcopy'
alias rm=trash
alias trim="awk '{\$1=\$1;print}'"
alias notes="cd $NOTES_DIR && nvim 00\ HOME.md"

# GIT ALIASES -----------------------------------------------------------------

alias gc='git commit'
alias gco='git checkout'
alias ga='git add'
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch -D'
alias gcp='git cherry-pick'
alias gd='git diff -w'
alias gds='git diff -w --staged'
alias grs='git restore --staged'
alias gst='git rev-parse --git-dir > /dev/null 2>&1 && git status || eza'
alias gu='git reset --soft HEAD~1'
alias gpr='git remote prune origin'
alias ff='gpr && git pull --ff-only'
alias grd='git fetch origin && git rebase origin/master'
alias grd='git fetch origin && (git show-ref --verify --quiet refs/remotes/origin/master && git rebase origin/master || git rebase origin/main)'
alias gbb='git-switchbranch'
alias gbf='git branch | head -1 | xargs' # top branch
alias gl=pretty_git_log
alias gla=pretty_git_log_all
#alias gl="git log --graph --format=format:'%C(bold blue)%h%C(reset) - %C(white)%s%C(reset) %C(green)%an %ar %C(reset) %C(bold magenta)%d%C(reset)'"
#alias gla="git log --all --graph --format=format:'%C(bold blue)%h%C(reset) - %C(white)%s%C(reset) %C(bold magenta)%d%C(reset)'"
alias git-current-branch="git branch | grep \* | cut -d ' ' -f2"
alias grc='git rebase --continue'
alias gra='git rebase --abort'
alias gec='git status | grep "both modified:" | cut -d ":" -f 2 | trim | xargs nvim -'
alias gcan='gc --amend --no-edit'

alias gp="script -q /dev/null git push -u 2>&1 | tee >(cat) | grep \"pull/new\" | awk '{print \$2}' | xargs open"
alias gpf='git push --force-with-lease'

alias gbdd='git-branch-utils -d'
alias gbuu='git-branch-utils -u'
alias gbrr='git-branch-utils -r -b develop'
alias gg='git branch | fzf | xargs git checkout'
alias gup='git branch --set-upstream-to=origin/$(git-current-branch) $(git-current-branch)'

alias gnext='git log --ancestry-path --format=%H ${commit}..master | tail -1 | xargs git checkout'
alias gprev='git checkout HEAD^'
alias gsee="pretty_git_log | head -20 | fzf --ansi --preview=\" echo '{}' | awk '{print \$2}' | bat --color=always\" | awk '{print \$2}' | xargs git show"

function gwa() {
    local branch=$1
    /opt/homebrew/bin/git worktree add "../${branch}" -b "${branch}" && \
        cd "../${branch}" && \
        /opt/homebrew/bin/git branch --set-upstream-to="origin/${branch}" "${branch}"
}

wt() {
    local branch=$1
    local path="../worktrees/${branch}"
    
    # Check if the worktree directory already exists
    if [ -d "$path" ]; then
        # Check if it's already a registered worktree (use full path to avoid alias)
        if /opt/homebrew/bin/git worktree list | /usr/bin/grep -q "$path"; then
            # It's already a worktree, just cd into it
            echo "Worktree already exists, switching to it..."
            cd "$path"
        else
            # Directory exists but isn't a worktree, remove it (use /bin/rm to avoid trash alias)
            echo "Directory exists but isn't a worktree, removing and recreating..."
            /bin/rm -rf "$path"
            # Now proceed with normal creation (don't recurse)
            if /opt/homebrew/bin/git show-ref --verify --quiet refs/heads/"$branch"; then
                /opt/homebrew/bin/git worktree add "$path" "$branch" && cd "$path"
            else
                /opt/homebrew/bin/git worktree add "$path" -b "$branch" && cd "$path"
            fi
        fi
    else
        # Check if branch exists
        if /opt/homebrew/bin/git show-ref --verify --quiet refs/heads/"$branch"; then
            # Branch exists, checkout existing branch
            /opt/homebrew/bin/git worktree add "$path" "$branch" && cd "$path"
        else
            # Branch doesn't exist, create new branch
            /opt/homebrew/bin/git worktree add "$path" -b "$branch" && cd "$path"
        fi
    fi
}

# FUNCTIONS -------------------------------------------------------------------
# function gg {
#     git branch | grep "$1" | head -1 | xargs git checkout
# }

function take {
    mkdir -p $1
    cd $1
}

note() {
    echo "date: $(date)" >> $HOME/drafts.txt
    echo "$@" >> $HOME/drafts.txt
    echo "" >> $HOME/drafts.txt
}

function unmount_all {
    diskutil list |
    grep external |
    cut -d ' ' -f 1 |
    while read file
    do
        diskutil unmountDisk "$file"
    done
}

mff ()
{
    local curr_branch=`git-current-branch`
    gco master
    ff
    gco $curr_branch
}



JOBFILE="$DOTFILES/job-specific.sh"
if [ -f "$JOBFILE" ]; then
    source "$JOBFILE"
fi

extract-audio-and-video () {
    ffmpeg -i "$1" -c:a copy obs-audio.aac
    ffmpeg -i "$1" -c:v copy obs-video.mp4
}

alias epdir='cd `epdir.sh`'

hs () {
 curl https://httpstat.us/$1
}

# alias dp='displayplacer "id:83F2F7DC-590D-6294-B7FB-521754A2A693 res:3840x2160 hz:60 color_depth:8 scaling:off origin:(0,0) degree:0" "id:BD0804E4-6EAA-1C8D-1CFB-D6B734DE10A5 res:3840x2160 hz:60 color_depth:8 scaling:off origin:(3840,0) degree:0"'
# alias mirror-displays='displayplacer "id:C3F5FA73-E883-4B6D-88B3-DA6D6A8192B3+7ECC0B33-A07B-46A6-AFB8-565FEFE68216 res:3840x2160 hz:60 color_depth:8 scaling:off origin:(0,0) degree:0"'

copy-line () {
  rg --line-number "${1:-.}" | sk --delimiter ':' --preview 'bat --color=always --highlight-line {2} {1}' | awk -F ':' '{print $3}' | sed 's/^\s+//' | pbcopy
}

open-at-line () {
  vim $(rg --line-number "${1:-.}" | sk --delimiter ':' --preview 'bat --color=always --highlight-line {2} {1}' | awk -F ':' '{print "+"$2" "$1}')
}

# alias ledger='ledger -f "$(find $NOTES_DIR -name transactions.ledger)"'
alias lg='ledger -f "$(find $NOTES_DIR -name 2024.ledger)"'
alias 'diff-typecheck'='node --max-old-space-size=5120 ./scripts/diff-typecheck.js'

alias yip='yarn install --pure-lockfile'

alias dark="$DOTFILES/bin/toggle-terminal-dark-mode.sh"
alias vf='nvim $(fd --type f --hidden --exclude .git | fzf -m --prompt="Open file(s) > ")'
alias kctl-test='kubectl --context="aws/us-west-1-test"'
alias kctl-ci='kubectl --context="aws/us-east-1-ci"'
alias kctl-prod='kubectl --context="aws/us-east-1-prod"'
alias kctl-dataeng='kubectl --context="aws/us-east-1-dataeng"'
alias st='git status'

# Columnized git log - both as glog and git log override  
alias glog='git log --pretty=format:"%C(yellow)%h%Creset - %C(green)%<(20,trunc)%an%Creset - %C(blue)%ad%Creset - %s" --date=format:"%Y-%m-%d %H:%M"'

# Override git function for columnized log with pager support
function git() {
    if [[ $1 == "log" ]]; then
        # Shift off the 'log' argument to get remaining args
        shift
        command git log --pretty=format:"%C(yellow)%h%Creset - %C(green)%<(20,trunc)%an%Creset - %C(blue)%ad%Creset - %s" --date=format:"%Y-%m-%d %H:%M" "$@"
    else
        command git "$@"
    fi
}

# Production MySQL connection with AWS SSO authentication check
prod-mysql() {
    # Check if authenticated with AWS SSO
    if ! aws sts get-caller-identity --profile rds_ro &>/dev/null; then
        echo "Not authenticated. Logging in to AWS SSO..."
        aws sso login --profile rds_ro
    fi
    ~/work/db.sh
}

# Run tests for all modified tracked files in git status
run-modified-tests() {
    local files=($(git status --porcelain | grep "^ M\|^M" | awk '{print $2}'))
    
    if [ ${#files[@]} -eq 0 ]; then
        echo "No modified tracked files found."
        return 1
    fi
    
    echo "Running tests for modified files..."
    printf '%s\n' "${files[@]}"
    echo ""
    
    pnpm exec mocha "${files[@]}"
}

alias rmt='run-modified-tests'

# Format a file with prettier
_prettier() {
    if [ -z "$1" ]; then
        echo "Usage: prettier <file>"
        return 1
    fi
    pnpm exec prettier "$1" --write
}

alias prettier='noglob _prettier'

alias kctl-test='kubectl --context="aws/us-west-1-test"'
alias kctl-ci='kubectl --context="aws/us-east-1-ci"'
alias kctl-prod='kubectl --context="aws/us-east-1-prod"'
alias kctl-dataeng='kubectl --context="aws/us-east-1-dataeng"'
