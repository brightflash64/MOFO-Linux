#!/bin/sh

# Copyright (c) 2018 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

i2pstart(){
	sudo /etc/init.d/privoxy stop
	sudo cp /usr/local/etc/privoxy/config.i2p /usr/local/etc/privoxy/config
	sudo /etc/init.d/privoxy start
	/usr/bin/i2prouter start;
}

i2pstop(){
	/usr/bin/i2prouter stop;
	sudo /etc/init.d/privoxy stop
	sudo cp /usr/local/etc/privoxy/config.orig /usr/local/etc/privoxy/config
	sudo /etc/init.d/privoxy start
sudo bash -c 'echo "nameserver 127.0.2.1
nameserver 127.0.2.2" > /run/resolvconf/resolv.conf'
	systemctl restart dnscrypt-proxy
	systemctl restart dnscrypt-proxy2
	exit
}

ans=$(zenity  --list  --title "I2P CONTROLLER" --text "Start and stop I2P" --radiolist  --column "Pick" --column "Action" FALSE "Start I2P" TRUE "Stop I2P");

	if [  "$ans" = "Start I2P" ]; then
		i2pstart
	else 
		i2pstop
	fi
