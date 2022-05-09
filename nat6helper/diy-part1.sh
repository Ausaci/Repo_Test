#!/bin/bash
#=============================================================
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#=============================================================

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
#sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default

# Add Nat6-helper
git clone https://github.com/Ausaci/luci-app-nat6-helper.git package/luci-app-nat6-helper

# Add helloworld fw876
# git clone https://github.com/fw876/helloworld package/helloworld

# Add helloworld_Copy (V2ray-core version 180-10 at Nov 28, 2020)
#git clone https://github.com/Ausaci/helloworld_Copy.git package/helloworld-copy

# Add luci-app-vssr
# git clone https://github.com/jerrykuku/lua-maxminddb.git package/lua-maxminddb
# git clone https://github.com/jerrykuku/luci-app-vssr.git package/luci-app-vssr

# Add luci-app-shadowsocks
# git clone https://github.com/shadowsocks/luci-app-shadowsocks.git package/luci-app-shadowsocks

# Add ServerChan
# git clone https://github.com/tty228/luci-app-serverchan.git package/luci-app-serverchan

# Add Netmap
# git clone https://github.com/Ausaci/luci-app-netmap package/netmap

# Add Aliddns
# git clone https://github.com/Ausaci/luci-app-aliddns package/aliddns

# Add jd-dailybonus
#git clone https://github.com/jerrykuku/luci-app-jd-dailybonus.git package/jd-dailybonus
