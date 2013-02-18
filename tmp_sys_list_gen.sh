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
DESTINATIONFILE=archives_details_tmpsys

#
# Script
#
if [ ! -f $SOURCEURLS ] || [ ! -w $SOURCEURLS ]
then
	echo -e "\tError while opening urls source file ($SOURCEURLS)"
	exit 1
fi
if [ ! -f $SOURCEMD5 ] || [ ! -w $SOURCEMD5 ]
then
	echo -e "\tError while opening md5 source file ($SOURCEMD5)"
	exit 1
fi
if [ -f $DESTINATIONFILE ] && [ ! -w $DESTINATIONFILE ]
then
	echo -e "\tThe destination file is not writable :("
	exit 1
fi
URLSLIGNES=$(cat $SOURCEURLS | wc -l)
MD5LIGNES=$(cat $SOURCEMD5| wc -l)
#oposite return status with ((..))
if (( $URLSLIGNES != $MD5LIGNES ))
then
	echo -e "\tThe two files do not have same amount of lignes"
	echo -e "\t\turls : $URLSLIGNES\tmd5s : $MD5LIGNES"
	exit 1
fi
rm -f $DESTINATIONFILE
for ((i=0;i<$URLSLIGNES;i++))
do
	FIRST=$(head -n $i $SOURCEMD5 | tail -n 1)
	SECOND=$(head -n $i $SOURCEURLS | tail -n 1)
	echo "$FIRST $SECOND" >> $DESTINATIONFILE
done
echo -e "\t$DESTINATIONFILE generated."
exit 0