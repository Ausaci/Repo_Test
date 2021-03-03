wget $(curl -s https://api.github.com/repos/HoldOnBro/Actions-OpenWrt/releases/32444440 | grep browser_download_url | cut -d '"' -f 4)
