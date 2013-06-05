# -*- coding: utf-8 -*-

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
        self.interface = "eth0"

class Usedip(object):
    """ Tables with IPs """
    def __init__(self):
        self.includedip = [] 
        self.excludedip = []

class Sysinfo(object):
    """ System informations for index """
    def __init__(self):
        self.network = None
        self.uptime = None
        self.uname = subprocess.check_output(['uname','-a']) # Not necessary to reload
        self.update("eth0")

    def update(self, interface):
        self.network = subprocess.check_output(['ip', 'a', 's', 'dev', interface]).replace("\n","<br />")
        self.uptime = subprocess.check_output(['uptime'])

class CustomModule(object):
    """ Custom Module Object """
    def __init__(self, name, description, path):
        self.name = name
        self.description = description
        self.path = path

class Module(object):
    """ Module Object """
    def __init__(self, name, preset, args):
        if preset:
            self.preset = preset
        if args:
            self.args = args
        self.name = name

class ScenarioObject(object):
    """ An item to add in the Scenario list """
    def __init__(self):
        self.target = None
        self.port = None
        self.module = None

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
            pass
        else:
            flash("Invalid Mask")
            return False

    if re.search("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",ip):
        return True
    else:
        flash("Invalid IP")
        return False
        
def extension_ok(nomfic):
    """ Renvoie True si le fichier possède une extension d'image valide. """
    return '.' in nomfic and nomfic.rsplit('.', 1)[1] in ('xml')
