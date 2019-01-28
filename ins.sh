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

#生成随机端口
rand(){
    min=$1
    max=$(($2-$min+1))
    num=$(cat /dev/urandom | head -n 10 | cksum | awk -F ' ' '{print $1}')
    echo $(($num%$max+$min))  
}

config_client(){
	cat > /etc/wireguard/client.conf <<-EOF
	[Interface]
	PrivateKey = $c1
	Address = 10.0.0.2/24 
	DNS = 8.8.4.4
	MTU = 1420

	[Peer]
	PublicKey = $s2
	Endpoint = $serverip:$port
	AllowedIPs = 0.0.0.0/0, ::0/0
	PersistentKeepalive = 25
	EOF

}

#centos7安装wireguard
wireguard_install(){
    sudo curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
    sudo yum install -y dkms gcc-c++ gcc-gfortran glibc-headers glibc-devel libquadmath-devel libtool systemtap systemtap-devel
    sudo yum -y install wireguard-dkms wireguard-tools
    mkdir /etc/wireguard
    cd /etc/wireguard
    wg genkey | tee sprivatekey | wg pubkey > spublickey
    wg genkey | tee cprivatekey | wg pubkey > cpublickey
    s1=$(cat sprivatekey)
    s2=$(cat spublickey)
    c1=$(cat cprivatekey)
    c2=$(cat cpublickey)
    serverip=$(curl icanhazip.com)
    port=$(rand 10000 60000)
    chmod 777 -R /etc/wireguard
    systemctl stop firewalld
    systemctl disable firewalld
    yum install -y iptables-services 
    systemctl enable iptables 
    systemctl start iptables 
    iptables -F
    service iptables save
    service iptables restart
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf
	sysctl -p
	cat > /etc/wireguard/wg0.conf <<-EOF
	[Interface]
	PrivateKey = $s1
	Address = 10.0.0.1/24 
	PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
	PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
	ListenPort = $port
	DNS = 8.8.4.4
	MTU = 1420

	[Peer]
	PublicKey = $c2
	AllowedIPs = 10.0.0.0/32
	EOF

    config_client
    wg-quick up wg0
    systemctl enable wg-quick@wg0
}

v2ray_install(){
	bash <(curl -L -s https://install.direct/go.sh)
	vim /etc/v2ray/config.json
}



bbr_install(){
	echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	echo 3 > /proc/sys/net/ipv4/tcp_fastopen
	sysctl -p
	sysctl net.ipv4.tcp_available_congestion_control
	lsmod | grep bbr
}

#开始菜单
start_menu(){
    clear
    echo "1. 升级内核（需要重启实例）"
	echo "2. 安装BBR加速"
	echo "3. 安装V2Ray"
    echo "4. 安装Wireguard"
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
	wireguard_install
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



