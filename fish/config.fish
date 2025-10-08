if status is-interactive
    # Commands to run in interactive sessions can go here
end

## Settings ##

set -U fish_prompt_pwd_dir_length 0
set -gx STARSHIP_DISABLE_RPROMPT 1
set -gx STARSHIP_SKIP_INIT 1
set -Ux STARSHIP_SHELL fish
set -Ux STARSHIP_LOG  "error"
set -Ux STARSHIP_TIMEOUT 10

# proxy
set -gx PROXY_URL "http://proxy.sr.se:8080"
set -gx NO_PROXY "*.local, 169.254/16, .sr.se, .dm.sr.se, .srse.dm.sr.se"

# Homebrew env
eval "$(/opt/homebrew/bin/brew shellenv)"

# Starship
## Guard: avoid duplicate inits if sourced again
if not set -q STARSHIP_INIT_DONE
    set -gx STARSHIP_INIT_DONE 1
    # Now load Starship only once (left‑prompt only)
    starship init fish | source
end
# starship init fish | source

# Carapace
set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense' # optional
carapace _carapace | source

# pnpm
set -gx PNPM_HOME "/Users/jessul01/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# kube
set -gx KUBECONFIG (ls ~/.kube/config ~/.kube/config-* 2>/dev/null | tr "\n" ":")
### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
set --export --prepend PATH "/Users/jessul01/.rd/bin"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :

# fzf
fzf --fish | source

# fnm
fnm env --use-on-cd --shell fish | source

## Aliases ##

function co --wraps='git checkout' --description 'alias co=git checkout'
  git checkout $argv;
end

function gl --wraps='git log --oneline --decorate=no' --description 'alias gl=git log --oneline --decorate=no'
  git log --oneline --decorate=no $argv;
end

function gst --wraps='git status' --description 'alias gst=git status'
  git status $argv;
end

function prco --wraps='gh pr checkout' --description 'alias prco=gh pr checkout'
  gh pr checkout $argv;
end

function z --wraps=zed --description 'alias z=zed'
  zed $argv;
end

function rcli --wraps=redis-cli --description 'alias rcli=redis-cli'
  redis-cli $argv;
end

## Functions ##

function proxyon
  set -gx http_proxy $PROXY_URL
  set -gx https_proxy $PROXY_URL
  set -gx no_proxy $NO_PROXY
  set -gx RSYNC_PROXY $PROXY_URL

  git config --global http.proxy $PROXY_URL
  git config --global https.proxy $PROXY_URL
  npm config --global set proxy $PROXY_URL
  npm config --global set https-proxy $PROXY_URL

  # launchctl setenv https_proxy $PROXY_URL
  # launchctl setenv http_proxy $PROXY_URL

  echo "proxy is on ✅"
end

function proxyoff
  set -e http_proxy
  set -e https_proxy
  set -e RSYNC_PROXY

  npm config --global delete proxy
  npm config --global delete https-proxy
  git config --global --unset https.proxy
  git config --global --unset http.proxy

  # launchctl unsetenv https_proxy
  # launchctl unsetenv http_proxy

  echo "proxy is off 🚫"
end

function session
    if not command -q tmux
        echo "❌ tmux not found. Please install tmux first."
        return 1
    end

    set -l clean_name (string trim -- $argv[1])

    if test -z "$clean_name"
        echo "Usage: session <name>"
        return 1
    end

    # Check whether the tmux session exists
    if tmux has-session -t $clean_name 2>/dev/null
        echo "Attaching to existing tmux session: $clean_name"
        tmux attach -t $clean_name
    else
        echo "Creating new tmux session: $clean_name"
        tmux new -s $clean_name
    end
end

function sessions
    if not command -q tmux
        echo "❌ tmux not found. Please install it first."
        return 1
    end

    # Capture tmux sessions safely
    set -l sessions_list (tmux ls 2>/dev/null | string replace -r '^([^:]+):.*$' '$1')

    # Use fzf to select or create a session
    set -l picked (
        printf '%s\n' $sessions_list | \
        fzf --prompt "Select or type tmux session > " --print-query | \
        string trim | \
        tail -n1
    )

    if test -z "$picked"
        echo "No session selected."
        return 1
    end

    # Check if selected session exists
    if tmux has-session -t $picked 2>/dev/null
        echo "Attaching to session: $picked"
        tmux attach -t $picked
    else
        echo "Creating new session: $picked"
        tmux new -s $picked
    end
end
