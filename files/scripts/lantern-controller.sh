#!/bin/sh

# Copyright (c) 2018 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

sudo /etc/init.d/privoxy stop
lantern -addr=127.0.0.1:8118
sudo cp /usr/local/etc/privoxy/config.orig /usr/local/etc/privoxy/config
sudo /etc/init.d/privoxy start
