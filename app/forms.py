from flask.ext.wtf import Form, TextField, BooleanField, PasswordField
from flask.ext.wtf import Required, NumberRange
class LoginForm(Form):
    password = PasswordField('password', validators = [Required()])

class SettingForm(Form):
	updatetime = TextField('updatetime', validators = [NumberRange(min=1000, max=None, message="A lower value than 1 second will slow down the interface.")])
