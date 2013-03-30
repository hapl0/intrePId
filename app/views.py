# -*- coding: utf-8 -*-

from flask import render_template, flash, redirect, session, abort, escape, url_for
from app import app
from forms import LoginForm

@app.route('/', methods = ['GET', 'POST'])
@app.route('/login', methods = ['GET', 'POST'])
def login():
	form = LoginForm()
	if form.validate_on_submit():
		if form.password.data == "azerty":
			session['username'] = "admin"
			flash("You're now logged in as "+session['username'])
			return redirect("/index")
		return redirect("/login")
	return render_template('login.html', title = 'Sign In', form = form)

@app.route('/index')
def index():
	if 'username' in session:
		return render_template('index.html', title = 'IntrePid')
	else:
		flash("You need to login before you go there.")
		return redirect("/login")

@app.route('/logout')
def logout():
	session.pop('username', None)
	return redirect("/login")