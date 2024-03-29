#/bin/bash
#########################################################################
#                                                                       #
#                                                                       #
#                      JRE/JDK alternative switcher                     #
#                                                                       #
#               Description: Switches to different java version         #
#                            by using update-alternative system on      # 
#                            ubuntu/debian systems                      #
#                                                                       #
#               (c) copyright 2021                                      #
#                 by Maniac                                             #
#                                                                       #
#               Version: 0.0.2                                          #
#                                                                       #
#########################################################################
#                       License                                         #
#  This program is free software. It comes without any warranty, to     #
#  the extent permitted by applicable law. You can redistribute it      #
#  and/or modify it under the terms of the Do What The Fuck You Want    #
#  To Public License, Version 2, as published by Sam Hocevar. See       #
#  http://sam.zoy.org/wtfpl/COPYING for more details.                   #
#########################################################################
# Changelog:
#
# 2021-11-19:
#       v 0.0.3: Added jdeps, jlink, jpackage and jconsole to list of
#                applications switched
# 2021-09-24:
#	v 0.0.2: Show 'export JAVA_HOME' commandline after execution
# 2021-09-22:
#       v 0.0.1: Initial release
#
#########################################################################

LANG=C

if [ ! -f /etc/debian_version ] ; then
        echo "This script is for debian/ubuntu based systems only!"
        exit 3
fi



if [ "$(whoami)" != "root" ] ; then
	echo "Root permissions required"
	exit 1
fi

JAVA_PROCS=( "java" "javac" "javaws" "javadoc" "jps" "jar" "jdeps" "jlink" "jpackage" "jconsole" )

if [ -z "$1" ] ; then
        echo "Java version required"
        echo "Usage: $0 [java-version]"
        echo
        echo "Available versions:"
        echo "---------------------"
        update-alternatives --list java | sed 's%/bin/java%%g' | sed 's%.*/%%g'
        echo
        exit 1;
fi

IFS=$'\n'
for i in $(update-alternatives --list javac) ; do
	if [ ! -z "$(echo $i | grep "/$1")" ] || [ ! -z "$(echo $i | grep "/$1")" ] ; then
		DIR=$(dirname $i)
		for p in ${JAVA_PROCS[@]} ; do
			echo "Switching $p to $1"
			update-alternatives --set $p "$DIR/$p"
		done
		HOMEDIR=$(dirname "$DIR")
		HOMEDIR=$(echo $HOMEDIR | sed "s%//%/%g")

		echo
		echo
		echo "To update your current environment, execute:"
		echo
		echo export JAVA_HOME="$HOMEDIR"
	fi
done
