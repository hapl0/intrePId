#!/bin/bash

#
# Vars
#
LFSFS=ext3
LFSSCRIPT=yay.sh

#
# FX
#
usage()
{
	echo
	echo $1
	echo
	echo "Usage : $0 /dev/sdXY /mount/point"
	echo
	exit 1
}

#
# Pre checks
#
if [[ $# != 2 ]]
then
	usage "Wrong parameters number"
fi
if [[  "$USER" != "root" ]]
then
	usage "This script must be run as root !"
fi
# check and create mount point
echo
echo " * Preparing mount point"
pushd . > /dev/null
mkdir -p "$2" > /dev/null
cd "$2"
LFS=$(pwd)
popd > /dev/null
if [ ! -d "$LFS" ]
then
	echo -e "\tError with mount point (param2)"
	exit 1
fi
# check file device
if [ ! -b "$1" ]
then
	echo -e "\tError with file device (param1)"
	exit 1
fi
# Mount
RES=$(mount | grep "$1 on $2")
echo
echo " * Mounting"
if [ ! "$RES" ]
then
	#Mounting
	mount "$1" "$LFS"
else
	echo -e "\tAlready Mounted"
fi
#check mount options
#SEDPARAM1=$(echo "$1" | sed -e "s:\/:\\\/:g")
#SEDPARAM2=$(echo "$2" | sed -e "s:\/:\\\/:g")
RES=$(mount | grep "$1 on $2" | sed -r "s:^$1 on $2 type $LFSFS \(rw\)$:good:")
if [ ! "$RES" == "good" ]
then
	echo "Wrong mount options !"
	echo -e "\t$RES"
	exit 1
fi
#Check LFS user
echo
echo " * Checking LFS user"
LFSUSER=$(cat /etc/passwd | grep lfs | sed -r s/^lfs:.*$/found/ | grep found)
if [ ! "$LFSUSER" ]
then
	echo -e "\tCan't find \"lfs\" user !"
	exit 1
fi
echo -e "\tlfs user found !"
#Preparing LFS script
echo
echo " * Checking LFS script"
if [ ! -f $LFSSCRIPT ]
then
	echo -e "\tCan't find $LFSSCRIPT ! Aborting."
	exit 1
fi
echo
echo " * Copying lfs script"
cp $LFSSCRIPT $LFS
if [ ! $? -eq 0 ]
then
	echo -e "\tError while copying the script"
	exit 1
fi
#launching lfs build
echo
echo " * Launching LFS script"
su lfs -c "bash $LFS/$LFSSCRIPT"
