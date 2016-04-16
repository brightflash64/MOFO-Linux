# coding=utf-8
#!/usr/bin/python2.7
import subprocess
import time
from configs import tmp_cfg_file, account_name, virtual_adapter, \
        tmp_cfg_file_template, device_name, \
        account_name, max_connections

#Get the default networking interface name
my_adapter = subprocess.check_output(['ip neigh | cut -d " " -f 3'], shell=True)
print 'default interface '+my_adapter

#Get the default gateway interface IP
my_gateway = subprocess.check_output(['ip neigh | cut -d " " -f 1'], shell=True)
print 'default gateway '+my_gateway

#Get the gateway interface inet address
inetstring = 'ip addr list '+my_adapter+' |grep "inet " |cut -d " " -f6 | cut -d -f 1'
my_inet = subprocess.check_output([inetstring], shell=True)
print 'my inet addr '+my_inet