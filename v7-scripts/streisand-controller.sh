#!/bin/bash

check_dependencies(){
mate-terminal -e 'sh -c  "cd /opt/streisand/ && ./util/venv-dependencies.sh /opt/streisand/env && read line"'
}

createkeys(){
mate-terminal -e 'sh -c  "ssh-keygen && read line"'
}

runstreisand(){
source "/opt/streisand/env/bin/activate"
mate-terminal -e 'sh -c  "cd /opt/streisand/ && ./streisand && read line"'
}

getout(){
deactivate
exit
}

ans=$(zenity  --list  --title "STREISAND VPN MANAGER" --width=400 --height=270 \
--text "Set up and run a VPN on your own server.
Note: You should backup your SSH keys and server 
credentials to a safe place off of this system.
See the README files in /opt/streisand for more
information." \
--radiolist  --column "Pick" --column "Action" \
FALSE "Run Streisand." \
FALSE "Check Dependencies." \
FALSE "Create an SSH key pair." \
TRUE "Stop Streisand.");

	if [  "$ans" = "Run Streisand." ]; then
		runstreisand

	elif [  "$ans" = "Check Dependencies." ]; then
		check_dependencies

	elif [  "$ans" = "Create an SSH key pair." ]; then
		createkeys

	elif [  "$ans" = "Stop Streisand." ]; then
		getout

	fi
