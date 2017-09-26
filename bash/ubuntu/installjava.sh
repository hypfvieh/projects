#!/bin/bash
#########################################################################
#                                                                       #
#                                                                       #
#                      JRE/JDK Installer Script				#
#                                                                       #
#               Description: Installs Oracle Java JRE/JDK from Tarball	# 
#                            and registers java/javaws and firefox	#
#			     plugin in ubuntu/debian 			#
#			     "update-alternatives" system		#
#                                                                       #
#               (c) copyright 2013-2017	                                #
#                 by Maniac                                             #
#                                                                       #
#		Version: 0.8.2						#
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
# Currently supported java versions: JRE/JDK 7, 8 and 9
#    Tested Ubuntu versions (AMD64): 12.04, 14.04, 15.10, 16.04
#
#
# Changelog:
#
# 2017-09-26:
#	v 0.8.2: Added support for jdk 9
#
# 2016-06-27:
#	v 0.8.1: Added support for ubuntu 16.04	
#
#
#########################################################################
LANG=C
TMP="/var/tmp"
INSTALLDIR="/opt/Oracle_Java"

if [ ! -f /etc/debian_version ] ; then
	echo "This installer is for debian/ubuntu based systems only!"
	exit 3
fi

if [ $(whoami) != "root" ] ; then
	echo "You have to be 'root' to install java!"
	exit 2
fi

if [ -z "$1" ] || [ ! -f "$1" ] ; then
	echo "No java-package given"
	exit 1
fi

if [ ! -d "$TMP" ] ; then
	echo "No temp directory found, please create $TMP first!"
	exit 2
fi


# Create Tempdir
mkdir -p "$TMP/$$"


FILE="$1"
# Check if it is tarball
echo "Checking File"
FTYPE=$(file -bz "$FILE" | grep "POSIX tar archive")

if [ -z "$FTYPE" ] ; then
	echo "This is not a tarball!"
	rm -rf "$TMP/$$"
	exit 1
fi


# We have a tarball, so extract it temporarily
echo "Extracting tarball"
tar xfz "$FILE" -C "$TMP/$$"
DIR=$(tar tzf "$FILE" | head -n 1)

# Try to assume Java base version (6, 7, 8, 9)
if [ ! -z "$(echo $DIR | grep '1.7')" ] ; then
	BASEVERSION=7
elif [ ! -z "$(echo $DIR | grep '1.6')" ] ; then
	BASEVERSION=6
elif [ ! -z "$(echo $DIR | grep '1.8')" ] ; then
	BASEVERSION=8
else # starting with jdk9, version of java was really called "9" instead of "1.9"
	DIR=$(tar tzf "$FILE" | head -n 1 | cut -d "/" -f 1)
	if [ ! -z "$(echo $DIR | cut -d '-' -f 2)" ] ; then
		BASEVERSION=$(echo $DIR | cut -d '-' -f 2)
	else
		echo "Unknown base version $DIR";
		exit 1
	fi
fi


# Check if target already exists
echo "Checking if install directory exists"
if [ -d "$INSTALLDIR/$DIR" ] ; then
	echo
	echo "Target directory already exists. Delete contents and use it anyway? (y/n) [n]"
	read WHY
	
	if [ "$WHY" != "y" ] && [ "$WHY" != "Y" ] ; then
		echo "Installation canceled"
		rm -rf "$TMP/$$"
		exit 
	fi
	echo
	rm -rf "$INSTALLDIR/$DIR"
fi

# Check if we have all files required for further actions
echo "Check for required files"
if [ -f "$TMP/$$/$DIR/bin/java" ] && [ -f "$TMP/$$/$DIR/bin/javaws" ] ; then

	if [ -f "$TMP/$$/$DIR/lib/"*"/libnpjp2.so" ] ; then
		MOZPLUGIN=""
	elif [ -f "$TMP/$$/$DIR/jre/lib/"*"/libnpjp2.so" ] ; then
		MOZPLUGIN="jre"
	fi

	# Workaround for new firefox-plugins directory (old: mozilla/plugins, new: firefox-addons/plugins)
	if [ -d "/usr/lib/mozilla/plugins" ] ; then
		MOZPLUGINDIR="/usr/lib/mozilla/plugins"
	elif [ -d "/usr/lib/firefox-addons/plugins" ] ; then
		MOZPLUGINDIR="/usr/lib/firefox-addons/plugins"
	fi


	echo "Creating installdir: $INSTALLDIR/$DIR"
	mkdir -p "$INSTALLDIR/$DIR"
	echo "Copying files"
	mv "$TMP/$$/$DIR/"* "$INSTALLDIR/$DIR/"

	if [ $? -eq 0 ] ; then
		echo "Installing alternatives for 'java' and 'javaws'"
		update-alternatives --install "/usr/bin/java" "java" "$INSTALLDIR/$DIR/bin/java" 1
		update-alternatives --install "/usr/bin/javaws" "javaws" "$INSTALLDIR/$DIR/bin/javaws" 1
		echo "Setting 'java' and 'javaws' to Oracle Java"
		update-alternatives --set "java" "$INSTALLDIR/$DIR/bin/java"
		update-alternatives --set "javaws" "$INSTALLDIR/$DIR/bin/javaws" 

		if [ ! -z "$MOZPLUGINDIR" ] ; then
			if [ -f "$INSTALLDIR/$DIR/$MOZPLUGIN/lib/i386/libnpjp2.so" ] ; then
				echo "Installing Firefox JAVA Plugin (i386)"
				update-alternatives --install "$MOZPLUGINDIR/mozilla-javaplugin.so" "mozilla-javaplugin.so" "$INSTALLDIR/$DIR/$MOZPLUGIN/lib/i386/libnpjp2.so" 1 
				update-alternatives --set "mozilla-javaplugin.so" "$INSTALLDIR/$DIR/$MOZPLUGIN/lib/i386/libnpjp2.so" 
			elif [ -f "$INSTALLDIR/$DIR/$MOZPLUGIN/lib/amd64/libnpjp2.so" ] ; then
				echo "Installing Firefox JAVA Plugin (amd64)"
				update-alternatives --install "$MOZPLUGINDIR/mozilla-javaplugin.so" "mozilla-javaplugin.so" "$INSTALLDIR/$DIR/$MOZPLUGIN/lib/amd64/libnpjp2.so" 1 
				update-alternatives --set "mozilla-javaplugin.so" "$INSTALLDIR/$DIR/$MOZPLUGIN/lib/amd64/libnpjp2.so" 
			elif [ -f "$INSTALLDIR/$DIR/$MOZPLUGIN/lib/libnpjp2.so" ] ; then
				echo "Installing Firefox JAVA Plugin"
				update-alternatives --install "$MOZPLUGINDIR/mozilla-javaplugin.so" "mozilla-javaplugin.so" "$INSTALLDIR/$DIR/$MOZPLUGIN/lib/libnpjp2.so" 1 
				update-alternatives --set "mozilla-javaplugin.so" "$INSTALLDIR/$DIR/$MOZPLUGIN/lib/libnpjp2.so" 

			else
				echo "No Java Browser-Plugin Found!"
			fi
		else
			echo "Cannot install firefox java plugin, don't know where to install it to"
		fi

		# check if this is a JDK, set java compiler to jdk
		if [ -f "$INSTALLDIR/$DIR/bin/javac" ] ; then
			update-alternatives --install "/usr/bin/javac" "javac" "$INSTALLDIR/$DIR/bin/javac" 1
			update-alternatives --set "javac" "$INSTALLDIR/$DIR/bin/javac"
			SYMLINKTARGET="jdk"
		else
			SYMLINKTARGET="jre"

		fi
		# add jar commandline tool
		if [ -f "$INSTALLDIR/$DIR/bin/jar" ] ; then
			update-alternatives --install "/usr/bin/jar" "jar" "$INSTALLDIR/$DIR/bin/jar" 1
			update-alternatives --set "jar" "$INSTALLDIR/$DIR/bin/jar"
		fi

		# add java process list tool
		if [ -f "$INSTALLDIR/$DIR/bin/jps" ] ; then
			update-alternatives --install "/usr/bin/jps" "jps" "$INSTALLDIR/$DIR/bin/jps" 1
			update-alternatives --set "jps" "$INSTALLDIR/$DIR/bin/jps"
		fi

		if [ ! -z "$BASEVERSION" ] ; then
			echo "Creating symlinks to $INSTALLDIR/$SYMLINKTARGET$BASEVERSION"
			if [ -L "$INSTALLDIR/$SYMLINKTARGET$BASEVERSION" ] ; then
				rm -f "$INSTALLDIR/$SYMLINKTARGET$BASEVERSION"
			fi
			ln -s "$INSTALLDIR/$DIR/" "$INSTALLDIR/$SYMLINKTARGET$BASEVERSION"
		fi

		rm -rf "$TMP/$$"
		echo "Java Installation done!"
	
	else
		echo "Error while moving JAVA into the correct install directory :("
		rm -rf "$TMP/$$"
		exit 1
	fi


else
	echo "Some files were missing, are you sure you downloaded Oracle Java?"
	rm -rf "$TMP/$$"
fi
