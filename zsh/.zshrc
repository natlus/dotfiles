autoload -Uz compinit; compinit

# prompt
setopt PROMPT_SUBST

function git_prompt_info() {
    local status_output
    status_output=$(git status --porcelain=v2 --branch 2>/dev/null) || return

    local branch ahead=0 behind=0 changed=0

    while IFS= read -r line; do
        case "$line" in
            '# branch.head '*)  branch="${line#'# branch.head '}" ;;
            '# branch.ab '*)
                local ab="${line#'# branch.ab '}"
                ahead="${ab%% *}"
                ahead="${ahead#+}"
                behind="${ab##* }"
                behind="${behind#-}"
                ;;
            '#'*) ;;
            *) changed=1 ;;
        esac
    done <<< "$status_output"

    [[ "$branch" == "(detached)" ]] && branch=$(git rev-parse --short HEAD 2>/dev/null)

    print -n "%F{#F6C99F}${branch}%f"
    [[ "$changed" -eq 1 ]] && print -n " %F{white}[+]%f"
    [[ "$ahead" -gt 0 ]] && print -n " %F{green}▴${ahead}%f"
    [[ "$behind" -gt 0 ]] && print -n " %F{red}▿${behind}%f"
}

PROMPT=$'%F{#B1FCE5}%1~%f: $(git_prompt_info) %F{white}$%f '

for _f in ${HOME}/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.zsh(N); do
  source $_f; break
done

# envs
export PATH=/opt/homebrew/bin:$PATH
export BAT_THEME="Vesper"
export PROXY_URL="http://proxy.sr.se:8080"
export NO_PROXY="*.local, 169.254/16, .sr.se, .dm.sr.se, .srse.dm.sr.se"
export http_proxy=""
export https_proxy=""
export RSYNC_PROXY=""

if [[ "$HERDR_ENV" == "1" && "$TERM" == "xterm-256color" ]]; then
    export TERM="xterm-ghostty"
fi

export LB_USERNAME=$(security find-generic-password -s "LB_USERNAME" -w | tr -d '\n')
export LB_PASSWORD=$(security find-generic-password -s "LB_PASSWORD" -w | tr -d '\n')
export NPM_TOKEN=$(security find-generic-password -s "NPM_TOKEN" -w | tr -d '\n')

# pnpm
export PNPM_HOME="/Users/jessul01/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# inits
source <(fzf --zsh)
eval "$(fnm env --use-on-cd --shell zsh)"
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
zstyle ':completion:*' menu select
source <(carapace _carapace)
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
eval "$(zoxide init zsh)"

# aliases
alias c="zed"
alias co="git checkout"
alias cm="git commit -m"
alias ca="git commit -am"
alias gst="git status"
alias prco="gh pr checkout"
alias rcli="redis-cli"
alias cat="bat"
alias CAT="cat"
alias pn="pnpm"
alias pnx="pnpx"
alias oc="opencode --port"
alias nv="nvim"

function session() {
    local session_name="$1"

    if ! command -v herdr &> /dev/null; then
        echo "❌ herdr not found. Please install herdr first."
        return 1
    fi

    if [[ -z "$session_name" ]]; then
        echo "Usage: session <name>"
        return 1
    fi

    herdr session attach "$session_name"
}

function sessions() {
    if ! command -v herdr &> /dev/null; then
        echo "❌ herdr not found. Please install herdr first."
        return 1
    fi

    if ! command -v fzf &> /dev/null; then
        echo "❌ fzf not found. Please install it first."
        return 1
    fi

    local session_list
    session_list=$(herdr session list 2>/dev/null | while read -r name _; do
        [[ "$name" == "name" || -z "$name" ]] && continue
        print -r -- "$name"
    done)

    local picked
    picked=$(print -r -- "$session_list" | fzf --prompt "Select herdr session > ")

    if [[ -z "$picked" ]]; then
        echo "No session selected."
        return 1
    fi

    herdr session attach "$picked"
}

function gitc() {
    # Check if we are in a git repository
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        echo "❌ Not a git repository"
        return 1
    fi

    # Get local branches sorted by commit date (descending)
    # 1. git for-each-ref: iterates over refs
    # 2. --sort=-committerdate: sorts by date (newest first)
    # 3. --format: formats the output to show only the ref name
    local branches
    branches=$(git for-each-ref --sort=-committerdate refs/heads/ \
        --format='%(refname:short)')

    # Check if we have any branches
    if [[ -z "$branches" ]]; then
        echo "No git branches found"
        return 1
    fi

    # Use fzf to select a branch
    local selected
    selected=$(echo "$branches" | \
        fzf --height=40% --reverse --prompt="Select branch: " \
            --preview="git log --oneline --color=always {} | head -20")

    # Check if a branch was selected
    if [[ -z "$selected" ]]; then
        echo "No branch selected"
        return 1
    fi

    # Extract branch name (trimming handled by xargs)
    local branch
    branch=$(echo "$selected" | xargs)

    echo "Checking out branch: $branch"
    git checkout "$branch"
}

function gl() {
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        echo "❌ Not a git repository"
        return 1
    fi

    # 1. git log: Generates the list (No color here to ensure hash is clean text)
    # 2. fzf:
    #    --preview: Uses color=always so the side view looks nice
    #    {1}: represents the commit hash
    local selected
    selected=$(git log --oneline --decorate=no | \
        fzf --reverse --height=80% \
            --prompt="Select commit: " \
            --preview="git show --color=always {1} | head -500")

    # Exit if nothing was selected (e.g. User pressed Esc)
    if [[ -z "$selected" ]]; then
        return 0
    fi

    # Extract just the hash (the first word of the line)
    local hash
    hash=$(echo "$selected" | awk '{print $1}')

    # Copy the hash to clipboard
    echo -n "$hash" | pbcopy
    echo "Copied $hash to clipboard"
}

function proxyon() {
    # Ensure PROXY_URL is set before trying to use it
    if [[ -z "$PROXY_URL" ]]; then
        echo "❌ PROXY_URL is not set. Please set it first (e.g., export PROXY_URL='http://127.0.0.1:7890')"
        return 1
    fi

    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export RSYNC_PROXY="$PROXY_URL"
    export HTTP_PROXY="$PROXY_URL"
    export HTTPS_PROXY="$PROXY_URL"

    # Git configuration
    git config --global http.proxy "$PROXY_URL"
    git config --global https.proxy "$PROXY_URL"

    # NPM configuration
    # Check if npm exists to avoid errors
    if command -v npm &> /dev/null; then
        npm config --global set proxy "$PROXY_URL"
        npm config --global set https-proxy "$PROXY_URL"
    fi

    # launchctl (macOS specific)
    # Check if launchctl exists (it won't on Linux)
    if command -v launchctl &> /dev/null; then
        launchctl setenv https_proxy "$PROXY_URL"
        launchctl setenv http_proxy "$PROXY_URL"
    fi

    echo "proxy is on ✅"
}

function proxyoff() {
    unset http_proxy
    unset https_proxy
    unset RSYNC_PROXY
    unset HTTP_PROXY
    unset HTTPS_PROXY

    # Git configuration
    git config --global --unset https.proxy
    git config --global --unset http.proxy

    # NPM configuration
    if command -v npm &> /dev/null; then
        npm config --global delete proxy
        npm config --global delete https-proxy
    fi

    # launchctl (macOS specific)
    if command -v launchctl &> /dev/null; then
        launchctl unsetenv https_proxy
        launchctl unsetenv http_proxy
    fi

    echo "proxy is off 🚫"
}

# bun completions
[ -s "/Users/jessul01/.bun/_bun" ] && source "/Users/jessul01/.bun/_bun"

. "$HOME/.atuin/bin/env"

eval "$(atuin init --disable-up-arrow zsh)"
