''' 
     Ping ip, return legacy, for Ubuntu 12.04
'''

import subprocess
import re
import threading



# create thread class
class PingIt(threading.Thread):
    def __init__(self, ipAddr):
        self.ipAddr = ipAddr
        self.pingTime = 0
        self.done = False
        self.cond = threading.Condition()
        threading.Thread.__init__(self)
        
    def run(self):
        self.cond.acquire()
        cmd = ['ping', '-c', '2', self.ipAddr]
        try:
            result = subprocess.check_output(cmd)
        except Exception as err1:
            result = -1
        if result != -1:
            p = re.compile('= \d+.\d+')
            self.pingTime = p.findall(result)[-1:]
            p = re.compile('\d+')
            try:
                # get int ping value without 'ms' mark
                self.pingTime = int(p.findall(self.pingTime[0])[0])
            except Exception as pingTimeGetErr:
                print 'get pingTime error: {}'.format(pingTimeGetErr)
            #self.pingTime = self.pingTime[-1:]
        else:
            self.pingTime = result
        self.cond.notify()
        self.done = True
        self.cond.release()
    
    # return legacy value  
    def getLegacy(self):
        self.cond.acquire()
        while not self.done:
            self.cond.wait()
        self.cond.release()
        # return -1 or legacy value like [160ms]
        if type(self.pingTime) == list:
            try:
                return self.pingTime[0]
            except Exception as errRtn:
                print("error return self.pingTime[0]: {}".format(errRtn))
                print("ip: {}, pingTime: {}".format(self.ipAddr, self.pingTime))
                return self.pingTime
        return self.pingTime
        



if __name__ == "__main__":
	ipList = ['192.168.0.1', '192.168.0.1', '202.120.2.101', '211.84.64.168',
		'192.168.0.1', '192.168.0.1', '202.120.2.101', '211.84.64.168',
		'192.168.0.1', '192.168.0.1', '202.120.2.101', '211.84.64.168',
		'192.168.0.1', '192.168.0.1', '202.120.2.101', '211.84.64.168']

	def GetLegacy(ip):
		p = PingIt(ip)
		p.start()
		pingValue = p.getLegacy()
		print pingValue


	for ip in ipList:
		t = threading.Thread(target=GetLegacy, args=(ip,), name='thread-'+ip)
		t.start()

