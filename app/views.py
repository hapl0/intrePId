# -*- coding: utf-8 -*-

from flask import render_template, flash, redirect, session, abort, escape, url_for, jsonify, request
from werkzeug import secure_filename
from app import app
from forms import LoginForm, SettingForm, TermForm, IpForm, LaunchSettings
from functions import getCpuLoad, getVmem, getDisk, validateLogin, checkIpString, Settings, Sysinfo, Usedip, ScenarioObject
import subprocess
import nmap


# System informations
# TODO: Initialize settings with XML data
globalsettings = Settings(data="2000")
info = Sysinfo()
ips = Usedip()
scenario = []

presets = {'Intense Scan':'nmap -T4 -A -v','Intense Scan plus UDP':'nmap -sS -sU -T4 -A -v'}

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
    # Validate login on each page so that a not logged in user can not access it
    if validateLogin():
        info.update(globalsettings.interface) # Updates the info on the homepage (network and uptime)
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
            if form.updatetime.data != globalsettings.updatetime:
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
            # Validating IP and multiple checks + error messages
            # Check for included IPs
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
            # Check for excluded IPs
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
        return render_template('scenarios.html', title = 'IntrePid', settings = globalsettings, form = form, ips=ips)
    else:
        return redirect('/')

# Request to remove an included IP
# Expects an argument ex : /scenarios/remove_include?id=...
@app.route('/scenarios/remove_include', methods = ['GET', 'POST'])
def remove_include():
    ips.includedip.pop(int(request.args.get('id')))
    flash("Removed")
    return redirect('/scenarios')

# Request to remove an Excluded IP
# Same as remove_include
@app.route('/scenarios/remove_exclude', methods = ['GET', 'POST'])
def remove_exclude():
    ips.excludedip.pop(int(request.args.get('id')))
    flash("Removed")
    return redirect('/scenarios')

# Creating a custom scenario attributing scans to targets
@app.route('/scenarios/type', methods = ['GET', 'POST'])
def type():
    if validateLogin():
        if ips.includedip:
            return render_template('type.html',title = 'IntrePId', settings = globalsettings, ips = ips)
        else:
            flash('No target specified')
            return redirect('/scenarios')
    else:
        return redirect('/')

@app.route('/scenarios/_addObject', methods = ['GET', 'POST'])
def addObject():
    newobject = ScenarioObject()
    newobject.target = ips.includedip[int(request.args.get('id'))]
    newobject.type = request.args.get('cmd')
    if request.args.get('cmd') in presets:
        newobject.command = presets[request.args.get('cmd')]
    scenario.append(newobject)
    flash("Saved in the manager")
    return redirect('/scenarios/type')


# Scenario Manager
@app.route('/scenarios/manager', methods = ['GET', 'POST'])
def manager():
    if validateLogin():
        if ips.includedip:
            form = LaunchSettings()
            return render_template('manager.html', title = 'IntrePId', settings = globalsettings, ips = ips, scenario = scenario, form = form)
        else:
            flash('No target specified')
            return redirect('/scenarios')
    else:
        return redirect('/')

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
    info.update(globalsettings.interface)
    return jsonify(uname = info.uname, uptime = info.uptime, net = info.network)