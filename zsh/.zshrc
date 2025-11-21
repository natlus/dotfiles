autoload -Uz compinit; compinit
export PATH=/opt/homebrew/bin:$PATH

export LB_USERNAME=$(security find-generic-password -s "LB_USERNAME" -w | tr -d '\n')
export LB_PASSWORD=$(security find-generic-password -s "LB_PASSWORD" -w | tr -d '\n')
export NPM_TOKEN=$(security find-generic-password -s "NPM_TOKEN" -w | tr -d '\n')

# pnpm
export PNPM_HOME="/Users/jessul01/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Starship
eval "$(starship init zsh)"

# fzf
source <(fzf --zsh)

# fnm
eval "$(fnm env --use-on-cd --shell zsh)"

# carapace
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
zstyle ':completion:*' menu select
source <(carapace _carapace)

# autosuggestions like fish
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zoxide
eval "$(zoxide init zsh)"

# alias
alias c="zed"
alias co="git checkout"
alias cm="git commit -m"
alias ca="git commit -am"
alias gl="git log --oneline --decorate=no"
alias gst="git status"
alias prco="gh pr checkout"
alias rcli="redis-cli"
alias cat="bat"
alias CAT="cat"
alias pn="pnpm"

function session() {
    local session_name="$1"

    # Check if tmux is installed
    if ! command -v tmux &> /dev/null; then
        echo "❌ tmux not found. Please install tmux first."
        return 1
    fi

    # Check if argument is provided
    if [[ -z "$session_name" ]]; then
        echo "Usage: session <name>"
        return 1
    fi

    # Check if session exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Attaching to existing tmux session: ${session_name}"
        tmux attach -t "$session_name"
    else
        echo "Creating new tmux session: ${session_name}"
        tmux new -s "$session_name"
    fi
}

function sessions() {
    # Check if tmux is installed
    if ! command -v tmux &> /dev/null; then
        echo "❌ tmux not found. Please install it first."
        return 1
    fi

    # Check if fzf is installed (required for the menu)
    if ! command -v fzf &> /dev/null; then
        echo "❌ fzf not found. Please install it first."
        return 1
    fi

    # Get list of sessions
    # -F "#{session_name}" prints only the name, cleaner than parsing the default output
    local session_list
    session_list=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

    # Run fzf
    # --print-query allows us to capture what the user typed if no match was found
    local fzf_output
    fzf_output=$(echo "$session_list" | fzf --prompt "Select or type tmux session > " --print-query)

    # fzf returns lines. The last line is the selection, the first line is the query (if --print-query is used)
    # If a selection was made, fzf outputs:
    #   query_string
    #   selected_item
    # If no existing item was selected (user typed a new name and hit enter), fzf outputs:
    #   query_string

    local picked
    picked=$(echo "$fzf_output" | tail -n 1 | xargs)

    if [[ -z "$picked" ]]; then
        echo "No session selected."
        return 1
    fi

    # Check if selected session exists
    if tmux has-session -t "$picked" 2>/dev/null; then
        echo "Attaching to session: ${picked}"
        tmux attach -t "$picked"
    else
        echo "Creating new session: ${picked}"
        tmux new -s "$picked"
    fi
}

function gitc() {
    # Check if we are in a git repository
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        echo "❌ Not a git repository"
        return 1
    fi

    # Get all branches (local and remote)
    # 1. git branch --all: lists all branches
    # 2. sed: removes leading '*', whitespace, and 'remotes/' prefix
    # 3. awk: trims whitespace and filters out empty lines
    # 4. sort -u: sorts and removes duplicates (uniq)
    local branches
    branches=$(git branch --all | \
        sed 's/^\*//; s/^[[:space:]]*//; s/^remotes\///' | \
        awk '{$1=$1};1' | \
        sort -u)

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

    # Check if a branch was selected (exit if variable is empty)
    if [[ -z "$selected" ]]; then
        echo "No branch selected"
        return 1
    fi

    # Extract branch name (trimming is handled by implicit variable expansion, but xargs is safer)
    local branch
    branch=$(echo "$selected" | xargs)

    echo "Checking out branch: $branch"
    git checkout "$branch"
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
