#!/bin/sh
Encoding=UTF-8

torstart(){
	systemctl stop privoxy.service
	sudo cp /usr/local/etc/privoxy/config.tor /usr/local/etc/privoxy/config
	systemctl start privoxy.service
	systemctl restart tor.service
}

torstop(){
	systemctl stop privoxy.service
	sudo cp /usr/local/etc/privoxy/config.orig /usr/local/etc/privoxy/config
	systemctl start privoxy.service
	systemctl stop tor.service
}

ans=$(zenity  --list  --title "TOR CONTROLLER" --text "Start and stop Tor" --radiolist  --column "Pick" --column "Action" TRUE "Start Tor" FALSE "Stop Tor");

	if [  "$ans" = "Start Tor" ]; then
		torstart
	else 
		torstop
	fi
