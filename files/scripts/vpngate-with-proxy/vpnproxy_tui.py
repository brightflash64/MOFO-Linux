#!/usr/bin/env python
# -*- coding: utf-8 -*-
__author__ = "duc_tin"
__copyright__ = "Copyright 2015+, duc_tin"
__license__ = "GPLv2"
__version__ = "1.25"
__maintainer__ = "duc_tin"
__email__ = "nguyenbaduc.tin@gmail.com"

import os
import signal
import base64
import time
import datetime
from copy import deepcopy
from config import *
from subprocess import call, Popen, PIPE
from threading import Thread
from Queue import Queue, Empty
from collections import deque, OrderedDict
from vpn_indicator import *

# Get sudo privilege
euid = os.geteuid()
if euid != 0:
    import platform
    if 'buntu' in platform.platform() and not Popen(['pgrep', '-f', 'vpn_indicator'], stdout=PIPE).communicate()[0]:
        print 'Launch vpn_indicator'
        with open('out.txt', 'w+') as f:
            Popen(['python', 'vpn_indicator.py'], stdout=PIPE, stderr=PIPE, bufsize=1,)

    args = ['sudo', sys.executable] + sys.argv + [os.environ]
    os.execlpe('sudo', *args)

# Threading
ON_POSIX = 'posix' in sys.builtin_module_names

# Read mirrors into an array
mirrors = open('mirrors.txt','r').read().split('\n')

class Server:
    def __init__(self, data):
        self.ip = data[1]
        self.score = int(data[2])
        self.ping = int(data[3]) if data[3] != '-' else 'inf'
        self.speed = int(data[4])
        self.country_long = data[5]
        self.country_short = data[6]
        self.NumSessions = data[7]
        self.uptime = data[8]
        self.logPolicy = data[11]
        self.config_data = base64.b64decode(data[-1])
        self.proto = 'tcp' if '\r\nproto tcp\r\n' in self.config_data else 'udp'
        port = re.findall('remote .+ \d+', self.config_data)
        if not port:
            self.port = '0'
        else:
            self.port = port[0].split()[-1]

    def write_file(self, use_proxy='no', proxy=None, port=None):
        txt_data = self.config_data
        if use_proxy == 'yes':
            txt_data = txt_data.replace('\r\n;http-proxy-retry\r\n', '\r\nhttp-proxy-retry 3\r\n')
            txt_data = txt_data.replace('\r\n;http-proxy [proxy server] [proxy port]\r\n',
                                        '\r\nhttp-proxy %s %s\r\n' % (proxy, port))

        extra_option = ['keepalive 5 30\r\n',         # prevent connection drop due to inactivity timeout
                        '%s' % ('connect-retry 2\r\n' if self.proto == 'tcp' else ''),
                        ]
        if True:
            index = txt_data.find('client\r\n')
            txt_data = txt_data[:index] + ''.join(extra_option) + txt_data[index:]

        tmp_vpn = open('vpn_tmp', 'w+')
        tmp_vpn.write(txt_data)
        return tmp_vpn

    def __str__(self):
        spaces = [6, 7, 6, 10, 10, 10, 10, 8, 8]
        speed = self.speed / 1000. ** 2
        uptime = datetime.timedelta(milliseconds=int(self.uptime))
        uptime = re.split(',|\.', str(uptime))[0]
        txt = [self.country_short, str(self.ping), '%.2f' % speed, uptime, self.logPolicy, str(self.score), self.proto, self.port]
        txt = [dta.center(spaces[ind + 1]) for ind, dta in enumerate(txt)]
        return ''.join(txt)

    def __repr__(self):
        speed = self.speed / 1000. ** 2
        uptime = datetime.timedelta(milliseconds=int(self.uptime))
        # uptime = re.split(',|\.', str(uptime))[0]
        uptime = str(uptime)[:-7]
        txt = [self.country_long.strip('of'), self.ip, str(self.ping), '%.2f' % speed, uptime, self.NumSessions,
               self.logPolicy, str(self.score), self.proto, self.port]
        return ';'.join(txt)


class Connection:
    def __init__(self):
        self.path = os.path.realpath(sys.argv[0])
        self.config_file = os.path.split(self.path)[0] + '/config.ini'
        self.cfg = Setting(self.config_file)
        self.args = sys.argv[1:]
        self.debug = []
        self.dropped_time = 0
        self.max_retry = 3

        self.vpndict = {}
        self.filters = {'Country': 'all', 'Port': 'all'}
        self.sorted = []

        self.vpn_server = None
        self.vpn_process = None
        self.vpn_queue = None
        self.connect_status = False
        self.kill = False
        self.get_limit = 1

        self.connected_servers = []
        self.messages = OrderedDict([('country', deque([' '], maxlen=1)),
                                     ('status', deque([' ', ' '], maxlen=2)),
                                     ('debug', deque(maxlen=20))])

        # get proxy from config file
        if not os.path.exists(self.config_file):
            self.first_config()

        self.cfg.load()
        if len(self.args):
            # process commandline arguments
            if self.args[0] in ['r', 'restore']:
                self.dns_manager('restore')
            else:
                get_input(self.cfg, self.args)

        self.use_proxy, self.proxy, self.port, self.ip = ['']*4
        self.sort_by, self.filters, self.dns_fix, self.dns = ['']*4
        self.verbose = ''
        self.reload()

    def reload(self):
        self.use_proxy, self.proxy, self.port, self.ip = self.cfg.proxy.values()
        self.sort_by = self.cfg.sort.values()[0]
        self.filters = self.cfg.filter
        self.dns_fix, self.dns = self.cfg.dns.values()
        self.verbose = self.cfg.openvpn.values()[0]

    def rewrite(self, section, **contents):
        for key in contents:
            self.cfg.sections[section][key] = contents[key]
        self.cfg.write()
        self.reload()

    def first_config(self):
        print '\n' + '_' * 12 + ctext(' First time config ', 'gB') + '_' * 12 + '\n'

        self.cfg.proxy['use_proxy'] = 'no' if raw_input(
            ctext('Do you need proxy to connect? ', 'B') + '[yes|no(default)]:') in 'no' else 'yes'
        if self.cfg.proxy['use_proxy'] == 'yes':
            print ' Input your http proxy address and port without including "http://" \nsuch as ' \
                  + ctext('www.abc.com:8080', 'pB')
            while 1:
                try:
                    proxy, port = raw_input(' Your\033[95m proxy:port \033[0m: ').split(':')
                    ip = socket.gethostbyname(proxy)
                    port = port.strip()
                    if not 0 <= int(port) <= 65535:
                        raise ValueError
                except ValueError:
                    print ctext(' Error: Http proxy must in format ', 'r') + ctext('address:port', 'B')
                    print ' Where ' + ctext('address', 'B') + ' is in form of www.abc.com or 123.321.4.5'
                    print '       ' + ctext('port', 'B') + ' is a number in range 0-65535'
                else:
                    self.cfg.proxy['address'] = proxy
                    self.cfg.proxy['port'] = port
                    self.cfg.proxy['ip'] = ip
                    break

        get_input(self.cfg, 'config')
        print '\n' + '_' * 12 + ctext(' Config done', 'gB') + '_' * 12 + '\n'

    def get_csv(self, url, queue, proxy={}):
        self.messages['debug'].appendleft(' using gate: ' + url)

	for url in mirrors:
            try:
                gate = url + '/api/iphone/'
                vpn_data = requests.get(gate, proxies=proxy, timeout=3).text.replace('\r', '')
                servers = [line.split(',') for line in vpn_data.split('\n')]
                if servers[0][0] == '*vpn_servers':
                    vpndict = {s[0]: Server(s) for s in servers[2:] if len(s) > 1}
                    self.messages['debug'].appendleft(' gate ' + url + ': success')
                    queue.put((1, vpndict))
                else:
                    self.messages['debug'].appendleft(' Received WRONG data file')
                    self.messages['debug'].appendleft(' Connection to gate ' + url + ' failed')
                    self.messages['debug'].appendleft(vpn_data)
                    queue.put((0, {}))

            except requests.exceptions.RequestException as e:
                self.messages['debug'].appendleft(str(e))
                self.messages['debug'].appendleft(' Connection to gate ' + url + ' failed')
                queue.put((0, {}))

    def get_data(self):
        if self.use_proxy == 'yes':
            self.messages['debug'].appendleft(' Pinging proxy... ')
            ping_name = ['ping', '-w 2', '-c 2', '-W 2', self.proxy]
            ping_ip = ['ping', '-w 2', '-c 2', '-W 2', self.ip]
            res1, err1 = Popen(ping_name, stdout=PIPE, stderr=PIPE).communicate()
            res2, err2 = Popen(ping_ip, stdout=PIPE, stderr=PIPE).communicate()

            if err1 and not err2:
                self.messages['debug'][0] += '[failed]'
                self.messages['debug'].extendleft([" Warning: Cannot resolve proxy's hostname. Use last known IP"])
                self.proxy = self.ip
            elif err1 and err2:
                self.messages['debug'][0] += '[failed]'
                self.messages['debug'].appendleft('  Ping proxy got error: ' + err1)
                self.messages['debug'].appendleft('  Check your proxy setting')
            elif not err1 and '100% packet loss' in res1:
                self.messages['debug'][0] += '[dead]'
                self.messages['debug'].appendleft(' Warning: Proxy not response to ping')
                self.messages['debug'].appendleft(" Either proxy's security does not allow it to response to "
                                                  "ping packet or proxy itself is dead")
            else:
                self.messages['debug'][0] += '[alive]'
                self.ip = socket.gethostbyname(self.proxy)

            proxies = {
                'http': 'http://' + self.proxy + ':' + self.port,
                'https': 'http://' + self.proxy + ':' + self.port,
            }

        else:
            proxies = {}

        my_queue = Queue()
        my_thread = []
        for url in mirrors[0:self.get_limit]:
            t = Thread(target=self.get_csv, args=(url, my_queue, proxies))
            t.start()
            my_thread.append(t)

        for t in my_thread: t.join()

        success = 0
        self.vpndict.clear()
        for res in [my_queue.get() for r in xrange(self.get_limit)]:
            success += res[0]
            self.vpndict.update(res[1])

        if not success:
            self.messages['debug'].appendleft(' Failed to get VPN servers data\n '
                                              'Check your network setting and proxy')
        else:
            self.messages['debug'].appendleft(' Fetching servers completed %s' % success)

    def refresh_data(self, resort_only=''):
        if not resort_only:
            # fetch data from vpngate.net
            self.get_data()

        if self.filters['country'] != 'all':
            name = self.filters['country']
            self.vpndict = dict([vpn for vpn in self.vpndict.items()
                                 if re.search(r'\b%s\b' % name, vpn[1].country_long.lower() + ' '
                                              + vpn[1].country_short.lower())])
        if self.filters['port'] != 'all':
            port = self.filters['port']
            self.vpndict = dict([vpn for vpn in self.vpndict.items() if vpn[1].port in port])

        if self.sort_by == 'speed':
            sort = sorted(self.vpndict.keys(), key=lambda x: self.vpndict[x].speed, reverse=True)
        elif self.sort_by == 'ping':
            sort = sorted(self.vpndict.keys(), key=lambda x: self.vpndict[x].ping)
        elif self.sort_by == 'score':
            sort = sorted(self.vpndict.keys(), key=lambda x: self.vpndict[x].score, reverse=True)
        elif self.sort_by == 'up time':
            sort = sorted(self.vpndict.keys(), key=lambda x: int(self.vpndict[x].uptime))
        else:
            print '\nValueError: sort_by must be in "speed|ping|score|up time" but got "%s" instead.' % self.sort_by
            print 'Change your setting by "$ ./vpnproxy config"\n'
            sys.exit()

        self.sorted[:] = sort

    def dns_manager(self, action='backup'):
        dns_orig = '/etc/resolv.conf.bak'

        if not os.path.exists(dns_orig):
            backup = ['-aL', '/etc/resolv.conf', '/etc/resolv.conf.bak']
            call(['cp'] + backup)

        if action == "change" and self.dns_fix == 'yes':
            DNS = self.dns.replace(' ', '').split(',')

            with open('/etc/resolv.conf', 'w+') as resolv:
                for dns in DNS:
                    resolv.write('nameserver ' + dns + '\n')

        elif action == "restore":
            self.messages['status'][1] = 'Restore dns'
            reverseDNS = ['-a', '/etc/resolv.conf.bak', '/etc/resolv.conf']
            call(['cp'] + reverseDNS)

    @staticmethod
    def vpn_output(out, queue):
        for line in iter(out.readline, b''):
            queue.put(line)
        out.close()

    def vpn_connect(self, chosen):
        """
        Disconnect the current connection and spawn a new one
        """
        if self.connect_status:
            self.vpn_cleanup()

        server = self.vpndict[self.sorted[chosen]]
        self.vpn_server = server
        self.messages['country'] += [server.country_long.strip('of') + '  ' + server.ip]
        self.connected_servers.append(server.ip)
        vpn_file = server.write_file(self.use_proxy, self.proxy, self.port)
        vpn_file.close()

        ovpn = vpn_file.name
        command = ['openvpn', '--config', ovpn]
        p = Popen(command, stdout=PIPE, stderr=PIPE, bufsize=1, close_fds=ON_POSIX)
        q = Queue()
        t = Thread(target=self.vpn_output, args=(p.stdout, q))
        t.daemon = True
        t.start()

        self.vpn_process = p
        self.vpn_queue = q

    def vpn_cleanup(self):
        p, q = self.vpn_process, self.vpn_queue
        if p.poll() is None:
            p.send_signal(signal.SIGINT)
            p.wait()
        self.connect_status = False
        self.dns_manager('restore')

        # make sure openvpn did close its device
        tuntap = Popen(['ifconfig', '-s'], stdout=PIPE).communicate()[0]
        devices = re.findall('tun\d+', tuntap)
        for dev in devices:
            call(('ip link delete '+dev).split())

    def kill_other(self):
        """
        Kill all openvpn processes no matter they are controlled by
        this program or not. Use when connection gets trouble
        """
        command = ['sudo', 'pkill', 'openvpn']
        call(command)
        self.messages['status'].appendleft(['All openvpn processes are terminated'])
        self.dns_manager('restore')

    def vpn_checker(self):
        """ Check VPN season
            If vpn tunnel break or fail to create, terminate vpn season
            So openvpn not keep sending requests to proxy server and
             save you from being blocked.
        """
        p, q = self.vpn_process, self.vpn_queue

        if self.kill and self.connect_status:
            self.kill = False
            self.vpn_cleanup()
            self.messages['status'] += ['VPN tunnel is terminated', '']
            self.messages['country'] += [' ', ' ']

        try:
            line = q.get_nowait()
        except Empty:
            return
        else:
            self.messages['debug'].appendleft(line.strip()[11:])
            if 'Initialization Sequence Completed' in line:
                self.dropped_time = 0
                self.dns_manager('change')
                self.messages['status'] += ['VPN tunnel established successfully', 'Ctrl+C to quit VPN']
                self.connect_status = True
            elif self.connect_status and 'Restart pause, ' in line and self.dropped_time <= self.max_retry:
                self.dropped_time += 1
                self.messages['status'][1] = 'Vpn has restarted %s time(s)' % self.dropped_time
            elif 'Restart pause, ' in line or 'Cannot resolve' in line or 'Connection timed out' in line or 'SIGTERM' in line:
                self.dropped_time = 0
                self.messages['status'] += ['Vpn got error, terminated', ' ']
                self.vpn_cleanup()
            elif 'ERROR' in line and 'add command failed' not in line or 'Exiting due' in line:
                self.messages['status'] += ['Vpn got error, exited', ' ']
                self.vpn_cleanup()
            elif '--http-proxy MUST' in line:
                self.messages['status'] += ['Can\'t use udp with proxy!', ' ']

            elif p.poll() is None and not self.connect_status:
                if 0 < self.dropped_time <= self.max_retry:
                    self.messages['status'][0] = 'Connecting...'
                else:
                    self.messages['status'] += ['Connecting...', ' ']


class Display:
    def __init__(self, vpn_connection):
        """
        :type vpn_connection: Connection
        """
        self.ovpn = vpn_connection
        self.get_data = Thread(target=self.ovpn.refresh_data)
        self.get_data_status = 'finish'
        self.vpn_log = deque(maxlen=20)

        self.timer = 0
        self.cache_msg = None
        self.index = 0
        self.ser_no = 16
        self.data_ls = ['']
        self.debug = urwid.Text(u'')
        self.palette = [('command', 'dark green, bold', 'default'),
                        ('normal', 'default', 'default'),
                        ('focus', 'yellow', 'dark blue'),
                        ('failed', 'dark red', 'default'),
                        ('lost', 'dark red, bold', 'default'),
                        ('attention', 'default, bold', 'default'),
                        ('attention2', 'default, bold, blink', 'default'),
                        ('button', 'standout, bold', ''),
                        ('popbgs', 'white', 'dark blue')]

        signal.signal(signal.SIGINT, self.signal_handler)

        # Header
        self.sets = self.setting()  # Pile of MyColumn

        # Body
        self.Udata = []  # used by make_GUI and update_GUI, just for ease of access
        self.table = self.make_GUI()  # list of lines, urwid.columns

        self.input = urwid.Edit(('command', u"Vpn command: "), edit_text=u'')
        self.clear_input = False
        urwid.connect_signal(self.input, 'change', self.input_handler)

        self.pages = urwid.Text([('command', 'page: '), '1/0'], align='center')
        self.cmd_row = urwid.Columns([self.input, self.pages])

        self.pile = urwid.Pile([self.debug] + self.table + [self.cmd_row])

        # Footer
        self.state = self.status()

        # Frame (Header, Body, Footer)
        self.Piles = MyPile([self.sets, self.pile, self.state], focus_item=1)
        fill = urwid.Filler(self.Piles, 'top')
        self.loop = urwid.MainLoop(fill, self.palette, unhandled_input=self.input_handler,
                                   pop_ups=True, handle_mouse=False)
        self.loop.set_alarm_in(sec=0.1, callback=self.periodic_checker)

        # indicator
        self.q2indicator = Queue()
        self.qfindicator = Queue()

        self.infoserver = InfoServer(8088)
        self.indicator = Thread(target=self.infoserver.run, args=(self.q2indicator, self.qfindicator))
        self.indicator.daemon = True
        self.indicator.start()
        self.sent = False
        self.last_msg = ''

    def get_vpn_data(self):
        del self.data_ls[:]

        for key in self.ovpn.sorted:
            self.data_ls.append(str(self.ovpn.vpndict[key]))
        self.update_GUI()

    def periodic_checker(self, loop, user_data=None):
        # check if user want to kill vpn
        if self.ovpn.vpn_process:
            self.ovpn.vpn_checker()

        # check if user want to fetch new vpn server list
        if 'call' in self.get_data_status and not self.get_data.isAlive():
            self.get_vpn_data()  # clear the template of server list
            self.get_data = Thread(target=self.ovpn.refresh_data, kwargs={'resort_only':self.get_data_status[4:]})
            self.get_data.daemon = True
            self.get_data.start()
            self.get_data_status = 'wait'
        elif self.get_data_status == 'wait' and not self.get_data.isAlive():
            self.get_vpn_data()
            self.get_data_status = 'finish'

        if self.clear_input:
            self.input.set_edit_text(self.clear_input[1])
            self.clear_input = False

        if self.ovpn.connect_status != self.sent:
            self.sent = self.ovpn.connect_status
            self.communicator((self.sent, ''))

        if self.cache_msg != self.ovpn.messages:
            self.status(self.ovpn.messages)
            self.cache_msg = deepcopy(self.ovpn.messages)
            loop.set_alarm_in(sec=0.1, callback=self.periodic_checker)
        else:
            loop.set_alarm_in(sec=0.5, callback=self.periodic_checker)

    def signal_handler(self, signum, frame):
        self.ovpn.kill = True
        self.printf("Ctrl C is pressed. Press again or 'q' to quit program")
        if not self.ovpn.connect_status:
            raise urwid.ExitMainLoop()

    def input_handler(self, Edit, key_ls=None):
        # handle for self.input (Edit) on the fly
        if key_ls:
            if 'q' in key_ls or 'Q' in key_ls:
                self.exit(self.loop)
            if 'No such server!' == key_ls[:-1] or 'Invalid command!' == key_ls[:-1] or 'refresh' == key_ls[:-1]:
                self.clear_input = True, key_ls[-1]

        # handle for non alphabet key press
        elif isinstance(Edit, str):
            key = Edit
            if 'up' in key:
                self.index -= self.ser_no
                if self.index < 0 and len(self.data_ls) > self.ser_no:
                    self.index = len(self.data_ls) - len(self.data_ls) % self.ser_no
                elif self.index < 0:
                    self.index = 0
                self.update_GUI()
            elif 'down' in key:
                self.index += self.ser_no
                if self.index > len(self.data_ls):
                    self.index = 0
                self.update_GUI()
            elif key == 'esc':
                self.input.set_edit_text('')
            elif key == 'enter':
                self.printf('')
                text = self.input.get_edit_text().lower()
                if 'invalid' in text:
                    self.input.set_edit_text('')

                elif text.isdigit():
                    chosen = int(text)
                    if chosen < len(self.data_ls):
                        self.index = (chosen // self.ser_no) * self.ser_no
                        self.ovpn.vpn_connect(chosen)
                        self.input.set_edit_text('')
                        self.update_GUI()
                    else:
                        self.input.set_edit_text('No such server!')
                        self.input.set_edit_pos(len(self.input.get_edit_text()))

                elif text in ['r', 'refresh']:
                    if screen.get_data_status == 'finish':
                        screen.get_data_status = 'call'
                        self.input.set_edit_text('')
                    else: self.input.set_edit_text('Invalid: please wait for last refresh to be finished')
                elif 'restore' in text:
                    self.ovpn.dns_manager('restore')
                    self.input.set_edit_text('')
                elif 'kill' in text:
                    self.ovpn.kill_other()
                    self.input.set_edit_text('')
                elif 'log' in text[:3]:
                    yn = self.ovpn.verbose
                    if 'on' in text[3:6]:
                        if yn == 'no': self.setting('f10')
                    elif 'off' in text[3:6]:
                        if yn == 'yes': self.setting('f10')
                    else:
                        self.ovpn.messages['debug'].appendleft(
                            ' Logging is currently ' + ('on' if yn == 'yes' else 'off'))
                        self.status(self.ovpn.messages)
                    self.input.set_edit_text('')

                else:
                    self.input.set_edit_text('Invalid command!')
                    self.input.set_edit_pos(len(self.input.get_edit_text()))

            elif key == 'ctrl f5':
                if screen.get_data_status == 'finish':
                    screen.get_data_status = 'call'
                    self.input.set_edit_text('')
                else: self.input.set_edit_text('Invalid: please wait for last refresh to be finished')
            elif key == 'ctrl r':
                self.ovpn.dns_manager('restore')
                self.input.set_edit_text('')
            elif key == 'ctrl k':
                self.ovpn.kill_other()
            elif len(key) > 1 and 'f' == key[0]:
                self.setting(key)
            else:
                pass

    @staticmethod
    def on_exit_clicked(button):
        raise urwid.ExitMainLoop()

    def printf(self, txt):
        self.debug.set_text(str(txt))

    def make_GUI(self):
        labels = ['Index', 'Country', 'Ping', 'Speed', 'Up time', 'Log Policy', 'Score', 'protocol', 'Portal']
        spaces = [5, 8, 6, 9, 10, 11, 9, 9, 9]

        txt_labels = []
        for i, txt in enumerate(labels):
            tex = urwid.Text(txt, align='center')
            txt_labels.append(('fixed', spaces[i], tex))
        Ulabel = urwid.Columns(txt_labels)

        Udata = []  # temporary, different from self.Udata
        for i in range(self.ser_no):
            self.Udata.append(deepcopy(Ulabel))
            Udata.append(urwid.Padding(urwid.AttrMap(self.Udata[i], 'normal'), width=90))

        Ulabel = urwid.AttrMap(Ulabel, 'command')

        return [Ulabel] + Udata

    def update_GUI(self):
        data_list = self.data_ls

        # Page number
        total = str(len(data_list) // self.ser_no + 1)
        page_no = str(self.index / self.ser_no + 1)
        while int(page_no) > int(total):
            self.index -= self.ser_no
            page_no = str(self.index / self.ser_no + 1)
        self.pages.set_text([('command', u'\u2191\u2193 page: '), page_no + '/' + total])

        # data for that page
        tmp_ls = data_list[self.index:self.index + self.ser_no]
        if len(tmp_ls) < self.ser_no:
            tmp_ls += [''] * (self.ser_no - len(tmp_ls))

        for i, line in enumerate(tmp_ls):
            ser_info = line.split() if line.split() else [''] * 8
            if len(ser_info) == 9:
                ser_info[3] += ' ' + ser_info.pop(4)
            tmp_index = str(self.index + i) if ser_info[0] else ''

            self.Udata[i].contents[0][0].set_text(tmp_index)
            for j, txt in enumerate(ser_info):
                self.Udata[i].contents[j + 1][0].set_text(txt)

            # colorize connected item
            self.table[i + 1].original_widget.set_attr_map({None: None})
            if tmp_index and self.ovpn.connected_servers:
                vpn_name = self.ovpn.sorted[int(tmp_index)]
                ip = self.ovpn.vpndict[vpn_name].ip
                if ip == self.ovpn.connected_servers[-1]:
                    self.table[i + 1].original_widget.set_attr_map({None: 'focus'})
                elif ip in self.ovpn.connected_servers:
                    self.table[i + 1].original_widget.set_attr_map({None: 'failed'})

    def setting(self, key=None):
        use_proxy, proxy, port, ip = self.ovpn.cfg.proxy.values()
        sort_by = self.ovpn.cfg.sort['key']
        s_country, s_port = self.ovpn.cfg.filter.values()
        dns_fix, dns = self.ovpn.cfg.dns.values()

        config_data = [use_proxy, dns_fix, s_country[0:4]+' '+s_port, sort_by]
        labels = ['Proxy: ', 'DNS fix: ', 'Filter: ', 'Sort by: ']
        buttons = ['F2', 'F3', 'F4', 'F5']
        popup = [PopUpProxy, PopUpDNS, PopUpCountry, PopUpSortBy]
        param = [(use_proxy, proxy, port), (dns_fix, dns), (s_country, s_port), sort_by]
        pop_size = [(0, 1, 39, 6), (0, 1, 35, 5), (0, 1, 35, 7), (7, 1, 12, 6)]

        if not key:
            txt_labels = []
            for i, txt in enumerate(labels):
                tex = MyText([('button', buttons[i]), ('attention', txt), config_data[i]])
                thing_with_popup = AddPopUp(tex, popup[i], value=param[i], trigger=buttons[i].lower(), size=pop_size[i])
                urwid.connect_signal(thing_with_popup, 'done', lambda button, k: self.setting(k))
                txt_labels.append(thing_with_popup)
            row1 = MyColumn(txt_labels[0:4])

            return row1

        else:
            self.Piles.focus_position = 1
            index = int(key[1:]) - 2

            if key == 'f2':
                yn = config_data[index] = self.sets.contents[index][0].result[0]
                proxy, port = self.sets.contents[index][0].result[1:]
                proxy_ = {'use_proxy': yn, 'address': proxy, 'port': port, 'ip': ip}
                self.ovpn.rewrite('proxy', **proxy_)

                tex = [('button', buttons[index]), ('attention', labels[index]), config_data[index]]
                self.sets[index].set_text(tex)

            elif key == 'f3':
                yn = config_data[index] = self.sets.contents[index][0].result[0]
                dns = self.sets.contents[index][0].result[1]

                dns_ = {'fix_dns': yn, 'dns': dns}
                self.ovpn.rewrite('DNS_leak', **dns_)

                tex = [('button', buttons[index]), ('attention', labels[index]), config_data[index]]
                self.sets[index].set_text(tex)

            elif key == 'f4':
                self.ovpn.filters['country'] = config_data[index] = self.sets.contents[index][0].result[0]
                self.ovpn.filters['port'] = self.sets.contents[index][0].result[1]
                s_c_p = self.ovpn.filters['country'][0:4] + ' ' + self.ovpn.filters['port'][0:4]
                self.ovpn.reload()
                self.ovpn.cfg.write()

                tex = [('button', buttons[index]), ('attention', labels[index]), s_c_p]
                if s_c_p.count('all') < 2:
                    self.ovpn.get_limit = 3
                else:
                    self.ovpn.get_limit = 1
                self.sets[index].set_text(tex)
                self.input.set_edit_text('refresh')
                self.input.set_edit_pos(len('refresh'))

            elif key == 'f5':
                sort_by = config_data[index] = self.sets.contents[index][0].result
                self.ovpn.rewrite('sort', key=sort_by)

                tex = [('button', buttons[index]), ('attention', labels[index]), config_data[index]]
                self.sets[index].set_text(tex)
                self.get_data_status = 'callresort'
                self.input.set_edit_text('refresh')
                self.input.set_edit_pos(len('refresh'))

            elif key == 'f10':
                yn = self.ovpn.verbose
                verbose = 'no' if yn == 'yes' else 'yes'
                self.ovpn.rewrite('openvpn', verbose=verbose)

                self.ovpn.messages['debug'].appendleft(time.asctime() +
                                                       ': Logging is turned ' + ('off' if yn == 'yes' else 'on'))
                self.status(self.ovpn.messages)

            elif key == 'f7':
                pass

            self.ovpn.cfg.write()

    def status(self, msg=None):
        self.logger(msg)
        if msg:
            ind = 0
            for mtype in list(msg):
                for m in msg[mtype]:
                    if 'successfully' in m or 'dns' in m or 'complete' in m:
                        self.state[ind].set_text(('attention', m))
                    elif 'got error' in m:
                        self.state[ind].set_text(('lost', m))
                    elif 'Connecting' in m:
                        self.state[ind].set_text(('attention2', m))
                    else:
                        self.state[ind].set_text(('normal', m))

                    ind += 1
            return

        message = [urwid.Text(u' ', align='center') for i in range(3)]
        debug_mes = [urwid.Text(u' ') for i in range(20)]
        return urwid.Pile(message + debug_mes)

    def communicator(self, (msg, ovpn)):
        if msg:
            msgs = 'successfully;'+repr(self.ovpn.vpn_server)
            self.q2indicator.put(msgs)
        else:
            self.q2indicator.put('terminate')

    def logger(self, msg):
        if self.ovpn.verbose == 'no':
            return

        logpath = self.ovpn.config_file[:-10] + 'vpn.log'
        if msg is None:
            if os.path.exists(logpath):
                call(['cp', '-f', logpath, logpath+'.old'])
            with open(logpath, 'w+') as log:
                log.writelines(['-' * 40 + '\n', time.asctime() + ': Vpngate with proxy is started\n'])

        else:
            with open(logpath, 'a+') as log:
                if msg['debug'] != self.vpn_log and ' Pinging proxy... ' not in msg['debug']:
                    ind = 0
                    m = msg['debug'][ind]
                    if self.vpn_log:
                        while m != self.vpn_log[0]:
                            ind += 1
                            m = msg['debug'][ind]
                        while ind > 0:
                            ind -= 1
                            m = msg['debug'][ind]
                            self.vpn_log.appendleft(m)
                            log.write(m + '\n')
                    else:
                        for m in list(msg['debug'])[::-1]:
                            self.vpn_log.appendleft(m)
                            log.write(m + '\n')

    def run(self):
        self.loop.run()

    def exit(self, loop, data=None):
        loop.set_alarm_in(sec=0.5, callback=self.exit)
        if not self.ovpn.vpn_process or self.ovpn.vpn_process.poll() is not None:
            raise urwid.ExitMainLoop()
        else:
            self.ovpn.kill = True

# ------------------------- Main  -----------------------------------
vpn_connect = Connection()  # initiate network parameter

# ------------------- check_dependencies: ---------------------------
required = {'openvpn': 0, 'python-pip': 0, 'requests': 0, 'urwid': 0}
for module in ['pip', 'requests', 'urwid']:
    try:
        __import__(module, globals(), locals(), [], -1)
    except ImportError:
        if 'pip' in module:
            module = 'python-' + module
        required[module] = 1

if not os.path.exists('/usr/sbin/openvpn'):
    required['openvpn'] = 1

need = sorted([p for p in required if required[p]])
if need:
    print ctext('\n**Lack of dependencies**\n', 'rB')
    env = dict(os.environ)
    if vpn_connect.use_proxy == 'yes':
        env['http_proxy'] = 'http://' + vpn_connect.proxy + ':' + vpn_connect.port
        env['https_proxy'] = 'http://' + vpn_connect.proxy + ':' + vpn_connect.port

    update_now = 'yes' if 'n' in raw_input(
        ctext("Have you 'sudo apt-get update' recently?", 'B') + "[ yes(default) | no]: ") else 'no'

    if update_now == 'yes':
        call(['apt-get', 'update'], env=env)

    for package in need:
        print '\n___Now installing', ctext(package, 'gB')
        print
        if package in ['openvpn', 'python-pip']:
            call(['apt-get', 'install', package], env=env)
        else:
            call(['pip', 'install', package], env=env)
            globals()[package] = __import__(package)
    raw_input(ctext('  Done!\n  Press Enter to continue', 'g'))

import requests
from ui_elements import *

# -------- all dependencies should be available after this line --------
# raw_input('haha')
screen = Display(vpn_connect)
screen.get_data_status = 'call'
screen.run()
