#!/bin/bash

check_dependencies(){
mate-terminal -e 'sh -c  "cd /opt/algo-master/ && python2 -m virtualenv --python=`which python2` env && read line"'
source "/opt/algo-master/env/bin/activate" 
mate-terminal -e 'sh -c "python2 -m pip install -r requirements.txt && read line"'
}

runalgo(){
python -m virtualenv --python=`which python2` env
source "/opt/algo-master/env/bin/activate"
mate-terminal -e 'sh -c  "cd /opt/algo-master/ && ./algo && read line"'
}

getout(){
deactivate
exit
}

ans=$(zenity  --list  --title "ALGO VPN MANAGER" --width=500 --height=250 \
--text "Set up and run a VPN on your own server.
Note: You should backup your SSH keys and server
credentials to a safe place off of this system.
See the README files in /opt/algo-master for more
information." \
--radiolist  --column "Pick" --column "Action" \
FALSE "Run Algo." \
FALSE "Check Dependencies." \
TRUE "Stop Algo.");

	if [  "$ans" = "Run Algo." ]; then
		runalgo

	elif [  "$ans" = "Check Dependencies." ]; then
		check_dependencies

	elif [  "$ans" = "Stop Algo." ]; then
		getout

	fi
