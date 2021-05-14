# Tag API of Armbian_Buster Release
wget $(curl -s https://api.github.com/repos/Ausaci/Auto_Build_OpenWrt/releases/39173651 | grep browser_download_url | cut -d '"' -f 4)
