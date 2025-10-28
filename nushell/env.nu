$env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/bin')
$env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
zoxide init nushell | save -f ~/.zoxide.nu

$env.LB_USERNAME = (^security find-generic-password -s "LB_USERNAME" -w | str trim)
$env.LB_PASSWORD = (^security find-generic-password -s "LB_PASSWORD" -w | str trim)

$env.NPM_TOKEN = (^security find-generic-password -s "NPM_TOKEN" -w | str trim)
