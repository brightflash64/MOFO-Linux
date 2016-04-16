#!/usr/bin/python2.7
import base64
import subprocess
import time
import get_ip
import get_location
import datetime
import os.path
import re
from MyOpenVPN import MyOpenVPN
from configs import connected_server, server_history, openvpn_config_file



# user input for operation
op_flag = raw_input('You have some choices:\n\t1. open vpn connection     \
\n\t2. close vpn connection\n\t3. exit\nSo, which one do you like:')


# defaut ip and port
ip = '124.56.10.199'
port = '995'


# "1" means user want to connect a vpn server
if op_flag == '1':
    print 'Retrieving best server for you, please wait ...'

    # get a list containing such servers that has a low ping to our local PC
    serv = get_ip.VgServer('openvpn')
    best_server = serv.get_result()

    # count the list items, it should exactly be 10, if not, 
    # there must be something wrong with the function
    server_count = len(best_server)
    if server_count < 10:
        print '\nno suitable server found, please retry!'
        exit(0)
    
    # show user the server list
    print 'Here is the best %s servers for you:'%server_count
    print '\n%4s%6s%10s%20s%7s%18s%9s'%('No.', 'ping', 'IP', 
                                         'PingGoogle', 'Speed', 
                                         'Region', 'Type')
    p_proto_type = re.compile('\r\nproto\ udp\r\n')
    for i in range(len(best_server)):
        #region = get_location.get_region(best_server[i][1]).replace(' ', '')
        region = best_server[i][5].replace(' ', '')
        openvpn_data_base64 = best_server[i][4]
        openvpn_data = base64.decodestring(openvpn_data_base64)
        proto_type = 'udp'
        p_tmp = p_proto_type.findall(openvpn_data)
        if p_tmp == []:
            proto_type = 'tcp'
        print '%2s.%6s%19s%9s%11s%18s%8s'%(i+1, best_server[i][0], best_server[i][1], 
                best_server[i][2], best_server[i][3], region, proto_type)
    

    choice_flag = -1
    
    # exactly 10 servers for choosing, if input not in this range, 
    # prompt to retry
    while choice_flag not in range(1, server_count+1):
    
        # selection input must be a number
        try:
            choice_flag = int(raw_input('\nWhich one do you like to connect with:'))
        except:
            print '\nPlease check your input!'
            exit()
    
    ip = best_server[choice_flag-1][1]
    openvpn_data_base64 = best_server[choice_flag-1][4]
    openvpn_data = base64.decodestring(openvpn_data_base64)
    # write openvpn_data to a temp config file
    with open(openvpn_config_file, 'wb') as fw:
        fw.write(openvpn_data)
    


    # save selected server info into a file, if we want to disconnect we will  
    # read from it
    with open(connected_server, 'wb') as fw:
        fw.write('%s'%ip)
    # save to log file
    current_time = datetime.datetime.now()
    if os.path.isfile(server_history) ==  False:
        with open(server_history, 'wb') as fa:
            fa.write('%s\t%30s\n'%('time', 'server'))
    with open(server_history, 'ab') as fa:
        fa.write('%s\t%s\n'%(current_time, ip))

    # prompt user to confirm the choice
    confirm_flag = raw_input('You have choose:%s, continue to connect?       \
\n\t1. yes\n\t2. no\nPlease make your choice:'%ip)
        
    # confirmed or not
    if confirm_flag == '1':
        print '\nBegin VPN configuration, please wait ...'
        print '\ncreating vpn instance ...'
        a = MyOpenVPN()
        
    elif confirm_flag == '2':
        print '\nexiting ...'
        exit(0)
    else:
        print '\nInvalid input, please check!'
        exit(0)
        

elif op_flag == '2' or '3':
    exit(0)
else:
    print '\nInvalid input, please check!'
    exit(0)
