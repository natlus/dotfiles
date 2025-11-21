export PATH=/opt/homebrew/bin:$PATH
export XDG_CONFIG_HOME="$HOME/.config/"

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
