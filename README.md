# projects
Releases of my own software projects (including sources)

## Bash

### ubuntu/installjava.sh
This litte script will help you to install Oracle Java 7 or 8 on your Ubuntu/Debian machine.
It supports both, JDK and JRE.

After reinstalling my system I was really annoyed by the steps you have to do to install Oracle Java on your machine (most of the webbased tools require a "real" java not the IcedTea java).
This script does it all for you. You just have to download the last recent version of Oracle Java and then use the script to install it.
The script just needs one parameter, and that is the name (or better path) to the downloaded java tarball.

sh installjava.sh <java-tarball>

e.g (assuming script and tarball are in the same directory).:

sh installjava.sh jre-7u15-linux-x64.tar.gz

Sample with tarball in another directory:

sh installjava.sh /tmp/jre-7u15-linux-x64.tar.gz

### ubuntu/cleanboot.sh

On most Ubuntu installations you will get a long list of kernels in you Grub menu, because on every update of the Ubuntu-Kernel you get a new entry and the old entries are never cleaned up.
 
This script cleans this mess up. It removes all old kernels and updates the Grub menu.
This includes ALL old kernels, it only keeps the newest.
 
To discover which kernels are old it uses the creation-timestamp of the file. The starting point is determined through the kernel-version of the currently running kernel. So if you do a kernel update, please reboot before running this script. Otherwise it will not delete the old kernel, as it is the currently running kernel.
This script may be useful for other distributions (like debian) as well, but it only has been tested on Ubuntu and is explicitly written for the usage with Ubuntu Linux!

However, if you are sure on what you are doing, you can also run this script on other linux distributions as well.
 
 
*Update 2013-05-16*
The script will now also delete the /lib/modules/$KERNELNAME directories for all kernels which are no longer existing in /boot
 
*Update 2013-10-03*
Script now only deletes certain files if an old version was found
 
*Update 2013-10-09*
Fixed file encoding, which has broken the whole script (damn windows line feed -.-)
Fixed bug which prevents old kernels and modules from being deleted (wrong variable checked)
Fixed old initrd files were not deleted
Added MintLinux to the supported OS list
Beautified the output a bit
Added check for BASH, you can still continue with another interpreter, but be warned: this script is for bash!


## Perl

### mysql/mysqltool.pl

This script will help you with mysqldumps.
If you have done a backup using mysqldump you might want to restore only a particular table or database. Maybe even with another name.
You also might have the problem that your dump is very big (some gigabytes) and you cannot edit it yourself that easy...
This is where this tool will help.
It allows you to extract certain databases from a full dump and also allows renaming of tables and/or databases.

The syntax is pretty simple:

	mysqltool.pl -i [inputfile] -d [database] [-r newdatabasename] [[-t table1] [-n newtablename]|[-T table1,table2] [-N table1=newname1,table2=newname2]] [-o outputfile] [-l] [-b]

Here are some examples (also found in the perlpod-doc in the script):

**Extract 'mydatabase' from full backup**

        mysqltool.pl -i backup.sql -d mydatabase -o mydatabase.sql
        
**Extract 'mydatabase' and rename it to 'otherdatabase'**

        mysqltool.pl -i backup.sql -d mydatabase -r otherdatabase -o mydatabase.sql

**Extract 'mydatabase' and only one table**

        mysqltool.pl -i backup.sql -d mydatabase -t mytable -o mydatabase.sql

**Extract 'mydatabase' and a few tables (mytable1,mytable2) which are renamed to othertable1,othertable2**

        mysqltool.pl -i backup.sql -d mydatabase -N mytable1=othertable1,mytable2=othertable2

**Extract 'mydatabase' and a few tables were only some were renamed (mytable1 -> othertable1, mytable2 stays untouched)**

        mysqltool.pl -i backup.sql -d mydatabase -N mytable1=othertable1 -T mytable2

**Read Dump using STDIN and extract 'mydatabase' writing to STDOUT**

        cat backup.sql | mysqltool.pl -d mydatabase

**List all Databases in MySQLDump**

        mysqltool.pl -i backup.sql -b

**List all Tables in selected Database**

        mysqltool.pl -i backup.sql -d mydatabase -l


## Pascal/Free Pascal/Delphi/Lazarus

### WinKeyToggle
A small programm for disabling and re-enabling the windows-keys on the fly (without logoff or reboot).

## Legacy

In the legacy folder are old and obsolete projects, no longer maintained. They are just here for reference reasons, or if anybody wants to use them as a starting point.
