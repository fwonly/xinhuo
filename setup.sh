#!/bin/bash
# Ensure running as root
if [ "$(id -u)" -ne 0 ]; then
    echo 'This script is designed to run as root'
    exit
fi

echo "####################################################################"
echo "Installing Basic Packages"
apt-get update
apt-get upgrade -y
apt-get install mono-complete -y
apt-get install mono-fastcgi-server4 -y
apt-get install nginx -y
apt-get install wget -y

echo "Downloading adb"
wget https://raw.github.com/fwonly/xinhuo/master/adb -O /usr/bin/adb
chmod +x /usr/bin/adb

# configure USB Access
echo "add android device rules"
if [ -f /etc/udev/rules.d/51-android.rules ]
then
    rm /etc/udev/rules.d/51-android.rules
fi

cat <<'EOF' >> /etc/udev/rules.d/51-android.rules
#Acer
SUBSYSTEM=="usb", ATTR{idVendor}=="0502", MODE="0666", GROUP="plugdev"
#ASUS
SUBSYSTEM=="usb", ATTR{idVendor}=="0b05", MODE="0666", GROUP="plugdev"
#Dell
SUBSYSTEM=="usb", ATTR{idVendor}=="413c", MODE="0666", GROUP="plugdev"
#Foxconn
SUBSYSTEM=="usb", ATTR{idVendor}=="0489", MODE="0666", GROUP="plugdev"
#Garmin-Asus
SUBSYSTEM=="usb", ATTR{idVendor}=="091e", MODE="0666", GROUP="plugdev"
#Google
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
#HTC
SUBSYSTEM=="usb", ATTR{idVendor}=="0bb4", MODE="0666", GROUP="plugdev"
#Huawei
SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", MODE="0666", GROUP="plugdev"
#K-Touch
SUBSYSTEM=="usb", ATTR{idVendor}=="24e3", MODE="0666", GROUP="plugdev"
#KT Tech
SUBSYSTEM=="usb", ATTR{idVendor}=="2116", MODE="0666", GROUP="plugdev"
#Kyocera
SUBSYSTEM=="usb", ATTR{idVendor}=="0482", MODE="0666", GROUP="plugdev"
#Lenevo
SUBSYSTEM=="usb", ATTR{idVendor}=="17EF", MODE="0666", GROUP="plugdev"
#LG
SUBSYSTEM=="usb", ATTR{idVendor}=="1004", MODE="0666", GROUP="plugdev"
#Motorola
SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", MODE="0666", GROUP="plugdev"
#NEC
SUBSYSTEM=="usb", ATTR{idVendor}=="0409", MODE="0666", GROUP="plugdev"
#Nvidia
SUBSYSTEM=="usb", ATTR{idVendor}=="0955", MODE="0666", GROUP="plugdev"
#OTGV
SUBSYSTEM=="usb", ATTR{idVendor}=="2257", MODE="0666", GROUP="plugdev"
#Pantech
SUBSYSTEM=="usb", ATTR{idVendor}=="10A9", MODE="0666", GROUP="plugdev"
#Philips
SUBSYSTEM=="usb", ATTR{idVendor}=="10A9", MODE="0666", GROUP="plugdev"
#PMC-Sierra
SUBSYSTEM=="usb", ATTR{idVendor}=="04da", MODE="0666", GROUP="plugdev"
#Qualcomm
SUBSYSTEM=="usb", ATTR{idVendor}=="05c6", MODE="0666", GROUP="plugdev"
#SK Telesys
SUBSYSTEM=="usb", ATTR{idVendor}=="1f53", MODE="0666", GROUP="plugdev"
#Samsung
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev"
#Sharp
SUBSYSTEM=="usb", ATTR{idVendor}=="04dd", MODE="0666", GROUP="plugdev"
#Sony Ericsson
SUBSYSTEM=="usb", ATTR{idVendor}=="0fce", MODE="0666", GROUP="plugdev"
# Spreadtrum
SUBSYSTEM=="usb", ATTR{idVendor}=="1782", MODE="0666", GROUP="plugdev"
#Toshiba
SUBSYSTEM=="usb", ATTR{idVendor}=="0930", MODE="0666", GROUP="plugdev"
#ZTE
SUBSYSTEM=="usb", ATTR{idVendor}=="19d2", MODE="0666", GROUP="plugdev"
EOF
chmod a+r /etc/udev/rules.d/51-android.rules

echo "add spectrum rule"
if [ ! -d .android ]
then
    mkdir .android
echo 0x1782 > .android/adb_usb.ini
fi

echo "restart udev services"
service udev restart

# 1. Nginx configuration
# 2. Xiake server setup
service nginx stop
echo "create AdbServer config file"
if ! [ -d /etc/nginx/conf.d ]; then	
	mkdir -p /etc/nginx/conf.d
fi
echo 'server{
    listen 80;
    server_name localhost;

    location   / {
    root /usr/www/;
    index Default.aspx;
    fastcgi_pass 127.0.0.1:9001;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include /etc/nginx/fastcgi_params;
    }
}
' >/etc/nginx/conf.d/AdbServer.conf
rm -f /etc/nginx/sites-enabled/*

echo "downloading server files"
if [ -d /usr/www ]; then 
    rm -rf /usr/www
fi
wget https://raw.github.com/fwonly/xinhuo/master/www.tgz >/dev/null 2>&1
tar xvf www.tgz -C /usr >/dev/null 2>&1

service nginx start

#start server
#test
#nohup fastcgi-mono-server4 /applications=/:/usr/www/    /socket=tcp:127.0.0.1:9001 &
#final
#cp server/startmono.sh /etc/init.d/
#chmod +x /etc/init.d/startmono.sh
#Create Init Script for OpenOffice (Headless Mode):
echo -e "\n---- create init script for server----"
echo '#!/bin/sh

### BEGIN INIT INFO
# Provides: directadmin
# Required-Start: 
# Required-Stop: 
# Should-Start: 
# Should-Stop: 
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start and stop startmono
# Description: DirectAdmin
### END INIT INFO

fastcgi-mono-server4 /applications=/:/usr/www/    /socket=tcp:127.0.0.1:9001
startmono.sh
' >/etc/init.d/startmono.sh

chmod +x /etc/init.d/startmono.sh
update-rc.d startmono.sh defaults

apt-get clean -y
apt-get autoclean -y
apt-get autoremove -y

echo "End of installation, restart to apply changes"
echo "####################################################################"
exit 0
