#!/usr/bin/python2.7
import csv
import sys
import re
import threading
import urllib2
import PingIt
from configs import proxy_url, mirrorfile



# lock ip list for appending
mlock = threading.RLock()

# read mirror list
f = open(mirrorfile, "r")

# object contains server information
class VgServer():
    def __init__(self, csv_or_html):
        self.threads = []
        self.allList = []
        self.pu = proxy_url
        self.csv_or_html = csv_or_html
        # progress count
        self.P_COUNT = 1
        self.P_STEP = 0
        
    
    def get_html_response(self, mirrorfile):
        print('\n')
        mirrorcount = 0
        for url in f:
            print(url)
            try:
                response = urllib2.urlopen(url,timeout=10)
            except Exception as err:
                print(('**Failed to access the mirror: ', err.reason))
                html = 'No data.'
                mirrorcount += 1
                if mirrorcount == 4:
                    print('No more mirrors to use.  Try again later.')
                    exit(0)
            else:
                html = response.read()
                print('Connected to mirror!')
                return html

        f.close()


    def get_csv_response(self, mirrorfile):
        print('\n')
        mirrorcount = 0
        for url in f:
            print(url)
            try:
                response = urllib2.urlopen(url,timeout=10)
            except Exception as err:
                print(('**Failed to access the mirror: ', err.reason))
                newcsv = 'No data.'
                mirrorcount += 1
                if mirrorcount == 4:
                    print('No more mirrors to use.  Try again later.')
                    exit(0)
            else:
		url2 = url + '/api/iphone/'
                newcsv = response.read()
                print('Connected to mirror!')
                return newcsv

        f.close()


    def get_ip_from_csv(self):
        try:
            csv_data = open('tmp_csv.csv', 'rb').read()
        except Exception as err:
            print 'tmp_csv.csv not found! trying get it from vpngate.net ..'
            if 'DOCTYPE html' in csv_data:
                print 'Got error data, trying to get fresh data!'
		freshdata = self.get_csv_response(mirrorfile)
		freshdata.write(csv_data)
		print 'Please start the script again.'
		exit(0)


            with open('tmp_csv.csv', 'wb') as fw:
                fw.write(csv_data)
        try:    
            tmp_csv_data = csv_data.split('\n')
        except Exception as err:
	    print 'fetch tmp_csv.csv file error, trying to get fresh data!!'
	    freshdata = self.get_csv_response(mirrorfile)
	    freshdata.write(csv_data)
	    print 'Please start the script again.'
	    exit(0)
        
        fieldnames = tmp_csv_data[1].split(',')
        tmp_csv_data = tmp_csv_data[2:]
        csv_reader = csv.DictReader(tmp_csv_data, 
                                    fieldnames=fieldnames,
                                    delimiter=',')
        
        ip_list = []
        count = 0
        for row in csv_reader:
            ip = row['IP']
            num_sessions = row['NumVpnSessions']
            lspeed = row['Speed']
            region = row['CountryLong']
            if lspeed is not None:
                lspeed = int(lspeed)/1024/1024
            pint_to_google = row['Ping']
            openvpn_data = row['OpenVPN_ConfigData_Base64\r']
            ip_list.append([ip, num_sessions, str(lspeed)+"Mbps", 
                            pint_to_google, openvpn_data, region])
        
        print 'get openvpn server list succeed, totally %s servers'%len(ip_list)
        # remove the last None item
        ip_list = ip_list[:-1]
        return ip_list
        
    
    # get the origin server list
    def get_ip_from_html(self):
        html = self.get_html_response(mirrorfile)
        # match strings like "ip=192.168.0.1&tcp=443"
        p_ip_tcp = re.compile('ip=\d+\.\d+\.\d+\.\d+&tcp=\d+')
        # match strings like "99 Mbps"
        p_linespeed = re.compile('\d+ Mbps')
        ip_tcp = p_ip_tcp.findall(html)
        linespeed = p_linespeed.findall(html)
        
        # match ip, though this may match strings like "111111111.111.11111.1":)
        p_ip = re.compile('\d+\.\d+\.\d+\.\d+')
        # match port
        p_port = re.compile('(?<=tcp\=)\d+')
        
        ip_list = []
        count = 0
        
        for i in ip_tcp:
            ip = p_ip.findall(i)[0]
            port = p_port.findall(i)[0]
            lspeed = linespeed[count]
            ip_list.append([ip, port, lspeed])
            count += 1

        print 'get [ip, port] list succeed, totally %s servers'%len(ip_list)
        return ip_list


    # get ping value
    def GetLegacy(self, ip_port):
        if self.csv_or_html == 'openvpn':
            ip = ip_port[0]
            ping = ip_port[1]
            lspeed = ip_port[2]
            ping_google = ip_port[3]
            openvpn_data = ip_port[4]
            region = ip_port[5]
        elif self.csv_or_html == 'vpngate':
            ip = ip_port[0]
            port = ip_port[1]
            lspeed = ip_port[2]
        else:
            print 'VPN program type error!'
            exit(0)
        
        p = PingIt.PingIt(ip)
        p.start()
        pingValue = p.getLegacy()
        
        if pingValue != -1:
            mlock.acquire()
            if self.csv_or_html == 'openvpn':
                self.allList.append([pingValue, ip, ping_google, lspeed, 
                                     openvpn_data, region])
            elif self.csv_or_html == 'vpngate':
                self.allList.append([pingValue, ip, port, lspeed])
            mlock.release()
            # update the progress status
            self.P_COUNT += self.P_STEP
            if self.P_COUNT > 100:
                self.P_COUNT = 100
            sys.stdout.write(('\b'*4+'%3d'%self.P_COUNT+'%'))
            sys.stdout.flush()
        else:
            # update the progress status
            self.P_COUNT += self.P_STEP
            if self.P_COUNT > 100:
                self.P_COUNT = 100
            sys.stdout.write(('\b'*4+'%3d'%self.P_COUNT+'%'))
            sys.stdout.flush()


    # get all ping result into a list
    def GetAll(self):
        if self.csv_or_html == 'openvpn':
            ip_list = self.get_ip_from_csv()
        elif self.csv_or_html == 'vpngate':
            ip_list = self.get_ip_from_html()
        else:
            print 'VPN program type error!'
            exit(0)
        
        self.P_STEP = 100.0 / len(ip_list) 
            
        for ip_port in ip_list:
            t = threading.Thread(target=self.GetLegacy, args=(ip_port, ), 
                                 name='thread-'+ip_port[0])
            t.start()
            self.threads.append(t)


    # return ip list sorted by ping value, 
    # like this: [[10, '61.153.236.234', '0', '00 Mbps'], [...], ...]
    def get_result(self):
        self.GetAll()
        # set toolbar
        #toolbar_width = 40
        #sys.stdout.write("[%s]" % (' ' * toolbar_width))
        #sys.stdout.flush()
        #sys.stdout.write("\b" * (toolbar_width+1)) 
        count = 1
        for t in self.threads:
            t.join() 
        
        print '\nsort list by ping value ... '
        self.allList = sorted(self.allList)
        
        # return best 10 in the list
        return self.allList[0:10]


if __name__ == "__main__":
    a = VgServer('openvpn')
    a.get_ip_from_csv()
    a.get_result()
