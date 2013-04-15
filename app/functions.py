import time
from psutil import cpu_percent, virtual_memory, disk_usage
from flask import flash, session

def getCpuLoad():
    """ Returns the CPU Load """
    load = cpu_percent(interval=1, percpu=False)
    return load

def getVmem():
    """ Returns the Ram percentage """
    mem = virtual_memory().percent
    return mem

def getDisk():
    """ Returns the Disk usage """
    disk = disk_usage('/').percent
    return disk

def validateLogin():
    """ Validates if logged in or not. True or False+Flash message """
    if 'username' in session:
        return True
    else:
        return False