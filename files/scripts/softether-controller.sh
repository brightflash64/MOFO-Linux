#!/bin/sh
Encoding=UTF-8

cd /usr/local/sbin/vpngate-scripts2

stopsoftether(){
	#stop softether
	./se.sh disconnect

}

startsoftether(){
	#start softether
	./se.sh server
	./se.sh connect
}

ans=$(zenity  --list  --title "SOFTETHER CONTROLLER" --text "Start or stop a SoftEther connection"--radiolist  --column "Pick" --column "Action" TRUE "Start SoftEther VPN" FALSE "Stop SoftEther VPN");

	if [  "$ans" = "Start SoftEther VPN" ]; then
		startsoftether
	else 
		stopsoftether
	fi
