#!/bin/sh

# Copyright (c) 2018 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

install(){
	java -jar /opt/freenet/freenet_installer_offline.jar
}

ans=$(zenity  --list  --title "FREENET INSTALLER" --text "Install Freenet Application" --radiolist  --column "Pick" --column "Action" TRUE "Install Freenet Application" FALSE "Do Not Install Freenet Application");

	if [  "$ans" = "Install Freenet Application" ]; then
		install
	else 
		exit
	fi
