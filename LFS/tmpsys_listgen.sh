#!/bin/bash

SOURCEURLS=wget-list
SOURCEURLSHTTP='http://www.linuxfromscratch.org/lfs/view/stable/wget-list'
SOURCEMD5=md5sums
SOURCEMD5HTTP='http://www.linuxfromscratch.org/lfs/view/stable/md5sums'
DESTINATIONFILE=tmpsys_files_details


if [ ! -f "$SOURCEURLS" ]
then
	echo -e "\tDownloading $SOURCEURLS from $SOURCEURLSHTTP" | tee -a $LOGFILE
	wget --quiet -O "$SOURCEURLS" "$SOURCEURLSHTTP"
	if [ ! $? -eq 0 ]
	then
		echo -e "\tError with $SOURCEURLS download attempt."
		exit 1
	fi
fi
if [ ! -r "$SOURCEURLS" ]
then
	echo -e "\tError while opening urls source file ($(pwd)/$SOURCEURLS)" | tee -a $LOGFILE
	exit 1
fi

if [ ! -f "$SOURCEMD5" ]
then
	echo -e "\tDownloading $SOURCEMD5 from $SOURCEMD5HTTP" | tee -a $LOGFILE
	wget --quiet -O "$SOURCEMD5" "$SOURCEMD5HTTP"
	if [ ! $? -eq 0 ]
	then
		echo -e "\tError with $SOURCEMD5 download attempt."
		exit 1
	fi
fi
if [ ! -r "$SOURCEMD5" ]
then
	echo -e "\tError while opening md5 source file ($(pwd)/$SOURCEMD5)" | tee -a $LOGFILE
	exit 1
fi

if [ -f "$DESTINATIONFILE" ]
then
	if [ ! -w "$DESTINATIONFILE" ]
	then
		echo -e "\tThe destination file is not writable :(" | tee -a $LOGFILE
		exit 1
	fi
	rm -f "$DESTINATIONFILE"
fi

URLSLIGNES=$(cat "$SOURCEURLS" | wc -l)
MD5LIGNES=$(cat "$SOURCEMD5" | wc -l)
if (( $URLSLIGNES != $MD5LIGNES ))
then
	echo -e "\tThe two files do not have same amount of lignes" | tee -a $LOGFILE
	echo -e "\t\turls : $URLSLIGNES\tmd5s : $MD5LIGNES" | tee -a $LOGFILE
	exit 1
fi
for ((i=1;i<=$URLSLIGNES;i++))
do
	FIRST=$(head -n $i $SOURCEMD5 | tail -n 1)
	SECOND=$(head -n $i $SOURCEURLS | tail -n 1)
	echo "$FIRST  $SECOND" >> "$DESTINATIONFILE"
done

echo -e "\t\t$DESTINATIONFILE generated." | tee -a $LOGFILE
exit 0
