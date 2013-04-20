# -*- coding: utf-8 -*-

from flask import render_template, flash, redirect, session, abort, escape, url_for, jsonify, request
from werkzeug import secure_filename
from app import app
from forms import LoginForm, SettingForm, TermForm, IpForm
from functions import getCpuLoad, getVmem, getDisk, validateLogin, checkIpString
import subprocess

class Settings(object):
    """ Settings class"""
    def __init__(self, data):
        self.updatetime = data
        self.password = "azerty"

class Usedip(object):
    """ Tables with IPs """
    def __init__(self):
        self.includedip = []
        self.excludedip = []

class Sysinfo(object):
    """ System informations for index """
    def __init__(self):
        self.uname = subprocess.check_output(['uname','-a'])
        self.update()

    def update(self):
        self.network = subprocess.check_output(['ifconfig', '-a']).replace("\n","<br />")
        self.uptime = subprocess.check_output(['uptime'])

class Scenario(object):
    """ Scenario object used to manage the scenarios """
    #TODO: Fonction pour remplir l'objet avec un XML utilisateur 

# System informations
# TODO: Initialize settings with XML data
globalsettings = Settings(data="2000")
info = Sysinfo()
ips = Usedip()

# App routes and application

# Login page
# Associated with login.html
@app.route('/', methods = ['GET', 'POST'])
@app.route('/login', methods = ['GET', 'POST'])
def login():
    if validateLogin():
        flash("Already logged in")
        return redirect('/index')
    form = LoginForm()
    if form.validate_on_submit():
        if form.password.data == globalsettings.password:
            session['username'] = "admin"
            flash("You're now logged")
            return redirect("/index")
        return redirect("/")
    return render_template('login.html', title = 'Sign In', form = form)

# Index page
# Associated with index.html
@app.route('/index', methods = ['GET','POST'])
def index():
    if validateLogin():
        info.update() # Updates the info on the homepage (network and uptime)
        return render_template('index.html', title = 'IntrePid', settings = globalsettings, info = info, ips = ips)
    else:
        return redirect("/")

# Settings page
# Associated with settings.html and updates the setting class "globalsettings"
@app.route('/settings', methods = ['GET','POST'])
def settings():
    if validateLogin():
        form = SettingForm()
        if form.validate_on_submit():
            if form.updatetime.data and form.updatetime.data != globalsettings.updatetime:
                globalsettings.updatetime = form.updatetime.data
                flash("Changes saved")
        return render_template('settings.html', title = 'IntrePid', settings = globalsettings, form = form, ips = ips)
    else:
        return redirect('/')

# Updates page
# Associated to updates.html
@app.route('/updates', methods = ['GET','POST'])
def updates():
    if validateLogin():
        return render_template('updates.html', title = 'IntrePid', settings = globalsettings, ips = ips)
    else:
        return redirect('/')

# Scenarios page
# Associated with scenarios.html
# Methods associated below
@app.route('/scenarios', methods = ['GET','POST'])
def scenarios():
    if validateLogin():
        form = IpForm()
        if form.validate_on_submit():
            if form.ipincluded.data:
                if checkIpString(form.ipincluded.data):
                    if form.ipincluded.data in ips.excludedip:
                        flash("IP is in the exclusion list")
                    else:
                        if form.ipincluded.data in ips.includedip:
                            flash("IP already added")
                        else:
                            ips.includedip.append(form.ipincluded.data)
                            flash("Saved")
                else:
                    flash("Failed")
            if form.ipexcluded.data:
                if checkIpString(form.ipexcluded.data):
                    if form.ipexcluded.data in ips.includedip:
                        flash("IP is in the inclusion list")
                    else:
                        if form.ipexcluded.data in ips.excludedip:
                            flash("IP already added")
                        else:
                            ips.excludedip.append(form.ipexcluded.data)
                            flash("Saved")
                else:
                    flash("Failed")
            return render_template('scenarios.html', title = 'IntrePid', settings = globalsettings, form = form, ips = ips)
        return render_template('scenarios.html', title = 'IntrePid', settings = globalsettings, form = form, ips=ips)
    else:
        return redirect('/')

# Request to remove an included IP
@app.route('/scenarios/remove_include', methods = ['GET', 'POST'])
def remove_include():
    ips.includedip.pop(int(request.args.get('id')))
    flash("Removed")
    return redirect('/scenarios')

# Request to remove an Excluded IP
@app.route('/scenarios/remove_exclude', methods = ['GET', 'POST'])
def remove_exclude():
    ips.excludedip.pop(int(request.args.get('id')))
    flash("Removed")
    return redirect('/scenarios')

# Creating a custom scenario attributing scans to targets
@app.route('/scenarios/type', methods = ['GET', 'POST'])
def type():
    if ips.includedip:
        return render_template('type.html',title = 'IntrePId', settings = globalsettings, ips = ips)
    else:
        flash('No target specified')
        return redirect('/scenarios')

@app.route('/scenarios/manager', methods = ['GET', 'POST'])
def manager():
    if ips.includedip:
        return render_template('manager.html', title = 'IntrePId', settings = globalsettings, ips = ips)
    else:
        flash('No target specified')
        return redirect('/scenarios')



# Terminal page
# Associated to terminal.html
@app.route('/term', methods = ['GET', 'POST'])
def term():
    if validateLogin():
        form = TermForm()
        if form.validate_on_submit():
            if form.command.data:
                string = form.command.data.encode('utf-8').split()
                output = subprocess.check_output(string)
                output = output.replace("\n","<br />")
                flash("Command sent")
                return render_template('terminal.html', title = 'IntrePid', settings = globalsettings, form = form, res=output, ips = ips)
        return render_template('terminal.html', title = 'IntrePid', settings = globalsettings, form = form, ips = ips)
    else:
        return redirect('/')

# Logout routine
@app.route('/logout')
def logout():
    session.pop('username', None)
    return redirect('/')

# Ajax requests
# Updates CPU, RAM and Disk on request
@app.route('/_stuff', methods= ['GET'])
def stuff():
    cpu=round(getCpuLoad())
    ram=round(getVmem())
    disk=round(getDisk())
    return jsonify(cpu=cpu, ram=ram, disk=disk)

# Updates System Info (info = SysInfo()) on request
@app.route('/_sysinfo', methods= ['GET'])
def _sysinfo():
    info.update()
    return jsonify(uname = info.uname, uptime = info.uptime, net = info.network)