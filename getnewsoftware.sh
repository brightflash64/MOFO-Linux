#! /bin/sh
#
#System setup script for MOFO Linux v4.5
#Use on Ubuntu / Mint / Debian
#Run this script as root!

#increase Ubuntu privacy
apt-get remove unity-lens-shopping

echo "\nsoftware installer prerequisites"
#veracrypt
add-apt-repository ppa:unit193/encryption

#zulucrypt:
apt-add-repository ppa:hda-me/zulucrypt

#dnscrypt-proxy
apt-add-repository ppa:anton+/dnscrypt

#fcitx
add-apt-repository ppa:fcitx-team/nightly

#onionshare
add-apt-repository ppa:micahflee/ppa

#libreoffice
add-apt-repository ppa:libreoffice/ppa

#firefox
add-apt-repository ppa:mozillateam/firefox-next

#Ubuntu
add-apt-repository universe
add-apt-repository multiverse
add-apt-repository wily-backports
add-apt-repository wily-proposed
add-apt-repository wily-updates

# get everything that we want from the repositories
apt-get update
apt-get upgrade
apt-get -y install $(grep -vE "^\s*#" newsoftware  | tr "\n" " ")

#voip software - ring
echo "\ngetting Ring"
sh -c "echo 'deb http://nightly.apt.ring.cx/ubuntu_15.04/ ring main' >> /etc/apt/sources.list.d/ring-nightly-man.list"
wget -O - "http://gpl.savoirfairelinux.net/ring-download/ring.pub.key" | sudo apt-key add -

#voip software - jitsi
echo "\nnext, Jitsi"
wget -O - "https://download.jitsi.org/jitsi/debian/jitsi_2.8.5426-1_amd64.deb"
dpkg -i jitsi_2.8.5426-1_amd64.deb

#get the latest bleachbit deb and put in the same directory as this script.
echo "\ngetting Bleachbit"
wget -O - "http://bleachbit.sourceforge.net/download/file?file=bleachbit_1.8_all_ubuntu1504.deb"
dpkg -i bleachbit_1.8_all_ubuntu1504.deb

#get the latest jondo deb and put in the same directory as this script.
echo "\nnext, JonDo"
wget -O - "https://anonymous-proxy-servers.net/downloads/jondo_all.deb"
dpkg -i jondo_all.deb

#get the latest Tor Browser and put in the opt directory.
echo "\nnext, Tor Browser"
cd /opt
wget -O - "https://github.com/TheTorProject/gettorbrowser/releases/download/v5.5.4/tor-browser-linux64-5.5.4_en-US.tar.xz"
tar -xjvf "tor-browser-linux64-5.5.4_en-US.tar.xz"
mv /opt/tor-browser-linux64-5.5.4_en-US /opt/tor-browser
rm -f tor-browser-linux64-5.5.4_en-US.tar.xz
cd ~

#get the latest Tor Messenger and put in the opt directory.
echo "\nnext, Tor Messenger"
cd /opt
wget -O - "https://dist.torproject.org/tormessenger/0.1.0b4/tor-messenger-linux64-0.1.0b4_en-US.tar.xz"
tar -xjvf "tor-messenger-linux64-0.1.0b4_en-US.tar.xz"
mv /opt/tor-messenger-linux64-0.1.0b4_en-US /opt/tor-messenger
rm -f tor-browser-linux64-5.5.4_en-US.tar.xz
cd ~

#install cjdns and configure for the Hyperboria network
echo "\nnext, Cjdns"
wget -c https://gist.githubusercontent.com/satindergrewal/1b8310e9a4a68183385c/raw/369ec444ab26b31552c4e5d10d2906c4214232fd/hyperboria.sh -O /etc/init.d/hyperboria
chmod +x /etc/init.d/hyperboria
/etc/init.d/hyperboria install

#get the latest popcorn-time package and put in the /opt directory.
echo "\nnext, Popcorn-Time"
cd /opt
wget -O - "https://get.popcorntime.sh/build/Popcorn-Time-0.3.9-Linux-64.tar.xz"
tar -xjvf "Popcorn-Time-0.3.9-Linux-64.tar.xz"
mv /opt/Popcorn-Time-0.3.9-Linux-64 /opt/popcorn-time
rm -f Popcorn-Time-0.3.9-Linux-64.tar.xz
cd ~
echo "\nFinished installing new software!"
echo "\nCleaning up apt..."
apt-get -y autoremove
apt-get clean

#create directories
echo "\nMaking new directories..."
mkdir /etc/skel/cjdns
mkdir /etc/skel/openvpn
mkdir /etc/skel/softether
mkdir /usr/local/etc/privoxy
mkdir /usr/local/sbin/cjdns
mkdir /usr/local/sbin/softether-scripts
mkdir /usr/local/sbin/vpngate-scripts2
mkdir /usr/local/sbin/vpngate-with-proxy
mkdir /etc/skel/.local
mkdir /etc/skel/.local/share
mkdir /etc/skel/.local/share/applications

#move certain files into the new system
echo "\nCopying files..."
cp /files/apt/10periodic /etc/apt/apt.conf.d/10periodic
cp /files/iradio-initial.xspf /usr/share/rhythmbox/plugins/iradio/iradio-initial.xspf
cp /files/alsa/asound.state /var/lib/alsa/asound.state
cp /files/pulse/daemon.conf /etc/pulse/daemon.conf
cp /files/pulse/default.pa /etc/pulse/default.pa
cp /files/networking/resolv.conf /run/resolvconf/resolv.conf
cp /files/networking/resolvconf /etc/network/if-up.d/resolvconf
cp /files/etc/asound.conf /etc/asound.conf
cp /files/etc/issue /etc/issue
cp /files/etc/issue.net /etc/issue.net
cp /files/etc/legal /etc/legal
cp /files/etc/lsb-release /etc/lsb-release
cp /files/etc/os-release /etc/os-release
cp /files/scripts/cjdns-controller.sh /usr/local/sbin/cjdns-controller.sh
cp /files/scripts/dnscrypy-proxy-controller.sh /usr/local/sbin/dnscrypt-proxy-controller.sh
cp /files/scripts/i2p-controller.sh /usr/local/sbin/i2p-controller.sh
cp /files/scripts/openvpn-controller.sh /usr/local/sbin/openvpn-controller.sh
cp /files/scripts/softether-controller.sh /usr/local/sbin/softether-controller.sh
cp /files/scripts/tor-controller.sh /usr/local/sbin/tor-controller.sh
cp /files/scripts/websdr-list.sh /usr/local/sbin/websdr-list.sh
cp /files/scripts/softether-scripts/* /usr/local/sbin/softether-scripts
cp /files/scripts/vpngate-scripts2/* /usr/local/sbin/vpngate-scripts2
cp /files/scripts/vpngate-with-proxy/* /usr/local/sbin/vpngate-scripts2
cp /files/mirrors.txt /etc/skel/softether/mirrors.txt
cp /files/mirrors.txt_link /usr/local/sbin/
cp /files/cjdns/cjdns_peers_ipv4 /etc/skel/cjdns/cjdns_peers_ipv4
cp /files/cjdns/cjdns_peers_ipv6 /etc/skel/cjdns/cjdns_peers_ipv6
cp /files/cjdns/cjdns_peers_ipv4_link /usr/local/sbin/cjdns/cjdns_peers_ipv4
cp /files/cjdns/cjdns_peers_ipv6_link /usr/local/sbin/cjdns/cjdns_peers_ipv6
cp /files/privoxy/config /usr/local/etc/privoxy/config
cp /files/privoxy/config.i2p /usr/local/etc/privoxy/config.i2p
cp /files/privoxy/config.orig /usr/local/etc/privoxy/config.orig
cp /files/privoxy/config.tor /usr/local/etc/privoxy/config.tor
cp /files/apps/cjdns-controller.desktop /usr/share/applications/cjdns-controller.desktop
cp /files/apps/dnscrypt-proxy-controller.desktop /usr/share/applications/dnscrypt-proxy-controller.desktop
cp /files/apps/i2p-controller.desktop /usr/share/applications/i2p-controller.desktop
cp /files/apps/nautilus-root.desktop /usr/share/applications/nautilus-root.desktop
cp /files/apps/openvpn-controller.desktop /usr/share/applications/openvpn-controller.desktop
cp /files/apps/start-tor-browser.desktop /etc/skel/.local/share/applications/start-tor-browser.desktop
cp /files/apps/start-tor-messenger.desktop /etc/skel/.local/share/applications/start-tor-messenger.desktop
cp /files/apps/popcorn-time.desktop /usr/share/applications/popcorn-time.desktop
cp /files/apps/tor-controller.desktop /usr/share/applications/tor-controller.desktop
cp /files/icons/Cjdns_logo.png /usr/share/pixmaps/Cjdns_logo.png
cp /files/icons/i2p.png /usr/share/pixmaps/i2p.png
cp /files/icons/tor.png /usr/share/pixmaps/tor.png
cp /files/opt/iccpr.html /opt/iccpr.html
cp /files/opt/MOFO-LINUX-README.html_link /etc/skel/MOFO-LINUX-README.html
cp /files/opt/MOFO-LINUX-README.html /opt/MOFO-LINUX-README.html
cp /files/opt/textpage.css /opt/textpage.css
cp /files/opt/udhr.html /opt/udhr.html

#make or edit some files
echo "\nediting condigurations..."
echo "Keep your OpenVPN configs, keys, and certificates in this folder." > /etc/skel/openvpn/README.txt

#set performance configuration in sysctl.conf
echo "
############
net.core.somaxconn = 1000
net.core.netdev_max_backlog = 5000
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_wmem = 4096 12582912 16777216
net.ipv4.tcp_rmem = 4096 12582912 16777216
net.ipv4.tcp_max_syn_backlog = 8096
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 10240 65535
# Set swappiness
vm.swappiness=10
# Improve cache management
vm.vfs_cache_pressure=50" >> /etc/sysctl.conf

echo "\nAll Tasks completed!"
