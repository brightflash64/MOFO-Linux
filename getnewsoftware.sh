#! /bin/sh
#
#System setup script for MOFO Linux v5.0
#Use on Ubuntu / Mint / Debian
#Run this script as root within the chroot!

#increase Ubuntu privacy, reduce resource load, remove conflicting packages
apt-get purge --auto-remove speech-dispatcher modemmanager cheese rhythmbox* shotwell unity-lens-shopping webbrowser-app deja-dup file-roller evince indicator-messages plymouth-theme-ubuntu-text snap-confine ubuntu-core-launcher ubiquity-ubuntu-artwork whoopsie zeitgeist zeitgeist-core
apt-get -y autoremove
apt-get clean

#bitmask
echo "\n\n software installer prerequisites"
add-apt-repository "deb http://deb.leap.se/client staging stretch"
wget -O- https://dl.bitmask.net/apt.key | apt-key add -

#update dnscrypt-proxy resolvers
wget "https://raw.githubusercontent.com/jedisct1/dnscrypt-proxy/master/dnscrypt-resolvers.csv"
mv dnscrypt-resolvers.csv /usr/share/dnscrypt-proxy/dnscrypt-resolvers.csv

#bubblewrap (for sandboxed tor browser)
apt-add-repository -y ppa:ansible/bubblewrap

#Tor
add-apt-repository "deb http://deb.torproject.org/torproject.org xenial main"
gpg --keyserver keys.gnupg.net --recv A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

#dnscrypt-proxy
apt-add-repository -y ppa:anton+/dnscrypt

#fcitx
add-apt-repository -y ppa:fcitx-team/nightly

#i2p
apt-add-repository -y ppa:i2p-maintainers/i2p

#onionshare
add-apt-repository -y ppa:micahflee/ppa

#firefox
add-apt-repository -y ppa:mozillateam/firefox-next

#l2tp/ipsec vpn
add-apt-repository -y ppa:nm-l2tp/network-manager-l2tp

#libreoffice
add-apt-repository -y ppa:libreoffice/ppa

#meek pluggable transport for Tor
add-apt-repository -y ppa:hda-me/meek

#node.js
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

#themes and icons
add-apt-repository -y ppa:noobslab/icons
add-apt-repository -y ppa:noobslab/themes

#thunderbird
add-apt-repository -y ppa:mozillateam/thunderbird-next

echo 'deb http://archive.getdeb.net/ubuntu xenial-getdeb apps' >> /etc/apt/sources.list.d/getdeb.list
wget 'http://archive.getdeb.net/getdeb-archive.key' | apt-key add -

#go language
add-apt-repository -y ppa:ubuntu-lxc/lxd-stable

#jitsi voip software
cd ~
echo "\n\n Getting Jitsi"
echo 'deb http://download.jitsi.org/deb unstable/' >> /etc/apt/sources.list.d/jitsi-unstable.list
wget 'https://download.jitsi.org/jitsi-key.gpg.key' | apt-key add -

#kodi multimedia center
add-apt-repository -y ppa:team-xbmc/unstable

#ring voip software
cd ~
echo "\n\n Getting Ring" 
echo 'deb https://dl.ring.cx/ring-nightly/ubuntu_16.04/ ring main' > /etc/apt/sources.list.d/ring-nightly-main.list
apt-key adv --keyserver pgp.mit.edu --recv-keys A295D773307D25A33AE72F2F64CD5FA175348F84

#veracrypt
add-apt-repository -y ppa:unit193/encryption

#zulucrypt:
apt-add-repository -y ppa:hda-me/zulucrypt

#Ubuntu
add-apt-repository multiverse
add-apt-repository universe
add-apt-repository xenial-backports
add-apt-repository xenial-proposed
add-apt-repository xenial-updates
add-apt-repository -y ppa:ubuntu-x-swat/updates
add-apt-repository -y ppa:xorg-edgers/ppa

# get everything that we want from the repositories
apt update
apt -y upgrade
apt -y install $(grep -vE "^\s*#" newsoftware  | tr "\n" " ")

#disable some services
systemctl disable snapd.refresh.service
systemctl disable tor.service

#lantern
echo "\n\n getting Lantern..."
wget "https://s3.amazonaws.com/lantern/lantern-installer-beta-64-bit.deb"
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

#install psiphon-tunnel-core
#echo "\nnext, Psiphon-Tunnel-Core"
# cd ~
# git clone https://github.com/Psiphon-Labs/psiphon-tunnel-core
# cd psiphon-tunnel-core/ConsoleClient
# ./make.bash linux 64

#install psiphon pyclient
# firtst: apt-get install mercurial meld
# next: hg clone https://bitbucket.org/psiphon/psiphon-circumvention-system/branch/pyclient
# then: built it from source...

#...or get this new Psiphon client, forked from the pyclient on bitbucket
echo "\n\n next, Psiphon (PyClient)"
cd ~
#git clone https://github.com/gilcu3/psiphon
git clone https://github.com/thispc/psiphon
cd /psiphon/openssh-5.9p1
./configure
make
mv ssh ../ssh
cd ../../
cp psiphon /usr/local/sbin/psiphon
pip install wget pexpect cryptography

#create the launcher file
echo "\n\n creating the .desktop file..."
echo '[Desktop Entry]
Comment=Psiphon Circumvention (vpn / proxy) controller for unblocked internet.
Exec=gnome-terminal -e '/usr/local/sbin/psiphon-controller.sh'
Name=Psiphon Controller
GenericName[en_US]=Psiphon censorship circumvention controller.
Categories=Network;Internet;Networking;Privacy;psiphon;VPN;proxy;
Icon=/usr/share/pixmaps/psiphon.png
NoDisplay=false
StartupNotify=false
Terminal=0
TerminalOptions=
Type=Application
GenericName[en_US.UTF-8]=Privacy, Cryptography, Circumvention Tools, Psiphon;' > /usr/share/applications/psiphon-controller.desktop

#get the latest bleachbit deb and put in the same directory as this script.
echo "\n\n next, Bleachbit"
wget 'https://download.bleachbit.org/beta/1.17/bleachbit_1.17_all_ubuntu1604.deb'
dpkg -i bleachbit_1.17_all_ubuntu1604.deb

# get the freenet java package, do not execute installer
wget 'https://github.com/freenet/fred/releases/download/build01478/new_installer_offline_1478.jar'
cp new_installer_offline_1478.jar /opt/freenet_installer_offline.jar

#get the latest Tor Browser and put in the opt directory.
echo "\n\n next, Tor Browser"
cd ~
wget "https://www.torproject.org/dist/torbrowser/7.5a4/sandbox-0.0.12-linux64.zip"
unzip "sandbox-0.0.12-linux64.zip"
mkdir /opt/tor-browser
mv sandbox/sandboxed-tor-browser /opt/tor-browser/sandboxed-tor-browser
rm -f sandbox-0.0.12-linux64.zip
rm -rf sandbox

#get the latest Tor Messenger and put in the opt directory.
echo "\n\n next, Tor Messener"
cd ~
wget "https://dist.torproject.org/tormessenger/current/tor-messenger-linux64-0.4.0b3_en-US.tar.xz"
tar -xJvf "tor-messenger-linux64-0.4.0b3_en-US.tar.xz"
mv tor-messenger-linux64-0.4.0b3_en-US /opt/tor-messenger
rm -f tor-messenger-linux64-0.4.0b3_en-US.tar.xz

#cjdns
echo "\n\n ...CJDNS..."
cd ~
cp ~/files/scripts/cjdns.sh /etc/init.d/cjdns
chmod +x /etc/init.d/cjdns
/etc/init.d/cjdns install
#set link for nodejs
ln -s /usr/bin/nodejs /usr/bin/node
ln -s /opt/cjdns/cjdroute /usr/bin
ln -s /opt/cjdns/contrib/systemd/cjdns.service /etc/systemd/system/cjdns.service

#get ipfs
wget "https://github.com/ipfs-shipyard/ipfs-desktop/releases/download/v0.3.0/ipfs-desktop_0.3.0_amd64.deb"
ln -s /usr/lib/ipfs-desktop/resources/app/node_modules/go-ipfs-dep/go-ipfs/ipfs /usr/local/bin/ipfs

#create a new launcher
echo "\n\n creating the ipfs-desktop.desktop file..."
echo '[Desktop Entry]
Name=IPFS Desktop
Comment=IPFS Native Application
GenericName=IPFS Desktop
Exec=ipfs-desktop %U
Icon=ipfs-desktop
Type=Application
StartupNotify=true
Categories=Network;Internet;Networking;' > /usr/share/applications/ipfs-desktop.desktop

#create a launcher for ipfs-daemon script
echo "\n\n creating the ipfs-daemon.desktop file..."
echo '[Desktop Entry]
Name=IPFS Daemon and WebUI
GenericName=IPFS Daemon and WebUI
Comment=Start, stop, and interact with IPFS
Exec=/usr/local/sbin/ipfs-daemon.sh
Icon=ipfs-desktop
Type=Application
StartupNotify=true
Categories=Network;Internet;Networking;' > /usr/share/applications/ipfs-daemon.desktop

#clean up
cd ~
echo "\n\n Finished installing new software!"
echo "\n\n Cleaning up apt..."
rm -f /var/lib/dpkg/info/dnscrypt-proxy2.postinst
rm -rf /etc/privoxy

#set symbolic links and copy the logo
ln -s /usr/local/etc/privoxy /etc/privoxy
ln -s /usr/share/fcitx/skin/default /usr/share/icons/Arc-Icons/status/fcitx
ln -s /usr/share/icons/Humanity/mimes /usr/share/icons/Arc-Icons/mimetypes
cp -f /usr/share/plymouth/mofo_logo.png /usr/share/unity-greeter/logo.png
systemctl enable privoxy.service
apt-get -y autoremove
apt-get clean

#create directories
echo "\n\n Creating directories..."
mkdir /etc/skel/cjdns
mkdir /etc/skel/openvpn
mkdir /etc/skel/softether
mkdir /opt/html
mkdir /usr/local/etc/privoxy
mkdir /usr/local/sbin/cjdns
mkdir /usr/local/sbin/softether-scripts
mkdir /usr/local/sbin/vpngate-scripts2
mkdir /usr/local/sbin/vpngate-with-proxy
mkdir /etc/skel/.local
mkdir /etc/skel/.local/share
mkdir /etc/skel/.local/share/applications

#move certain files into the new system
echo "\n\n Copying files..."
cp ~/files/apt/10periodic /etc/apt/apt.conf.d/10periodic
cp ~/files/rhythmbox/iradio-initial.xspf /usr/share/rhythmbox/plugins/iradio/iradio-initial.xspf
cp ~/files/alsa/asound.state /var/lib/alsa/asound.state
cp ~/files/etc/pulse/daemon.conf /etc/pulse/daemon.conf
cp ~/files/etc/cpulse/default.pa /etc/pulse/default.pa
cp ~/files/networking/resolv.conf /run/resolvconf/resolv.conf
cp ~/files/networking/resolvconf /etc/network/if-up.d/resolvconf
cp ~/files/etc/asound.conf /etc/asound.conf
cp ~/files/etc/issue /etc/issue
cp ~/files/etc/issue.net /etc/issue.net
cp ~/files/etc/legal /etc/legal
cp ~/files/etc/lsb-release /etc/lsb-release
cp ~/files/etc/os-release /etc/os-release
cp ~/files/gedit/org.gnome.gedit.gschema.xml /usr/share/glib-2.0/schemas/org.gnome.gedit.gschema.xml
cp ~/files/firefox/privoxy.js /usr/lib/firefox/defaults/pref/privoxy.js
cp ~/files/scripts/cjdns-controller.sh /usr/local/sbin/cjdns-controller.sh
cp ~/files/scripts/dnscrypt-proxy-controller.sh /usr/local/sbin/dnscrypt-proxy-controller.sh
cp ~/files/scripts/freenet-installer.sh /usr/local/sbin/freenet-installer.sh
cp ~/files/scripts/i2p-controller.sh /usr/local/sbin/i2p-controller.sh
cp ~/files/scripts/openvpn-controller.sh /usr/local/sbin/openvpn-controller.sh
cp ~/files/scripts/softether-controller.sh /usr/local/sbin/softether-controller.sh
cp ~/files/scripts/tor-controller.sh /usr/local/sbin/tor-controller.sh
cp ~/files/scripts/websdr-list.sh /usr/local/sbin/websdr-list.sh
cp ~/files/scripts/softether-scripts/* /usr/local/sbin/softether-scripts
cp ~/files/scripts/vpngate-scripts2/* /usr/local/sbin/vpngate-scripts2
cp ~/files/scripts/vpngate-scripts3/* /usr/local/sbin/vpngate-scripts3
cp ~/files/scripts/vpngate-with-proxy/* /usr/local/sbin/vpngate-scripts2
cp ~/files/mirrors.txt /etc/skel/softether/mirrors.txt
cp ~/files/mirrors.txt_link /usr/local/sbin/
cp ~/files/cjdns/cjdns_peers_ipv4 /etc/skel/cjdns/cjdns_peers_ipv4
cp ~/files/cjdns/cjdns_peers_ipv6 /etc/skel/cjdns/cjdns_peers_ipv6
cp ~/files/cjdns/cjdns_peers_ipv4_link /usr/local/sbin/cjdns/cjdns_peers_ipv4
cp ~/files/cjdns/cjdns_peers_ipv6_link /usr/local/sbin/cjdns/cjdns_peers_ipv6
cp ~/files/privoxy/config /usr/local/etc/privoxy/config
cp ~/files/privoxy/config.i2p /usr/local/etc/privoxy/config.i2p
cp ~/files/privoxy/config.orig /usr/local/etc/privoxy/config.orig
cp ~/files/privoxy/config.tor /usr/local/etc/privoxy/config.tor
cp ~/files/apps/cjdns-controller.desktop /usr/share/applications/cjdns-controller.desktop
cp ~/files/apps/dnscrypt-proxy-controller.desktop /usr/share/applications/dnscrypt-proxy-controller.desktop
cp ~/files/apps/freenet-installer.desktop /usr/share/applications/freenet-installer.desktop
cp ~/files/apps/i2p-controller.desktop /usr/share/applications/i2p-controller.desktop
cp ~/files/apps/lantern.desktop /usr/share/applications/lantern.desktop
cp ~/files/apps/mofolinux-intro.desktop /usr/share/applications/mofolinux-intro.desktop
cp ~/files/apps/nautilus-root.desktop /usr/share/applications/nautilus-root.desktop
cp ~/files/apps/openvpn-controller.desktop /usr/share/applications/openvpn-controller.desktop
cp ~/files/apps/start-tor-browser.desktop /etc/skel/.local/share/applications/start-tor-browser.desktop
cp ~/files/apps/start-tor-messenger.desktop /etc/skel/.local/share/applications/start-tor-messenger.desktop
cp ~/files/apps/tor-controller.desktop /usr/share/applications/tor-controller.desktop
cp ~/files/icons/Cjdns_logo.png /usr/share/pixmaps/Cjdns_logo.png
cp ~/files/icons/i2p.png /usr/share/pixmaps/i2p.png
cp ~/files/icons/tor.png /usr/share/pixmaps/tor.png
cp ~/files/icons/radio-icon.png /usr/share/pixmaps/radio-icon.png
cp ~/files/icons/freenet.ico /usr/share/pixmaps/freenet.ico
cp ~/files/opt/iccpr.html /opt/iccpr.html
cp ~/files/opt/MOFO-LINUX-README.html_link /etc/skel/MOFO-LINUX-README.html
cp ~/files/opt/MOFO-LINUX-README.html /opt/html/MOFO-LINUX-README.html
cp ~/files/opt/textpage.css /opt/html/textpage.css
cp ~/files/opt/udhr.html /opt/html/udhr.html

# replace mate-screenshot with a symlink to gnome-screenshot
ln -s gnome-screenshot mate-screenshot

#rename some files to disable services
mv /etc/init/avahi-cups-reload.conf /etc/init/avahi-cups-reload.disabled
mv /etc/init/bluetooth.conf /etc/init/bluetooth.disabled
mv /etc/init/tty3.conf /etc/init/tty3.disabled
mv /etc/init/tty4.conf /etc/init/tty4.disabled
mv /etc/init/tty5.conf /etc/init/tty5.disabled
mv /etc/init/tty6.conf /etc/init/tty6.disabled

#make or edit some files
echo "\n\n Editing configurations..."
echo "Keep your OpenVPN configs, keys, and certificates in this folder." > /etc/skel/openvpn/README.txt

#Tweak performance and blacklist some modules
#blacklist the rtl28xxu kernel driver
echo "blacklist dvb_usb_rtl28xxu
blacklist e4000
blacklist rtl2832" >> /etc/modprobe.d/rtl-sdr-blacklist.conf

#set up /etc/init.d/rc.local
echo "
#rtc and hpet timers
echo 3072 > /sys/class/rtc/rtc0/max_user_freq
echo 3072 > /proc/sys/dev/hpet/max-user-freq

#Ecryptfs
modprobe ecryptfs

#Veracrypt
modprobe fuse

#settings for i2p
iptables -I INPUT 1 -p tcp --tcp-flags SYN,RST,ACK SYN --dport 20000 -m conntrack --ctstate NEW -j ACCEPT
iptables -I INPUT 1 -p udp --dport 20000 -m conntrack --ctstate NEW -j ACCEPT" >> /etc/init.d/rc.local

#set performance configuration in sysctl.conf
echo "
############
vm.swappiness = 10
vm.dirty_ratio = 3
vm.vfs_cache_pressure=50
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
net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf

#configure for realtime audio
echo "@audio - rtprio 95
@audio - memlock 512000
@audio - nice -19" > /etc/security/limits.d/audio.conf

#set performance config in rc.local
echo "#rtc and hpet timers
echo 3072 > /sys/class/rtc/rtc0/max_user_freq
echo 3072 > /proc/sys/dev/hpet/max-user-freq" >> /etc/init.d/rc.local

#move /tmp to ram
cp /usr/share/systemd/tmp.mount /etc/systemd/system/tmp.mount
systemctl enable tmp.mount

echo "\n\n All tasks completed!"
