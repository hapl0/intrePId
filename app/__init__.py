# -*- coding: utf-8 -*-
from flask import Flask
from flask.ext.login import LoginManager


app = Flask(__name__)
app.config.from_object('config')
login_manager = LoginManager()
login_manager.setup_app(app)
from app import views