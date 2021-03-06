#!/bin/sh

# Copyright (c) 2018 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

startopenvpn(){
sudo killall openvpn
file=$(zenity --file-selection --title="Select an *.ovpn File" --filename=$HOME/openvpn/)
sudo mate-terminal -e "sh -c 'openvpn --config $file'"&
}

vpngate(){
sudo killall openvpn
sudo sed -i -e 's/\/[a-z][a-z]\/.*//g' $HOME/softether/mirrors.txt
cd /usr/local/sbin/softether-scripts
sudo mate-terminal -e 'python2 ./start_openvpn.py'
}

stopopenvpn(){
sudo killall -9 openvpn
exit
}

ans=$(zenity  --list  --title "OPENVPN CONTROLLER" --text "Start or stop an OpenVPN connection." --radiolist  --column "Pick" --column "Action" TRUE "Start OpenVPN (VPN Gate)" FALSE "Start OpenVPN (Config File)" FALSE "Stop OpenVPN");

	if [  "$ans" = "Start OpenVPN (VPN Gate)" ]; then
                vpngate

	elif [  "$ans" = "Start OpenVPN (Config File)" ]; then
		startopenvpn

	elif [  "$ans" = "Stop OpenVPN" ]; then
		stopopenvpn
	fi

