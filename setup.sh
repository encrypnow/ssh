#!/bin/bash

### Warna
Green="\e[92;1m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[36m"
FONT="\033[0m"
GREENBG="\033[42;37m"
REDBG="\033[41;37m"
OK="${Green}--->${FONT}"
ERROR="${RED}[ERROR]${FONT}"
GRAY="\e[1;30m"
NC='\e[0m'
red='\e[1;31m'
green='\e[0;32m'

### Informasi
TANGGAL=$(date '+%Y-%m-%d')
TIMES="10"
NAMES=$(whoami)
IMP="wget -q -O"    
CHATID="1036440597"
LOCAL_DATE="/usr/bin/"
TIME=$(date +'%Y-%m-%d %H:%M:%S')
RAMMS=$(free -m | awk 'NR==2 {print $2}')
REPO="https://raw.githubusercontent.com/encrypnow/ssh/main/"

### Cek root
if [ "${EUID}" -ne 0 ]; then
		echo "You need to run this script as root"
		exit 1
fi
if [ "$(systemd-detect-virt)" == "openvz" ]; then
		echo "OpenVZ is not supported"
		exit 1
fi


### Proses Installasi

mkdir -p /etc/xray

### Tambah domain
function add_domain() {
    read -rp "Input Your Domain For This Server :" -e SUB_DOMAIN
    echo "Host : $SUB_DOMAIN"
    echo $SUB_DOMAIN > /root/domain
    cp /root/domain /etc/xray/domain
}

### Pasang SSL
function pasang_ssl() {
    print_install "Memasang SSL pada domain"
    domain=$(cat /root/domain)
    STOPWEBSERVER=$(lsof -i:80 | cut -d' ' -f1 | awk 'NR==2 {print $1}')
    rm -rf /root/.acme.sh
    mkdir /root/.acme.sh
    systemctl stop $STOPWEBSERVER
    systemctl stop nginx
    curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
    chmod +x /root/.acme.sh/acme.sh
    /root/.acme.sh/acme.sh --upgrade --auto-upgrade
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    /root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
    ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
    chmod 777 /etc/xray/xray.key
    print_success "SSL Certificate"
}

## Install SSH-OVPN
function install(){
	wget ${REPO}ssh/ssh-vpn.sh && chmod +x ssh-vpn.sh && screen -S ssh-vpn ./ssh-vpn.sh

	## Install Websocket
	wget ${REPO}websocket/ws.sh && chmod +x ws.sh && screen -S websocket ./ws.sh

    wget -O /tmp/menu-master.zip "${REPO}menu/menu.zip" >/dev/null 2>&1
    mkdir /tmp/menu
    7z e  /tmp/menu-master.zip -o/tmp/menu/ >/dev/null 2>&1
    chmod +x /tmp/menu/*
    mv /tmp/menu/* /usr/sbin/

}

add_domain
pasang_ssl
install
rm *.zip
rm *.sh
rm menu
rm *.zip
echo -e ""
echo -ne "[ ${YELLOW}WARNING${NC} ] reboot now ? (y/n)? "
read answer
if [ "$answer" == "${answer#[Yy]}" ] ;then
exit 0
else
reboot
fi
