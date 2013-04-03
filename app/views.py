# -*- coding: utf-8 -*-

from flask import render_template, flash, redirect, session, abort, escape, url_for, jsonify
from app import app
from forms import LoginForm, SettingForm
from functions import getCpuLoad, getVmem, getDisk

class settings(object):
	""" Settings class"""
	def __init__(self, data):
		self.updatetime=data

globalsettings = settings(data="2000")

@app.route('/', methods = ['GET', 'POST'])
@app.route('/login', methods = ['GET', 'POST'])
def login():
	form = LoginForm()
	if form.validate_on_submit():
		if form.password.data == "azerty":
			session['username'] = "admin"
			flash("You're now logged")
			return redirect("/index")
		return redirect("/login")
	return render_template('login.html', title = 'Sign In', form = form)

@app.route('/index', methods = ['GET','POST'])
def index():
	if 'username' in session:
		return render_template('index.html', title = 'IntrePid', settings = globalsettings)
	else:
		flash("You need to login before you go there.")
		return redirect("/login")

@app.route('/_stuff', methods= ['GET'])
def stuff():
	cpu=round(getCpuLoad())
	ram=round(getVmem())
	disk=round(getDisk())
	return jsonify(cpu=cpu, ram=ram, disk=disk)

@app.route('/settings', methods = ['GET','POST'])
def settings():
	form = SettingForm()
	if form.validate_on_submit():
		if form.updatetime.data != globalsettings.updatetime:
			globalsettings.updatetime=form.updatetime.data
			flash("Changes saved")
	return render_template('settings.html', title = 'IntrePid', settings = globalsettings, form=form)

@app.route('/updates', methods = ['GET','POST'])
def updates():
	return render_template('updates.html', title = 'IntrePid', settings = globalsettings)

@app.route('/scenarios', methods = ['GET','POST'])
def scenarios():
	return render_template('scenarios.html', title = 'IntrePid', settings = globalsettings)

@app.route('/logout')
def logout():
	session.pop('username', None)
	return redirect("/login")