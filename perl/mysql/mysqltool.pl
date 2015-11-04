#!/usr/bin/perl
#########################################################################
#                                                                       #
#                                                                       #
# 		               MysqlTool	                        #
#                                                                       #
#               Description: Split Mysql-Dumps or rename databases/	#
#                            tables in MySQL Dumps	                #
#                                                                       #
#               (c) copyright 2012	                                #
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
#
# Author: Maniac 2012/12/17
# 
# Scriptname: mysqltool.pl
#
# Changelog:
# Version 0.1 	New:	Initial Release
# Version 0.2 	Added:	Read SQL-Dump from STDIN (enabling piping input to script) if no -i parameter specified
# Version 0.3	Added:	some perlpod documentation
# Version 0.4	Fixed:	Combinations of -T and -N parameter are now processed correctly
#		Fixed:	Database renaming now works in any case

use strict;
use warnings;
use Getopt::Std;


my $pversion = "0.4";

my %params = ();
getopts("lbd:r:t:T:o:i:n:N:h",\%params);

my $database = "";
my $outputfile = "";
my $inputfile = "";
my $newdbname = "";
my %tables = ();

my $renametable = 0;
my $renamedb = 0;
my $use_output_file = 0;
my $use_all_tables = 1;

#################### Get/Check Cmdline ARGS ###################

if (defined($params{'t'}) && defined($params{'T'})) {
	print "Confused?!\nPlease use only one table parameter (-t for one table, -T for multiple tables)\n\n";
	&usage();
	exit(1);
}
if (defined($params{'T'}) && defined($params{'n'})) {
	print "Confused?!\nParameter -n [newtablename] is not allowed in combination with -T (only -t is allowed)\n\n";
	&usage();
	exit(1);
}
if (defined($params{'t'}) && defined($params{'N'})) {
	print "Confused?!\nParameter -t [table] is not allowed in combination with -N (only -n is allowed)\n\n";
	&usage();
	exit(1);
}

if (defined($params{'h'})) {
	&usage();
	exit(0);
}


if (defined($params{'i'})) {
	if (! -e $params{'i'}) {
		print "Input-File '".$params{'i'}."' not found!\n"; 
	}
	$inputfile = $params{'i'};
}
else {
	$inputfile = "&STDIN";
}

if (defined($params{'b'}) && defined($params{'i'})) {
	my @dbs = &listdatabases($params{i});
	print "Parsing: ".$params{'i'}."\n";
	print "All databases in ".$params{'i'}."\n\n";
	foreach my $db (@dbs) {
		print "$db\n";
	}

	exit(0);
}

if (defined($params{'d'})) {
	$database = $params{'d'};
}
else {
	&usage();
	exit(1);
}

if (defined($params{'l'}) && !defined($params{'d'})) {
	print "No database selected\n";
	exit(1);
}
if (defined($params{'l'}) && defined($params{'i'}) && defined($params{'d'})) {
	my @tbls = &listtables($params{'i'},$params{'d'});
	print "Parsing: ".$params{'i'}."\n";
	print "Tables in database '".$params{'d'}."'\n\n";
	foreach my $tb (@tbls) {
		print "$tb\n";
	}
	exit(0);
}

if (defined($params{'t'})) {
	$use_all_tables = 0;
	$tables{$params{'t'}} = undef;
}
if (defined($params{'N'})) {
	$renametable = 1;
	$use_all_tables = 0;
	my @tablecombo = split(/,/,$params{'N'});
	foreach my $table (@tablecombo) {
		$table =~ s/\n|\r//g;
		my ($orgname,$newname) = split(/=/,$table);
		$tables{$orgname} = $newname;
	}
}
if (defined($params{'T'})) {
	$use_all_tables = 0;
	my @Ttables = split(/,/,$params{'T'});
	foreach my $table (@Ttables) {
		if (!defined($tables{$table})) {
			$tables{$table} = "";
		}
	}
}
if (defined($params{'n'})) {
	$use_all_tables = 0;
	$renametable = 1;
	foreach my $oldtable (keys %tables) {
		$tables{$oldtable} = $params{'n'};
		last;
	}

}
if (defined($params{'o'})) {
	$outputfile = $params{'o'};
	$use_output_file = 1;
	open(OUT,">",$outputfile);
}
if (defined($params{'r'})) {
	$renamedb = 1;
	$newdbname = $params{'r'};
}

####################### MAIN Program ##########################

my $dbflag = 0;
my $tableflag = 0;

my $new_table_name = "";
my $new_db_name = "";

my $empty = 0;
open(IN,"<".$inputfile) || die "Could not open $inputfile\n";
	while (my $line = <IN>) {
		if ($line =~ /^-- Current Database: `$database`/) {
			$dbflag = 1;
			if ($renamedb == 1) {
				$new_db_name = $newdbname;
				$line =~ s/^-- Current Database: `$database`/-- Current Database: `$new_db_name`/;	
				$empty = 0;
			}
			output($use_output_file,$line);
			next;
		}
		elsif ($line =~ /^-- Current Database: `.*`/) {
			if ($dbflag == 1) {
				$dbflag = 0;	
				# stop reading if we are on a different database than the selected one
				last;
			}
		}
		if ($use_all_tables == 0) {
			if ($line =~ /^-- Table structure for table `(.*)`/ && $dbflag > 0)  {
				if (grep(/$1/,keys %tables) > 0) {
					$tableflag = 1;
					if ($renametable == 1 && $tables{$1} ne "") {
						$new_table_name = $tables{$1};
						$line =~ s/^-- Table structure for table `(.*)`/-- Table structure for table `$new_table_name`/;
						$empty = 0;
					}
					else {
						$new_table_name = "";
					}
	
				}
				else {
					$tableflag = 0;
				}
			}
		}
		# If we found the database and want to rename it, do it here
		if ($dbflag == 1 && $renamedb == 1) {
				if ($line =~ /^CREATE DATABASE(.*)`$database`(.*)/) {
					$empty = 0;
					my $tmp = $1;
					my $tmp2 = $2;
					$line =~ s/^CREATE DATABASE(.*)`$database`(.*)/CREATE DATABASE$tmp`$new_db_name`$tmp2/;
					output($use_output_file,$line);
		                        next;	
				}
				elsif ($line =~ /^USE `$database`/) {
					$empty = 0;
					$line =~ s/^USE `$database`/USE `$new_db_name`/;
					output($use_output_file,$line);
		                        next;	

				}
				
		}
		# we found the database and one of the selected tables
		if ($tableflag == 1 && $dbflag == 1) {
			# we should rename the table, and the new name is not empty
			if ($renametable == 1 && $new_table_name ne "") {

				if ($line =~ /^CREATE TABLE `(.*)`/) {
					if (grep(/$1/,keys %tables) > 0) {
						my $tmp = $1;
						$line =~ s/^CREATE TABLE `$tmp`/CREATE TABLE `$tables{$tmp}`/;
						$empty = 0;
					}
				}
				elsif ($line =~ /^DROP TABLE IF EXISTS `(.*)`/) {
					if (grep(/$1/,keys %tables) > 0) {
						my $tmp = $1;
						$line =~ s/^DROP TABLE IF EXISTS `$tmp`/DROP TABLE IF EXISTS `$tables{$tmp}`/;
						$empty = 0;
					}
				}
				elsif ($line =~ /^ALTER TABLE `(.*)` (.*) KEYS/) {
					if (grep(/$1/,keys %tables) > 0) {
						my $tmp = $1;
						my $tmp2 = $2;
						$line =~ s/^ALTER TABLE `$tmp` $tmp2 KEYS/ALTER TABLE `$tables{$tmp}` $tmp2 KEYS/;
						$empty = 0;
					}

				}	
				elsif ($line =~ /^(\/\*!\d+) ALTER TABLE `(.*)` (.*) KEYS/) {
					my $tmp = $2;
					my $tmp2 = $1;
					my $tmp3 = $3;
					if (grep(/$tmp/,keys %tables) > 0) {
						$line =~ s/^(\/\*!\d+) ALTER TABLE `$tmp` $tmp3 KEYS/$tmp2 ALTER TABLE `$tables{$tmp}` $tmp3 KEYS/;
						$empty = 0;
					}

				}	
				elsif ($line =~ /^-- Dumping data for table `(.*)`/) {
					if (grep(/$1/,keys %tables) > 0) {
						my $tmp = $1;
						$line =~ s/^-- Dumping data for table `(.*)`/-- Dumping data for table `$tables{$tmp}`/;
						$empty = 0;
					}

				}
				elsif ($line =~ /^-- Dumping routines for table `(.*)`/) {
					if (grep(/$1/,keys %tables) > 0) {
						my $tmp = $1;
						$line =~ s/^-- Dumping routines for table `(.*)`/-- Dumping routines for table `$tables{$tmp}`/;
						$empty = 0;
					}

				}
				elsif ($line =~ /^INSERT INTO `(.*)`/) {
					if (grep(/$1/,keys %tables) > 0) {
						my $tmp = $1;
						$line =~ s/^INSERT INTO `$tmp`/INSERT INTO `$tables{$tmp}`/;
						$empty = 0;
					}

				}
				elsif ($line =~ /^LOCK TABLES `(.*)` WRITE/) {
					if (grep(/$1/,keys %tables) > 0) {
						my $tmp = $1;
						$line =~ s/^LOCK TABLES `$tmp` WRITE/LOCK TABLES `$tables{$tmp}` WRITE/;
						$empty = 0;
					}

				}
	
			}
			output($use_output_file,$line);	
		}
		# we should dump all tables, and we have already found our database
		elsif ($use_all_tables == 1 && $dbflag == 1) {
			output($use_output_file,$line);
		}
		if ($line =~ /^\/\*\!(\d)+ SET/) {
			$empty = 0;
			output($use_output_file,$line);
		}
		if ($line =~ /^-- MySQL dump (\d+)\.(\d+)$/) {
			my $ver = $1.".".$2;
			$empty = 0;
			$line =~ s/^-- MySQL dump $ver$/-- MySQL dump $ver -- Modified by $0 (Version: $pversion)/g;
			output($use_output_file,$line);
		}
		if ($line =~ /^-- Host: .*/) {
			$empty = 0;
			output($use_output_file,$line);
		}
		if ($line =~ /^-- (-+)/) {
			$empty = 0;
			output($use_output_file,$line);
		}
		if ($line =~ /^-- Server version.*/) {
			$empty = 0;
			output($use_output_file,$line);
		}
		if ((($line =~ /^$/) || ($line =~/^--$/)) && $empty == 0 ) {
			$empty = 1;
			output($use_output_file,$line);
		}
		
	}
close(IN);

if ($use_output_file > 0) {
	close(OUT);
}

####################### Some Subs #############################


#
# Desc: Prints usage message
# Params: <none>
# Returns: <none>
sub usage() {
	print "$0 -i [inputfile] -d [database] [-r newdatabasename] [[-t table1] [-n table1=newtablename]|[-T table1,table2] [-N table1=newname1,table2=newname2]] [-o outputfile] [-l] [-b]\n";
	print "\t-i\t\tFile to read from (optional, you can also use STDIN)\n";
	print "\t-o\t\tFile to write to (STDOUT otherwise)\n";
	print "\t-d\t\tDatabase to read (required)\n";
	print "\t-t\t\tTable to read (optional, requires -d)\n";
	print "\t-T\t\tMultiple comma-separated tables to read (optional, requires -d)\n";
	print "\t-n\t\tName to rename table to (optional, requires -d)\n";
	print "\t-N\t\tMultiple comma-separated list of new table names [style: oldtablename=newtablename,oldtable2=newtable2] (optional)\n";
	print "\t-r\t\tName to rename database to (optional, requires -d)\n";
	print "\t-l\t\tList all tables in selected database (required -d parameter)\n";
	print "\t-b\t\tList all databases found\n";
}

#
# Desc: prints a message either to file or to stdout
# Params: $flag, $message
# Returns: <none>
sub output {
	my $flag = shift;
	my $out = shift;

	if ($flag > 0) {
		print OUT $out;
	}
	else {
		print $out;
	}

}

#
# Desc: Lists all databases found in the given SQLDump
# Params: $dumpfile
# Returns: @databases
sub listdatabases {
	my $dumpfile = shift;
	
	if (! -e $dumpfile) {
		print "$dumpfile not found\n";
		exit(1);
	}

	my @return = ();
	open(DIN,"<",$dumpfile) || die "Could not open $dumpfile";
		while (my $line = <DIN>) {
			if ($line =~ /^-- Current Database: `(.*)`/) {
				push(@return,$1);	
			}
		}
	close(DIN);

	return @return;

}

#
# Desc: Lists all tables in the specified database
# Params: $dumpfile, $database
# Returns: @tables
sub listtables {
	my $dumpfile = shift;
	my $dbase = shift;

	if (! -e $dumpfile) {
		print "$dumpfile not found\n";
		exit(1);
	}

	my @return = ();
	my $flag = 0;
	open(DIN,"<",$dumpfile) || die "Could not open $dumpfile";
		while (my $line = <DIN>) {
			if ($line =~ /^-- Current Database: `$dbase`/) {
				$flag = 1;
			}
			elsif ($line =~ /^-- Current Database: `(.*)`/) {
				$flag = 0;
			}

			if ($flag == 1) {
				if ($line =~ /^-- Table structure for table `(.*)`/) {
					push(@return,$1);
				}
			}
		}
	close(DIN);

	return @return;

}

=head1 Usage

        mysqltool.pl -i [inputfile] -d [database] [-r newdatabasename] [[-t table1] [-n newtablename]|[-T table1,table2] [-N table1=newname1,table2=newname2]] [-o outputfile] [-l] [-b]

=over 12

=item -i [inputfile]
        
        specifies the file to read from. You can alternativly use STDIN to redirect output of e.g. cat to the script. See <Examples> 

=item -d [database]
        
        specifies the database to extract. This is required for any operation except parameter -b

=item -r [newdatabasename]

        use this parameter to rename the database

=item -t [table]

        use this if you only want to dump one table from the selected database

=item -n [newtablename]

        use this if you want to rename the table you are dumping (-t required)

=item -T [table1,table2]

        use this if you want to dump multiple tables but not all tables

=item -N [table1=newname1,table2=newname2]

        use this if you want to dump multiple tables and rename them

=item -o [outputfile]

        specifies the file to write the modified sql-dump to. If not specified STDOUT is used

=item -l
        
        shows a list of available tables (-d required)

=item -b
        
        shows a list of databases found in the dump

=back

=head1 Known Bugs

	The commented lines in the mysqldump are not 100% correct rewritten.
	Comments like:
	--
	-- Foo bar
	--

	Are truncated to
	-- Foo bar
	--

	As this these lines are only comments and not really needed by MySQL this bug should not have
	any impact on importing the modified dump

=cut


=head1 Examples


=head2 Extract 'mydatabase' from full backup

        mysqltool.pl -i backup.sql -d mydatabase -o mydatabase.sql
        
=head2 Extract 'mydatabase' and rename it to 'otherdatabase'

        mysqltool.pl -i backup.sql -d mydatabase -r otherdatabase -o mydatabase.sql

=head2 Extract 'mydatabase' and only one table

        mysqltool.pl -i backup.sql -d mydatabase -t mytable -o mydatabase.sql

=head2 Extract 'mydatabase' and a few tables (mytable1,mytable2) which are renamed to othertable1,othertable2

        mysqltool.pl -i backup.sql -d mydatabase -N mytable1=othertable1,mytable2=othertable2

=head2 Extract 'mydatabase' and a few tables were only some were renamed (mytable1 -> othertable1, mytable2 stays untouched)

        mysqltool.pl -i backup.sql -d mydatabase -N mytable1=othertable1 -T mytable2

=head2 Read Dump using STDIN and extract 'mydatabase' writing to STDOUT

        cat backup.sql | mysqltool.pl -d mydatabase 

=head2 List all Databases in MySQLDump

        mysqltool.pl -i backup.sql -b

=head2 List all Tables in selected Database

        mysqltool.pl -i backup.sql -d mydatabase -l
=cut

