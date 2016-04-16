#!/usr/bin/python2.7
import urllib2
from configs import location_post_url


# get ip location
def get_region(ip):
    response = urllib2.urlopen(location_post_url%ip)
    
    if location_post_url == "http://opendata.baidu.com/api.php?query=%s&resource_id=6006&oe=utf-8":
        data = response.read()[1:-1].split('"')
        index = data.index('location') + 2
    else:
        print '\nPlease construct your own method to get ip location!'
        confirm_flag = int(raw_input('Press "1" to continue, "0" to exit:'))
        if confirm_flag == 0:
            exit(0)
        elif confirm_flag == 1:
            return '/'
        else:
            print '\nPlease check your input!'
            exit(0)
            
    return data[index]
    
