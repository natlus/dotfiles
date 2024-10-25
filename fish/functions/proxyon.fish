
function proxyon
  # bun ~/.config/fish/functions/proxyon.bun.sh

  export http_proxy=$PROXY_URL
  export https_proxy=$PROXY_URL
  export no_proxy=$NO_PROXY
  export RSYNC_PROXY=$PROXY_URL

  git config --global http.proxy $PROXY_URL
  git config --global https.proxy $PROXY_URL
  npm config --global set proxy $PROXY_URL
  npm config --global set https-proxy $PROXY_URL

  launchctl setenv https_proxy $PROXY_URL
  launchctl setenv http_proxy $PROXY_URL

  # echo "🙃 http_proxy=$http_proxy"
  # echo "🙃 https_proxy=$https_proxy"
  # echo "🙃 npm proxy=$(npm get proxy)"
  # echo "🙃 no_proxy=$no_proxy"
  # echo "🙃 RSYNC_PROXY=$https_proxy"

  echo "proxy is on ✅"
end