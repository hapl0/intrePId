from flask.ext.wtf import Form, TextField, BooleanField, PasswordField
from flask.ext.wtf import Required, NumberRange, IPAddress
class LoginForm(Form):
    password = PasswordField('password', validators = [Required()])

class SettingForm(Form):
	updatetime = TextField('updatetime')
	currentpassword = PasswordField('currentpassword')
	newpassword = PasswordField('newpassword')
	confirmpassword = PasswordField('confirmpassword')

class IpScenarioForm(Form):
	include = TextField('updatetime')

class TermForm(Form):
	command = TextField('command')

class IpForm(Form):
	ipincluded = TextField('ipincluded')
	ipexcluded = TextField('ipexcluded')