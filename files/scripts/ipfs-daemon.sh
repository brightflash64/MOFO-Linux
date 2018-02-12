#!/bin/sh

# Copyright (c) 2018 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

initstart(){
ipfs init &
sleep 5
ipfsstart
}

ipfsstart(){
ipfs daemon &
sleep 10
firefox --new-tab http://127.0.0.1:5001/webui/
}

ipfsstop(){
ipfs shutdown
}

ans=$(zenity  --list  --text "IPFS DAEMON" --height 170 --width 360 \
--radiolist --column "Select"  --column "Action" FALSE "Initialize IPFS and start the daemon" \
FALSE "Start IPFS daemon" TRUE "Stop IPFS daemon");

	if 	 [  "$ans" = "Initialize IPFS and start the daemon" ]; then
		initstart

	elif [  "$ans" = "Start IPFS daemon" ]; then
		ipfsstart

	elif [  "$ans" = "Stop IPFS daemon" ]; then
		ipfsstop
	fi
