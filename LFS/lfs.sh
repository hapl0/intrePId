#!/bin/bash

. "lfs.includes"

#
# Script
#

#
# PreLFS
#
clear
echo
echo -e "\t   PreLFS Script started"
echo -e "\t  ***********************"

# check and create mount point
echo
echo " * Preparing mount point ($LFS)"
pushd . > /dev/null
mkdir -p "$LFS" > /dev/null
cd "$LFS"
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
RES=$(/sbin/swapon $SWAP)
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

#LFS Requirement
echo
echo " * Updating host environment"
apt-get install -y bash binutils bison bzip2 coreutils diffutils findutils gawk gcc eglibc-source grep gzip m4 make patch perl sed tar texinfo xz-utils >> $LOGFILE 2>&1
returncheck $?

#Check LFS user
echo
echo " * Checking LFS user"
LFSUSER=$(cat /etc/passwd | grep lfs | sed -r s/^lfs:.*$/found/ | grep found)
if [ ! "$LFSUSER" ]
then
echo -e "\tCreating \"lfs\" user "
useradd lfs -m -s "/bin/bash" -p lfs
returncheck $?
else
echo -e "\tlfs user found"
fi

#Overwrite LFS user environnement
echo
echo " * Setting up environnement for lfs user"
cat > /home/lfs/.bash_profile << EOF
exec env -i HOME=/home/lfs TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
cat > /home/lfs/.bashrc << EOF
set +h
umask 022
LFS=$LFS
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
read -p "        /tools (LFS II-4.2) found. [Enter] to remove it [Ctrl]+[C] to stop the script"
rm -r /tools
fi
ln -sv $LFS/tools / >> $LOGFILE 2>&1
if [ ! $? -eq 0 ]
then
echo -e "\tError while creating /tools symbolic link (LFS II-4.2) :"
echo -e "\t$RES"
exit 1
else
echo -e "\t/tools symlink ok"
fi
chown lfs $LFS/tools
##sources
if [ ! -d "$LFS/sources" ]
then
mkdir $LFS/sources
returncheck $?
fi
chown lfs $LFS/sources
chmod a+wt $LFS/sources
##logfile
chmod 666 $LOGFILE

#Copying files index
echo
echo " * Copying archives index files"
cp $TMPSYSINFO $LFS/sources
returncheck $?

#
# PreLFS /end
#

#launching lfs build
echo
read -p "   Ready to launch main lfs script. Press [Enter] to continue or [Ctrl]+[c] to exit."
echo
echo

#
# LFS /start
#

#
# LFS - Temporary System /start
#
clear
su lfs -c "bash lfs_tmpsys.partial"
returncheck $?
echo
echo -e "\tSwitching back to `whoami` user" #must be root /debug
echo
echo -e "\tStripping"
strip --strip-debug /tools/lib/* >> $LOGFILE 2>&1
strip --strip-unneeded /tools/{,s}bin/* >> $LOGFILE 2>&1
rm -rf /tools/{,share}/{info,man,doc} >> $LOGFILE 2>&1
returncheck $?
echo
echo -e "\tChanging Ownership of tools folder"
chown -R root:root $LFS/tools
returncheck $?

#
# LFS - Temporary System /end
#

#
# LFS - Final System /start
#





#
# LFS - Final System /end
#

#
# LFS /end
#
exit 0





##SAMPLE PACKET PROCESS

#5.14. Ncurses-5.9
CURRENTPACKAGE="ncurses-5.9"
preparepackage "$CURRENTNUMBER" "$TMPSYSNBFILES" "$CURRENTPACKAGE"
RETURNCODE=$?
if [ $RETURNCODE -eq 0 ] #if return 2 from preparepackage, package already processed : skipping
then
	#specific actions
echo -e "\t\tconfigure" | tee -a $LOGFILE
./configure --prefix=/tools --with-shared --without-debug --without-ada --enable-overwrite >> $LOGFILE 2>&1
returncheck $?
echo -e "\t\tmake" | tee -a $LOGFILE
make >> $LOGFILE 2>&1
returncheck $?
echo -e "\t\tinstall" | tee -a $LOGFILE
make install >> $LOGFILE 2>&1
returncheck $?
	#/specific actions
	endpackage "$CURRENTPACKAGE"
	returncheck $?
elif [ $RETURNCODE -eq 2 ]
then
	echo -e "\t\tPackage already processed, skipping." | tee -a $LOGFILE
else
	echo -e "\t\tError while preparing $CURRENTPACKAGE archive" | tee -a $LOGFILE
	returncheck 1
fi
CURRENTNUMBER=$(($CURRENTNUMBER+1))
echo | tee -a $LOGFILE
