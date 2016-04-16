#!/bin/sh
Encoding=UTF-8

i2pstart(){
	systemctl stop privoxy.service
	sudo cp /usr/local/etc/privoxy/config.i2p /usr/local/etc/privoxy/config
	systemctl start privoxy.service
	/usr/bin/i2prouter start;
}

i2pstop(){
	systemctl stop privoxy.service
	sudo cp /usr/local/etc/privoxy/config.orig /usr/local/etc/privoxy/config
	systemctl start privoxy.service
	/usr/bin/i2prouter stop;
}

ans=$(zenity  --list  --title "I2P CONTROLLER" --text "Start and stop I2P" --radiolist  --column "Pick" --column "Action" TRUE "Start I2P" FALSE "Stop I2P");

	if [  "$ans" = "Start I2P" ]; then
		i2pstart
	else 
		i2pstop
	fi
