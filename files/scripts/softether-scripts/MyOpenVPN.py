#import subprocess
import os
from configs import openvpn_config_file


class MyOpenVPN():
    def __init__(self):
        print 'Initializing openvpn connection ...'
        self.connect_openvpn()
    
    
    def connect_openvpn(self):
        os.system('openvpn %s'%openvpn_config_file)
        
        # create Popen instance
        #p = subprocess.Popen(['openvpn', openvpn_config_file], stdin=subprocess.PIPE, 
        #                    stdout=subprocess.PIPE)

        # run commands and exit
        #p.stdin.write('\n')
        #a = p.communicate()

        # display commands response
        #for i in a:
        #    print i
        
        # write openvpn logs
        #with open('openvpn.log', 'wb') as fw:
        #    fw.write(a)
