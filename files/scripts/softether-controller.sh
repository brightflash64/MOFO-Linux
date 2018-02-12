#!/bin/sh

# Copyright (c) 2018 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

stopsoftether(){
	sudo killall -9 vpncmd
        systemctl stop network-manager
        sleep 3
        systemctl start network-manager
	exit
}

startsoftether(){
	sudo /etc/init.d/privoxy stop
	sudo cp /usr/local/etc/privoxy/config.orig /usr/local/etc/privoxy/config
	sudo /etc/init.d/privoxy start
sudo bash -c 'echo "nameserver 127.0.2.1
nameserver 127.0.2.2" > /run/resolvconf/resolv.conf'
	systemctl restart dnscrypt-proxy
	systemctl restart dnscrypt-proxy2
        sed -i -e 's/\/[a-z][a-z]\/.*//g' $HOME/softether/mirrors.txt
	cd /usr/local/sbin/softether-scripts
	sudo mate-terminal -e 'python ./start_vpn.py'
	stopsoftether
}

ans=$(zenity  --list  --title "SOFTETHER CONTROLLER" --text "Start or stop a SoftEther connection" --radiolist --column "Pick" --column "Action" TRUE "Start SoftEther VPN" FALSE "Stop SoftEther VPN");

	if [  "$ans" = "Start SoftEther VPN" ]; then
		startsoftether
	else 
		stopsoftether
	fi
