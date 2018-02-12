#!/bin/sh

# Bitmask-controller.
# Copyright (c) 2018 by Philip Collier, <webmaster@mofolinux.com>
# mofo-updater is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

runbitmask(){
cd /usr/local/sbin/bitmask
./bitmask
}

#set networking configuration for bitmask vpn
sudo service privoxy stop
sudo cp /usr/local/etc/privoxy/config.orig /usr/local/etc/privoxy/config
sudo service privoxy start
sudo service dnscrypt-proxy stop
sudo service dnscrypt-proxy2 stop
sudo echo "nameserver 9.9.9.9
nameserver 8.8.8.8" > /run/resolvconf/resolv.conf

runbitmask

#restore normal networking configuration
sudo echo "nameserver 127.0.2.1
nameserver 127.0.2.2" > /run/resolvconf/resolv.conf
sudo killall -9 bitmask
sudo service dnscrypt-proxy start
sudo service dnscrypt-proxy2 start
