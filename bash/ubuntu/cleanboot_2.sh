#!/usr/bin/env bash

#########################################################################
#                                                                       #
#                                                                       #
#                      /boot Cleaner script                             #
#                                                                       #
#               Description: Removes old kernel and configs from        #
#			     /boot directory. It uses the creation time #
#			     to figure out which kernel is the oldest	#
#                                                                       #
#                                                                       #
#               (c) copyright 2010-2013                                 #
#                 by Maniac                                             #
#                                                                       #
#                                                                       #
#########################################################################
#                       License                                         #
#  This program is free software. It comes without any warranty, to     #
#  the extent permitted by applicable law. You can redistribute it      #
#  and/or modify it under the terms of the Do What The Fuck You Want    #
#  To Public License, Version 2, as published by Sam Hocevar. See       #
#  http://sam.zoy.org/wtfpl/COPYING for more details.                   #
#########################################################################
#
# Version 0.1: Initial Release
# Version 0.2: Better exception handling
# Version 0.3: remove obsolete modules directories, too
# Version 0.4: check if we found previous versions of each file before removing 
#              in the old version, missing vmcoreinfo causes shell comparsion failures
# Version 0.5: Fixed file encoding bug (windows line end was used instead of unix line end)
#	       Fixed bug which prevented old kernel versions from being deleted (only config, sysmap etc. were deleted)
#	       Fixed old initrd files were not deleted
#	       Added MintLinux to the supported OS list
#	       Beautified the output a bit ;)
#	       Added check for BASH, you can still continue with another interpreter, but be warned: this script is for bash!

LANG=C

KERNELVER=$(uname -r) 

DIST=$(lsb_release -i -s | tr [:upper:] [:lower:])

MODULEDIR="/lib/modules"

SUPPORTED_OS="ubuntu linuxmint"

UNSUPPORTED=1
for i in $SUPPORTED_OS ; do
	if [ "$i" = "$DIST" ] ; then
		UNSUPPORTED=0
		break
	fi
done

if [ "$UNSUPPORTED" -ge 1 ] ; then
	echo "This script is only for Ubuntu or Ubuntu based systems!"
	echo "You may damage your system if you use it anyway!"


fi
		
if [ "$(whoami)" != "root" ] ; then
	echo "Please run script as root"
	exit
fi

echo "Found running Kernel: $KERNELVER"
echo

if [ -z "$BASH_VERSION" ] ; then
	echo "It looks like you are not using bash (BASH_VERSION variable is empty!)"
	echo "Running this script with another interpreter than bash will propably break your system!"
	echo
	echo "Please ensure that you run this script with BASH"
	echo "and not with DASH or something else!"
	echo ""
	echo "Best way to run this script is using bash directly:"
	echo "$(which bash) $0"
	echo ""
fi

read -p "Start removing old kernels? (y/n) " CONT
if [ -z "$CONT" ] || [ "$CONT" = "n" ] || [ "$CONT" = "N" ] ; then
	exit
fi

echo
echo "====================================================="
echo

if [ -f "/boot/vmlinuz-$KERNELVER" ] ; then
        RUNNINGKERNEL=$(stat -c %Y /boot/vmlinuz-$KERNELVER)
fi
if [ -f "/boot/abi-$KERNELVER" ] ; then
        RUNNINGABI=$(stat -c %Y /boot/abi-$KERNELVER)
fi
if [ -f "/boot/config-$KERNELVER" ] ; then
        RUNNINGCONFIG=$(stat -c %Y /boot/config-$KERNELVER)
fi
if [ -f "/boot/initrd.img-$KERNELVER" ] ; then
        RUNNINGINITRD=$(stat -c %Y /boot/initrd.img-$KERNELVER)
fi
if [ -f "/boot/System.map-$KERNELVER" ] ; then
        RUNNINGSYSMAP=$(stat -c %Y /boot/System.map-$KERNELVER)
fi
if [ -f "/boot/vmcoreinfo-$KERNELVER" ] ; then
        RUNNINGVMCORE=$(stat -c %Y /boot/vmcoreinfo-$KERNELVER)
fi


echo "Starting cleanup"
echo

if [ ! -z "$RUNNINGKERNEL" ] ; then
	echo "Removing old Kernel versions"
	for i in $(ls -1 /boot/vmlinuz-* 2> /dev/null) ; do 

		READKERNEL=$(stat -c %Y "$i")

		if [ "$RUNNINGKERNEL" -eq "$READKERNEL" ] ; then
			echo "$i not removed, it's currently in use"		
		elif [ "$RUNNINGKERNEL" -gt "$READKERNEL" ] ; then
			echo "Removing $i"
			rm -f "$i"
		elif [ "$RUNNINGKERNEL" -ne "$READKERNEL" ] ; then
			echo "$i not removed, it's new"
		fi
	done
	echo
fi

if [ ! -z "$RUNNINGABI" ] ; then 
	echo "Removing ABI files"
	for i in $(ls -1 /boot/abi-* 2> /dev/null) ; do
		
		READABI=$(stat -c %Y "$i")

		if [ "$RUNNINGABI" -eq "$READABI" ] ; then
			echo "$i not removed, it's currently in use"		
		elif [ "$RUNNINGABI" -gt "$READABI" ] ; then
			echo "Removing $i"
			rm -f "$i"
		elif [ "$RUNNINGABI" -ne "$READABI" ] ; then
			echo "$i not removed, it's new"
		fi
	done
	echo
fi

if [ ! -z "$RUNNINGCONFIG" ] ; then
	echo "Removing kernel configs"
	for i in $(ls -1 /boot/config-* 2> /dev/null) ; do
		
		READCONFIG=$(stat -c %Y "$i")
		
		if [ "$RUNNINGCONFIG" -eq "$READCONFIG" ] ; then
			echo "$i not removed, it's currently in use"		
		elif [ "$RUNNINGCONFIG" -gt "$READCONFIG" ] ; then
			echo "Removing $i"
			rm -f "$i"
		elif [ "$RUNNINGCONFIG" -ne "$READCONFIG" ] ; then
			echo "$i not removed, it's new"
		fi
	done
	echo
fi

if [ ! -z "$RUNNINGINITRD" ] ; then
	echo "Removing old initrds"
	for i in $(ls -1 /boot/initrd.img-* 2> /dev/null) ; do
		
		READINITRD=$(stat -c %Y "$i")
		if [ "$RUNNINGINITRD" -eq "$READINITRD" ] ; then		
			echo "$i not removed, it's currently in use"		
		elif [ "$RUNNINGINITRD" -gt "$READINITRD" ] ; then
			echo "Removing $i"
			rm -f "$i"
		elif [ "$RUNNINGINITRD" -ne "$READINITRD" ] ; then
			echo "$i not removed, it's new"
		fi
	done
	echo
fi

if [ ! -z "$RUNNINGSYSMAP" ] ; then
	echo "Removing sysmaps"
	for i in $(ls -1 /boot/System.map-* 2> /dev/null) ; do
		
		READSYSMAP=$(stat -c %Y $i)
		
		if [ "$RUNNINGSYSMAP" -eq "$READSYSMAP" ] ; then
			echo "$i not removed, it's currently in use"		
		elif [ "$RUNNINGSYSMAP" -gt "$READSYSMAP" ] ; then
			echo "Removing $i"
			rm -f $i
		elif [ "$RUNNINGSYSMAP" -ne "$READSYSMAP" ] ; then
			echo "$i not removed, it's new"
		fi
	done
	echo
fi

if [ ! -z "$RUNNINGVMCORE" ] ; then
	echo "Removing vmcoreinfos"
	for i in $(ls -1 /boot/vmcoreinfo-* 2> /dev/null) ; do
		
		READVMCORE=$(stat -c %Y "$i")

		if [ "$RUNNINGVMCORE" -eq "$READVMCORE" ] ; then
			echo "$i not removed, it's currently in use"		
		elif [ "$RUNNINGVMCORE" -gt "$READVMCORE" ] ; then
			echo "Removing $i"
			rm -f "$i"
		elif [ "$RUNNINGVMCORE" -ne "$READVMCORE" ] ; then
			echo "$i not removed, it's new"
		fi
	done
	echo
fi

echo 
echo "Removing obsolete module directories"

KEEPVERSIONS=""
for i in $(ls -1 /boot/vmlinuz-*) ; do
	READ=$(echo "$i" | sed "s/vmlinuz-//g")
	KEEPVERSIONS=$KEEPVERSIONS" "$READ
done

for i in $(ls -1 $MODULEDIR) ; do
	if [ -z "$(echo $KEEPVERSIONS | grep "$i")" ] ; then
		echo "Removing modules directory: $i"
		rm -rf "$MODULEDIR/$i"
	else 
		echo "Keeping modules directory: $i - kernel still in /boot directory"
	fi

done
echo ""
echo "Cleaning done"
echo ""
echo "====================================================="
echo ""
echo "Regenerating grub.conf"
update-grub > /dev/null
echo ""
echo "grub.conf done"
echo ""
echo "====================================================="
echo "                       ALL DONE"
echo "====================================================="

