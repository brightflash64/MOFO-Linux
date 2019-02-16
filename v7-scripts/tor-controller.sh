#!/bin/sh

# Copyright (c) 2018 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

torobfs4(){
echo '//configure prefs for Tor
user_pref("network.proxy.ftp", "127.0.0.1");
user_pref("network.proxy.ftp_port", 9050);
user_pref("network.proxy.http", "127.0.0.1");
user_pref("network.proxy.http_port", 9050);
user_pref("network.proxy.share_proxy_settings", true);
user_pref("network.proxy.socks", "127.0.0.1");
user_pref("network.proxy.socks_port", 9050);
user_pref("network.proxy.ssl", "127.0.0.1");
user_pref("network.proxy.ssl_port", 9050);
user_pref("network.proxy.type", 1);' > /usr/local/etc/firefox/user.js
echo 'UseBridges 1
ClientTransportPlugin obfs3,obfs4,scramblesuit exec /usr/bin/obfs4proxy managed
ClientTransportPlugin meek exec /usr/bin/meek-client
Bridge ${bridgedata}' > /etc/torrc.d/10_bridges
mate-terminal -e 'tor'
source torsocks on
}

torstop(){
echo '//clear the proxy prefs
user_pref("network.proxy.ftp", "");
user_pref("network.proxy.ftp_port", 0);
user_pref("network.proxy.http", "");
user_pref("network.proxy.http_port", 0);
user_pref("network.proxy.share_proxy_settings", true);
user_pref("network.proxy.socks", "");
user_pref("network.proxy.socks_port", 0);
user_pref("network.proxy.ssl", "");
user_pref("network.proxy.ssl_port", 0);
user_pref("network.proxy.type", 5);' > /usr/local/etc/firefox/user.js
source torsocks off
systemctl stop tor.service
}

ans=$(zenity  --width 350 --height 200 --list  --title "TOR CONTROLLER" --text "Start and stop Tor" --radiolist  --column "Pick" --column "Action" FALSE "Start Tor and use Obfs4 or Scramblesuit" TRUE "Stop Tor");

	if [  "$ans" = "Start Tor and use Obfs4 or Scramblesuit" ]; then
        bridgedata=$(zenity --width 350 --height 50 --forms --title="Tor Pluggable Transport Configuration" --text="For Obfs4 or Scramblesuit bridges send an email to: bridges@torproject.org \nand either the text \"get transport obfs4\" or \"get transport scramblesuit\""  --add-entry="Enter Pluggable Transport Data:");

		torobfs4

	else
		torstop
	fi
