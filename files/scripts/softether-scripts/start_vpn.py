#!/usr/bin/python2.7
import subprocess
import time
import get_ip
import get_location
import datetime
import os.path
from MyVPN import MyVPN
from configs import connected_server, server_history

subprocess.call(['vpnclient', 'start'])


# user input for operation
op_flag = raw_input('You have some choices:\n\t1. Start SoftEther vpn connection     \
\n\t2. Stop SoftEther vpn connection (Recycle NetworkManager)\n\t3. exit\nPlease select:')


# defaut ip and port
ip = '124.56.10.199'
port = '995'


# "1" means user want to connect a vpn server
if op_flag == '1':
    print 'Retrieving best server for you, please wait ...'

    # get a list containing such servers that has a low ping to our local PC
    serv = get_ip.VgServer('vpngate')
    best_server = serv.get_result()

    # count the list items, it should exactly be 10, if not, 
    # there must be something wrong with the function
    server_count = len(best_server)
    if server_count < 10:
        print '\nno suitable server found, please retry!'
        exit(0)
    
    # show user the server list
    print 'Here are the best %s servers for you:'%server_count
    print '\n\tNo.\tping\tIP\t\tPort\tLineSpeed\tRegion'
    for i in range(len(best_server)):
        region = get_location.get_region(best_server[i][1])
        print '\t%s.'%(i+1),
        print '\t%s\t%s\t%s\t%s\t\t%s'%(best_server[i][0], best_server[i][1], 
                best_server[i][2],best_server[i][3], region)
    
    
    choice_flag = -1
    
    # exactly 10 servers for choosing, if input not in this range, 
    # prompt to retry
    while choice_flag not in range(1, server_count+1):
    
        # selection input must be a number
        try:
            choice_flag = int(raw_input('Please select a VPN server:'))
        except:
            print '\nPlease check your input!'
    
    ip = best_server[choice_flag-1][1]
    port = best_server[choice_flag-1][2]


    # save selected server info into a file, if we want to disconnect we will  
    # read from it
    with open(connected_server, 'wb') as fw:
        fw.write('%s:%s'%(ip, port))
    # save to log file
    current_time = datetime.datetime.now()
    if os.path.isfile(server_history) ==  False:
        with open(server_history, 'wb') as fa:
            fa.write('%s\t%30s\n'%('time', 'server'))
    with open(server_history, 'ab') as fa:
        fa.write('%s\t%s:%s\n'%(current_time, ip, port))
    print '\nBegin VPN configuration, please wait ...'
    print '\ncreating vpn instance ...'
    a = MyVPN(ip, port, 1)
    a.vg_switch()
        
        
# restore ip route setting to default
elif op_flag == '2':
    with open(connected_server, 'rb') as fr:
        recent_server = fr.readline().split(':')
        ip, port = recent_server
    a = MyVPN(ip, port, 0)
    a.vg_switch()

elif op_flag == '3':
    exit(0)
else:
    print '\nInvalid input, please check!'
    exit(0)
