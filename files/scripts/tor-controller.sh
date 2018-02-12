#!/bin/sh

# Copyright (c) 2018 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

torobfs4(){
	sudo cp /etc/tor/torrc.orig /etc/tor/torrc
	sudo sed -i "207s/.*/Bridge $bridgedata/" /etc/tor/torrc
	sudo /etc/init.d/privoxy stop
	sudo cp /usr/local/etc/privoxy/config.tor /usr/local/etc/privoxy/config
	sudo /etc/init.d/privoxy start
	mate-terminal -e 'tor'
}

torstop(){
	systemctl stop tor.service
	sudo /etc/init.d/privoxy stop
	sudo cp /usr/local/etc/privoxy/config.orig /usr/local/etc/privoxy/config
	sudo /etc/init.d/privoxy start
sudo bash -c 'echo "nameserver 127.0.2.1
nameserver 127.0.2.2" > /run/resolvconf/resolv.conf'
	systemctl restart dnscrypt-proxy
	systemctl restart dnscrypt-proxy2
}

ans=$(zenity  --width 350 --height 200 --list  --title "TOR CONTROLLER" --text "Start and stop Tor" --radiolist  --column "Pick" --column "Action" TRUE "Start Tor and use Obfs4 or Scramblesuit" FALSE "Stop Tor");

	if [  "$ans" = "Start Tor and use Obfs4 or Scramblesuit" ]; then
        bridgedata=$(zenity --width 350 --height 50 --forms --title="Tor Pluggable Transport Configuration" --text="For Obfs4 or Scramblesuit bridges send an email to: bridges@torproject.org \nand either the text \"get transport obfs4\" or \"get transport scramblesuit\""  --add-entry="Enter Pluggable Transport Data:");

		torobfs4

	else
		torstop
	fi
