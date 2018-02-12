#!/bin/sh

# mofo-updater for MOFO Linux, version 0.5
# Copyright (c) 2018 by Philip Collier, <webmaster@mofolinux.com>
# mofo-updater is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

apt update
apt -y upgrade
snap refresh

#lantern
echo "\n\n getting Lantern..."
#wget "https://github.com/getlantern/lantern-binaries/raw/master/lantern-installer-beta-64-bit.deb"
dpkg -i lantern-installer-beta-64-bit.deb

#replace the .desktop file
echo "\n\n creating the desktop file..."
echo '[Desktop Entry]
Type=Application
Name=Lantern
Exec=/usr/local/sbin/lantern-controller.sh
Icon=lantern
Comment=uncensored network access application, internet unblocker, VPN / Proxy
Categories=Network;Internet;Networking;Privacy;' > /usr/share/applications/lantern.desktop

#get the latest Tor Browser and put in the opt directory.
echo "\n\n next, Tor Browser"
cd ~
#wget "https://www.torproject.org/dist/torbrowser/7.5a10/sandbox-0.0.16-linux64.zip"
unzip "sandbox-0.0.16-linux64.zip"
mv sandbox/sandboxed-tor-browser /opt/tor-browser/sandboxed-tor-browser
rm -f sandbox-0.0.16-linux64.zip
rm -rf sandbox

#get the latest Tor Messenger and put in the opt directory.
echo "\n\n next, Tor Messenger"
cd ~
#wget "https://dist.torproject.org/tormessenger/current/tor-messenger-linux64-0.5.0b1_en-US.tar.xz"
tar -xJvf "tor-messenger-linux64-0.5.0b1_en-US.tar.xz"
rm -rt /opt/tor-messenger
mv tor-messenger-linux64-0.5.0b1_en-US /opt/tor-messenger
rm -f tor-messenger-linux64-0.5.0b1_en-US.tar.xz

#update cjdns
echo "\n\n updating cjdns..."
cd /opt
rm -rf cjdns
git clone https://github.com/cjdelisle/cjdns
cd cjdns
./do
ln -s /opt/cjdns/cjdroute /usr/bin/cjdroute

# get the freenet java package, do not execute installer
#wget 'https://github.com/freenet/fred/releases/download/build01479/new_installer_offline_1479.jar'
cp new_installer_offline_1479.jar /opt/freenet_installer_offline.jar

#veracrypt - the app will update from the ppa, but the icon
#should be upgraded.

#replace the .desktop file
echo "\n\n creating the desktop file..."
echo '[Desktop Entry]
Type=Application
Name=VeraCrypt
GenericName=VeraCrypt volume manager
Comment=Create and mount VeraCrypt encrypted volumes
Icon=/usr/share/pixmaps/veracrypt.png
Exec=veracrypt
Categories=Security;Utility;Filesystem
Keywords=encryption,filesystem
Terminal=false
X-Ayatana-Desktop-Shortcuts=MountFavorites;DismountAll
MimeType=application/x-veracrypt-volume;application/x-truecrypt-volume;

[MountFavorites Shortcut Group]
Name=Mount All Favorite Volumes
Exec=/usr/bin/veracrypt --auto-mount=favorites
TargetEnvironment=Unity

[DismountAll Shortcut Group]
Name=Dismount All Mounted Volumes
Exec=/usr/bin/veracrypt --dismount
TargetEnvironment=Unity'  > /usr/share/applications/veracrypt.desktop

#get the latest bleachbit deb and put in the same directory as this script.
echo "\n\n next, Bleachbit"
#wget 'https://download.bleachbit.org/beta/1.19/bleachbit_1.19_all_ubuntu1604.deb'
dpkg -i bleachbit_1.19_all_ubuntu1604.deb

#update ipfs-desktop
wget "https://github.com/ipfs-shipyard/ipfs-desktop/releases/download/v0.3.0/ipfs-desktop_0.3.0_amd64.deb"
dpkg -i ipfs-desktop_0.3.0_amd64.deb

echo "\n\n All updates are accomplished!"
