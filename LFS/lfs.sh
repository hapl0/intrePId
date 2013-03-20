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
PROCESSORNUMBER=5
exec 2>&1
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
		echo -e "\tYou may have to clean the current step..."
		echo -e "\tPlease check log file : $LOGFILE"
		exit $1
	else
		return 0
	fi
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
		else
			download $1 $2 $3 $4
			return $?	
		fi
	fi
}

preparepackage()
{
	# $1 = package number
	# $2 = total packages
	# $3 = package name (without .tar.gz or similar)
	# return 0 = OK
	# return 1 = ERROR
	# return 2 = OK (already processed)
	
	echo -e "\t\t$1/$2" | tee -a $LOGFILE
	echo -e "\t\t$3" | tee -a $LOGFILE
	if [ ! $# -eq 3  ]
	then
		echo -e "\t\tprepare() must be called with 3 parameters ! (actual : $#)" | tee -a $LOGFILE
		return 1
	else
		if [[ $1 != [[:digit:]] ]] && [[ $2 != [[:digit:]] ]]
		then
			echo -e "\t\t$1 et $2 are not numbers" | tee -a $LOGFILE
			return 1
		else
			if [[ $1 > $2 ]]
			then 
				echo -e "\t\ttotal packages appears to be incorrect (CURRENT:$1 TOTAL:$2)" | tee -a $LOGFILE
				return 1
			fi
			if [ ! "$3" ]
			then
				echo -e "\t\t$3 is empty" | tee -a $LOGFILE
				return 1
			fi
		fi
	fi
	#check if package already processed
	if [ -f "$3.done" ]
	then 
		return 2
	fi
	#start processing package
	CURRENTFILENAME=$(ls | grep "$3.tar")
	if [ ! "$CURRENTFILENAME" ]
	then
		echo -e "\t\tcan't find an archive name for $3 package :(" | tee -a $LOGFILE
		return 1
	fi
	if [ -f "$CURRENTFILENAME" ]
	then
		if [ ! -r "$CURRENTFILENAME" ]
		then
			echo -e "\t\t$CURRENTFILENAME is not readable !" | tee -a $LOGFILE
			return 1
		fi
	else
		echo -e "\t\t$CURRENTFILENAME does not exist !" | tee -a $LOGFILE
		return 1	
	fi
			
	echo -e "\t\tunpacking" | tee -a $LOGFILE
	tar xf $CURRENTFILENAME >> $LOGFILE 2>&1
	if [ ! $? -eq 0 ]
	then
		echo -e "\t\terror while extracting tar !" | tee -a $LOGFILE
		return 1
	fi
	#entering extracted folder
	cd $3
	return 0
}

endpackage()
{
	# $1= package name (something-1.0) without .tar.xx : first folder to delete
	# $2+ = extra folders to delete
	#return 0 = OK
	#return 1 = ERROR
	if (( $# < 1 ))
	then
		echo -e "\t\tendpackage() must be called with at least one parameter !" | tee -a $LOGFILE
		return 1
	fi
	if [ ! "$1" ]
	then
		echo -e "\t\tendpackage() can not be called with an empty name !" | tee -a $LOGFILE
		return 1
	fi
	#starting
	PACKAGE=$1
	cd $LFS/sources
	while (( $# > 0 ))
	do
		if [ -d "$1" ]
		then
			echo -e "\t\tdeleting \"$1\" folder" | tee -a $LOGFILE
			rm -f -r $1
		else
			echo -e "\t\tcan't find a folder called \"$1\" for deletion !" | tee -a $LOGFILE
			return 1
		fi
		shift
	done
	touch "$PACKAGE.done"
	return 0
}


#
# Script
#
clear
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

	#Check LFS user
	echo
	echo " * Checking LFS user"
	LFSUSER=$(cat /etc/passwd | grep lfs | sed -r s/^lfs:.*$/found/ | grep found)
	if [ ! "$LFSUSER" ]
	then
		echo -e "\tCan't find \"lfs\" user !"
		exit 1
		# create user ? :)
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

	#launching lfs build
	echo
	read -p "   Ready to launch main lfs script. Press [Enter] to continue or [Ctrl]+[c] to exit."
	echo
	echo
	su lfs -c "bash $0"

	#
	# PreLFS /end
	#

elif [ "$USER" == "lfs" ]; then
	echo >> $LOGFILE 2>&1
	echo >> $LOGFILE 2>&1
	echo >> $LOGFILE 2>&1
	date >> $LOGFILE 2>&1
	echo >> $LOGFILE 2>&1
	#
	# LFS /start
	#
	echo
	echo -e "\t   LFS Script started" | tee -a $LOGFILE
	echo -e "\t  ********************"
	echo | tee -a $LOGFILE

	#preparing
	export MAKEFLAGS="-j $PROCESSORNUMBER"
	. ~/.bashrc #get ENV vars
	echo "makeflags : $MAKEFLAGS"
	echo "LFS : $LFS"
	echo "LC_ALL : $LC_ALL" 
	echo "LFS_TGT : $LFS_TGT"
	echo "PATH : $PATH"

	#
	# LFS - Temporary System /start
	#
	echo " * Temporary System" | tee -a $LOGFILE
	echo "" | tee -a $LOGFILE
	cd $LFS/sources

	#
	#downloading sources
	echo -e "\tDownloading sources (check progress by using \"tail -f $LOGFILE\")" | tee -a $LOGFILE
	if [ ! -f "$TMPSYSINFO" ]
	then
		pwd
		echo -e "\t\tCan't find $TMPSYSINFO" | tee -a $LOGFILE
		echo -e "\t\tIt can be generated using \"tmpsys_listgen.sh\" before launching this script" | tee -a $LOGFILE
		exit 1
	fi
	TMPSYSNBFILES=$(cat "$TMPSYSINFO" | wc -l)
	for (( i=1 ; i<=$TMPSYSNBFILES ; i++ ))
	do
		echo -e "\t\t$i/$TMPSYSNBFILES" | tee -a $LOGFILE
		download $(head -n $i $TMPSYSINFO | tail -n 1)
		returncheck $? #exit if something went wrong
		echo | tee -a $LOGFILE
	done

	#
	#constructing temporary system
	echo | tee -a $LOGFILE
	echo | tee -a $LOGFILE
	echo -e "\tBuilding sources (check progress by using \"tail -f $LOGFILE\")" | tee -a $LOGFILE
	echo | tee -a $LOGFILE
	CURRENTNUMBER=1
	TMPSYSNBFILES=$(ls $LFS/sources/*.tar.* | wc -l)


	#5.4. Binutils-2.23.1 - Pass 1
	CURRENTPACKAGE="binutils-2.23.1"
	preparepackage "$CURRENTNUMBER" "$TMPSYSNBFILES" "$CURRENTPACKAGE"
	if [ ! $? -eq 2 ] #if return 2 from preparepackage, package already processed : skipping
	then
		#specific actions
echo -e "\t\tcreating \"binutils-build\" extra folder" | tee -a $LOGFILE
mkdir -v ../binutils-build >> $LOGFILE 2>&1
returncheck $?
cd ../binutils-build
echo -e "\t\tpreparing build" | tee -a $LOGFILE
../binutils-2.23.1/configure --prefix=/tools --with-sysroot=$LFS --with-lib-path=/tools/lib --target=$LFS_TGT --disable-nls --disable-werror >> $LOGFILE 2>&1
returncheck $?
echo -e "\t\tmake in progress" | tee -a $LOGFILE
make >> $LOGFILE 2>&1
returncheck $?
echo -e "\t\tadditional changes" | tee -a $LOGFILE
( case $(uname -m) in
  x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
esac ) >> $LOGFILE 2>&1
echo -e "\t\tinstalling package" | tee -a $LOGFILE
make install >> $LOGFILE 2>&1
returncheck $?
		#/specific actions
		endpackage "$CURRENTPACKAGE" "binutils-build"
		returncheck $?
	else
		echo -e "\t\tPackage already processed, skipping."
	fi
	CURRENTNUMBER=$(($CURRENTNUMBER+1))
	echo | tee -a $LOGFILE


	#5.4. gcc-4.7.2 - Passe 1
	CURRENTPACKAGE="gcc-4.7.2"
	preparepackage "$CURRENTNUMBER" "$TMPSYSNBFILES" "$CURRENTPACKAGE"
	if [ ! $? -eq 2 ] #if return 2 from preparepackage, package already process : skipping
	then
#specific actions
echo -e "\t\tPreparing packets for gcc" | tee -a $LOGFILE
tar -Jxf ../mpfr-3.1.1.tar.xz >> $LOGFILE 2>&1
returncheck $?
mv -v mpfr-3.1.1 mpfr >> $LOGFILE 2>&1
tar -Jxf ../gmp-5.1.1.tar.xz >> $LOGFILE 2>&1
returncheck $?
mv -v gmp-5.1.1 gmp >> $LOGFILE 2>&1
returncheck $?
tar -zxf ../mpc-1.0.1.tar.gz >> $LOGFILE 2>&1
returncheck $?
mv -v mpc-1.0.1 mpc >> $LOGFILE 2>&1
returncheck $?
echo -e "\t\tChange the location of the dynamic linker's default GCC to use the one installed in /tools" | tee -a $LOGFILE
#echo -e "\t\tRemove /usr/include for gcc" | tee -a $LOGFILE
for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv $file{,.orig} >> $LOGFILE 2>&1
  returncheck $?
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' -e 's@/usr@/tools@g' $file.orig > $file
  returncheck $?
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  returncheck $?
  touch $file.orig
  returncheck $?
done
echo -e "\t\tAdditionnal configuration" | tee -a $LOGFILE
sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure
returncheck $?
sed -i 's/BUILD_INFO=info/BUILD_INFO=/' gcc/configure
returncheck $?
mkdir -v ../gcc-build  >> $LOGFILE 2>&1
cd ../gcc-build
returncheck $?
echo -e "\t\tPreparing gcc compilation" | tee -a $LOGFILE
../gcc-4.7.2/configure         \
    --target=$LFS_TGT          \
    --prefix=/tools            \
    --with-sysroot=$LFS        \
    --with-newlib              \
    --without-headers          \
    --with-local-prefix=/tools \
    --with-native-system-header-dir=/tools/include \
    --disable-nls              \
    --disable-shared           \
    --disable-multilib         \
    --disable-decimal-float    \
    --disable-threads          \
    --disable-libmudflap       \
    --disable-libssp           \
    --disable-libgomp          \
    --disable-libquadmath      \
    --enable-languages=c       \
    --with-mpfr-include=$(pwd)/../gcc-4.7.2/mpfr/src \
    --with-mpfr-lib=$(pwd)/mpfr/src/.libs >> $LOGFILE 2>&1
returncheck $?
echo -e "\t\tGCC Compilation" | tee -a $LOGFILE
make >> $LOGFILE 2>&1
returncheck $?
echo -e "\t\tInstalling gcc" | tee -a $LOGFILE
make install >> $LOGFILE 2>&1
returncheck $?
echo -e "\t\tCreating symbolic link" | tee -a $LOGFILE
ln -sv libgcc.a `$LFS_TGT-gcc -print-libgcc-file-name | sed 's/libgcc/&_eh/'` >> $LOGFILE 2>&1
returncheck $?
#/specific actions
		endpackage "$CURRENTPACKAGE" "gcc-build"
	else
		echo -e "\t\tPackage already processed, skipping." 
	fi
	CURRENTNUMBER=$(($CURRENTNUMBER+1))
	echo | tee -a $LOGFILE


	#5.4. Linux-3.8.1 API Headers
	CURRENTPACKAGE="linux-3.8.1"
	preparepackage "$CURRENTNUMBER" "$TMPSYSNBFILES" "$CURRENTPACKAGE"
	if [ ! $? -eq 2 ] #if return 2 from preparepackage, package already processed : skipping
	then
		#specific actions
echo -e "\t\tmake mrproper" | tee -a $LOGFILE
make mrproper >> $LOGFILE 2>&1
returncheck $?
echo -e "\t\tmake headers_check" | tee -a $LOGFILE
make headers_check >> $LOGFILE 2>&1
returncheck $?
echo -e "\t\tmake headers_install" | tee -a $LOGFILE
make INSTALL_HDR_PATH=dest headers_install >> $LOGFILE 2>&1
returncheck $?
echo -e "\t\tpost-configuration" | tee -a $LOGFILE
cp -rv dest/include/* /tools/include >> $LOGFILE 2>&1
returncheck $?
		#/specific actions
		endpackage "$CURRENTPACKAGE"
		returncheck $?
	else
		echo -e "\t\tPackage already processed, skipping."
	fi
	CURRENTNUMBER=$(($CURRENTNUMBER+1))
	echo | tee -a $LOGFILE



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
