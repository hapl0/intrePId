# -*- coding: utf-8 -*-

from flask import render_template, flash, redirect, session, abort, escape, url_for, jsonify, request, send_from_directory
from werkzeug import secure_filename
from app import app
from forms import LoginForm, SettingForm, TermForm, IpForm, LaunchSettings
from functions import getCpuLoad, getVmem, getDisk, validateLogin, checkIpString, Settings, Sysinfo, Usedip, ScenarioObject, extension_ok
import subprocess
import nmap
import os
from xml.dom.minidom import parseString

# System informations
# TODO: Initialize settings with XML data
# TODO: Or Initialize settings with Shelve

# Cwd a supprimer en prod
cwd = os.getcwd()
DOSSIER_UPS = os.getcwd()+"/app/ups/"
globalsettings = Settings(data="2000")
info = Sysinfo()
ips = Usedip()
scenario = []

presets = {'Intense Scan':'nmap -T4 -A -v',
'Intense Scan plus UDP':'nmap -sS -sU -T4 -A -v',
'Intense Scan, all TCP Ports':'nmap -p 1-65535 -T4 -A -v',
'Intense Scan, no Ping':'nmap -T4 -A -v -Pn',
'Ping Scan':'nmap -sn',
'Quick Scan':'nmap -T4 -F',
'Quick Scan Plus':'nmap -sV -T4 -O -F --version-light',
'Quick Traceroute':'nmap -sn --traceroute'}

# App routes and application

# Login page
# Associated with login.html
@app.route('/', methods = ['GET', 'POST'])
@app.route('/login', methods = ['GET', 'POST'])
def login():
    if validateLogin():
        flash(u"Already logged in",'error')
        return redirect('/index')
    form = LoginForm()
    if form.validate_on_submit():
        if form.password.data == globalsettings.password:
            session['username'] = "admin"
            flash(u"You're now logged", 'info')
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
            if form.updatetime.data and form.updatetime.data != globalsettings.updatetime:
                globalsettings.updatetime = form.updatetime.data
                flash(u"Updatetime Changed", 'info')
            if form.interface.data and form.interface.data != globalsettings.interface:
                globalsettings.updatetime = form.interface.data
                flash(u"Interface Changed", 'info')
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
        xmlist = [xml for xml in os.listdir(DOSSIER_UPS) if extension_ok(xml)]
        form = IpForm()
        if form.validate_on_submit():
            # Validating IP and multiple checks + error messages
            # Check for included IPs
            if form.ipincluded.data:
                if checkIpString(form.ipincluded.data):
                    if form.ipincluded.data in ips.excludedip:
                        flash(u"IP is in the exclusion list", 'error')
                    else:
                        if form.ipincluded.data in ips.includedip:
                            flash(u"IP already added", 'error')
                        else:
                            ips.includedip.append(form.ipincluded.data)
                            flash(u"Saved",'info')
            # Check for excluded IPs
            if form.ipexcluded.data:
                if checkIpString(form.ipexcluded.data):
                    if form.ipexcluded.data in ips.includedip:
                        flash(u"IP is in the inclusion list", 'error')
                    else:
                        if form.ipexcluded.data in ips.excludedip:
                            flash(u"IP already added", 'error')
                        else:
                            ips.excludedip.append(form.ipexcluded.data)
                            flash(u"Saved", 'info')
        else:
            if request.method == 'POST':
                f = request.files['fic']
                if f:
                    if extension_ok(f.filename):
                        nom = secure_filename(f.filename)
                        f.save(DOSSIER_UPS+nom)
                        flash(u'File uploaded', 'info')
                        return redirect("/scenarios#select")
                    else:
                        flash(u'Wrong extension (only *.xml)', 'error')
                else:
                    flash(u'No file to upload', 'error')
        return render_template('scenarios.html', title = 'IntrePid', settings = globalsettings, form = form, ips=ips, xmlist=xmlist)
    else:
        return redirect('/')

# Request to remove an included IP
# Expects an argument ex : /scenarios/remove_include?id=...
@app.route('/scenarios/remove_include', methods = ['GET', 'POST'])
def remove_include():
    ips.includedip.pop(int(request.args.get('id')))
    flash(u"Removed", 'info')
    return redirect('/scenarios')

# Request to remove an Excluded IP
# Same as remove_include
@app.route('/scenarios/remove_exclude', methods = ['GET', 'POST'])
def remove_exclude():
    ips.excludedip.pop(int(request.args.get('id')))
    flash(u"Removed" 'info')
    return redirect('/scenarios')

# Creating a custom scenario attributing scans to targets
@app.route('/scenarios/type', methods = ['GET', 'POST'])
def type():
    if validateLogin():
        if ips.includedip:
            return render_template('type.html',title = 'IntrePId', settings = globalsettings, ips = ips)
        else:
            flash(u"No target specified", "error")
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
    flash(u"Saved in the manager", "info")
    return redirect('/scenarios/type')


# Scenario Manager
# Associated to manager.html
@app.route('/scenarios/manager', methods = ['GET', 'POST'])
def manager():
    if validateLogin():
        if ips.includedip and scenario:
            form = LaunchSettings()
            return render_template('manager.html', title = 'IntrePId', settings = globalsettings, ips = ips, scenario = scenario, form = form)
        else:
            flash(u"No scenario object specified", 'error')
            return redirect('/scenarios/type')
    else:
        return redirect('/')

@app.route('/scenarios/manager/_upObj')
def upObj():
    index = int(request.args.get('id'))
    try:
        scenario[index], scenario[index-1] = scenario[index-1], scenario[index]
    except:
        flash(u"Can't move that item", 'error')
    return redirect('/scenarios/manager')

@app.route('/scenarios/manager/_downObj')
def downObj():
    index = int(request.args.get('id'))
    try:
        scenario[index], scenario[index+1] = scenario[index+1], scenario[index]
    except:
        flash(u"Can't move that item", 'error')
    return redirect('/scenarios/manager')

@app.route('/scenarios/manager/_delObj')
def delObj():
    index = int(request.args.get('id'))
    try:
        scenario.pop(index)
    except:
        flash(u"That element doesn't exist anymore" ,'error')
    return redirect('/scenarios/manager')

@app.route('/scenarios/manager/_startSingle')
def startSingle():
    index = int(request.args.get('id'))
    scenario[index].status = "Working"
    return redirect('/scenarios/manager')


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
                flash(u"Command sent", 'info')
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

# Updates System Info (info = SysInfo()) on request)
@app.route('/_sysinfo', methods= ['GET'])
def _sysinfo():
    info.update(globalsettings.interface)
    return jsonify(uname = info.uname, uptime = info.uptime, net = info.network)

#######################
#                     #
#  TODO MOTHERFUCKER  #
#                     #
#######################
# Update scenario in XML

@app.route('/liste/open/')
def cat_f():
    nom = request.args.get('file','')
    f_open = open(DOSSIER_UPS + nom , "r")
    file = f_open.read()
    dom = parseString(file)

    xmlTag = dom.getElementsByTagName('runstats')[0].toxml()
    return render_template('up_liste.html', nom=xmlTag, settings = globalsettings, ips = ips , dom=dom)

@app.route('/liste/download')
def download():
    nom = request.args.get('file')
    return send_from_directory(DOSSIER_UPS, nom)

@app.route('/liste/delete/')
def deletefile():
    nom = request.args.get('id','')
    os.remove(DOSSIER_UPS + nom)
    return redirect ('/scenarios#select')
