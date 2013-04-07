# -*- coding: utf-8 -*-

from flask import render_template, flash, redirect, session, abort, escape, url_for, jsonify
from app import app
from forms import LoginForm, SettingForm, TermForm, IpForm
from functions import getCpuLoad, getVmem, getDisk, validateLogin
import subprocess

class settings(object):
	""" Settings class"""
	def __init__(self, data):
		self.updatetime = data
		self.password = "azerty"

globalsettings = settings(data="2000")

class usedip(object):
	""" Tables with IPs """
	def __init__(self):
		self.includedip = ""
		self.excludeip = ""

class sysinfo(object):
	""" System informations for index """
	def __init__(self):
		self.uname = subprocess.check_output(['uname','-a'])
		self.network = subprocess.check_output(['ifconfig', '-a']).replace("\n","<br />")
		self.uptime = subprocess.check_output(['uptime'])


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
		info = sysinfo()
		return render_template('index.html', title = 'IntrePid', settings = globalsettings, info = info)
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
		return render_template('settings.html', title = 'IntrePid', settings = globalsettings, form = form)
	else:
		return redirect('/')

# Updates page
# Associated to updates.html
@app.route('/updates', methods = ['GET','POST'])
def updates():
	if validateLogin():
		return render_template('updates.html', title = 'IntrePid', settings = globalsettings)
	else:
		return redirect('/')

# Scenarios page
# Associated with scenarios.html
@app.route('/scenarios', methods = ['GET','POST'])
def scenarios():
	if validateLogin():
		form = IpForm()
		if form.validate_on_submit():
			flash("Saved")
		return render_template('scenarios.html', title = 'IntrePid', settings = globalsettings, form = form)
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
				return render_template('terminal.html', title = 'IntrePid', settings = globalsettings, form = form, res=output)
		return render_template('terminal.html', title = 'IntrePid', settings = globalsettings, form = form)
	else:
		return redirect('/')

# Logout routine
@app.route('/logout')
def logout():
	session.pop('username', None)
	return redirect('/')

# Ajax requests

@app.route('/_stuff', methods= ['GET'])
def stuff():
	cpu=round(getCpuLoad())
	ram=round(getVmem())
	disk=round(getDisk())
	return jsonify(cpu=cpu, ram=ram, disk=disk)