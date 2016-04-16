#!/bin/sh
Encoding=UTF-8

dnscryptrestart(){
echo "nameserver 127.0.2.1
nameserver 127.0.2.2" > /run/resolvconf/resolv.conf
systemctl restart dnscrypt-proxy
systemctl restart dnscrypt-proxy2
}

dnscryptstop(){
echo "nameserver 8.8.8.8
nameserver 8.8.4.4" > /run/resolvconf/resolv.conf
systemctl stop dnscrypt-proxy
systemctl stop dnscrypt-proxy2
}

ans=$(zenity  --list  --text "DNSCRYPT-PROXY-CONTROLLER" --radiolist --column "Pick" TRUE "Stop DNSCrypt-Proxy" FALSE "Restart  DNSCrypt-Proxy" --column "Action");

	if [  "$ans" = "Stop DNSCrypt-Proxy" ]; then
		dnscryptstop
	else 
		dnscryptrestart
	fi
