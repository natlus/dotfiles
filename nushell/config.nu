# config.nu
#
# Installed by:
# version = "0.103.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.

$env.config = {
	buffer_editor: 'zed'
	show_banner: false
	# edit_mode: vi
	# cursor_shape: {
	#         vi_insert: line # block, underscore, line, blink_block, blink_underscore, blink_line, inherit to skip setting cursor shape (block is the default)
	#         vi_normal: block # block, underscore, line, blink_block, blink_underscore, blink_line, inherit to skip setting cursor shape (underscore is the default)
	# }
}


$env.PROMPT_INDICATOR_VI_NORMAL = ""
$env.PROMPT_INDICATOR_VI_INSERT = ""

# $env.config.buffer_editor = 'zed'
# $env.EDITOR = "zed"
# $env.config.show_banner = false
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'

$env.PROXY_URL = "http://proxy.sr.se:8080"
$env.NO_PROXY = "*.local, 169.254/16, .sr.se, .dm.sr.se, .srse.dm.sr.se"
$env.http_proxy = ""
$env.https_proxy = ""
$env.RSYNC_PROXY = ""

# PATH
$env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/bin')
fnm env --json | from json | load-env
$env.PATH = ($env.PATH | append $"($env.FNM_MULTISHELL_PATH)/bin")

# aliases
alias c = code
alias z = zed
alias co = git checkout
alias cm = git commit -m
alias ca = git commit -am
alias gl = git log --oneline --decorate=no
alias gst = git status
alias prco = gh pr checkout
alias rcli = redis-cli

def --env proxyon [] {
    $env.http_proxy = $env.PROXY_URL
    $env.https_proxy = $env.PROXY_URL
    # $env.no_proxy = "*.local, 169.254/16, .sr.se, .dm.sr.se, .srse.dm.sr.se"
    $env.RSYNC_PROXY = $env.PROXY_URL

    git config --global http.proxy $env.PROXY_URL
    git config --global https.proxy $env.PROXY_URL
    npm config --global set proxy $env.PROXY_URL
    npm config --global set https-proxy $env.PROXY_URL

    launchctl setenv https_proxy $env.PROXY_URL
    launchctl setenv http_proxy $env.PROXY_URL

    echo "proxy is on ✅"
}

def --env proxyoff [] {
    $env.http_proxy = ""
    $env.https_proxy = ""
    # $env.no_proxy = ""
    $env.RSYNC_PROXY = ""

    npm config --global delete proxy
    npm config --global delete https-proxy
    git config --global --unset https.proxy
    git config --global --unset http.proxy

    launchctl unsetenv https_proxy
    launchctl unsetenv http_proxy

    echo "proxy is off 🚫"
}

# # session helper for dtach
# def session [
#     name: string,
#     ...cmd: string
# ] {
#  let sockdir = $"($nu.home-path)/.local/share/dtach"
#     mkdir $sockdir | ignore
#
#     # Normalize: trim + remove trailing .sock (exactly once)
#     let clean_name = (
#         $name
#         | str trim
#         | str replace '\.sock$' '' 
#     )
#
#     let sockfile = $"($sockdir)/($clean_name).sock"
#     let command  = if ($cmd | is-empty) { "nu" } else { ($cmd | str join " ") }
#
#     ^dtach -A $sockfile $command
# }

def session [name: string] {
    if (which tmux | is-empty) {
        print "❌ tmux not found. Please install tmux first."
        return
    }

    let clean_name = ($name | str trim)

    if ($clean_name | is-empty) {
        print "Usage: tmux-session <name>"
        return
    }

    # Check whether the tmux session exists (by exit code)
    let exists = ((^tmux has-session -t $clean_name | complete).exit_code == 0)

    if $exists {
        print $"Attaching to existing tmux session: ($clean_name)"
        ^tmux attach -t $clean_name
    } else {
        print $"Creating new tmux session: ($clean_name)"
        ^tmux new -s $clean_name
    }
}

# def sessions [] {
#     let sockdir = $"($nu.home-path)/.local/share/dtach"
#     mkdir $sockdir | ignore
#
#     # Get all socket filenames safely
#     let sessions = (
#         ls $sockdir
#         | get name
#         | path basename
#         | where {|n| $n | str ends-with ".sock"}
#         | each {|n| $n | str replace --regex '\.sock$' '' }  # <-- regex flag fixed
#     )
#
#     let picked = (
#         $sessions
#         | str join (char nl)
#         | ^fzf --prompt "Select or type session > " --no-sort
#         | str trim
#     )
#
#     if ($picked | is-empty) {
#         print "No session selected."
#     } else {
#         session $picked
#     }
# }

def sessions [] {
    if (which tmux | is-empty) {
        print "❌ tmux not found. Please install it first."
        return
    }

    # Capture tmux ls safely (won't crash if no sessions)
    let list_result = (^tmux ls | complete)

    # Determine if tmux ls succeeded (exit_code 0 means sessions exist)
    let has_sessions = ($list_result.exit_code == 0)

    let sessions = if $has_sessions {
        $list_result.stdout
        | lines
        | each {|l| $l | str replace --regex '^([^:]+):.*$' '$1' }
    } else {
        []
    }

    let picked = (
        $sessions
        | str join (char nl)
        | ^fzf --prompt "Select or type tmux session > " --print-query
        | str trim
    )

    if ($picked | is-empty) {
        print "No session selected."
        return
    }

    # Check if selected session exists (again, use exit_code)
    let exists = ((^tmux has-session -t $picked | complete).exit_code == 0)

    if $exists {
        print $"Attaching to session: ($picked)"
        ^tmux attach -t $picked
    } else {
        print $"Creating new session: ($picked)"
        ^tmux new -s $picked
    }
}

# Starship
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

fnm use

source ~/.cache/carapace/init.nu
