#!/bin/sh
Encoding=UTF-8

startopenvpn(){
	killall openvpn
	openvpn --config $ans;
}

stopopenvpn(){
	killall -9 openvpn
}

ans=$(zenity  --list  --title "OPENVPN CONTROLLER" --text "Start or stop an OpenVPN connection." --radiolist  --column "Pick" --column "Action" TRUE "Start OpenVPN" FALSE "Stop OpenVPN");

	if [  "$ans" = "Start OpenVPN" ]; then

		ans=$(zenity --file-selection --directory --title="Select an *.ovpn File" --filename=$HOME/openvpn/);
				case $? in
				         0)
				                echo "\"$ans\" selected."; startopenvpn;;
				         1)
				                echo "No file selected.";;
				        -1)
				                echo "An unexpected error has occurred.";;
				esac

	else 
		stopopenvpn
	fi

