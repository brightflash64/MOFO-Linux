#!/bin/sh

# Copyright (c) 2018 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

i2pstart(){
echo '//configure prefs for i2p
user_pref("network.proxy.http", "127.0.0.1");
user_pref("network.proxy.http_port", 4444);
user_pref("network.proxy.share_proxy_settings", true);
user_pref("network.proxy.ssl", "127.0.0.1");
user_pref("network.proxy.ssl_port", 4444);
user_pref("network.proxy.type", 1);' > /usr/local/etc/firefox/user.js
/usr/bin/i2prouter start;
}

i2pstop(){
/usr/bin/i2prouter stop;
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
exit
}

ans=$(zenity  --list  --title "I2P CONTROLLER" --text "Start and stop I2P" \
--width=500 --radiolist  --column "Pick" --column "Action" \
FALSE "Start I2P and configure Firefox settings." \
TRUE "Stop I2P and restore Firefox settings.");

	if [  "$ans" = "Start I2P and configure Firefox settings." ]; then
		i2pstart
	else 
		i2pstop
	fi
