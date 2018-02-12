#!/bin/sh

# DNScrypt-proxy-controller.
# Copyright (c) 2018 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

dnscryptrestart(){
sudo bash -c 'echo "nameserver 127.0.2.1
nameserver 127.0.2.2" > /run/resolvconf/resolv.conf'
systemctl restart dnscrypt-proxy
systemctl restart dnscrypt-proxy2
}

dnscryptstop(){
sudo bash -c 'echo "nameserver 9.9.9.9
nameserver 8.8.8.8" > /run/resolvconf/resolv.conf'
systemctl stop dnscrypt-proxy
systemctl stop dnscrypt-proxy2
}

ans=$(zenity  --list  --text "DNSCRYPT-PROXY-CONTROLLER" --radiolist --column "Pick" TRUE "Stop DNSCrypt-Proxy" FALSE "Restart  DNSCrypt-Proxy" --column "Action");

	if [  "$ans" = "Stop DNSCrypt-Proxy" ]; then
		dnscryptstop
	else 
		dnscryptrestart
	fi
