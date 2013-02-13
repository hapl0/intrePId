#!/bin/bash

#
# Vars
#

LOGFILE="$LFS/lfs.log"
LAUNCHINTERM="gnome-terminal -e"

#
# Fx
#

#
# Script
#
echo
echo
echo " -> LFS Script started <-"
echo
if [ "$USER" != "lfs" ]
then
	echo -e "\tUnexpected user : $USER"
fi
#preparing
cd $LFS
#dwlding sources
echo
echo " * Downloading sources" | tee -a $LOGFILE
cd sources
if [ ! -f wget-list ]
then
	echo -e "\twget-list not found, downloading..." | tee -a $LOGFILE
	wget "http://www.linuxfromscratch.org/lfs/view/stable/wget-list" &>> $LOGFILE
	if [ ! $? -eq 0 ]
	then
		echo -e "\tError while downloading wget-list"
		exit 1
	fi
	echo -e "\twget-list downloaded"
else
	echo -e "\twget-list already exists, skipping download"
fi
if [ ! -f md5sums ]
then
	echo -e "\tmd5sums not found, downloading..." | tee -a $LOGFILE
	wget "http://www.linuxfromscratch.org/lfs/view/stable/md5sums" 2>&1 >> $LOGFILE
	if [ ! $? -eq 0 ]
	then
		echo -e "\tError while downloading md5sums"
		exit 1
	fi
	echo -e "\tmd5sums downloaded"
else
	echo -e "\tmd5sums already exists, skipping download"
fi
echo -e "\tdownloading packets..."
wget -i wget-list >> $LOGFILE
if [ ! $? -eq 0 ]
then
	echo -e "\tError while downloading"
	exit 1
fi
# md5 checks
echo
echo " * Checking downloaded files"
md5sum -c md5sums
if [ ! $? -eq 0 ]
then
	echo -e "\tCan't validate all files"
	exit 1
fi
echo "Keep going :)"


