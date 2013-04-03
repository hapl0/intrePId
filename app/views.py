# -*- coding: utf-8 -*-

from flask import render_template, flash, redirect, session, abort, escape, url_for, jsonify
from app import app
from forms import LoginForm
from functions import getCpuLoad

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
		return render_template('index.html', title = 'IntrePid')
	else:
		flash("You need to login before you go there.")
		return redirect("/login")

@app.route('/_stuff', methods= ['GET'])
def stuff():
	result=getCpuLoad()
	return jsonify(result=result)

@app.route('/settings', methods = ['GET','POST'])
def settings():
	return render_template('settings.html', title = 'IntrePid')

@app.route('/updates', methods = ['GET','POST'])
def updates():
	return render_template('updates.html', title = 'IntrePid')

@app.route('/scenarios', methods = ['GET','POST'])
def scenarios():
	return render_template('scenarios.html', title = 'IntrePid')

@app.route('/logout')
def logout():
	session.pop('username', None)
	return redirect("/login")