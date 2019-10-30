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
    rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
    yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
    yum -y --enablerepo=elrepo-kernel install kernel-ml
    sed -i "s/GRUB_DEFAULT=saved/GRUB_DEFAULT=0/" /etc/default/grub
    grub2-mkconfig -o /boot/grub2/grub.cfg
    wget https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-ml-devel-5.3.7-1.el7.elrepo.x86_64.rpm
    rpm -ivh kernel-ml-devel-5.3.7-1.el7.elrepo.x86_64.rpm
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
	vim /etc/v2ray/config.json
	# service v2ray start
	# service v2ray status
	# echo "Address:\"$(curl -s icanhazip.com)\""
	# sed -n '/port/p' /etc/v2ray/config.json
	# sed -n '/id/p' /etc/v2ray/config.json
	# sed -n '/alterId/p' /etc/v2ray/config.json
	}

bbr_install(){
	echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	echo 3 > /proc/sys/net/ipv4/tcp_fastopen
	echo 1 > /proc/sys/net/ipv4/ip_forward
	echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
	sysctl -p
	sysctl -a |grep net.ipv4.ip_forward
	sysctl net.ipv4.tcp_available_congestion_control
	lsmod | grep bbr
}

xshell_root(){
	sed -i 's/PermitRootLogin no/PermitRootLogin yes\nPasswordAuthentication yes/' /etc/ssh/sshd_config
	passwd root
	#systemctl restart ssh
    read -p "重启后可在XSHELL登陆，是否现在重启 ? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "${Info} 重启中..."
		reboot
	fi
}

str_v2ray(){
service v2ray start
service v2ray status
}

sta_v2ray(){
service v2ray status
}

rst_v2ray(){
systemctl restart v2ray
#service v2ray restart
service v2ray status
}

#开始菜单
start_menu(){
    clear
	echo ""
	echo ""
	echo -e "\033[41;33m   》步骤【1-3】需要按顺序执行》\033[0m"
    echo -e "\033[32m   1. 升级CentOS内核（需要重启实例）\033[0m"
	echo -e "\033[32m   2. 打开BBR加速 \033[0m"
	echo -e "\033[32m   3. 安装V2Ray \033[0m"
	#echo -e "\033[41;33m   》步骤【1-3】需要按顺序执行》\033[0m"
    echo "   4. 配置shell登陆（需要设置ROOT密码）"
    echo "   5. 启动V2Ray服务"
	echo "   6. 查看V2Ray状态"
    echo "   7. 重启V2Ray"
    echo "   8. 退出"
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
	str_v2ray
	;;
	6)
	sta_v2ray
	;;
	7)
	rst_v2ray
	;;
	8)
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



