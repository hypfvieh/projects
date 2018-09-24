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
#               (c) copyright 2013-2018	                                #
#                 by Maniac                                             #
#                                                                       #
#		Version: 0.9.1						#
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
# 2018-09-24:
#	v 0.9.2: Added support for openjdk
#		 Added support for java/openjdk 11
#                Added flag "--install-dir" to choose a different installation base directory (otherwise target will be either /opt/openJDK or /opt/Oracle_Java depending on detected release)
#		 Added flag "--openjdk" to force installer to assume downloaded package is OpenJDK
#		 Added flag "--oracleJava" to force installer to assume downloaded package is Oracle Java release
#
# 2018-04-24:
#       v 0.9.1: Added update-alternative call for javadoc
#
# 2017-10-19:
#	v 0.9.0: Fixed symlink issue with jdk 9 when jdk has minor version too
#		 Changed behavior: Ownership/group of installation directory will be changed to root (can be disabled, see below)
#		 Added flag "--disable-alternatives" --> disable 'update-alternatives' so java is only 'extracted' but not set as default java version
#		 Added flag "--alternatives-use-symlink" --> Use symlinked path in 'update-alternatives' instead of installation path itself (will override --no-symlink)
#		 Added flag "--no-symlink" --> Disable symlinking at all
#		 Added flag "--disable-change-permission" --> Disable changing owner/group on installation directory
#		 Added flag "--set-user=USERNAME" --> Specify the user which should own the installation directory
#		 Added flag "--set-group=GROUP" --> Specify the group which should own the installation directory
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

ALLOW_ALTERNATIVES=1
ALLOW_SYMLINK=1
ALLOW_CHOWN=1

ALTERNATIVES_USE_SYMLINK=0

if [ ! -f /etc/debian_version ] ; then
	echo "This installer is for debian/ubuntu based systems only!"
	exit 3
fi

if [ $(whoami) != "root" ] ; then
	echo "You have to be 'root' to install java!"
	exit 2
fi


if [ ! -d "$TMP" ] ; then
	echo "No temp directory found, please create $TMP first!"
	exit 2
fi

JAVAOWNER=root
JAVAGROUP=root

MANUALDIR=0
OPENJDK=0
FORCERELEASE=0

OLDIFS=$IFS
IFS=$'\n'
for i in "${@}" ; do
        if [ "$i" = "--disable-alternatives" ] ; then
                ALLOW_ALTERNATIVES=0
		echo ">> Usage of 'update-alternatives' is disabled"
        elif [ "$i" = "--disable-change-permission" ] ; then
                ALLOW_CHOWN=0
		echo ">> Permission changing is disabled"
        elif [ "$i" = "--no-symlink" ] ; then
                ALLOW_SYMLINK=0
		echo ">> Symlink creation is disabled"
        elif [ "$i" = "--alternatives-use-symlink" ] ; then
                ALTERNATIVES_USE_SYMLINK=1
		if [ "$ALLOW_SYMLINK" -eq 0 ] ; then
			echo ">> Overriding --no-symlink option, symlinks are now enabled"
		fi
		ALLOW_SYMLINK=1
		echo ">> 'update-alternatives' will use symlink instead of installation directory"
        elif [ -f "$i" ] && [ -z "$FILE" ] ; then
                FILE=$i
		echo ">> Using tarball: $FILE"
		if [ "$FORCERELEASE" -eq 0 ] ; then
			FNBGN=$(basename "$FILE")
			FNBGN=${FNBGN:0:7}
			FNBGN=$(echo $FNBGN | tr '[:upper:]' '[:lower:]')
			if [ "$FNBGN" = "openjdk" ] ; then
				echo ">> Detected OpenJDK Build"
				OPENJDK=1
				if [ "$MANUALDIR" -eq 0 ] ; then
					INSTALLDIR="/opt/openJDK"
				fi
			else
				echo ">> Guessing this is a Oracle JDK/JRE"
			fi
		else
			# release is forced to be openjdk and no manual install directory is given
			if [ "$OPENJDK" -eq 1 && "$MANUALDIR" -eq 0 ] ; then
				INSTALLDIR="/opt/openJDK"
			fi
			# otherwise use default (oracle) directory or provided install base directory
		fi
		echo ">> Installing to $INSTALLDIR"
	elif [ "${i:0:11}" = "--set-user=" ] ; then
		JAVAOWNER=${i:12}
		echo ">> Using user '$JAVAOWNER' as directory owner"
	elif [ "${i:0:12}" = "--set-group=" ] ; then
		JAVAGROUP=${i:13}
		echo ">> Using group '$JAVAGROUP' as directory group owner"
	elif [ "${i:0:14}" = "--install-dir=" ] ; then
		INSTALLDIR=${i:15}
		echo ">> Using install dir '$INSTALLDIR' as target directory"
		MANUALDIR=1
	elif [ "${i:0:9}" = "--openjdk" ] ; then
		echo ">> Forcing install routine for OpenJDK"
		OPENJDK=1
		FORCERELEASE=1
	elif [ "${i:0:12}" = "--oracleJava" ] ; then
		echo ">> Forcing install routine for Oracle Java"
		OPENJDK=0
		FORCERELEASE=0
        elif [ "$i" = "--help" ] || [ "$i" = "-h" ] ; then 
                echo "Supported flags: "
                echo -en "\t--disable-alternatives\t\t Do not use 'update-alternatives to register installation to system [default: enabled]\n"
                echo -en "\t--disable-change-permission\t Do not change owner/group of installation [default: enabled]\n" 
                echo -en "\t--no-symlink\t\t\t Do not create a symlink from this installation with major version name (e.g. jdk-1.8.0_151 linked to jdk8), [default:enabled]\n"
                echo -en "\t--alternatives-use-symlink\t 'update-alternatives' will use the symlinked version for installation (see above), will override --no-symlink [default: disabled]\n"
                echo -en "\t--set-user=USERNAME\t\t Change ownership of installed java to given user [default: root]\n"
                echo -en "\t--set-group=GROUP\t\t Change group of installed java to given group [default: root]\n"
                exit 1
        fi
done
IFS=$OLDIFS

if [ -z "$FILE" ] || [ ! -f "$FILE" ] ; then
	echo "No java tarball given or tarball could not be found"
	exit 1
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
echo "Checking java version"
DIR=$(tar tzf "$FILE" | head -n 1 | cut -d "/" -f 1)

BASEVERSION=$(echo $DIR | cut -d "/" -f 1 | sed "s/[jredk\-]//g")
if [ ! -z "$(echo $BASEVERSION | grep '.')" ] ; then
	SYMLINKVER=$(echo $BASEVERSION | cut -d "." -f 1)

	if [ "$SYMLINKVER" = "1" ] ; then # java version below 9 has version info like "1.7"
		SYMLINKVER=$(echo $BASEVERSION | cut -d "." -f 2)
	fi
fi

echo "Found java version: $BASEVERSION"

echo "Extracting tarball"
tar xfz "$FILE" -C "$TMP/$$"

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

if [ -f "$TMP/$$/$DIR/bin/java" ] ; then

	# check for javaws later as this binary is no longer included in jdk builds
	HAS_JAVAWS=0
	if [ -f "$TMP/$$/$DIR/bin/javaws" ] ; then
		HAS_JAVAWS=1
	fi

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
		if [ "$ALLOW_CHOWN" -eq 1 ] ; then
			chown -R $JAVAOWNER:$JAVAGROUP "$INSTALLDIR/$DIR/"
			if [ $? -ne 0 ] ; then
				echo "Error setting ownership of new installation to $JAVAOWNER:$JAVAGROUP"
				exit 1
			fi
		fi
	
		if [ -f "$INSTALLDIR/$DIR/bin/javac" ] ; then
			SYMLINKTARGET="jdk"
		else
			SYMLINKTARGET="jre"
		fi

		if [ "$ALLOW_SYMLINK" -eq 1 ] && [ ! -z "$SYMLINKVER" ] ; then
			echo "Creating symlinks to $INSTALLDIR/$SYMLINKTARGET$SYMLINKVER"
			if [ -L "$INSTALLDIR/$SYMLINKTARGET$SYMLINKVER" ] ; then
				rm -f "$INSTALLDIR/$SYMLINKTARGET$SYMLINKVER"
			fi
			ln -s "$INSTALLDIR/$DIR/" "$INSTALLDIR/$SYMLINKTARGET$SYMLINKVER"
		fi

		if [ "$ALTERNATIVES_USE_SYMLINK" -eq 1 ] ; then
			UPDATEALTERNATIVESPATH="$INSTALLDIR/$SYMLINKTARGET$SYMLINKVER"
		else
			UPDATEALTERNATIVESPATH="$INSTALLDIR/$DIR"
		fi

		if [ $ALLOW_ALTERNATIVES -eq 1 ] ; then
			
			echo "Installing alternatives for 'java'"
			update-alternatives --install "/usr/bin/java" "java" "$UPDATEALTERNATIVESPATH/bin/java" 1
			echo -en "Updating 'java'"
			update-alternatives --set "java" "$UPDATEALTERNATIVESPATH/bin/java"

			if [ "$HAS_JAVAWS" -eq 1 ] ; then
				echo "Installing alternatives for 'javaws'"
				update-alternatives --install "/usr/bin/javaws" "javaws" "$UPDATEALTERNATIVESPATH/bin/javaws" 1

				echo "Updating 'javaws'"
				update-alternatives --set "javaws" "$UPDATEALTERNATIVESPATH/bin/javaws" 
			fi
		
			# add jar commandline tool
			if [ -f "$INSTALLDIR/$DIR/bin/jar" ] ; then
				update-alternatives --install "/usr/bin/jar" "jar" "$UPDATEALTERNATIVESPATH/bin/jar" 1
				update-alternatives --set "jar" "$UPDATEALTERNATIVESPATH/bin/jar"
			fi
			
			# add javadoc commandline tool
			if [ -f "$INSTALLDIR/$DIR/bin/javadoc" ] ; then
				update-alternatives --install "/usr/bin/javadoc" "javadoc" "$UPDATEALTERNATIVESPATH/bin/javadoc" 1
				update-alternatives --set "javadoc" "$UPDATEALTERNATIVESPATH/bin/javadoc"
			fi

			# add java process list tool
			if [ -f "$INSTALLDIR/$DIR/bin/jps" ] ; then
				update-alternatives --install "/usr/bin/jps" "jps" "$UPDATEALTERNATIVESPATH/bin/jps" 1
				update-alternatives --set "jps" "$UPDATEALTERNATIVESPATH/bin/jps"
			fi

			if [ ! -z "$MOZPLUGINDIR" ] ; then
				if [ -f "$UPDATEALTERNATIVESPATH/$MOZPLUGIN/lib/i386/libnpjp2.so" ] ; then
					echo "Installing Firefox JAVA Plugin (i386)"
					update-alternatives --install "$MOZPLUGINDIR/mozilla-javaplugin.so" "mozilla-javaplugin.so" "$UPDATEALTERNATIVESPATH/$MOZPLUGIN/lib/i386/libnpjp2.so" 1 
					update-alternatives --set "mozilla-javaplugin.so" "$INSTALLDIR/$DIR/$MOZPLUGIN/lib/i386/libnpjp2.so" 
				elif [ -f "$UPDATEALTERNATIVESPATH/$MOZPLUGIN/lib/amd64/libnpjp2.so" ] ; then
					echo "Installing Firefox JAVA Plugin (amd64)"
					update-alternatives --install "$MOZPLUGINDIR/mozilla-javaplugin.so" "mozilla-javaplugin.so" "$UPDATEALTERNATIVESPATH/$MOZPLUGIN/lib/amd64/libnpjp2.so" 1 
					update-alternatives --set "mozilla-javaplugin.so" "$UPDATEALTERNATIVESPATH/$MOZPLUGIN/lib/amd64/libnpjp2.so" 
				elif [ -f "$UPDATEALTERNATIVESPATH/$MOZPLUGIN/lib/libnpjp2.so" ] ; then
					echo "Installing Firefox JAVA Plugin"
					update-alternatives --install "$MOZPLUGINDIR/mozilla-javaplugin.so" "mozilla-javaplugin.so" "$UPDATEALTERNATIVESPATH/$MOZPLUGIN/lib/libnpjp2.so" 1 
					update-alternatives --set "mozilla-javaplugin.so" "$UPDATEALTERNATIVESPATH/$MOZPLUGIN/lib/libnpjp2.so" 
				else
					echo "No Java Browser-Plugin found (this is the regular case in java versions > 1.8)"
				fi
			else
				echo "Cannot install firefox java plugin, don't know where to install it to"
			fi

			if [ -f "$INSTALLDIR/$DIR/bin/javac" ] ; then
				update-alternatives --install "/usr/bin/javac" "javac" "$UPDATEALTERNATIVESPATH/bin/javac" 1
				update-alternatives --set "javac" "$UPDATEALTERNATIVESPATH/bin/javac"
			fi
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
