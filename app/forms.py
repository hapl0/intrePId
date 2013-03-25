from flask.ext.wtf import Form, TextField, BooleanField, PasswordField
from flask.ext.wtf import Required

class LoginForm(Form):
    password = PasswordField('password', validators = [Required()])
