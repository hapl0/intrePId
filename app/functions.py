import time, psutil 

def getCpuLoad():
    """ Returns the CPU Load """
    load = psutil.cpu_percent(interval=1, percpu=False)
    return load

def getVmem():
    """ Returns the Ram percentage """
    mem = psutil.virtual_memory().percent
    return mem

def getDisk():
    """ Returns the Disk usage """
    disk = psutil.disk_usage('/').percent
    return disk
