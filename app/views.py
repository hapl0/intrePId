# -*- coding: utf-8 -*-

from flask import render_template, flash, redirect, session, abort, escape, url_for, jsonify
from app import app
from forms import LoginForm, SettingForm, TermForm
from functions import getCpuLoad, getVmem, getDisk, validateLogin
import subprocess

class settings(object):
	""" Settings class"""
	def __init__(self, data):
		self.updatetime = data
		self.password = "azerty"

globalsettings = settings(data="2000")

@app.route('/', methods = ['GET', 'POST'])
@app.route('/login', methods = ['GET', 'POST'])
def login():
	form = LoginForm()
	if form.validate_on_submit():
		if form.password.data == globalsettings.password:
			session['username'] = "admin"
			flash("You're now logged")
			return redirect("/index")
		return redirect("/")
	return render_template('login.html', title = 'Sign In', form = form)

@app.route('/index', methods = ['GET','POST'])
def index():
	if validateLogin():
		return render_template('index.html', title = 'IntrePid', settings = globalsettings)
	else:
		return redirect("/")

@app.route('/settings', methods = ['GET','POST'])
def settings():
	if validateLogin():
		form = SettingForm()
		if form.validate_on_submit():
			if form.updatetime.data and form.updatetime.data != globalsettings.updatetime:
				globalsettings.updatetime = form.updatetime.data
				flash("Changes saved")
		return render_template('settings.html', title = 'IntrePid', settings = globalsettings, form=form)
	else:
		return redirect('/')

@app.route('/updates', methods = ['GET','POST'])
def updates():
	if validateLogin():
		return render_template('updates.html', title = 'IntrePid', settings = globalsettings)
	else:
		return redirect('/')

@app.route('/scenarios', methods = ['GET','POST'])
def scenarios():
	if validateLogin():
		return render_template('scenarios.html', title = 'IntrePid', settings = globalsettings)
	else:
		return redirect('/')

@app.route('/term', methods = ['GET', 'POST'])
def term():
	if validateLogin():
		form = TermForm()
		if form.validate_on_submit():
			stuff=form.command.data.split()
			if len(stuff) > 1:
				output = subprocess.check_output([stuff[0],stuff[1]])
			else :
				output = subprocess.check_output([form.command.data])
			print output
			output = output.replace("\n","<br />")
			flash("Command sent")
			return render_template('terminal.html', title = 'IntrePid', settings = globalsettings, form = form, res=output)
		return render_template('terminal.html', title = 'IntrePid', settings = globalsettings, form = form)
	else:
		return redirect('/')


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