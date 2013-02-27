#!/bin/bash

#
# Vars
#

#PreLFS
LFSPART=/dev/sda3
LFSFS=ext3
LFS=/mnt/lfs #mount point
SWAP=/dev/sda4

#LFS
LOGFILE="$LFS/lfs.log"
TMPSYSINFO=tmpsys_files_details
PROCESSORNUMBER=4

#
# Fx
#

returncheck()
{
	if [ $# -eq 0 ]
	then
		return 1
	fi
	if [ ! $1 -eq 0 ]
	then
		echo "Error code : $1. Stopping now." | tee -a $LOGFILE
		echo -e "\tPlease check log file : $LOGFILE"
		exit $1
	else
		return 0
	fi
}

tmpsys_listgen()
{
	SOURCEURLS=wget-list
	SOURCEURLSHTTP=http://www.linuxfromscratch.org/lfs/view/stable/wget-list
	SOURCEMD5=md5sums
	SOURCEMD5HTTP=http://www.linuxfromscratch.org/lfs/view/stable/md5sums

	if [ ! $# -eq 1 ]
	then
		echo "tmpsys_listgen have to be called with one parameter (destination file)" | tee -a $LOGFILE
		return 1
	fi
	DESTINATIONFILE=$1

	if [ ! -f "$SOURCEURLS" ]
	then
		echo -e "\tDownloading $SOURCEURLS from $SOURCEURLSHTTP" | tee -a $LOGFILE
		wget --quiet "$SOURCEURLSHTTP"
		if [ ! $? -eq 0 ]
		then
			echo -e "\tError with $SOURCEURLS download attempt."
			return 1
		fi
	fi
	if [ ! -r "$SOURCEURLS" ]
	then
		echo -e "\tError while opening urls source file ($(pwd)/$SOURCEURLS)" | tee -a $LOGFILE
		return 1
	fi

	if [ ! -f "$SOURCEMD5" ]
	then
		echo -e "\tDownloading $SOURCEMD5 from $SOURCEMD5HTTP" | tee -a $LOGFILE
		wget --quiet "$SOURCEMD5SHTTP"
		if [ ! $? -eq 0 ]
		then
			echo -e "\tError with $SOURCEMD5 download attempt."
			return 1
		fi
	fi
	if [ ! -r "$SOURCEMD5" ]
	then
		echo -e "\tError while opening md5 source file ($(pwd)/$SOURCEMD5)" | tee -a $LOGFILE
		return 1
	fi

	if [ -f "$DESTINATIONFILE" ]
	then
		if [ ! -w "$DESTINATIONFILE" ]
		then
			echo -e "\tThe destination file is not writable :(" | tee -a $LOGFILE
			return 1
		fi
		rm -f "$DESTINATIONFILE"
	fi

	URLSLIGNES=$(cat "$SOURCEURLS" | wc -l)
	MD5LIGNES=$(cat "$SOURCEMD5" | wc -l)
	if (( $URLSLIGNES != $MD5LIGNES ))
	then
		echo -e "\tThe two files do not have same amount of lignes" | tee -a $LOGFILE
		echo -e "\t\turls : $URLSLIGNES\tmd5s : $MD5LIGNES" | tee -a $LOGFILE
		return 1
	fi
	for ((i=1;i<=$URLSLIGNES;i++))
	do
		FIRST=$(head -n $i $SOURCEMD5 | tail -n 1)
		SECOND=$(head -n $i $SOURCEURLS | tail -n 1)
		echo "$FIRST  $SECOND" >> "$DESTINATIONFILE"
	done

	echo -e "\t\t$DESTINATIONFILE generated." | tee -a $LOGFILE
	return 0
}

download() 
{
	#$1 = MD5
	#$2 = filename
	#$3 = primary URL
	#$4 = backup URL
	if (( $# < 3  )) || (( $# > 4 ))
	then
		echo "download() must be called with 3 or 4 parameters ! (actual : $#)" | tee -a $LOGFILE
		return 2
	fi
	#echo -e "\tFilename :\t$2"
	#echo -e "\tMD5 :\t\t$1"
	#echo -e "\tURL :\t\t$3"
	#echo -e "\tURL2 :\t\t$4"
	#read -p "Pause"
	if [ -f $2 ]
	then
		echo -e "\t\t$2 found, checking md5" | tee -a $LOGFILE
		echo "$1  $2" > tempmd5 #double space !
		md5sum -c tempmd5 >> $LOGFILE 2>&1
		if [ ! $? -eq 0 ]
		then
			echo -e "\t\tinvalid md5 hash for $2" | tee -a $LOGFILE
			rm -f $2
			rm tempmd5
			download $1 $2 $3 $4
			RTRNCODE=$?
		else
			echo -e "\t\tvalid md5 hash for $2" | tee -a $LOGFILE
			rm tempmd5
			RTRNCODE=0
		fi
		return $RTRNCODE
	else
		echo -e "\t\tdownloading $2" | tee -a $LOGFILE
		wget "$3" >> $LOGFILE 2>&1
		if [ ! $? -eq 0 ]
		then
			echo -e "\t\terror while downloading the primary url of $2" | tee -a $LOGFILE
			if [ "$4" ]
			then
				echo -e "\t\new download attempt from backup url"
				wget "$4" >> $LOGFILE 2>&1
				if [ ! $? -eq 0 ]
				then
					echo -e "\t\terror while downloading the backup url of $2" | tee -a $LOGFILE
					return 1
				else
					download $1 $2 $3 $4
					return $?
				fi
			else
				echo -e "\t\tno backup url :("
				return 1
			fi
		fi
	fi
}

preparepackage()
{
	# $1 = package number
	# $2 = total packages
	# $3 = package name (without .tar.gz or similar)
	echo -e "\t\t$1/$2"
	echo -e "\t\t$3"
	if (( $# -eq 3  ))
	then
		echo "prepare() must be called with 3 parameters ! (actual : $#)" | tee -a $LOGFILE
		exit 1
	else
		if [[ $1 != [[:digit:]] ]] && [[ $2 != [[:digit:]] ]]
		then
			echo "$1 et $2 ne sont pas des nombres"
			return 1
		else
			if [
		
	CURRENTFILENAME=$(ls $3*)
	if [ ! "$3" ]
	then
		echo -e "\t\t\tCan't find a file name for $3 :(" | tee -a $LOGFILE
		return 1
	fi
	if [ -f "$CURRENTFILENAME" ]
	then
		if [ ! -r "$CURRENTFILENAME" ]
		then
			echo -e "\t\t\t$CURRENTFILENAME is not readable !" | tee -a $LOGFILE
			return 1
		fi
	else
		echo -e "\t\t\t$CURRENTFILENAME does not exist !" | tee -a $LOGFILE
		return 1	
	fi
			
	echo -e "\t\t\tUnpacking..." | tee -a $LOGFILE
	tar xvf $CURRENTFILENAME >> $LOGFILE
	if [ ! $? -eq 0 ]
	then
		echo -e "\t\t\tError while extracting tar !"
		return 1
	fi
	#entering extracted folder
	cd $3
	#tmp
	pwd
	read -p "Pause"
	return 0
}

endpackage()
{
	#package name (something-1.0) without .tar.xx
	# $2+ extra folders to delete
	cd $LFS/sources
	#delete folder(s)
	> "$1.done"
	CURRENTNUMBER=$(($CURRENTNUMBER+1))
	return 0
}


#
# Script
#

if [ "$USER" == "root" ]; then
	#
	# PreLFS
	#
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
	if [ -e /tools ] #not sure if working, need a debug test
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
	else
		echo -e "\t/tools symlink ok"
	fi
	##sources
	if [ ! -d "$LFS/sources" ]
	then
		mkdir $LFS/sources
	fi
	chmod a+wt $LFS/sources

	#Copying scripts for lfs
	#echo
	#echo " * Copying LFS scripts"
	#if [ ! -f $LFSSCRIPT ]
	#then
	#	echo -e "\tCan't find $LFSSCRIPT ! Aborting."
	#	exit 1
	#else
	#	echo -e "\tLFS script found, copying to $LFS"
	#	cp $LFSSCRIPT $LFS
	#	if [ ! $? -eq 0 ]
	#	then
	#		echo -e "\tError while copying the script"
	#		exit 1
	#	fi
	#	chown lfs $LFS/$LFSSCRIPT
	#fi
	#if [ ! -f $TMPSYSSCRIPT ]
	#then
	#	echo -e "\tCan't find $TMPSYSSCRIPT."
	#	read -p "       Skipping, can be an issue during LFS script execution (Press [Enter] to continue)."
	#else
	#	echo -e "\t$TMPSYSSCRIPT script found, copying to $LFS"
	#	cp $TMPSYSSCRIPT $LFS
	#	if [ ! $? -eq 0 ]
	#	then
	#		echo -e "\tError while copying the script"
	#		exit 1
	#	fi
	#	chown lfs $LFS/$TMPSYSSCRIPT
	#fi

	#launching lfs build
	echo
	echo " * Launching LFS script"
	echo
	echo
	su lfs -c "bash $0"
	#
	# PreLFS /end
	#
elif [ "$USER" == "lfs" ]; then
	echo >> $LOGFILE
	echo >> $LOGFILE
	echo >> $LOGFILE
	date >> $LOGFILE
	echo >> $LOGFILE
	#
	# LFS /start
	#
	echo
	echo -e "\t   LFS Script started" | tee -a $LOGFILE
	echo -e "\t  ********************"
	echo | tee -a $LOGFILE

	#preparing
	MAKEFLAGS="-j $PROCESSORNUMBER"

	#
	# LFS - Temporary System /end
	#
	echo " * Temporary System" | tee -a $LOGFILE
	echo "" | tee -a $LOGFILE
	cd $LFS/sources

	#
	#downloading sources
	echo -e "\tDownloading sources (check progress by using \"tail -f $LOGFILE\")" | tee -a $LOGFILE
	if [ ! -f $TMPSYSINFO ]
	then
		echo -e "\t\tCan't find $TMPSYSINFO" | tee -a $LOGFILE
		echo -e "\t\tGenerating..." | tee -a $LOGFILE
		tmpsys_listgen $TMPSYSINFO
		echo | tee -a $LOGFILE
		returncheck $?
	fi
	TMPSYSNBFILES=$(cat $TMPSYSINFO | wc -l)
	for ((i=1;i<=$RES;i++))
	do
		echo -e "\t\t$i/$TMPSYSNBFILES" | tee -a $LOGFILE
		download $(head -n $i $TMPSYSINFO | tail -n 1)
		returncheck $? #exit if something went wrong
		echo | tee -a $LOGFILE
	done

	#
	#constructing temporary system
	echo | tee -a $LOGFILE
	echo -e "\tBuilding sources (check progress by using \"tail -f $LOGFILE\")" | tee -a $LOGFILE
	echo | tee -a $LOGFILE
	CURRENTNUMBER=1

	#5.4. Binutils-2.22 - Pass 1
	preparepackage $CURRENTNUMBER $TMPSYSNBFILES "binutils-2.22"
	if [ ! $? -eq 2 ] #if return 2 from preparepackage, package already process : skipping
	then
		returncheck $?
		#specific actions
		#...
		#/specific actions
		endpackage "binutils-2.22"
	fi
	


	#
	# LFS - Temporary System /end
	#
else
	echo
	echo " This script must be called as :"
	echo -e "\troot -> preLFS checks then LFS script run"
	echo -e "\tlfs  -> skip preLFS checks and run directly LFS script"
	echo
fi
