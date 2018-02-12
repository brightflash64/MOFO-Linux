#!/bin/sh

# Copyright (c) 2018 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

psiphonstop(){
sudo pkill -f "python ./psi_client.py"
sudo /etc/init.d/privoxy stop
sudo cp /usr/local/etc/privoxy/config.orig /usr/local/etc/privoxy/config
sudo /etc/init.d/privoxy start
sudo bash -c 'echo "nameserver 127.0.2.1
nameserver 127.0.2.2" > /run/resolvconf/resolv.conf'
systemctl restart dnscrypt-proxy
systemctl restart dnscrypt-proxy2
exit
}

updatestart(){
sudo /etc/init.d/privoxy stop
sudo cp /usr/local/etc/privoxy/config.psiphon /usr/local/etc/privoxy/config
sudo /etc/init.d/privoxy start
cd /usr/local/sbin/psiphon/
python ./psi_client.py -u
psiphonstart
psiphonstop
}

psiphonstart(){
sudo /etc/init.d/privoxy stop
sudo cp /usr/local/etc/privoxy/config.psiphon /usr/local/etc/privoxy/config
sudo /etc/init.d/privoxy start
cd /usr/local/sbin/psiphon/
python ./psi_client.py
psiphonstop
}

ans=$(zenity  --list  --title "PSIPHON CONTROLLER" --text "Start and stop Psiphon" --radiolist  --column "Pick" --column "Action" FALSE "Start Psiphon" FALSE "Update and Start Psiphon" TRUE "Stop Psiphon");

	if [  "$ans" = "Start Psiphon" ]; then
		psiphonstart

	elif [  "$ans" = "Update and Start Psiphon" ]; then
		updatestart

	elif [  "$ans" = "Stop Psiphon" ]; then 
		psiphonstop

	fi
