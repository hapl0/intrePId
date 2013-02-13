#!/bin/bash

#
# Vars
#
LFSPART=/dev/sda3
LFSFS=ext3
MOUNTPOINT=/mnt/lfs
SWAP=/dev/sda4
PROCESSORNUMBER=4
LFSSCRIPT=lfs.sh

#
# Pre lfs
#
if [[  "$USER" != "root" ]]
then
	usage "This script must be run as root !"
fi
# check and create mount point
echo
echo " * Preparing mount point"
pushd . > /dev/null
mkdir -p "$MOUNTPOINT" > /dev/null
cd "$MOUNTPOINT"
LFS=$(pwd)
popd > /dev/null
if [ ! -d "$LFS" ]
then
	echo -e "\tMount point does not seem to be a directory !"
	exit 1
fi
if [ "$(ls -A $LFS)" ]
then
	echo -e "\tThe mount point is not empty !"
	exit 1
fi
echo -e "\tMount point ready"
# check file device
echo
echo " * Checking file devices"
if [ ! -b "$LFSPART" ]
then
	echo -e "\tLFS partition device is not a block file !"
	exit 1
fi
echo -e "\tLFS file device ok"
RES=$(mount | grep $LFSPART)
if [ "$RES" ]
then
	echo -e "\tLFS partition is already mounted !"
	exit 1
fi
echo -e "\tLFS file device ready"
if [ ! -b "$SWAP" ]
then
	echo -e "\tSWAP partition is not a block device !"
	exit 1
fi
echo -e "\tSWAP file device ready"
# Activate SWAP
echo
echo " * Activating SWAP"
RES=$(/sbin/swapon $SWAP 2>&1)
if [ ! $? -eq 0 ]
then
	echo -e "\t$RES"
	read -p "        Press [Enter] to continue anyway or [Ctrl]+[C] to stop the script"
else
	echo -e "\tSWAP activated on $SWAP"
fi
# Mount
echo
echo " * Mounting"
RES=$(mount "$LFSPART" "$LFS")
if [ ! $? -eq 0 ]
then
	echo -e "\tError while mounting $LFSPART on $LFS :"
	echo -e "\t$RES"
	exit 1
fi
echo -e "\t$LFSPART mounted on $LFS"
#check mount options
RES=$(mount | grep "$LFSPART on $LFS" | sed -r "s:^$LFSPART on $LFS type $LFSFS \(rw\)$:good:")
if [ ! "$RES" == "good" ]
then
	echo -e "\tWrong mount options !"
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
echo -e "\tlfs user found"
#Overwrite LFS user environnement
echo
echo " * Setting up environnement for lfs user"
cat > /home/lfs/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
cat > /home/lfs/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOF
chown lfs:lfs /home/lfs/.bash_profile /home/lfs/.bashrc
#Preparing LFS folder structure
echo
echo " * Preparing folder structure"
##tools
if [ ! -d "$LFS/tools" ]
then
	mkdir "$LFS/tools"
	if [ $? -eq 0 ]
	then
		echo -e "\t$LFS/tools created"
	else
		echo -e "\tCan't create $LFS/tools !"
		exit 1
	fi
else
	echo -e "\t$LFS/tools already exists"
fi
if [ -e /tools ]
then
	read -p "        /tools (LFS II-4.2) already exists. Press [Enter] to remove it or [Ctrl]+[C] to stop the script."
	rm -r /tools
fi
RES=(ln -sv $LFS/tools /)
if [ ! $? -eq 0 ]
then
	echo -e "\tError while creating symbolic link (LFS II-4.2) :"
	echo -e "\t$RES"
	exit 1
fi
echo -e "\t/tools symlink ok"
##sources
if [ ! -d "$LFS/sources" ]
then
	mkdir $LFS/sources
fi
chmod a+wt $LFS/sources
#Preparing LFS script
echo
echo " * Checking LFS script"
if [ ! -f $LFSSCRIPT ]
then
	echo -e "\tCan't find $LFSSCRIPT ! Aborting."
	exit 1
fi
echo -e "\tLFS script found, copying to $LFS"
cp $LFSSCRIPT $LFS
if [ ! $? -eq 0 ]
then
	echo -e "\tError while copying the script"
	exit 1
fi
chown lfs $LFS/$LFSSCRIPT
#launching lfs build
echo
echo " * Launching LFS script"
export LFS
export MAKEFLAGS="-j $PROCESSORNUMBER"
su lfs -c "bash $LFS/$LFSSCRIPT"
