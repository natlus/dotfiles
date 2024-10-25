function proxyoff
  # bun ~/.config/fish/functions/proxyoff.bun.sh

  export http_proxy=
  export https_proxy=
  export no_proxy=
  export RSYNC_PROXY=

  # yarn config delete proxy -g
  # yarn config delete https-proxy -g

  npm config --global delete proxy
  npm config --global delete https-proxy
  git config --global --unset https.proxy
  git config --global --unset http.proxy

  launchctl unsetenv https_proxy
  launchctl unsetenv http_proxy

  # echo "😅 http_proxy=$http_proxy"
  # echo "😅 https_proxy=$https_proxy"
  # echo "😅 npm proxy=$(npm get proxy)"

  echo "proxy is off 🚫"
end
