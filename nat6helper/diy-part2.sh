#!/bin/bash
#============================================================
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#============================================================

# Modify default IP
#sed -i 's/192.168.1.1/192.168.11.1/g' package/base-files/files/bin/config_generate

# Modify hostname
#sed -i 's/OpenWrt/Newifi-D2(Device_name)/g' package/base-files/files/bin/config_generate

# Modify the version number
#sed -i "s/OpenWrt /Ausaci build $(TZ=UTC-8 date "+%Y.%m.%d") @ OpenWrt /g" package/lean/default-settings/files/zzz-default-settings

# Modify Timezone
# sed -i "s/timezone='UTC'/timezone='CST-8'/" package/base-files/files/bin/config_generate
# sed -i "/timezone='CST-8'/a set system.@system[-1].zonename='Asia/Shanghai'" ./package/base-files/files/bin/config_generate

# Modify Firewall custom
# echo "iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE" >> package/network/config/firewall/files/firewall.user

# Modify default theme
# sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Add kernel build user
#[ -z $(grep "CONFIG_KERNEL_BUILD_USER=" .config) ] &&
#    echo 'CONFIG_KERNEL_BUILD_USER="Ausaci"' >>.config ||
#    sed -i 's@\(CONFIG_KERNEL_BUILD_USER=\).*@\1$"Ausaci"@' .config

# Add kernel build domain
#[ -z $(grep "CONFIG_KERNEL_BUILD_DOMAIN=" .config) ] &&
#    echo 'CONFIG_KERNEL_BUILD_DOMAIN="GitHub Actions"' >>.config ||
#    sed -i 's@\(CONFIG_KERNEL_BUILD_DOMAIN=\).*@\1$"GitHub Actions"@' .config
