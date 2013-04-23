import time
from psutil import cpu_percent, virtual_memory, disk_usage
from flask import flash, session
import subprocess
import re

class Settings(object):
    """ Settings class"""
    def __init__(self, data):
        self.updatetime = data # Update frequency of cpu/ram/disk
        self.password = "azerty" # Password

class Usedip(object):
    """ Tables with IPs """
    def __init__(self):
        self.includedip = [] 
        self.excludedip = []

class Sysinfo(object):
    """ System informations for index """
    def __init__(self):
        self.uname = subprocess.check_output(['uname','-a']) # Not necessary to reload
        self.update()

    def update(self):
        self.network = subprocess.check_output(['ifconfig', '-a']).replace("\n","<br />")
        self.uptime = subprocess.check_output(['uptime'])

class ScenarioObject(object):
    """ An item to add in the Scenario list """

    def __init__(self):
        self.target = None
        self.command = None


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

def checkIpString(ip):
    """ Validates if this is an IP Adress with a mask or not """
    slashes = len(re.findall("/",ip))
    if slashes > 1:
        flash("Too many slashes")
        return False
        
    if slashes == 1:
        temp = ip.split("/")
        ip = temp[0]
        mask = temp[1]
        if re.search("^[1-32]", mask):
            return True
        else:
            flash("Invalid Mask")
            return False

    if re.search("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",ip):
        return True
    else:
        flash("Invalid IP")
        return False