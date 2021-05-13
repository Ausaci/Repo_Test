#!/bin/bash
#
# Copyright (c) 2019-2021 Samuel <https://github.com/Ausaci>
#
# Description: Auto install WireGuard & Cloudflare WARP according to VPS and WARP IP type.
#
# Usage:
# chmod +x wireguard-warp.sh UpdateLinuxKernel.sh
# ./wireguard-warp.sh
#

export SCRIPT_VER=1.0.1

### Default variable Begin ###

iNet_Interface="eth0"
inet4prefix="inet "
inet6prefix="inet6 "

### Default variable End ###


### Function Begin ###
# Set text color
fun_set_text_color(){
	COLOR_RED='\E[1;31m'
	COLOR_GREEN='\E[1;32m'
	COLOR_YELOW='\E[1;33m'
	COLOR_BLUE='\E[1;34m'
	COLOR_PINK='\E[1;35m'
	COLOR_PINKBACK_WHITEFONT='\033[45;37m'
	COLOR_GREEN_LIGHTNING='\033[32m \033[05m'
	COLOR_END='\E[0m'
}

fun_set_text_color

fun_clr(){
	local clear_flag=""
	clear_flag=$1
	if [[ ${clear_flag} == "clear" ]]; then
		clear
	fi
	echo ""
	echo "+------------------------------------------------------------+"
	echo "|      A tool to auto install WireGuard & WARP on Linux      |" 
	echo "|            Only for Debian 10 and Ubuntu 20.04             |"
	echo "|        Author: Samuel <https://github.com/Ausaci>          |"
	echo "+------------------------------------------------------------+"
	echo ""
}

fun_clr "clear"

# 验证系统
if [[ $(uname -s) != Linux ]]; then
	echo -e "${COLOR_RED}This operating system is not supported!${COLOR_END}"
	exit 1
fi

# 验证是否为 root 账户
fun_rootness(){
	if [[ $(id -u) != 0 ]]; then
		echo -e "${COLOR_RED}This script must be run as root!${COLOR_END}"
		exit 1
	fi
}

# 安装必要工具包
fun_initial_install(){
	# 安装必要工具包
	apt-get update
	apt install curl sudo lsb-release -y

	# 安装网络工具包
	sudo apt update
	sudo apt install net-tools iproute2 openresolv dnsutils -y

	# 安装 WireGuard Tools （Wire­Guard 配置工具：wg、wg-quick）
	sudo apt install wireguard-tools --no-install-recommends
}

# 选择 WireGuard 的安装方式
fun_choose_wireguard_type(){
	def_wgtype=3
	wginfo1="${COLOR_GREEN}[1]. WireGuard Integrated Linux Kernel${COLOR_END}"
	wginfo2="${COLOR_GREEN}[2]. WireGuard-dkms${COLOR_END}"
	wginfo3="${COLOR_GREEN}[3]. WireGuard-Go${COLOR_END}"
	wginfo4="${COLOR_GREEN}[4]. Skipping installing WireGuard${COLOR_END}"
	echo -e ""
	echo -e "${COLOR_BLUE}Please choose which way to install WireGuard: {COLOR_END}"
	echo -e ""
	echo -e "${wginfo1} (Linux Kernel > 5.6 . Only for KVM / HyperV / XEN HVM VPS)"
	echo -e "${wginfo2} (Linux Kernel < 5.6 . Only for KVM / HyperV / XEN HVM VPS)"
	echo -e "${wginfo3} (For all VPS, with lower performance)"
	echo -e "${wginfo4}"
	echo -e ""
	echo -e "${COLOR_YELOW}Please input 1, 2, 3, or 4. Default:${COLOR_END} ${wginfo3}: "
	read -p "" set_wgtype
	echo -e ""
	[ -z "${set_wgtype}" ] && set_wgtype="${def_wgtype}"
	case "${set_wgtype}" in
		1)
			wgtype=1
			wginfo=$wginfo1
			wgecho=1
			;;
		2)
			wgtype=2
			wginfo=$wginfo2
			wgecho=1
			;;
		3)
			wgtype=3
			wginfo=$wginfo3
			wgecho=1
			;;
		4)
			wgtype=4
			wginfo=$wginfo4
			wgecho=1
			;;
		[eE][xX][iI][tT])
			exit 1
			;;
		*)
			echo -e "${COLOR_RED}Error! Please input integer number between 1 and 4${COLOR_END}"
			;;
	esac
	if [[ $wgecho == 1 ]]; then
		echo    "----------------------------------------------------------------------------"
		echo -e      "       Your select: ${wginfo}    "
		echo    "----------------------------------------------------------------------------"
	fi
}

# 检查系统内核是否满足内核集成的最低要求
fun_compare_kernel_version(){
	KERNEL_NOW=`uname -r | awk -F- '{print $1}'`
	KERNEL_LEAST=5.6.0
	
	function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
	function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
	function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
	function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }
	echo ""
	if version_lt $KERNEL_NOW $KERNEL_LEAST; then
		echo -e "${COLOR_RED}Your device needs to update! Kernel update program will be executed...${COLOR_END}"
		#curl -fsSL git.io/UpdateLinuxKernel.sh | sudo bash
		./UpdateLinuxKernel.sh
	else
		echo -e "${COLOR_GREEN}Your device DO NOT need to update!${COLOR_END}"
	fi
	echo ""
}

# 选择 WARP 的安装方式（弃用）
fun_choose_warp_type(){
	def_warptype=1
	warpinfo1="${COLOR_GREEN}[1]. IPv4 & IPv6 (Lossless)${COLOR_END}"
	warpinfo2="${COLOR_GREEN}[2]. Add IPv6 support for IPv4 VPS${COLOR_END}"
	warpinfo3="${COLOR_GREEN}[3]. Add IPv4 support for IPv6 VPS${COLOR_END}"
	warpinfo4="${COLOR_GREEN}[4]. Skipping configuring WARP${COLOR_END}"
	echo -e ""
	echo -e "${COLOR_BLUE}Please choose which way to configure Cloudflare WARP: ${COLOR_END}"
	echo -e ""
	echo -e "${warpinfo1}"
	echo -e "${warpinfo2}"
	echo -e "${warpinfo3}"
	echo -e "${warpinfo4}"
	echo -e ""
	echo -e "${COLOR_YELOW}Please input 1, 2, 3, or 4. Default:${COLOR_END} ${warpinfo1}"
	read -p "" set_warptype
	echo -e ""
	[ -z "${set_warptype}" ] && set_warptype="${def_warptype}"
	case "${set_warptype}" in
		1)
			warptpye=1
			warpinfo=$warpinfo1
			warpecho=1
			;;
		2)
			warptpye=2
			warpinfo=$warpinfo2
			warpecho=1
			;;
		3)
			warptpye=3
			warpinfo=$warpinfo3
			warpecho=1
			;;
		4)
			warptpye=4
			warpinfo=$warpinfo4
			warpecho=1
			;;
		[eE][xX][iI][tT])
			exit 1
			;;
		*)
			echo "${COLOR_RED}Error! Please input integer number between 1 and 4${COLOR_END}"
			;;
	esac
	if [[ $warpecho == 1 ]]; then
		echo    "----------------------------------------------------------------------------"
		echo -e      "       Your select: ${warpinfo}    "
		echo    "----------------------------------------------------------------------------"
	fi
}

# 输入 VPS IP 类型 和 WARP 要接管 IP 的类型，并返回 wgcf.conf 的配置
fun_get_vps_warp_iptype(){
 	iptypeinfo1="${COLOR_GREEN}[1]. IPv4${COLOR_END}"
	iptypeinfo2="${COLOR_GREEN}[2]. IPv6${COLOR_END}"
	iptypeinfo3="${COLOR_GREEN}[3]. IPv4 & IPv6${COLOR_END}"
	IP_CONF1="IPv4"
	IP_CONF2="IPv6"
	IP_CONF3="IPv4_IPv6"
	def_vps_iptype=1
	def_warp_iptype=3
	echo ""
	echo -e "${COLOR_BLUE}Please choose your VPS IP type: ${COLOR_END}"
	echo -e ""
	echo -e "${iptypeinfo1}"
	echo -e "${iptypeinfo2}"
	echo -e "${iptypeinfo3}"
	echo -e ""
	echo -e "${COLOR_YELOW}Please input 1, 2, or 3. Default:${COLOR_END} ${iptypeinfo1}"
	read -p "" vps_iptype
	[ -z "${vps_iptype}" ] && vps_iptype="${def_vps_iptype}"
	echo ""
	echo -e "${COLOR_BLUE}Please choose WARP IP type you want: ${COLOR_END}"
	echo -e ""
	echo -e "${iptypeinfo1}"
	echo -e "${iptypeinfo2}"
	echo -e "${iptypeinfo3}"
	echo -e ""
	echo -e "${COLOR_YELOW}Please input 1, 2, or 3. Default:${COLOR_END} ${iptypeinfo3}"
	read -p "" warp_iptype
	[ -z "${warp_iptype}" ] && warp_iptype="${def_warp_iptype}"
	case "${vps_iptype}" in
		1)
			vpsip=4
			vpsinfo="${iptypeinfo1}"
			case "${warp_iptype}" in
				1)
					warpip=4
					warpinfo="${iptypeinfo1}"
					IP_RULE_CONF="${IP_CONF1}"
					DNS_CONF="${IP_CONF1}"
					ENDPT_CONF="${IP_CONF1}"
					ALLOW_CONF="${IP_CONF1}"
					vwecho=1
					;;
				2)
					warpip=6
					warpinfo="${iptypeinfo2}"
					IP_RULE_CONF=""
					DNS_CONF="${IP_CONF1}"
					ENDPT_CONF="${IP_CONF1}"
					ALLOW_CONF="${IP_CONF2}"
					vwecho=1
					;;
				3)
					warpip=46
					warpinfo="${iptypeinfo3}"
					IP_RULE_CONF="${IP_CONF1}"
					DNS_CONF="${IP_CONF1}"
					ENDPT_CONF="${IP_CONF1}"
					ALLOW_CONF="${IP_CONF3}"
					vwecho=1
					;;
				*)
					echo -e "${COLOR_RED}Error! Please input integer number between 1 and 3${COLOR_END}"
					;;
			esac
			;;
		2)
			vpsip=6
			vpsinfo="${iptypeinfo2}"
			case "${warp_iptype}" in
				1)
					warpip=4
					warpinfo="${iptypeinfo1}"
					IP_RULE_CONF=""
					DNS_CONF="${IP_CONF2}"
					ENDPT_CONF="${IP_CONF2}"
					ALLOW_CONF="${IP_CONF1}"
					vwecho=1
					;;
				2)
					warpip=6
					warpinfo="${iptypeinfo2}"
					IP_RULE_CONF="${IP_CONF2}"
					DNS_CONF="${IP_CONF2}"
					ENDPT_CONF="${IP_CONF2}"
					ALLOW_CONF="${IP_CONF2}"
					vwecho=1
					;;
				3)
					warpip=46
					warpinfo="${iptypeinfo3}"
					IP_RULE_CONF="${IP_CONF2}"
					DNS_CONF="${IP_CONF2}"
					ENDPT_CONF="${IP_CONF2}"
					ALLOW_CONF="${IP_CONF3}"
					vwecho=1
					;;
				*)
					echo -e "${COLOR_RED}Error! Please input integer number between 1 and 3${COLOR_END}"
					;;
			esac
			;;
		3)
			vpsip=46
			vpsinfo="${iptypeinfo3}"
			case "${warp_iptype}" in
				1)
					warpip=4
					warpinfo="${iptypeinfo1}"
					IP_RULE_CONF="${IP_CONF1}"
					DNS_CONF="${IP_CONF1}"
					ENDPT_CONF="${IP_CONF3}"
					ALLOW_CONF="${IP_CONF1}"
					vwecho=1
					;;
				2)
					warpip=6
					warpinfo="${iptypeinfo2}"
					IP_RULE_CONF="${IP_CONF2}"
					DNS_CONF="${IP_CONF1}"
					ENDPT_CONF="${IP_CONF3}"
					ALLOW_CONF="${IP_CONF2}"
					vwecho=1
					;;
				3)
					warpip=46
					warpinfo="${iptypeinfo3}"
					IP_RULE_CONF="${IP_CONF3}"
					DNS_CONF="${IP_CONF1}"
					ENDPT_CONF="${IP_CONF3}"
					ALLOW_CONF="${IP_CONF3}"
					vwecho=1
					;;
				*)
					echo -e "${COLOR_RED}Error! Please input integer number between 1 and 3${COLOR_END}"
					;;
			esac
			;;
		*)
			echo -e "${COLOR_RED}Error! Please input integer number between 1 and 3${COLOR_END}"
			;;
	esac
	if [[ $vwecho == 1 ]]; then
		echo    "----------------------------------------------------------------------------"
		echo -e      "      Your select: VPS: ${vpsinfo}; WARP: ${warpinfo}    "
		echo    "----------------------------------------------------------------------------"
	fi

}


# 输入接口名称
fun_input_iNet_Interface(){
	def_iNet_Interface=${iNet_Interface}
	echo ""
	echo -e "${COLOR_BLUE}Please input your inet interface name. Default:${COLOR_END} ${COLOR_GREEN}${def_iNet_Interface}${COLOR_END}"
	read -p "" iNet_Interface
	echo -e ""
	[ -z "${iNet_Interface}" ] && iNet_Interface="${def_iNet_Interface}"
	echo -e "Your inet interface name is: ${COLOR_GREEN}${iNet_Interface}${COLOR_END}"
	echo -e ""
}

# 获取 iNet_Interface 接口的 IPv4 / IPv6 地址（弃用）
fun_getiptype(){
	def_iptype="IPv4"
	def_inet4prefix=${inet4prefix}
	def_inet6prefix=${inet6prefix}
	echo -e ""
	echo -e "${COLOR_BLUE}Please select IPv4 or IPv6:${COLOR_END}"
	echo -e ""
	echo -e "${COLOR_GREEN}[1]. IPv4 (Default)${COLOR_END}"
	echo -e "${COLOR_GREEN}[2]. IPv6${COLOR_END}"
	echo -e ""
	read -p "" set_iptype
	echo -e ""
	[ -z "${set_iptype}" ] && set_iptype="${def_iptype}"
	case "${set_iptype}" in
		1|[Ii][Pp][Vv][4])
			inetprefix=${def_inet4prefix}
			set_iptype="IPv4"
			iptypecho=1
			;;
		2|[Ii][Pp][Vv][6])
			inetprefix=${def_inet6prefix}
			set_iptype="IPv6"
			iptypecho=1
			;;
		[eE][xX][iI][tT])
			exit 1
			;;
		*)
			echo -e "${COLOR_RED}Error! Please input 1 or 2${COLOR_END}"
			;;
	esac
	if [[ $iptypecho == 1 ]]; then
		echo    "---------------------------------"
		echo -e      "       Your select: ${set_iptype}    "
		echo    "---------------------------------"
		inet=$(echo `ifconfig ${iNet_Interface} | grep "${inetprefix}" | awk '{print $2}' | sed -r 's/^.*addr*://g'`)
		echo -e ""
		echo ${inet}
	fi
}

# 手动输入 IPv4 inet 地址
fun_input_inet(){
	def_inet_addr="${inet}"
	echo ""
	echo -e "If your IPv4 inet addr is not right, please input IPv4 inet addr. Default: ${def_inet_addr}"
#	echo -e "Default IPv4 inet addr: ${def_inet_addr} \n"
	read -p "" inet_addr
	[ -z "${inet_addr}" ] && inet_addr="${def_inet_addr}"
	inet=${inet_addr}
}

# 手动输入 IPv6 inet6 地址
fun_input_inet6(){
	def_inet6_addr="${inet6}"
	echo ""
	echo -e "If your IPv6 inet6 addr is not right, please input IPv6 inet6 addr. Default:  ${def_inet6_addr}"
#	echo -e "Default IPv6 inet6 addr: ${def_inet6_addr} \n"
	read -p "" inet6_addr
	[ -z "${inet6_addr}" ] && inet6_addr="${def_inet6_addr}"
	inet6=${inet6_addr}
}

# 添加路由以实现无损连接 IPv4 和 IPv6 地址
fun_add_ip_rule_v1(){
	WARP_IP_TYPE_IPRULE=$1
	if [[ $WARP_IP_TYPE_IPRULE = "IPv4" ]]; then
		sed -i "7 s/^/PostUp = ip rule add from ${inet} lookup main\nPostDown = ip rule delete from ${inet} lookup main\n/" wgcf-profile.conf
	elif [[ $WARP_IP_TYPE_IPRULE = "IPv6" ]]; then
		sed -i "7 s/^/PostUp = ip rule add from ${inet6} lookup main\nPostDown = ip rule delete from ${inet6} lookup main\n/" wgcf-profile.conf
	elif [[ $WARP_IP_TYPE_IPRULE = "IPv4_IPv6" ]]; then
		sed -i "7 s/^/PostUp = ip rule add from ${inet} lookup main\nPostDown = ip rule delete from ${inet} lookup main\nPostUp = ip rule add from ${inet6} lookup main\nPostDown = ip rule delete from ${inet6} lookup main\n/" wgcf-profile.conf
	else
		echo -e ""
		echo -e "${COLOR_BLUE}IP rules don't need to change!${COLOR_END}"
		echo -e ""
	fi
}

# 添加路由以实现无损连接 IPv4 和 IPv6 地址 （方式二）
fun_add_ip_rule_v2(){
	WARP_IP_TYPE_IPRULE=$1
	if [[ $WARP_IP_TYPE_IPRULE = "IPv4" ]]; then
		sed -i "7 s/^/PostUp = ip -4 rule add from ${inet} table main\nPostDown = ip -4 rule delete from ${inet} table main\n/" wgcf-profile.conf
	elif [[ $WARP_IP_TYPE_IPRULE = "IPv6" ]]; then
		sed -i "7 s/^/PostUp = ip -6 rule add from ${inet6} table main\nPostDown = ip -6 rule delete from ${inet6} table main\n/" wgcf-profile.conf
	elif [[ $WARP_IP_TYPE_IPRULE = "IPv4_IPv6" ]]; then
		sed -i "7 s/^/PostUp = ip -4 rule add from ${inet} table main\nPostDown = ip -4 rule delete from ${inet} table main\nPostUp = ip -6 rule add from ${inet6} table main\nPostDown = ip -6 rule delete from ${inet6} table main\n/" wgcf-profile.conf
	else
		echo -e ""
		echo -e "${COLOR_BLUE}IP rules don't need to change!${COLOR_END}"
		echo -e ""
	fi
}

# 更改配置文件中的默认 DNS
fun_change_DNS(){
	WARP_IP_TYPE_DNS=$1
	if [[ $WARP_IP_TYPE_DNS = "IPv4" ]]; then
		sed -i "s/1.1.1.1/8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844/g" wgcf-profile.conf
	elif [[ $WARP_IP_TYPE_DNS = "IPv6" ]]; then
		sed -i "s/1.1.1.1/2001:4860:4860::8888,2001:4860:4860::8844,8.8.8.8,8.8.4.4/g" wgcf-profile.conf
	elif [[ $WARP_IP_TYPE_DNS = "IPv4_IPv6" ]]; then
		sed -i "s/1.1.1.1/8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844/g" wgcf-profile.conf
	else
		sed -i "/1.1.1.1/d" wgcf-profile.conf
	fi
}

# 根据接管 IP 类型，更改配置文件中的 Endpoint
fun_change_endpoint(){
	WARP_IP_TYPE_ENDPT=$1
	if [[ $WARP_IP_TYPE_ENDPT = "IPv4" ]]; then
		sed -i "s/engage.cloudflareclient.com/162.159.192.1/g" wgcf-profile.conf
	elif [[ $WARP_IP_TYPE_ENDPT = "IPv6" ]]; then
		sed -i "s/engage.cloudflareclient.com/[2606:4700:d0::a29f:c001]/g" wgcf-profile.conf
	elif [[ $WARP_IP_TYPE_ENDPT = "IPv4_IPv6" ]]; then
		echo -e ""
		echo -e "${COLOR_BLUE}Endpoints don't need to change!${COLOR_END}"
		echo -e ""
	else
		echo -e ""
		echo -e "${COLOR_BLUE}Endpoints don't need to change!${COLOR_END}"
		echo -e ""
	fi
}

# 更改允许的流量
fun_change_allowedIPs(){
	WARP_IP_TYPE_ALLOW=$1
	if [[ $WARP_IP_TYPE_ALLOW = "IPv4" ]]; then
		sed -i '/\:\:\/0/d' wgcf-profile.conf
	elif [[ $WARP_IP_TYPE_ALLOW = "IPv6" ]]; then
		sed -i "/0\.0\.0\.0\/0/d" wgcf-profile.conf
	elif [[ $WARP_IP_TYPE_ALLOW = "IPv4_IPv6" ]]; then
		echo -e ""
		echo -e "${COLOR_BLUE}AllowedIPs don't need to change!${COLOR_END}"
		echo -e ""
	else
		echo -e ""
		echo -e "${COLOR_BLUE}AllowedIPs don't need to change!${COLOR_END}"
		echo -e ""
	fi
}

# 使用 wgcf 工具生成 WireGuard 配置文件
fun_wgcf(){

# 安装 wgcf 工具
curl -fsSL git.io/wgcf.sh | sudo bash

# 注册 WARP 账户 (将生成 wgcf-account.toml 文件保存账户信息)
wgcf register

# 生成 Wire­Guard 配置文件 (wgcf-profile.conf)
wgcf generate

# 备份 WARP 账户和配置文件
sudo \cp -rf wgcf-account.toml wgcf-account-backup.toml
sudo \cp -rf wgcf-profile.conf wgcf-profile-backup.conf

}

fun_check_warp(){
	sudo wg-quick up wgcf
	echo -e ""
	echo -e "${COLOR_GREEN_LIGHTNING}Please check wgcf interface!${COLOR_END} \n"
	ip a
	echo -e ""
	read -p "Press 'Enter' to continue OR 'Ctrl + C' to cancel" press
	echo -e ""
	echo -e "${COLOR_GREEN_LIGHTNING}Please check if WARP network works!${COLOR_END} \n"
	echo -e "${COLOR_YELOW}Your IPv4 IP is:${COLOR_END}"
	curl ip.p3terx.com -4
	echo -e "\n${COLOR_YELOW}Your IPv6 IP is:${COLOR_END}"
	curl ip.p3terx.com -6
	echo -e ""
	read -p "Press 'Enter' to continue OR 'Ctrl + C' to cancel" press
	sudo wg-quick down wgcf
}

### Function End ###

### 安装 WireGuard ###

# 安装必要工具包
fun_initial_install

# 选择 WireGuard 安装方式
fun_choose_wireguard_type

# 根据选择安装 WireGuard 的方式启动安装程序
if [[ $wgtype == 1 ]]; then
	fun_compare_kernel_version
	echo -e "${COLOR_GREEN}WireGuard is installed successfully!${COLOR_END}"
elif [[ $wgtype == 2 ]]; then
	sudo apt install wireguard-dkms -y
	modprobe wireguard
	lsmod | grep wireguard
	echo -e "${COLOR_GREEN}WireGuard is installed successfully!${COLOR_END}"
elif [[ $wgtype == 3 ]]; then
	curl -fsSL git.io/wireguard-go.sh | sudo bash
	modprobe tun
	lsmod | grep tun
	echo -e "${COLOR_GREEN}WireGuard is installed successfully!${COLOR_END}"
elif [[ $wgtype == 4 ]]; then
	echo -e "${wginfo4}"
else 
	echo -e "${COLOR_RED}Error! Please input integer number between 1 and 4${COLOR_END}"
	exit 1
fi

### 安装 WireGuard 完成 ###


### 配置 WARP ###


# 使用 wgcf 生成 WireGuard 配置文件
fun_wgcf

# 输入接口名称，默认为 "eth0"
fun_input_iNet_Interface

# 根据配置接口自动获取 iNet_Interface 接口的 IPv4 / IPv6 地址，不一定为公网 IP
inet=$(echo `ifconfig ${iNet_Interface} | grep "${inet4prefix}" | awk '{print $2}' | sed -r 's/^.*addr*://g'`)
inet6=$(echo `ifconfig ${iNet_Interface} | grep "${inet6prefix}" | awk '{print $2}' | sed -r 's/^.*addr*://g'`)


# 手动输入主机 IPv4 地址，不一定为公网
#fun_input_inet
# 手动输入主机 IPv6 地址
#fun_input_inet6

# 输入 VPS IP 类型 和 WARP 要接管 IP 的类型，并返回 wgcf.conf 的配置
fun_get_vps_warp_iptype

# 添加路由以实现无损连接（lookup）
#fun_add_ip_rule_v1 $IP_RULE_CONF

# 添加路由以实现无损连接（table）
fun_add_ip_rule_v2 $IP_RULE_CONF

# 更改默认 DNS
fun_change_DNS $DNS_CONF

# 更改默认 Endpoint
fun_change_endpoint $ENDPT_CONF

# 更改允许 IP
fun_change_allowedIPs $ALLOW_CONF

sudo \cp -rf wgcf-profile.conf /etc/wireguard/wgcf.conf

# 检查是否 WARP 是否工作
#fun_check_warp

# 启用守护进程
sudo systemctl start wg-quick@wgcf

# 设置开机启动
sudo systemctl enable wg-quick@wgcf

echo -e "${COLOR_GREEN}Cloudflare WARP is configured successfully!${COLOR_END}"

### 配置 WARP 完成 ###


### 配置 IPv4 / IPv6 优先级 Begin ###

# IPv4 优先
#grep -qE '^[ ]*precedence[ ]*::ffff:0:0/96[ ]*100' /etc/gai.conf || echo 'precedence ::ffff:0:0/96  100' | sudo tee -a /etc/gai.conf

# IPv6 优先
#grep -qE '^[ ]*label[ ]*2002::/16[ ]*2' /etc/gai.conf || echo 'label 2002::/16   2' | sudo tee -a /etc/gai.conf

# 验证优先级
#curl ip.p3terx.com

### 配置 IPv4 / IPv6 优先级 End ###

