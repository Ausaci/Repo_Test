#!/bin/bash
# v1.0
#
# Copyright (c) 2019-2021 Samuel <https://github.com/Ausaci>
#
# Description: Auto update Linux kernel for Ubuntu 20.04 & Debian 10.
#
# Usage:
# chmod +x UpdateLinuxKernel.sh
# ./UpdateLinuxKernel.sh
#

export SCRIPT_ULK_VER=1.0.1

# Check kernel version command:
# sudo apt-cache search linux-image | grep generic
UBUNTU_KERNEL_LATEST=5.8.0-53

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
    echo "|           A tool to auto update kernel on Linux            |" 
    echo "|            Only for Debian 10 and Ubuntu 20.04             |"
    echo "|        Author: Samuel <https://github.com/Ausaci>          |"
    echo "+------------------------------------------------------------+"
    echo ""
}

fun_clr

# Check OS
checkos(){
    if   grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        OS=CentOS
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        OS=Debian
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        OS=Ubuntu
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        OS=Fedora
    else
        echo "Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
}

# Check system version
check_sys_version(){
	sys_ver_now=`lsb_release -sr`
	sys_ver_least_debian=10
	sys_ver_least_ubuntu=20.04
		
	function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
	function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
	function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
	function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }
	
	if [ $OS == "Debian" ]; then
		sys_ver_least=$sys_ver_least_debian
	elif [ $OS == "Ubuntu" ]; then
		sys_ver_least=$sys_ver_least_ubuntu
	else
		echo "${COLOR_RED}Not support OS, please reinstall Debian 10 or Ubuntu 20.04 OS and retry!${COLOR_END}"
		exit 1
	fi
	
	if version_ge $sys_ver_now $sys_ver_least; then
		echo -e "${COLOR_GREEN}Your system version is supported!${COLOR_END}"
	else
		echo -e "${COLOR_RED}Not support system version, please reinstall Debian 10 or Ubuntu 20.04 OS and retry!${COLOR_END}"
		exit 1
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
	if version_lt $KERNEL_NOW $KERNEL_LEAST; then
		echo -e "${COLOR_RED}Your device's kernel needs to update! Kernel update program continue running...${COLOR_END}"
	else
		echo -e "${COLOR_GREEN}Your device's kernel has already intergrated WireGuard!${COLOR_END}"
		#exit 1
	fi
}

checkos

check_sys_version

# 检查系统内核是否满足内核集成 WireGuard 的最低要求
fun_compare_kernel_version

if [ $OS == "Debian" ]; then
	echo -e "${COLOR_GREEN}*** Your system OS is: Debian ***${COLOR_END}"
	apt update
	apt install curl sudo lsb-release -y
	echo "deb http://deb.debian.org/debian $(lsb_release -sc)-backports main" | sudo tee /etc/apt/sources.list.d/backports.list
	sudo apt update
	sudo apt install net-tools iproute2 openresolv dnsutils -y
	sudo apt -t $(lsb_release -sc)-backports install linux-image-$(dpkg --print-architecture) linux-headers-$(dpkg --print-architecture) --install-recommends -y
	echo -e "${COLOR_GREEN}Update Kernel Successfully! Please reboot and check [uname -r]!${COLOR_END}"
	
elif [ $OS == "Ubuntu" ]; then
	echo -e "${COLOR_GREEN}*** Your system OS is: Ubuntu ***${COLOR_END}"
	sudo apt-get update
	sudo apt-get install linux-image-${UBUNTU_KERNEL_LATEST}-generic --install-recommends -y
	echo -e "${COLOR_GREEN}Update Kernel Successfully! Please reboot and check [uname -r]!${COLOR_END}"
else
	echo "${COLOR_RED}Not support OS, please reinstall Debian 10 or Ubuntu 20.04 OS and retry!${COLOR_END}"
	exit 1
fi
