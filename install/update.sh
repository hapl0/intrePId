#!/usr/bin/bash

# Updates the dependencies.

../flask/bin/pip install -r requirements.txt

if [ $? -eq 0 ]; then
	echo -e "\nI don't know if it updated something but everything went good."
else
	echo -e "Dependency problem detected. Please make sure your requirements.txt is up to date."
fi