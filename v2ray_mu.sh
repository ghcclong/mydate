#!/bin/bash

#判断系统
if [ ! -e '/etc/redhat-release' ]; then
	echo "仅支持centos7"
	exit
fi
if  [ -n "$(grep ' 6\.' /etc/redhat-release)" ] ;then
	echo "仅支持centos7"
	exit
fi

#更新内核
update_kernel(){

    sudo yum -y install epel-release
    sed -i "0,/enabled=0/s//enabled=1/" /etc/yum.repos.d/epel.repo
    yum remove -y kernel-devel
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
    yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
    yum -y --enablerepo=elrepo-kernel install kernel-ml
    sed -i "s/GRUB_DEFAULT=saved/GRUB_DEFAULT=0/" /etc/default/grub
    grub2-mkconfig -o /boot/grub2/grub.cfg
    wget https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-ml-devel-4.20.4-1.el7.elrepo.x86_64.rpm
    rpm -ivh kernel-ml-devel-4.20.4-1.el7.elrepo.x86_64.rpm
    yum -y --enablerepo=elrepo-kernel install kernel-ml-devel
	timedatectl set-timezone Asia/Shanghai
    read -p "需要重启实例，是否现在重启 ? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "${Info} 重启中..."
		reboot
	fi
}

v2ray_install(){
	bash <(curl -L -s https://install.direct/go.sh)
	#vim /etc/v2ray/config.json
	service v2ray start
	service v2ray status
	curl icanhazip.com
	nl /etc/v2ray/config.json | sed '/port/p'
	nl /etc/v2ray/config.json | sed '/protocol/p'
	nl /etc/v2ray/config.json | sed '/id/p'
	nl /etc/v2ray/config.json | sed '/alterId/p'
	}

bbr_install(){
	echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	echo 3 > /proc/sys/net/ipv4/tcp_fastopen
	echo 1 > /proc/sys/net/ipv4/ip_forward
	echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf
	sysctl -p
	sysctl net.ipv4.tcp_available_congestion_control
	lsmod | grep bbr
}

xshell_root(){
	sed -i 's/PermitRootLogin no/PermitRootLogin yes\nPasswordAuthentication yes/' /etc/ssh/sshd_config
	passwd root
	systemctl restart ssh
}

#开始菜单
start_menu(){
    clear
    echo "1. 升级内核（需要重启实例）"
	echo "2. 打开BBR加速"
	echo "3. 安装V2Ray"
    echo "4. 配置shell登陆（需要设置ROOT密码）"
    echo "5. 退出脚本"
    echo
    read -p "请输入数字:" num
    case "$num" in
    1)
	update_kernel
	;;
	2)
	bbr_install
	;;
	3)
	v2ray_install
	;;
	4)
	xshell_root
	;;
	5)
	exit 1
	;;
	*)
	clear
	echo "请输入正确数字"
	sleep 5s
	start_menu
	;;
    esac
}

start_menu


