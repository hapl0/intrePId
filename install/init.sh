#!/usr/bin/bash

# Set up the virtualenv and download dependencies.
# MUST BE RUN AT LEAST ONCE BEFORE LAUNCHING THE APP.
# Updating the dependencies can be done by using update.sh

pythonversion=`python -c 'import sys; print(".".join(map(str, sys.version_info[:3])))'`
pythonbranch=`echo $pythonversion | cut -f1 -d"."`
echo "Current Python version is $pythonversion."
if [[ $pythonbranch != "2" ]]; then
	python2version=`python2.7 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))'`
	if [ $? -eq 0 ]; then
		echo "Python 2.7 available. Starting Installation"
		python2.7 virtualenv/virtualenv.py --no-site-packages ../flask
		if [ $? -eq 0 ]; then
			echo -e "Created the virtualenv successfully.\nStarting Installation of Dependencies."
			../flask/bin/pip install -r requirements.txt
			if [ $? -eq 0 ]; then
				echo -e "\nHell Yeah you can now start using the application."
			else
				echo -e "The virtualenv was installed but there is a dependency problem."
				echo -e "Please launch the update.sh script to solve it."
			fi
		else
			echo "There seems to be a problem with the virtualenv installation."
			exit 1
		fi
	else
		echo -e "You don't seem to have the correct Python version.\nPlease download and install Python2.7"
		exit 1
	fi
fi