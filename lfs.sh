#!/bin/bash

#
# Vars
#

LOGFILE="$LFS/lfs.log"
TMPSYSINFO=tmpsys_files_details
TMPSYSGEN=tmpsys_listgen.sh
TMPSYSURL=http://www.linuxfromscratch.org/lfs/view/stable/wget-list
TMPSYSMD5=http://www.linuxfromscratch.org/lfs/view/stable/md5sums

#
# Fx
#

download() 
{
	#$1 = MD5
	#$2 = filename
	#$3 = URL
	if [ ! $# -eq 3 ]
	then
		echo "download() must be called with 3 parameters ! (actual : $#)"
	fi
	#echo -e "\tFilename :\t$2"
	#echo -e "\tMD5 :\t\t$1"
	#echo -e "\tURL :\t\t$3"
	#read -p "Pause"
	if [ -f $2 ]
	then
		echo -e "\t\t$2 found, checking md5"
		echo "$1  $2" > tempmd5 #double space !
		md5sum -c tempmd5 >> $LOGFILE 2>&1
		if [ ! $? -eq 0 ]
		then
			echo -e "\t\tinvalid md5 hash for $2"
			rm -f $2
			rm tempmd5
			download $1 $2 $3
			RTRNCODE=$?
		else
			echo -e "\t\tvalid md5 hash for $2"
			rm tempmd5
			RTRNCODE=0
		fi
		return $RTRNCODE
	else
		echo -e "\t\tdownloading $2"
		wget "$3" >> $LOGFILE 2>&1
		if [ ! $? -eq 0 ]
		then
			echo -e "\t\terror while downloading attempt of $2"
			return 1
		fi
		download $1 $2 $3
		return $?
	fi
}

returncheck()
{
	if [ $# -eq 0 ]
	then
		return
	fi
	if [ ! $1 -eq 0 ]
	then
		echo "Error code : $1. Exiting now."
		exit $1
	fi
}


#
# Script
#
echo | tee $LOGFILE
echo | tee -a $LOGFILE
echo " -> LFS Script started <-" | tee -a $LOGFILE
if [ "$USER" != "lfs" ]
then
	echo
	echo -e "\tUnexpected user : $USER" | tee -a $LOGFILE
	exit 1
fi
#preparing
cd $LFS
#dwlding sources
echo
echo " * Temporary System" | tee -a $LOGFILE
echo "" | tee -a $LOGFILE
cd sources
echo -e "\tDownloading sources (check progress using \"tail -f $LOGFILE\")"
if [ ! -f $TMPSYSINFO ]
then
	echo -e "\t\tCan't find $TMPSYSINFO"
	echo -e "\t\tGenerating using \"$TMPSYSGEN\""
	wget --quiet "$TMPSYSURL"
	returncheck $?
	wget --quiet "$TMPSYSMD5"
	returncheck $?
	$LFS/$TMPSYSGEN $TMPSYSINFO
	returncheck $?
fi
RES=$(cat $TMPSYSINFO | wc -l)
PERCENTMULTIPLICATOR=$((100/$RES))
for ((i=1;i<=$RES;i++))
do
	download $(head -n $i $TMPSYSINFO | tail -n 1)
	echo -e "\t\t$(($i*$PERCENTMULTIPLICATOR))% done"
	echo
done

