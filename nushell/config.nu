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

$env.config.buffer_editor = 'zed'
$env.config.show_banner = false

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

# Starship
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

fnm use
