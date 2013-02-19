#!/bin/bash
#
# Generates a file with all informations needed by lfs script (md5 archive_name url)
# from two different files (from LFS "wget-list" and "md5sums")
#

#
# Vars
#
SOURCEURLS=wget-list
SOURCEMD5=md5sums
DESTINATIONFILE=tmpsys_files_details

#
# Script
#
if [ $# > 0 ]
then
	DESTINATIONFILE="$1"
fi
if [ ! -f "$SOURCEURLS" ] || [ ! -r "$SOURCEURLS" ]
then
	echo -e "\tError while opening urls source file ($SOURCEURLS)"
	exit 1
fi
if [ ! -f "$SOURCEMD5" ] || [ ! -r "$SOURCEMD5" ]
then
	echo -e "\tError while opening md5 source file ($SOURCEMD5)"
	exit 1
fi
if [ -f "$DESTINATIONFILE" ]
then
	if [ ! -w "$DESTINATIONFILE" ]
	then
		echo -e "\tThe destination file is not writable :("
		exit 1
	fi
	rm -f "$DESTINATIONFILE"
fi
URLSLIGNES=$(cat "$SOURCEURLS" | wc -l)
MD5LIGNES=$(cat "$SOURCEMD5" | wc -l)
if (( $URLSLIGNES != $MD5LIGNES ))
then
	echo -e "\tThe two files do not have same amount of lignes"
	echo -e "\t\turls : $URLSLIGNES\tmd5s : $MD5LIGNES"
	exit 1
fi
for ((i=1;i<=$URLSLIGNES;i++))
do
	FIRST=$(head -n $i $SOURCEMD5 | tail -n 1)
	SECOND=$(head -n $i $SOURCEURLS | tail -n 1)
	echo "$FIRST $SECOND" >> "$DESTINATIONFILE"
done
echo -e "\t\t$DESTINATIONFILE generated."
exit 0
