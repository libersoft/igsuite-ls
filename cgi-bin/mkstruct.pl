#! /usr/bin/perl
# Procedure: mkstruct.pl
# Last update: 25/05/2009
#############################################################################
# IGSuite 4.0.0 - Provides an Office Suite by  simple web interface         #
# Copyright (C) 2002 Dante Ortolani  [LucaS]                                #
#                                                                           #
# This program is free software; you can redistribute it and/or             #
# modify it under the terms of the GNU General Public License               #
# as published by the Free Software Foundation; either version 2            #
# of the License, or (at your option) any later version.                    #
#                                                                           #
# This program is distributed in the hope that it will be useful,           #
# but WITHOUT ANY WARRANTY; without even the implied warranty of            #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             #
# GNU General Public License for more details.                              #
#                                                                           #
# You should have received a copy of the GNU General Public License         #
# along with this program; if not, write to the Free Software Foundation,   #
# Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.           #
#############################################################################

####### defines acceptable command-line options ############
BEGIN                                                       #
 {                                                          #
  sub setargv                                               #
   {                                                        #
    return ( 'action:s'        => \$IG::on{action},         #
             'mode:s'          => \$IG::on{mode},           #
             'dbname:s'        => \$IG::on{dbname},         #
 	 );                                                 			#
   }                                                        #
 }                                                          #
############################################################

use strict;
use Config;
use IG;
use IG::DBStructure;
use IG::System;

IG::MkEnv(__PACKAGE__);

## Dispatch Table
IG::DTable( ckstruct        => sub { _ck_privileges() },
            default_action  => sub { _ck_privileges() },
            help            => 1 );

############################################################################
############################################################################
sub help
 {
  print "IGSuite database utility\n".
        "Just type: perl mkstruct.pl [-dbname=DBNAME]\n";
 }

############################################################################
############################################################################
sub default_action
 {
  if ( $IG::request_method eq 'commandline' )
   {
    ## requested by command-line
    print STDOUT "Just a moment...\n";
    ckstruct();
    print STDOUT "\nDone!\n\n";
    return;
   }

  HtmlHead();
  TaskHead( title => "IGSuite $IG::VERSION - MkStruct",
            width => 400,
            icon  => 1 );

  TaskMsg( $lang{error_alert_msg}, 4 );

  ## we can't use IG::FormHead here!
  PrOut "<form name=\"proto\" action=\"mkstruct.pl\" method=\"post\" target=\"_top\">".
        "<input type=\"hidden\" name=\"action\" value=\"ckstruct\">".
        "<input type=\"submit\" name=\"next\" target=\"_top\" value=\"$lang{next}\">".
        "</form>";

  HtmlFoot();
 }

############################################################################
############################################################################
sub ckstruct
 {
  ## remove old log file
  IG::FileUnlink("$IG::logs_dir${S}log.cache")
    or die( "Can't delete file '$IG::logs_dir${S}log.cache'.".
            "Please remove it manually an try again\n" );

  ## Make directory structure
  mk_directory_structure();

  ## Make database  structure
  mk_database_structure();

  ## Check and make index.html file 
  mk_index();

  ## Rewrite the JavaScript "ig.js" needed by framework
  mk_javascripts();
  
  ## Write an Apache Config file if doesn't exist
  mk_apache_config_files();

  ## Set a right shebang in all Perl scripts
  set_shebang();

  ## Set right files and directory owner permissions
  set_files_owner();

  ## Show results
  if ($IG::request_method ne "commandline")
   {
    HtmlHead();
    TaskHead( title => "IGSuite $IG::VERSION - MkStruct",
              width => 400,
              icon  => 1 );

    push @IG::errmsg, $lang{procedure_ended};
    my $logerror = "<strong>$lang{error_logs}</strong><br><br>\n";

    ## load logs
    open (LOG, '<', "$IG::logs_dir${S}log.cache")
      or die("Can't read from '$IG::logs_dir${S}log.cache'.\n");
    $logerror .= "$_ <br>" while <LOG>; 
    close(LOG);

    ## show log
    TaskMsg( $logerror, 2 );

    ## we can't use IG framework here because we can't access to database
    PrOut "<form name=\"proto\" action=\"igsuite\" method=\"post\" target=\"_top\">".
          "<input type=\"submit\" name=\"next\" target=\"_top\" value=\"$lang{next}\">".
          "</form>\n";

    HtmlFoot();
   }
 }

##########################################################################
##########################################################################
##########################################################################
##########################################################################
sub mk_index
 {
  my $index_file = "$IG::htdocs_dir${S}index.html";
  writelog("* Write index.html start file...\n");

  if (-e $index_file)
   {
    IG::FileCopy( $index_file,
                  $index_file . '.saved' );

    writelog("- Attention: index.html file rewritten.\n");
    writelog("  You can find original file in index.html.saved\n");
   }

  open (IND, '>', $index_file)
    or die("! Can't write file index.html, ".
           "check user write privileges on '$index_file'.\n");

  #XXX2FIX cgi-bin directory may change
  print IND <<END;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"
     "http://www.w3.org/TR/html4/frameset.dtd">
<html><head><title>Organizza.info</title>
<META HTTP-EQUIV="refresh" CONTENT="0; URL=/cgi-bin/igsuite">
</head>
<body>
Redirecting...
</body>
</html>

END
  close(IND);
  chmod 0664, $index_file;
 }

###########################################################################
###########################################################################
sub mk_directory_structure
 {
  ## We have to translate directory names
  writelog("* Check directory structure...\n");

  my @directory =
   ( 
	"$IG::htdocs_dir",
	"$IG::htdocs_dir${S}images",
	"$IG::htdocs_dir${S}$IG::default_lang{home}",
	"$IG::htdocs_dir${S}$IG::default_lang{home}${S}guest",
	"$IG::htdocs_dir${S}$IG::default_lang{letters}",
	"$IG::htdocs_dir${S}$IG::default_lang{letters}${S}$IG::default_lang{templates}",
	"$IG::htdocs_dir${S}$IG::default_lang{email_msgs}",
	"$IG::htdocs_dir${S}$IG::default_lang{email_msgs}${S}$IG::default_lang{templates}",
	"$IG::htdocs_dir${S}$IG::default_lang{offers}",
	"$IG::htdocs_dir${S}$IG::default_lang{offers}${S}$IG::default_lang{templates}",
	"$IG::htdocs_dir${S}$IG::default_lang{gare}",
	"$IG::htdocs_dir${S}$IG::default_lang{gare}${S}$IG::default_lang{templates}",
	"$IG::htdocs_dir${S}$IG::default_lang{orders}",
	"$IG::htdocs_dir${S}$IG::default_lang{orders}${S}$IG::default_lang{templates}",
	"$IG::htdocs_dir${S}$IG::default_lang{archive}",
	"$IG::htdocs_dir${S}$IG::default_lang{archive}${S}$IG::default_lang{templates}",
	"$IG::htdocs_dir${S}$IG::default_lang{fax_received}",
	"$IG::htdocs_dir${S}$IG::default_lang{fax_sent}",
	"$IG::htdocs_dir${S}$IG::default_lang{basket}",
	"$IG::htdocs_dir${S}$IG::default_lang{contracts}",
	"$IG::htdocs_dir${S}$IG::default_lang{contracts}${S}$IG::default_lang{templates}",
	"$IG::htdocs_dir${S}$IG::default_lang{nc_ext}",
	"$IG::htdocs_dir${S}$IG::default_lang{nc_ext}${S}$IG::default_lang{templates}",
	"$IG::htdocs_dir${S}$IG::default_lang{nc_int}",
	"$IG::htdocs_dir${S}$IG::default_lang{nc_int}${S}$IG::default_lang{templates}",
	"$IG::htdocs_dir${S}$IG::default_lang{documentation}",
	"$IG::htdocs_dir${S}$IG::default_lang{help_files}",
	"$IG::htdocs_dir${S}$IG::default_lang{equipments}",
	"$IG::cgi_dir${S}log",
	"$IG::cgi_dir${S}conf",
	"$IG::cgi_dir${S}lang",
	"$IG::cgi_dir${S}tema",
	"$IG::cgi_dir${S}IG",
	"$IG::cgi_dir${S}data",
	"$IG::cgi_dir${S}data${S}plugins",
	"$IG::cgi_dir${S}data${S}users",
	"$IG::cgi_dir${S}data${S}apache",
	"$IG::cgi_dir${S}data${S}temp",
	"$IG::cgi_dir${S}data${S}igwiki",
	"$IG::cgi_dir${S}data${S}igwiki${S}templates",
	"$IG::cgi_dir${S}data${S}repository",
	"$IG::cgi_dir${S}data${S}repository${S}archive",
	"$IG::cgi_dir${S}data${S}repository${S}binders",
	"$IG::cgi_dir${S}data${S}repository${S}todo",
	"$IG::cgi_dir${S}data${S}repository${S}calendar",
	"$IG::cgi_dir${S}data${S}repository${S}igwiki",
	"$IG::cgi_dir${S}data${S}repository${S}letters",
	"$IG::cgi_dir${S}data${S}repository${S}contacts",
	"$IG::cgi_dir${S}data${S}repository${S}contracts",
	"$IG::cgi_dir${S}data${S}repository${S}offers",
	"$IG::cgi_dir${S}data${S}repository${S}gare",
	"$IG::cgi_dir${S}data${S}repository${S}opportunities",
	"$IG::cgi_dir${S}data${S}repository${S}orders",
	"$IG::cgi_dir${S}data${S}repository${S}users",
	"$IG::cgi_dir${S}data${S}repository${S}fax_received",
	"$IG::cgi_dir${S}data${S}repository${S}fax_sent",
	"$IG::cgi_dir${S}data${S}repository${S}nc_ext",
	"$IG::cgi_dir${S}data${S}repository${S}nc_int",
	"$IG::cgi_dir${S}data${S}repository${S}vendors",
	"$IG::cgi_dir${S}data${S}repository${S}equipments",
	"$IG::cgi_dir${S}data${S}photo",
	"$IG::cgi_dir${S}data${S}photo${S}equipments",
	"$IG::cgi_dir${S}data${S}photo${S}users",
	"$IG::temp_dir",
	"$IG::logs_dir",
     );

  for my $i ( 0 .. $#directory )
   {
    if ( $i && ! -e "$directory[$i]" )
     {
      ## mk directory
      mkdir ( "$directory[$i]", 0755 )
        or die("- Can't create directory $directory[$i]\n")
     }
    else
     {
      ## directory exists let's check privilege
      if ( $IG::OS eq 'UNIX' &&  $< == 0 )
       {
        IG::SysExec ( command   => 'chmod',
                      arguments => [( '755', $directory[$i] )] )
        or die("ALERT: Can't execute: 'chmod 755 $directory[$i]'\n");
       }
     }
   }
 }

###########################################################################
###########################################################################
sub set_files_owner
 {
  ## In *nix systems we have to adjust some user file/directory privileges.
  ## If we are root we need to change owner of scripts to $www_user 
  ## because we want to be sure that $www_user has 'rwx' privileges
  ## for each IGSuite script and directory.
  ## If we are not 'root' we suppose and hope the owner is $www_user!

  if ( $IG::OS eq 'UNIX' &&  $< == 0 && $IG::www_user )
   {
    writelog("* Set right files and directories owner...\n");

    IG::SysExec ( command   => 'chown',
                  arguments => [( '-R', $IG::www_user, $IG::cgi_dir )] )
     or die("ALERT: Can't execute: 'chown -R $IG::www_user $IG::cgi_dir'\n");

    IG::SysExec ( command   => 'chown',
                  arguments => [( '-R', $IG::www_user, $IG::logs_dir )] )
     or die("ALERT: Can't execute: 'chown -R $IG::www_user $IG::logs_dir'\n");

    IG::SysExec ( command   => 'chown',
                  arguments => [( '-R', $IG::www_user, $IG::htdocs_dir )] )
     or die("ALERT: Can't execute: 'chown -R $IG::www_user $IG::htdocs_dir'\n");
   }
 }
 
###########################################################################
###########################################################################
sub set_shebang
 {
  my @row;
  my $perl;
  return if -e "/usr/bin/perl";

  for  ("c:\\igsuite\\perl\\bin\\perl.exe",
	"c:\\perl\\bin\\perl.exe",
	"d:\\perl\\bin\\perl.exe",
	"/usr/local/bin/perl",
	"/bin/perl",
	"$^X",
	"$Config{bin}${S}perl",
	"$Config{bin}${S}perl.exe" )
   { ($perl=$_) && last if -e $_ }

  die("Can't find a valid Perl interpreter ".
      "to setting a shebang in your scripts\n" ) if !$perl;

  chdir($IG::cgi_dir) if -d $IG::cgi_dir;

  for (<*>)
   {
    ## read the script
    open (IN, '<', $_);
    binmode(IN);
    my @rows = <IN>;
    close (IN);
    next if substr($rows[0],0,2) ne "\#\!";
 
    ## adjust the shebang
    $rows[0] = "\#\! $perl" .
               ( $IG::OS eq 'WINDOWS' ? "\r\n" : "\n" );

    ## rewrite modified script    
    open( OUT, '>', $_ );
    binmode(OUT);
    print OUT @rows;
    close (OUT);
   }
   
  writelog("- Changed all shebangs!\n") if $perl;
 }

###########################################################################
###########################################################################
sub mk_database_structure
 {
  my ($conn, $result, $table_name, $k);
  my @fname;
  writelog("* Check database tables structure...\n");

  if ( $on{dbname} ) 
   { $IG::db_name = $on{dbname} }
  else
   { $IG::db_name ||= 'igsuite' }


  if ( $IG::db_driver eq 'postgres' || !$IG::db_driver )
   {
    ## 	POSTGRES DRIVER (OLD) ##############################################
    eval 'require Pg';
    Pg->import;
    die("No Pg module found! remember with driver set to 'postgres' ".
        " I don't want module DBD::Pg but Pg.pm!\n") if $@; 

    ## Check Postgres
    $conn = Pg::setdbLogin(	$IG::db_host,
				$IG::db_port,
				'',
				'',
				'template1',
				$IG::db_login,
				$IG::db_password);

    if (cmp_eq(Pg->PGRES_CONNECTION_OK, $conn->status)==0)
     { die("ATTENTION! you have to check:\n".
	   " - that user $IG::db_login with $IG::db_password password can create databases;\n".
	   " - that Postgres is running on server $IG::db_host;\n".
	   " - that perl module for $IG::db_driver you are using is compatible with IG\n".
	   "   or if you want, you can read DataBase Howto section in README file distribuited with this package\n"
	  );
     }

    ## Make Database
    $conn = Pg::setdbLogin(	$IG::db_host,
				$IG::db_port,
				"",
				"",
				$IG::db_name,
				$IG::db_login,
				$IG::db_password );

    if (cmp_eq(Pg->PGRES_CONNECTION_OK, $conn->status) == 0)
     {
      $conn = Pg::setdbLogin(	$IG::db_host,
				$IG::db_port,
				"",
				"",
				"template1",
				$IG::db_login,
				$IG::db_password );

      $result = $conn->exec("CREATE DATABASE $IG::db_name");

      if (cmp_eq(Pg->PGRES_COMMAND_OK, $result->resultStatus)==0)
       { die ("Panic!: I tried to connect to postgres and create ".
		"'$IG::db_name' database, but an unknown error occurred, ".
		"pheraps I haven't right privileges to access or to create ".
		"database in mysql! Check login and password in IGSuite ".
	        "configuration file '$IG::cgi_dir${S}conf${S}igsuite.conf'\n");
       }
     }

    ## Make tables
    foreach $table_name (sort keys %db_tables_index)
     {
      my $is_a_new_table;
      writelog("* Check table '$table_name' on Database '$IG::db_name'\n");
      $conn = Pg::setdbLogin( 	$IG::db_host,
				$IG::db_port,
				"",
				"",
				$IG::db_name,
				$IG::db_login,
				$IG::db_password );

      if (cmp_eq(Pg->PGRES_CONNECTION_OK, $conn->status) == 0 )
       { die("\nATTENTION! Can't connect to $IG::db_name database\n") }  
 
      $result = $conn->exec("SELECT * FROM $table_name where 0=1");
      if (cmp_eq(Pg->PGRES_TUPLES_OK, $result->resultStatus) == 0 )
       {
        writelog("* Create table: $table_name\n");
        $result = $conn->exec("CREATE TABLE $table_name ($db_tables{$table_name}[0]{name} $db_tables{$table_name}[0]{type})");
        $result = $conn->exec("SELECT * FROM $table_name");
	$is_a_new_table++;
       }

      for ($k = 0; $k < $result->nfields; $k++)
       { $fname[$k] = $result->fname($k) }

      for my $cnt (0..$db_tables_index{$table_name}[0])
       {
        if ($db_tables{$table_name}[$cnt]{name} eq $fname[$cnt])
         { next }
        elsif ($db_tables{$table_name}[$cnt]{name} ne $fname[$cnt] && $fname[$cnt] ne "")
         {
          writelog("- ATTENTION! you have to rename manually old field".
                   " '$fname[$cnt]' in the new one".
                   " '$db_tables{$table_name}[$cnt]{name}' in table".
                   " '$table_name' and execute this application again\n" );
	  last;
         }
        else
         {
          ## Insert new field
          writelog("- Inserted field: $db_tables{$table_name}[$cnt]{name}\n");
          $result = $conn->exec("ALTER TABLE $table_name ".
                                "ADD COLUMN".
                                " $db_tables{$table_name}[$cnt]{name}".
                                " $db_tables{$table_name}[$cnt]{type}");

          ## Populate field
          if ( $db_tables{$table_name}[$cnt]{queries} )
           {
            my @queries = @{$db_tables{$table_name}[$cnt]{queries}};
            writelog("- Populated field: $db_tables{$table_name}[$cnt]{name}\n");
            for ( @queries )
             {
              $result = $conn->exec($_);
             }
           }
         }
       }

      ## Populate new table with old one
      if ($is_a_new_table && $db_tables_index{$table_name}[2])
       {
        writelog("- Populate new table $table_name with old values from $db_tables_index{$table_name}[2]\n");
        $result = $conn->exec("insert into $table_name ( select * from $db_tables_index{$table_name}[2] )");
       }

      ## Create index
      if ($db_tables_index{$table_name}[1])
       {
        my $cnt = 0;
        for (split (/\;/,$db_tables_index{$table_name}[1]))
         {
          $cnt++;
          $result = $conn->exec("DROP INDEX idx${cnt}_$table_name");
          $result = $conn->exec("CREATE INDEX idx${cnt}_$table_name ON $table_name ($_)");
          writelog("- Create index idx${cnt}_$table_name\n");
         }
       }

      @fname = ();
     }

    ## Create Views
    foreach my $view (keys %db_views)
     {
      $result = $conn->exec("DROP VIEW $view");
      $result = $conn->exec($db_views{$view});
      writelog("* Create view $view\n");
     }

    return 1;
   }
  elsif ( $IG::db_driver eq 'pg' )
   {
    ## DBD::PG DRIVER #####################################################
    require DBI;
    die("No DBI module found!\n") if $@; 

    my $drh = DBI->install_driver('Pg');
    die( "ATTENTION! you have to check:".
         " that perl module for $IG::db_driver you are using is compatible with IG\n".
         " or if you want, you can read DataBase Howto section in README file\n".
         " distribuited with this package\n" ) if !$drh;

    ## Try to connect to Database to check if already exists
    my $dbh = DBI->connect( "dbi:Pg:database=$IG::db_name;host=$IG::db_host;port=$IG::db_port",
                            $IG::db_login,
                            $IG::db_password,
                            { PrintError => 0,
                              RaiseError => 0,
                              AutoCommit => 1 }
			  );
    if ( !$dbh )
     {
      ## doesn't exist try to connect to template1 and create it
      $dbh = DBI->connect( "dbi:Pg:database=template1;host=$IG::db_host;port=$IG::db_port",
                           $IG::db_login,
                           $IG::db_password,
                           { PrintError => 0,
                             RaiseError => 0,
                             AutoCommit => 1 }
                         );
 
      die( "Panic!: I tried to connect to 'template1' to create ".
           "'$IG::db_name' database, but an unknown error occurred, ".
           "pheraps I haven't right privileges to access or to create ".
           "database in postgres! Check login and password in IGSuite ".
           "configuration file '$IG::cgi_dir${S}conf${S}igsuite.conf'\n"
         ) if !$dbh;

      ## create igsuite database
      my $result = $dbh->do( "CREATE DATABASE $IG::db_name" );
      die( "Cant' create '$IG::db_name' database! Make sure user $IG::db_login ".
           "has all privileges needed and Postgres is running.\n") if !$result;
     }

    ## Make Tables
    foreach my $table_name (sort keys %db_tables_index)
     {
      my $is_a_new_table;
      writelog("* Check table '$table_name' on database '$IG::db_name'...\n");

      $dbh = DBI->connect( "dbi:Pg:database=$IG::db_name;host=$IG::db_host;port=$IG::db_port",
                           $IG::db_login,
                           $IG::db_password,
                           { PrintError => 0,
                             RaiseError => 0,
                             AutoCommit => 1 }
			 )
        or die("\nATTENTION! can't re-connect to '$IG::db_name' database!\n");

      my $sth = $dbh->prepare("select * from $table_name where 0=1");
      $sth->execute();

      if ( $dbh->err )
       {
        writelog("* Create table: $table_name\n");

        my $result = $dbh->do( "CREATE TABLE ".
                               "$table_name ($db_tables{$table_name}[0]{name} ".
                               "$db_tables{$table_name}[0]{type})" );

        ## we have to check again table to count columns
        $sth = $dbh->prepare("select * from $table_name");
        $sth->execute();
        $is_a_new_table++;
       }

      ## check table structure
      my @fname;
      for my $k ( 0 .. $sth->{NUM_OF_FIELDS} )
       { $fname[$k] = $sth->{NAME}->[$k]; }

      for my $cnt (0..$db_tables_index{$table_name}[0])
       {
        if ($db_tables{$table_name}[$cnt]{name} eq $fname[$cnt])
         {
          if ( $on{mode} eq 'update_release' )
           {
            ## force column type
            writelog("- Force column '$db_tables{$table_name}[$cnt]{name}'".
                     "  to type '$db_tables{$table_name}[$cnt]{type}'\n");

            my $result = $dbh->do( "ALTER TABLE $table_name ".
                                   "ALTER COLUMN $db_tables{$table_name}[$cnt]{name} ".
                                   "TYPE $db_tables{$table_name}[$cnt]{type}" );
            
            writelog( "FAILED: " . $dbh->errstr . "\n" ) if !$result;
           }
          
          next;
         }
        elsif ($db_tables{$table_name}[$cnt]{name} ne $fname[$cnt] && $fname[$cnt] ne "")
         {
          writelog("- ATTENTION! you have to rename manually old field".
                   " '$fname[$cnt]' in newone".
                   " '$db_tables{$table_name}[$cnt]{name}' in table".
                   " '$table_name' and execute this application again\n" );
	  last;
         }
        else
         {
          ## Insert new field
          writelog("- Inserted field: $db_tables{$table_name}[$cnt]{name}\n");
          my $result = $dbh->do( "ALTER TABLE $table_name ".
                              "ADD COLUMN".
                              " $db_tables{$table_name}[$cnt]{name}".
                              " $db_tables{$table_name}[$cnt]{type}" );

          ## Populate field
          if ( $db_tables{$table_name}[$cnt]{queries} )
           {
            my @queries = @{$db_tables{$table_name}[$cnt]{queries}};
            writelog("- Populated field: $db_tables{$table_name}[$cnt]{name}\n");
            for ( @queries )
             {
              $dbh->do( $_ );
             }
           }
         }
       }

      ## Populate new table with old one
      if ($is_a_new_table && $db_tables_index{$table_name}[2])
       {
        writelog("- Populate new table $table_name with old values from $db_tables_index{$table_name}[2]\n");
        my $result = $dbh->do("insert into $table_name select * from $db_tables_index{$table_name}[2]");
       }

      ## reMake relative index
      if ($db_tables_index{$table_name}[1])
       {
        my $cnt = 0;
        for (split (/\;/,$db_tables_index{$table_name}[1]))
         {
          $cnt++;
          $dbh->do("DROP INDEX idx${cnt}_$table_name");
          $dbh->do("CREATE INDEX idx${cnt}_$table_name ON $table_name ($_)");
          writelog("- Create index idx${cnt}_$table_name\n");
         }
       }

      @fname = ();
     }

    ## Create Views
    foreach my $view (keys %db_views)
     {
      $dbh->do("DROP VIEW $view");
      $dbh->do($db_views{$view});
      writelog("* Create view $view\n");
     }

    return 1;
   }
  elsif ( $IG::db_driver eq 'mysql' )
   {
    ## MYSQL DRIVER #####################################################
    require DBI;
    die("No DBI module found!\n") if $@; 

    my ($drh , $dbh, $sth);

    $drh = DBI->install_driver('mysql')
      or die("ATTENTION! you have to check:\n".
	     " - that user $IG::db_login with $IG::db_password password can create databases;\n".
	     " - that Mysql is running on server $IG::db_host;\n".
	     " - that perl module for $IG::db_driver you are using is compatible with IG\n".
	     "   or if you want, you can read DataBase Howto section in README file distribuited with this package\n"
            );

    ## Make Database
    $dbh = DBI->connect("DBI:mysql:database=$IG::db_name:host=$IG::db_host:port=$IG::db_port",
			$IG::db_login,
			$IG::db_password,  {	PrintError => 0,
						RaiseError => 0,
						AutoCommit => 1
			                   }
			);
    if (!$dbh)
     {
      $dbh = DBI->connect("DBI:mysql:database=mysql:host=$IG::db_host:port=$IG::db_port",
			  $IG::db_login,
			  $IG::db_password,  {	PrintError => 0,
						RaiseError => 0,
						AutoCommit => 1
					     }
			);
      if (!$dbh)
       {
        $dbh = DBI->connect("DBI:mysql:database=test:host=$IG::db_host:port=$IG::db_port",
			    $IG::db_login,
			    $IG::db_password,   {	PrintError => 0,
							RaiseError => 0,
							AutoCommit => 1
						}
			)
	 or die ("Panic!: I tried to connect to mysql and create ".
		 "'$IG::db_name' database, but an unknown error occurred, ".
		 "pheraps I haven't right privileges to access or to create ".
		 "database in mysql! Check login and password in IGSuite ".
	         "configuration file '$IG::cgi_dir${S}conf${S}igsuite.conf'\n");
       }

      my $rc = $dbh->func('createdb',
			  $IG::db_name,
			  'admin')
         or die("Cant' create $IG::db_name database make sure $IG::db_login ".
		"user has all privileges needed and Mysql is running\n");
     }

    ## Make Tables
    foreach $table_name (sort keys %db_tables_index)
     {
      my $is_a_new_table;
      writelog("* Check table '$table_name' on database '$IG::db_name'...\n");

      $dbh = DBI->connect("DBI:mysql:database=$IG::db_name:host=$IG::db_host:port=$IG::db_port",
			  $IG::db_login,
			  $IG::db_password, {	PrintError => 0,
						RaiseError => 0,
						AutoCommit => 1
					    }
			 )
        or die("\nATTENTION! can't connect to $IG::db_name database!\n");

      $sth = $dbh->prepare("select * from $table_name where 0=1");
      $sth->execute();

      my $err = $dbh->err;
      my $errstr = $dbh->errstr;
      my $state = $dbh->state;

      if ($err)
       {
        writelog("* Create table: $table_name\n");

        $result = $dbh->do("CREATE TABLE $table_name ($db_tables{$table_name}[0]{name} $db_tables{$table_name}[0]{type})");
        $sth = $dbh->prepare("select * from $table_name");
        $sth->execute();
        $is_a_new_table++;
       }

      for ($k = 0; $k < $sth->{NUM_OF_FIELDS}; $k++)
       { $fname[$k] = $sth->{NAME}->[$k]; }

      for my $cnt (0..$db_tables_index{$table_name}[0])
       {
        if ($db_tables{$table_name}[$cnt]{name} eq $fname[$cnt])
         {
          if ( $on{mode} eq 'update_release' )
           {
            ## force column type
            writelog("- Force column '$db_tables{$table_name}[$cnt]{name}'".
                     "  to type '$db_tables{$table_name}[$cnt]{type}'\n");

            my $result = $dbh->do( "ALTER TABLE $table_name ".
                                   "MODIFY COLUMN".
                                   " $db_tables{$table_name}[$cnt]{name}".
                                   " $db_tables{$table_name}[$cnt]{type}" );
            
            writelog( "FAILED: " . $dbh->errstr . "\n" ) if !$result;
           }
          
          next;
         }
        elsif ($db_tables{$table_name}[$cnt]{name} ne $fname[$cnt] && $fname[$cnt] ne "")
         {
          writelog("- ATTENTION! you have to rename manually old field".
                   " '$fname[$cnt]' in newone".
                   " '$db_tables{$table_name}[$cnt]{name}' in table".
                   " '$table_name' and execute this application again\n" );
	  last;
         }
        else
         {
          ## Insert new field
          writelog("- Inserted field: $db_tables{$table_name}[$cnt]{name}\n");
          $result = $dbh->do( "ALTER TABLE $table_name ".
                              "ADD COLUMN".
                              " $db_tables{$table_name}[$cnt]{name}".
                              " $db_tables{$table_name}[$cnt]{type}" );

          ## Populate field
          if ( $db_tables{$table_name}[$cnt]{queries} )
           {
            my @queries = @{$db_tables{$table_name}[$cnt]{queries}};
            writelog("- Populated field: $db_tables{$table_name}[$cnt]{name}\n");
            for ( @queries )
             {
              $result = $dbh->do($_);
             }
           }
         }
       }

      ## Populate new table with old one
      if ($is_a_new_table && $db_tables_index{$table_name}[2])
       {
        writelog("- Populate new table $table_name with old values from $db_tables_index{$table_name}[2]\n");
        $result = $dbh->do("insert into $table_name select * from $db_tables_index{$table_name}[2]");
       }

      ## reMake relative index
      if ($db_tables_index{$table_name}[1])
       {
        my $cnt = 0;
        for (split (/\;/,$db_tables_index{$table_name}[1]))
         {
          $cnt++;
          $result = $dbh->do("DROP INDEX idx${cnt}_$table_name");
          $result = $dbh->do("CREATE INDEX idx${cnt}_$table_name ON $table_name ($_)");
          writelog("- Create index idx${cnt}_$table_name\n");
         }
       }

      @fname = ();
     }

    ## Create Views
    foreach my $view (keys %db_views)
     {
      $result = $dbh->do("DROP VIEW $view");
      $result = $dbh->do($db_views{$view});
      writelog("* Create view $view\n");
     }

    return 1;
   }
  elsif ( $IG::db_driver eq 'sqlite' )
   {
    ## SQLITE DRIVER #######################################################
    require DBI;
    die("No DBI module found!\n") if $@; 

    my ($drh , $dbh, $sth);

    $drh = DBI->install_driver('SQLite')
      or die("ATTENTION! you have to check:\n".
	     " - that user $IG::db_login with $IG::db_password password can create databases;\n".
	     " - that Mysql is running on server $IG::db_host;\n".
	     " - that perl module for $IG::db_driver you are using is compatible with IG\n".
	     "   or if you want, you can read DataBase Howto section in README file distribuited with this package\n"
            );

    ## Make Database
    $dbh = DBI->connect( "DBI:SQLite:".
			 "dbname=$IG::cgi_dir${S}data${S}$IG::db_name.sqlite",
      			 '',
			 '',
			 { PrintError => 0,
			   RaiseError => 0,
			   AutoCommit => 1
  			 }
		       );

    if (!$dbh)
     {
	die(	"Panic!: I tried to connect to sqlite and create ".
		 "'$IG::db_name' database, but an unknown error occurred, ".
		 "pheraps I haven't right privileges to access or to create ".
		 "an sqlite database! Check ".
	         "configuration file '$IG::cgi_dir${S}conf${S}igsuite.conf'\n");
     }
    $dbh->{AutoCommit} = 1;
    $dbh->{PrintError} = 0;
    $dbh->{RaiseError} = 0;

    ## Make Tables
    foreach $table_name (sort keys %db_tables_index)
     {
      my $is_a_new_table;
      writelog("* Check table '$table_name' on database '$IG::db_name'...\n");

      $sth = $dbh->prepare("select * from $table_name where 0=1");
      $sth->execute() if $sth;

      my $err = $dbh->err;
      my $errstr = $dbh->errstr;
      my $state = $dbh->state;

      if ($err)
       {
        writelog("* Create table: $table_name\n");

        $result = $dbh->do("CREATE TABLE $table_name ($db_tables{$table_name}[0]{name} $db_tables{$table_name}[0]{type})");
        $sth = $dbh->prepare("select * from $table_name");
        $sth->execute();
        $is_a_new_table++;
       }

      for ($k = 0; $k < $sth->{NUM_OF_FIELDS}; $k++)
       { $fname[$k] = $sth->{NAME}->[$k]; }

      for my $cnt (0..$db_tables_index{$table_name}[0])
       {
        if ($db_tables{$table_name}[$cnt]{name} eq $fname[$cnt])
         { next }
        elsif ($db_tables{$table_name}[$cnt]{name} ne $fname[$cnt] && $fname[$cnt] ne "")
         {
          writelog("- ATTENTION! you have to rename manually old field".
                   " '$fname[$cnt]' in newone".
                   " '$db_tables{$table_name}[$cnt]{name}' in table".
                   " '$table_name' and execute this application again\n" );
	  last;
         }
        else
         {
          ## Insert new field
          writelog("- Inserted field: $db_tables{$table_name}[$cnt]{name}\n"); 
          $result = $dbh->do( "ALTER TABLE $table_name ".
                              "ADD COLUMN".
                              " $db_tables{$table_name}[$cnt]{name}".
                              " $db_tables{$table_name}[$cnt]{type}" );

          ## Populate field
          if ( $db_tables{$table_name}[$cnt]{queries} )
           {
            my @queries = @{$db_tables{$table_name}[$cnt]{queries}};
            writelog("- Populated field: $db_tables{$table_name}[$cnt]{name}\n");
            for ( @queries )
             {
              $result = $dbh->do($_);
             }
           }
         }
       }

      ## Populate new table with old one
      if ($is_a_new_table && $db_tables_index{$table_name}[2])
       {
        writelog("- Populate new table $table_name with old values from $db_tables_index{$table_name}[2]\n");
        $result = $dbh->do("insert into $table_name select * from $db_tables_index{$table_name}[2]");
       }

      ## reMake relative index
      if ($db_tables_index{$table_name}[1])
       {
        my $cnt = 0;
        for (split (/\;/,$db_tables_index{$table_name}[1]))
         {
          $cnt++;
          $result = $dbh->do("DROP INDEX idx${cnt}_$table_name");
          $result = $dbh->do("CREATE INDEX idx${cnt}_$table_name ON $table_name ($_)");
          writelog("- Create index idx${cnt}_$table_name\n");
         }
       }

      @fname = ();
     }

    ## Create Views
    foreach my $view (keys %db_views)
     {
      $result = $dbh->do("DROP VIEW $view");
      $result = $dbh->do($db_views{$view});
      writelog("* Create view $view\n");
     }

    return 1;
   }
  else
   {
    ## unsupported rdbms driver
    die("Unsupported rdbms driver specified in igsuite.conf! IGSuite works ".
	"in this release only with mysql, sqlite or postgres\n");
   }
 }

###########################################################################
###########################################################################
sub mk_apache_config_files
 {
  ## write Apache users database
  my $apache_users_db = "$IG::cgi_dir${S}data${S}apache${S}igsuite_users.db";
  if ( ! -e $apache_users_db )
   {
    open( FH, '>', $apache_users_db )
      or die("Can't create Apache users database in '$apache_users_db'\n");
    close(FH);
   }

  ## write Apache groups database
  my $apache_groups_db = "$IG::cgi_dir${S}data${S}apache${S}igsuite_groups.db";
  if ( ! -e $apache_groups_db )
   {
    open( FH, '>', $apache_groups_db )
      or die("Can't create Apache groups database in '$apache_groups_db'\n");
    print FH "administrators: $IG::login_admin\n";
    close(FH);
   }

  ## write an Apache configuration to make IGSuite access more secure
  my $apache_config_file = $IG::cgi_dir . ${S} . 'conf' . ${S} . 'apache.conf';
  return if -e $apache_config_file;

  open (DET, '>', $apache_config_file)
    or die("Can't create Apache configuration file in '$apache_config_file'.\n");

  print DET <<END;
##############################################################################
##                                                                          ##
##  IGSuite 3.2 - Apache Configuration File  10.02.2007                     ##
##  By Luca Dante Ortolani lucas\@igsuite.org                                ##
##                                                                          ##
##  To rebuild this configuration file delete or rename this file and       ##
##  execute again mkstruct.pl script.                                       ##
##                                                                          ##
##  Remember you have to install Apache modules: mod_env mod_dav mod_dav_fs ##
##############################################################################

## Set an env variable to comunicate to IGSuite scripts
<IfModule mod_dav_fs.c>
 <IfModule mod_env.c>
  SetEnv APACHE_CONFIGURED_BY_IGSUITE true
 </IfModule>
</IfModule>

## Prevent logging of image requests
<IfModule mod_setenvif.c>
SetEnvIf Request_URI \\.gif image-request
SetEnvIf Request_URI \\.jpg image-request
SetEnvIf Request_URI \\.png image-request
</IfModule>

## Error logs
LogLevel error
ErrorLog "$IG::logs_dir${S}igsuite-error_log"

## Transfer logs
TransferLog "$IG::logs_dir${S}igsuite-transfer_log"

## Custom logs
CustomLog "$IG::logs_dir${S}igsuite-custom_log" common env=!image-request

## don't loose time with IP address lookups
HostnameLookups Off

## Moddav options
<IfModule mod_dav_fs.c>
 DAVLockDB "$IG::cgi_dir${S}data${S}apache${S}DAVlock"
 DAVMinTimeout 600
</IfModule>

## Cgi dir
ScriptAlias /cgi-bin/ "$IG::cgi_dir$S"
<Directory "$IG::cgi_dir">
  AllowOverride None
  Options +ExecCGI -Includes
  Order allow,deny
  Allow from all
  #Allow from 192.168.0 192.168.4
</Directory>

## Stored Documents directory      
<Directory "$IG::htdocs_dir">
  Options None
  AllowOverride None

  <IfModule mod_dav.c>
   Dav Off
  </IfModule>

  Order deny,allow
  Deny from all
  Allow from all
  #Allow from 192.168.0 192.168.4

  ## stop to file that start with '.'
  <FilesMatch "^\\.">
   deny from all
  </FilesMatch>

  AuthType Basic
  AuthName "IGSuite Server"
  AuthUserFile "$IG::cgi_dir${S}data${S}apache${S}igsuite_users.db"
  AuthGroupFile "$IG::cgi_dir${S}data${S}apache${S}igsuite_groups.db"
</Directory>

## 1 Contract
Alias "/DAV/$IG::default_lang{contracts}/" "$IG::htdocs_dir${S}$IG::default_lang{contracts}${S}"
<Location "/DAV/$IG::default_lang{contracts}">
 <IfModule mod_dav.c>
  Dav On
  Require group contracts administrators
  Satisfy all
 </IfModule>
</Location>

## 2 Offers
Alias "/DAV/$IG::default_lang{offers}/" "$IG::htdocs_dir${S}$IG::default_lang{offers}${S}"
<Location "/DAV/$IG::default_lang{offers}">
 <IfModule mod_dav.c>
  Dav On
  Require group offers administrators
  Satisfy all
 </IfModule>
</Location>

## 3 nc_ext
Alias "/DAV/$IG::default_lang{nc_ext}/" "$IG::htdocs_dir${S}$IG::default_lang{nc_ext}${S}"
<Location "/DAV/$IG::default_lang{nc_ext}">
 <IfModule mod_dav.c>
  Dav On
  Require group nc_ext administrators
  Satisfy all
 </IfModule>
</Location>

## 4 nc_int
Alias "/DAV/$IG::default_lang{nc_int}/" "$IG::htdocs_dir${S}$IG::default_lang{nc_int}${S}"
<Location "/DAV/$IG::default_lang{nc_int}">
 <IfModule mod_dav.c>
  Dav On
  Require group nc_int administrators
  Satisfy all
 </IfModule>
</Location>

## 5 letters
Alias "/DAV/$IG::default_lang{letters}/" "$IG::htdocs_dir${S}$IG::default_lang{letters}${S}"
<Location "/DAV/$IG::default_lang{letters}">
 <IfModule mod_dav.c>
  Dav On
  Require group letters administrators
  Satisfy all
 </IfModule>
</Location>

## 6 fax_sent
Alias "/DAV/$IG::default_lang{fax_sent}/" "$IG::htdocs_dir${S}$IG::default_lang{fax_sent}${S}"
<Location "/DAV/$IG::default_lang{fax_sent}">
 <IfModule mod_dav.c>
  Dav On
  Require group fax_sent administrators
  Satisfy all
 </IfModule>
</Location>

## 7 fax_received
Alias "/DAV/$IG::default_lang{fax_received}/" "$IG::htdocs_dir${S}$IG::default_lang{fax_received}${S}"
<Location "/DAV/$IG::default_lang{fax_received}">
 <IfModule mod_dav.c>
  Dav On
  Require group fax_received administrators
  Satisfy all
 </IfModule>
</Location>

## 8 archive
Alias "/DAV/$IG::default_lang{archive}/" "$IG::htdocs_dir${S}$IG::default_lang{archive}${S}"
<Location "/DAV/$IG::default_lang{archive}">
 <IfModule mod_dav.c>
  Dav On
  Require group archive administrators
  Satisfy all
 </IfModule>
</Location>

## 9 orders
Alias "/DAV/$IG::default_lang{orders}/" "$IG::htdocs_dir${S}$IG::default_lang{orders}${S}"
<Location "/DAV/$IG::default_lang{orders}">
 <IfModule mod_dav.c>
  Dav On
  Require group orders administrators
  Satisfy all
 </IfModule>
</Location>

## E emails
Alias "/DAV/$IG::default_lang{email_msgs}/" "$IG::htdocs_dir${S}$IG::default_lang{email_msgs}${S}"
<Location "/DAV/$IG::default_lang{email_msgs}">
 <IfModule mod_dav.c>
  Dav On
  Require group emails administrators
  Satisfy all
 </IfModule>
</Location>

END
  close(DET);
  writelog("* Write Apache configuration file...\n");
 }

###########################################################################
###########################################################################
sub mk_javascripts
 {
  ## write ig.js (common IG javascript)
  my $js_file = "$IG::htdocs_dir${S}images${S}ig.js";

  open (DET, '>', $js_file) or die("Can't write to '$js_file'.\n");
  print DET <<END;
// IGSuite 3.2
// JavaScript functions

// store variables to control where the popup will appear
// relative to the cursor position positive numbers are below and to
// the right of the cursor, negative numbers are above and to the left
var xOffset = 15;
var yOffset = 25;
var lastMouseX;
var lastMouseY;
var lastMouseButton;
var layer = new String();
var style = new String();
var qpv = '[Open Preview]';
var cpv = '[Close Preview]';

// Global needed by protocolInfoBox
var infoBoxTime;
var infoBoxFutureEvent;

// Find screen or frame max width and height
var maxWidth = 500;
var maxHeight = 300;

// Check if a frame exists
function ckFrame(what)
 {
  for (var i=0;i<parent.frames.length;i++)
   {
    if (parent.frames[i].name == what)
     return true;
   }
  return false;
 }
                                  
// Show Protocol Info Box
function protocolInfoBox(elemId, divName, objEvent)
 {
  if(!objEvent) objEvent = window.event;
  infoBoxFutureEvent = objEvent;
  ajaxrequest(['ajaxaction__docinfo','NO_CACHE','id__'+elemId ], [divName]);
  if ( Prototype.Browser.Safari )
   {
    clearTimeout(infoBoxTime);
    var futureShowPopup = "showPopup('" + divName + "', infoBoxFutureEvent, 1)";
    infoBoxTime = setTimeout(futureShowPopup, 1000);
   }
  else
   {
    showPopup(divName, objEvent, 1);
   }
 }

function getElementDimensions(elemID) //#XXX2TEST
 {
  var base = \$(elemID);
  var offsetTrail = base;
  var offsetLeft = 0;
  var offsetTop = 0;
  var width = 0;
  var widthOffset = 1;
    
  while (offsetTrail)
   {
    offsetLeft += offsetTrail.offsetLeft;
    offsetTop += offsetTrail.offsetTop;
    offsetTrail = offsetTrail.offsetParent;
   }

  if ( navigator.userAgent.indexOf("Mac") != -1 &&
       typeof document.body.leftMargin != "undefined" )
   {
    offsetLeft += document.body.leftMargin;
    offsetTop += document.body.topMargin;
   }
   
  //if (!isIE)
  // { width =  base.offsetWidth-widthOffset*2; }
  //else
  // { width = base.offsetWidth; }
  
  return { left:offsetLeft, 
           top:offsetTop, 
           width:base.offsetWidth, 
           height:base.offsetHeight,
           bottom:offsetTop + base.offsetHeight, 
           right:offsetLeft + width };
 }


// Generally used by Ajax
function resetDiv( divId )
 {
  document.getElementById(divId).innerHTML = "";
 }


function high(which2)
 {
  theobject = which2;
  highlighting = setInterval("highlightit(theobject)",50);
 }
 
function low(which2)
 {
  clearInterval(highlighting);
  if (which2.style.MozOpacity) which2.style.MozOpacity = 0.3
  else if (which2.filters) which2.filters.alpha.opacity = 30
 }

function highlightit(cur2)
 {
  if (cur2.style.MozOpacity<1)
   cur2.style.MozOpacity = parseFloat(cur2.style.MozOpacity)+0.1
  else if (cur2.filters&&cur2.filters.alpha.opacity<100)
   cur2.filters.alpha.opacity += 10
  else if (window.highlighting)
   clearInterval(highlighting)
 }


// Correctly handle PNG transparency in Win IE 5.5 or higher.
// http://homepage.ntlworld.com/bobosola. Updated 02-March-2004

function correctPNG() 
 {
  for(var i=0; i<document.images.length; i++)
   {
    var img = document.images[i];
    var imgName = img.src.toUpperCase();
    if (imgName.substring(imgName.length-3, imgName.length) == "PNG")
     {
      var imgID = (img.id) ? "id='" + img.id + "' " : "";
      var imgClass = (img.className) ? "class='" + img.className + "' " : "";
      var imgTitle = (img.title) ? "title='" + img.title + "' " : "title='" + img.alt + "' ";
      var imgStyle = "display:inline-block;" + img.style.cssText;
      if (img.align == "left") imgStyle = "float:left;" + imgStyle;
      if (img.align == "right") imgStyle = "float:right;" + imgStyle;
      if (img.parentElement.href) imgStyle = "cursor:hand;" + imgStyle;
      var strNewHTML = "<span " + imgID + imgClass + imgTitle
       + " style=\\"" + "width:" + img.width + "px; height:" + img.height + "px;" + imgStyle + ";"
       + "filter:progid:DXImageTransform.Microsoft.AlphaImageLoader"
       + "(src=\'" + img.src + "\', sizingMethod='scale');\\"></span>";
      img.outerHTML = strNewHTML;
      i = i-1;
     }
   }
 }


function replaceArea(areaname, toolbar, areaWidth, areaHeight)
 {
  if ( !toolbar ) { toolbar='IGBasic'; }
  if ( !areaWidth) { areaWidth='530'; }
  if ( !areaHeight) { areaHeight='530'; }

  var oFCKeditor = new FCKeditor( areaname ) ;
  oFCKeditor.Config["CustomConfigurationsPath"] = "$IG::img_url/igfckeditor.js";
  oFCKeditor.Config['DefaultLanguage'] = '$IG::default_lang';
  oFCKeditor.ToolbarSet = toolbar;
  oFCKeditor.Height = areaHeight;
  oFCKeditor.Width = areaWidth;
  oFCKeditor.BasePath = '$IG::plugin_conf{fckeditor}{webpath}';
  oFCKeditor.ReplaceTextarea() ;
 }

 
function ckCookie()
 {
  var cookieEnabled = (navigator.cookieEnabled) ? true : false

  //if not IE4+ nor NS6+
  if (typeof navigator.cookieEnabled=="undefined" && !cookieEnabled)
   {
    document.cookie = "testcookie";
    cookieEnabled = (document.cookie.indexOf("testcookie")!=-1)? true : false;
   }

  return (cookieEnabled) ? true : false;
 }                    


function getSize()
 {
  if (self.innerHeight) // all except Explorer
   {
        maxWidth = self.innerWidth;
        maxHeight = self.innerHeight;
   }
  else if (document.documentElement && document.documentElement.clientWidth)
        // Explorer 6 Strict Mode
   {
        maxWidth = document.documentElement.clientWidth;
        maxHeight = document.documentElement.clientHeight;
   }
  else if (document.body) // other Explorers
   {
        maxWidth = document.body.clientWidth;
        maxHeight = document.body.clientHeight;
   }
 }


// Javascript error handler
window.onerror = tellerror;
function tellerror(msg, url, linenumber)
 {
  alert('Error message=['+msg+'] URL=['+url+'] Line Number=['+linenumber+']');
  return true;
 }

// Needed by MkRepository
function pv(url, id, pwidth, pheight, omsg, cmsg)
 {
  qpv = omsg;
  cpv = cmsg;

  if(document.all || document.getElementById)
   {
    document.write('<a title="Click to preview" id="link'+id+'" href="'+url+'" onClick="pview(this,'+pwidth+','+pheight+');return false">'+qpv+'</a>');
   }
 }

function pview(link, pwidth, pheight)
 {
  var iframe = 'if' + link.id;
      iframe = \$(iframe);

  if(link.innerHTML == qpv)
   {
    if(iframe)
     {
      // Reuses the IFrame if open already
      iframe.src = link.href;
      iframe.style.height = pheight;
      iframe.style.visibility = 'visible';
     }
    else
     {
      // Build the Frame and Load the URL
      myBR = document.createElement('br');
      myBR.setAttribute('id','br'+link.id);
      link.parentNode.appendChild(myBR);
      myIframe = document.createElement('iframe');
      myIframe.setAttribute('id','if'+link.id);
      myIframe.setAttribute('name','myframe');
      myIframe.setAttribute('width','100%');
      myIframe.setAttribute('height',pheight);
      myIframe.setAttribute('class','pframe');
      myIframe.setAttribute('src',link.href);
      link.parentNode.appendChild(myIframe);
     }
    link.innerHTML = cpv;
   }
  else if(iframe)
   {
    myBR = 'br'+link.id;
    myBR = \$(myBR);
    link.innerHTML = qpv;
    link.parentNode.removeChild(iframe);
    link.parentNode.removeChild(myBR);
   }
 }


function setRowBorder(theRow, theBorder)
 {
  var theCells = null;

  // browser can't get the row -> exits
  if ( typeof(theRow.style) == 'undefined' )
   { return false; }

  // Gets the current row and exits if the browser can't get it
  if (typeof(document.getElementsByTagName) != 'undefined')
   { theCells = theRow.getElementsByTagName('td'); }
  else if (typeof(theRow.cells) != 'undefined')
   { theCells = theRow.cells; }
  else
   { return false; }

  var rowCellsCnt  = theCells.length;

  // Sets the new color
  var c = null;
  for (c = 0; c < rowCellsCnt; c++)
   {
     theCells[c].style.borderBottom = theBorder;
   }
  return true;
 }


// to increase or decrease textarea field
function increaseTextArea(thisTextarea, add)
 {
  var dimensions = thisTextarea.getDimensions();
  var newHeight = parseInt(dimensions.height) + add;
  thisTextarea.style.height = newHeight + "px";
 }

function decreaseTextArea(thisTextarea, subtract)
 {
  var dimensions = thisTextarea.getDimensions();

  if ((parseInt(dimensions.height) - subtract) > 20)
   {
    var newHeight = parseInt(dimensions.height) - subtract;
    thisTextarea.style.height = newHeight + "px";
   }
  else
   {
    thisTextarea.style.height = "30px";
   }
 }

// needed by Input multiselect
function moveTo(lform,lname,l1,l2)
 {
  var catList1 = eval('document.' + lform + '.' + lname + l1);
  var catList2 = eval('document.' + lform + '.' + lname + l2);
  var found = false;
  
  for (var i = catList2.length-1; i >= 0; i--)
   {
    if (catList2.options[i].selected)
     {
      var newVal = catList2.options[i].value;
      var newTex = catList2.options[i].text;
      catList1[catList1.length] = new Option(newTex,newVal);
      catList2.options[i] = null;
      found = true;
     }
   }

  if( !found )
   { alert("First select an item to move"); }
  else
   {
    var catList = eval('document.' + lform + '.' + lname + '2');
    var List = "";
    for (var i = 0; i < catList.options.length; i++)
     {
      // the '\\n' here is important to get netscape and IE on the same page
      List += catList.options[i].value + '\\n';
     }
    var myValue = eval('document.' + lform + '.' + lname);
    myValue.value = List;
   }
 }

// needed by Input multiselect
function moveUp(lform,lname,l1)
 {
  var catList = eval('document.' + lform + '.' + lname + l1);
  var found = false;

  for (var i = catList.length-1; i >= 0; i--)
   {
    if (catList.options[i].selected && !found)
     {
      var oriValue = catList.options[i].value;
      var oriText = catList.options[i].text;
      catList.options[i].value = catList.options[i-1].value;
      catList.options[i].text = catList.options[i-1].text;
      catList.options[i-1].value = oriValue;
      catList.options[i-1].text = oriText;
      catList.selectedIndex = i-1;
      found = true;
     }
   } 

  if( !found )
   { alert("First select an item to move"); }
  else
   {
    var catList = eval('document.' + lform + '.' + lname + '2');
    var List = "";
    for (var i = 0; i < catList.options.length; i++)
     {
      // the '\\n' here is important to get netscape and IE on the same page
      List += catList.options[i].value + '\\n';
     }
    var myValue = eval('document.' + lform + '.' + lname);
    myValue.value = List;
   }
 }

function moveDown(lform,lname,l1)
 {
  var catList = eval('document.' + lform + '.' + lname + l1);
  var found = false;

  for (var i = catList.length-1; i >= 0; i--)
   {
    if (catList.options[i].selected && !found)
     {
      var oriValue = catList.options[i].value;
      var oriText = catList.options[i].text;
      catList.options[i].value = catList.options[i+1].value;
      catList.options[i].text = catList.options[i+1].text;
      catList.options[i+1].value = oriValue;
      catList.options[i+1].text = oriText;
      catList.selectedIndex = i+1;
      found = true;
     }
   }

  if( !found )
   { alert("First select an item to move"); }
  else
   {
    var catList = eval('document.' + lform + '.' + lname + '2');
    var List = "";
    for (var i = 0; i < catList.options.length; i++)
     {
      // the '\\n' here is important to get netscape and IE on the same page
      List += catList.options[i].value + '\\n';
     }
    var myValue = eval('document.' + lform + '.' + lname);
    myValue.value = List;
   }
 }


// needed by MkTab to show or hide tabs
function goOver(objectId,name)
 {
  if ( !name ) { name='layer'; }
  for ( var i=0; i<=20; i++ )
   {
    var styleObject = getStyleObject(name + i);
    styleObject.visibility = 'hidden';
    styleObject.display = 'none';
   }

  var styleObject = getStyleObject(name + objectId);
  styleObject.visibility = 'inherit';
  styleObject.display = 'block';
  return true;
 }


//validate filed values
function validate(field,pattern,msg)
 {
  var regExpObj = new RegExp(pattern,"g");
  if ( !(regExpObj.test(field.value)) )
   {
    alert (msg);
    field.focus();
    field.select();
   }
 }


function getMouseOptions(e)
 {
  if (navigator.appName.indexOf("Microsoft") != -1) e = window.event;
  lastMouseX = e.screenX;
  lastMouseY = e.screenY;
  lastMouseButton = e.ctrlKey;
 }


function winPopUp(str, Width, Height, title, option)
 {
  if ( !Height ) { Height = '200'; }
  if ( !Width )  { Width  = '200'; }
  if ( !title )  { title  = 'IGSuite'; }
  if ( !option ) { option = 'location=no,status=no,dependent=yes,scrollbars=yes,resizable=yes'; }

  if (lastMouseX - Width < 0)
   { lastMouseX = Width; }
  if (lastMouseY + Height > screen.height)
   { lastMouseY -= (lastMouseY + Height + 50) - screen.height; }
  lastMouseX -= Width;
  lastMouseY += 10;

  option += ",height=" + Height + ",width=" + Width;
  option += ",left=" + lastMouseX + ",top=" + lastMouseY;
  var newwindow = window.open(str, title, option);

  if (!newwindow)
   {
    alert("A popup window could not be opened. Your browser may be blocking popups for this application.");
   }
  else
   {
    if ( typeof newwindow.name == 'undefined')
     { newwindow.name = title; }

    // In some browsers, setting the "window.opener" property to any window
    // object will make the browser believe that the window was opened with
    // Javascript so we can close it without warnings message.
    if (typeof newwindow.opener == 'undefined')
     { newwindow.opener = self; }
   }

  // return newwindow;
 }


function showPopup (targetObjectId, eventObj, objAutoHide, objWidth, objHeight)
 {
  if (!eventObj) var eventObj = window.event;

  // hide any currently-visible popups
  hideCurrentPopup();

  // stop event from bubbling up any farther
  eventObj.cancelBubble = true;
  if (eventObj.stopPropagation) eventObj.stopPropagation();

  // set a display:block attribute to the object
  changeObjectVisibility(targetObjectId, 'hidden', 'block');

  // refresh screen size available
  getSize();

  var pos = getElementDimensions(targetObjectId);
  if (!objWidth) var objWidth = pos.width;
  if (!objHeight) var objHeight = pos.height;

  // move popup div to current cursor position 
  // (add scrollTop to account for scrolling for IE)
  var posx = 0;
  var posy = 0;

  if (eventObj.pageX || eventObj.pageY)
   {
    posx = eventObj.pageX + xOffset;
    posy = eventObj.pageY + yOffset;
   }
  else if (eventObj.clientX || eventObj.clientY)
   {
    // posx = eventObj.clientX + document.body.scrollLeft + xOffset;
    // posy = eventObj.clientY + document.body.scrollTop + yOffset;
    posx = eventObj.clientX + document.body.scrollLeft + document.documentElement.scrollLeft + xOffset;
    posy = eventObj.clientY + document.body.scrollTop + document.documentElement.scrollTop + yOffset;
   }

  // modify coordinate if it's out of screen
  if (( posx + objWidth + 10) > maxWidth)
   {
    posx = posx - objWidth - 30;
   }

  // modify coordinate if it's out of screen
  if ((posy + objHeight + 10) > maxHeight)
   {
    posy = posy - objHeight - 30;
   }

  moveObject(targetObjectId, posx, posy);

  // and make it visible
  if( changeObjectVisibility(targetObjectId, 'visible', 'block') )
   {
    // if we successfully showed the popup
    // store its Id on a globally-accessible object
    if( objAutoHide ) window.currentlyVisiblePopup = targetObjectId;
    return true;
   }
  else
   {
    // we couldn't show the popup, boo hoo!
    return false;
   }
 }


function placePopup (targetObjectId, posXPopup, posYPopup, objAutoHide)
 {
  moveObject(targetObjectId, posXPopup, posYPopup);

  // and make it visible
  if( changeObjectVisibility(targetObjectId, 'visible', 'block') )
   {
    // if we successfully showed the popup
    // store its Id on a globally-accessible object
    if( objAutoHide ) window.currentlyVisiblePopup = targetObjectId;
    return true;
   }
  else
   {
    // we couldn't show the popup, boo hoo!
    return false;
   }
 }


function hideCurrentPopup()
 {
  // note: we've stored the currently-visible popup on the
  // global object window.currentlyVisiblePopup
  if(window.currentlyVisiblePopup)
   {
    changeObjectVisibility(window.currentlyVisiblePopup, 'hidden', 'none');
    window.currentlyVisiblePopup = false;
   }
 }


function hideThisPopup (targetObjectId)
 {
  if(targetObjectId)
   {
    changeObjectVisibility(targetObjectId, 'hidden', 'none');
   }
 }

function mkImgThumbs(imgList)
 {
  for (i=0; i<imgList.length; i++)
   {
    ajxImgThumbReq.delay(((i*2)+1), i, imgList);
   }
 }

function ajxImgThumbReq(imgIdx, imgList)
 {
   new Ajax.Request(imgUpdateUrl + imgList[imgIdx],
                    {
                     method:'get',
                     onSuccess: function(transport)
                      {
                       var s = transport.responseText || "";
                       if ( s )
                        {
                         \$(s).src = imgThumbUrl + s + '.png';
                         \$('qe_' + s).src = imgThumbUrl + s + '.png';
                        }
                      }
                    }
                   );
 }



// ***********************
// hacks and workarounds *
// ***********************

// setup an event handler to hide popups for generic clicks on the document
document.onclick = hideCurrentPopup;


// ************************
// layer utility routines *
// ************************


function getStyleObject(objectId)
 {
  var objectId = \$(objectId);
  return objectId ? objectId.style : false;
 }


function changeObjectVisibility(objectId, newVisibility, newDisplay)
 {
  var styleObject = getStyleObject(objectId);
  if ( styleObject )
   {
    styleObject.visibility = newVisibility;
    styleObject.display = newDisplay;
    return true;
   }
  else
   {
    return false;
   }
 }


function moveObject(objectId, newXCoordinate, newYCoordinate)
 {
  // get a reference to the cross-browser style object and make sure the object exists
  var styleObject = getStyleObject(objectId);
  if(styleObject)
   {
    if (newXCoordinate < 0)
     { newXCoordinate = 1; }
 
    if (newYCoordinate < 0)
     { newYCoordinate = 1; }

    styleObject.left = newXCoordinate;
    styleObject.top = newYCoordinate;
    return true;
   }
  else
   {
    // we couldn't find the object, so we can't very well move it
    return false;
   }
 }

END
  close(DET);
  chmod 0664, $js_file;
  writelog("* Rewritten common javascript in '$js_file'\n");

  ## write spellChecker.js (needed by spell checking)
  my $spellck_file = "$IG::htdocs_dir${S}images${S}spellChecker.js";
  open (DET, '>', $spellck_file)
    or die("Can't write to '$spellck_file'.\n");

  print DET <<END;
////////////////////////////////////////////////////
// spellChecker.js
//
// spellChecker object
//
// This file is sourced on web pages that have a textarea object to evaluate
// for spelling. It includes the implementation for the spellCheckObject.
//
////////////////////////////////////////////////////


// constructor
function spellChecker( textObject ) {

	// public properties - configurable
	this.popUpUrl = 'spellpack?action=spellchecker_html';
	this.popUpName = 'spellchecker';
	this.popUpProps = "menu=no,width=440,height=400,top=70,left=120,resizable=yes,status=yes";
	// this.spellCheckScript = '/speller/server-scripts/spellchecker.php';
	this.spellCheckScript = 'spellcheck';

	// values used to keep track of what happened to a word
	this.replWordFlag = "R";	// single replace
	this.ignrWordFlag = "I";	// single ignore
	this.replAllFlag = "RA";	// replace all occurances
	this.ignrAllFlag = "IA";	// ignore all occurances
	this.fromReplAll = "~RA";	// an occurance of a "replace all" word
	this.fromIgnrAll = "~IA";	// an occurance of a "ignore all" word
	// properties set at run time
	this.wordFlags = new Array();
	this.currentTextIndex = 0;
	this.currentWordIndex = 0;
	this.spellCheckerWin = null;
	this.controlWin = null;
	this.wordWin = null;
	this.textArea = textObject;	// deprecated
	this.textInputs = arguments; 

	// private methods
	this._spellcheck = _spellcheck;
	this._getSuggestions = _getSuggestions;
	this._setAsIgnored = _setAsIgnored;
	this._getTotalReplaced = _getTotalReplaced;
	this._setWordText = _setWordText;
	this._getFormInputs = _getFormInputs;

	// public methods
	this.openChecker = openChecker;
	this.startCheck = startCheck;
	this.checkTextBoxes = checkTextBoxes;
	this.checkTextAreas = checkTextAreas;
	this.spellCheckAll = spellCheckAll;
	this.ignoreWord = ignoreWord;
	this.ignoreAll = ignoreAll;
	this.replaceWord = replaceWord;
	this.replaceAll = replaceAll;
	this.terminateSpell = terminateSpell;
	this.undo = undo;

	// set the current window's "speller" property to the instance of this class.
	// this object can now be referenced by child windows/frames.
	window.speller = this;
}

// call this method to check all text boxes (and only text boxes) in the HTML document
function checkTextBoxes() {
	this.textInputs = this._getFormInputs( "^text\$" );
	this.openChecker();
}

// call this method to check all textareas (and only textareas ) in the HTML document
function checkTextAreas() {
	this.textInputs = this._getFormInputs( "^textarea\$" );
	this.openChecker();
}

// call this method to check all text boxes and textareas in the HTML document
function spellCheckAll() {
	this.textInputs = this._getFormInputs( "^text(area)?\$" );
	this.openChecker();
}

// call this method to check text boxe(s) and/or textarea(s) that were passed in to the
// object's constructor or to the textInputs property
function openChecker() {
	this.spellCheckerWin = window.open( this.popUpUrl, this.popUpName, this.popUpProps );
	if( !this.spellCheckerWin.opener ) {
		this.spellCheckerWin.opener = window;
	}
}

function startCheck( wordWindowObj, controlWindowObj ) {

	// set properties from args
	this.wordWin = wordWindowObj;
	this.controlWin = controlWindowObj;
	
	// reset properties
	this.wordWin.resetForm();
	this.controlWin.resetForm();
	this.currentTextIndex = 0;
	this.currentWordIndex = 0;
	// initialize the flags to an array - one element for each text input
	this.wordFlags = new Array( this.wordWin.textInputs.length );
	// each element will be an array that keeps track of each word in the text
	for( var i=0; i<this.wordFlags.length; i++ ) {
		this.wordFlags[i] = [];
	}

	// start
	this._spellcheck();
	
	return true;
}

function ignoreWord() {
	var wi = this.currentWordIndex;
	var ti = this.currentTextIndex;
	if( !this.wordWin ) {
		alert( 'Error: Word frame not available.' );
		return false;
	}
	if( !this.wordWin.getTextVal( ti, wi )) {
		alert( 'Error: "Not in dictionary" text is missing.' );
		return false;
	}
	// set as ignored
	if( this._setAsIgnored( ti, wi, this.ignrWordFlag )) {
		this.currentWordIndex++;
		this._spellcheck();
	}
}

function ignoreAll() {
	var wi = this.currentWordIndex;
	var ti = this.currentTextIndex;
	if( !this.wordWin ) {
		alert( 'Error: Word frame not available.' );
		return false;
	}
	// get the word that is currently being evaluated.
	var s_word_to_repl = this.wordWin.getTextVal( ti, wi );
	if( !s_word_to_repl ) {
		alert( 'Error: "Not in dictionary" text is missing' );
		return false;
	}

	// set this word as an "ignore all" word. 
	this._setAsIgnored( ti, wi, this.ignrAllFlag );

	// loop through all the words after this word
	for( var i = ti; i < this.wordWin.textInputs.length; i++ ) {
		for( var j = 0; j < this.wordWin.totalWords( i ); j++ ) {
			if(( i == ti && j > wi ) || i > ti ) {
				// future word: set as "from ignore all" if
				// 1) do not already have a flag and 
				// 2) have the same value as current word
				if(( this.wordWin.getTextVal( i, j ) == s_word_to_repl )
				&& ( !this.wordFlags[i][j] )) {
					this._setAsIgnored( i, j, this.fromIgnrAll );
				}
			}
		}
	}

	// finally, move on
	this.currentWordIndex++;
	this._spellcheck();
}

function replaceWord() {
	var wi = this.currentWordIndex;
	var ti = this.currentTextIndex;
	if( !this.wordWin ) {
		alert( 'Error: Word frame not available.' );
		return false;
	}
	if( !this.wordWin.getTextVal( ti, wi )) {
		alert( 'Error: "Not in dictionary" text is missing' );
		return false;
	}
	if( !this.controlWin.replacementText ) {
		return;
	}
	var txt = this.controlWin.replacementText;
	if( txt.value ) {
		var newspell = new String( txt.value );
		if( this._setWordText( ti, wi, newspell, this.replWordFlag )) {
			this.currentWordIndex++;
			this._spellcheck();
		}
	}
}

function replaceAll() {
	var ti = this.currentTextIndex;
	var wi = this.currentWordIndex;
	if( !this.wordWin ) {
		alert( 'Error: Word frame not available.' );
		return false;
	}
	var s_word_to_repl = this.wordWin.getTextVal( ti, wi );
	if( !s_word_to_repl ) {
		alert( 'Error: "Not in dictionary" text is missing' );
		return false;
	}
	var txt = this.controlWin.replacementText;
	if( !txt.value ) return;
	var newspell = new String( txt.value );

	// set this word as a "replace all" word. 
	this._setWordText( ti, wi, newspell, this.replAllFlag );

	// loop through all the words after this word
	for( var i = ti; i < this.wordWin.textInputs.length; i++ ) {
		for( var j = 0; j < this.wordWin.totalWords( i ); j++ ) {
			if(( i == ti && j > wi ) || i > ti ) {
				// future word: set word text to s_word_to_repl if
				// 1) do not already have a flag and 
				// 2) have the same value as s_word_to_repl
				if(( this.wordWin.getTextVal( i, j ) == s_word_to_repl )
				&& ( !this.wordFlags[i][j] )) {
					this._setWordText( i, j, newspell, this.fromReplAll );
				}
			}
		}
	}
	
	// finally, move on
	this.currentWordIndex++;
	this._spellcheck();
}

function terminateSpell() {
	// called when we have reached the end of the spell checking.
	var msg = "Spell check complete:\\n\\n";
	var numrepl = this._getTotalReplaced();
	if( numrepl == 0 ) {
		// see if there were no misspellings to begin with
		if( !this.wordWin ) {
			msg = "";
		} else {
			if( this.wordWin.totalMisspellings() ) {
				msg += "No words changed.";
			} else {
				msg += "No misspellings found.";
			}
		}
	} else if( numrepl == 1 ) {
		msg += "One word changed.";
	} else {
		msg += numrepl + " words changed.";
	}
	if( msg ) {
		msg += "\\n";
		alert( msg );
	}

	if( numrepl > 0 ) {
		// update the text field(s) on the opener window
		for( var i = 0; i < this.textInputs.length; i++ ) {
			// this.textArea.value = this.wordWin.text;
			if( this.wordWin ) {
				if( this.wordWin.textInputs[i] ) {
					this.textInputs[i].value = this.wordWin.textInputs[i];
				}
			}
		}
	}

	// return back to the calling window
	this.spellCheckerWin.close();

	return true;
}

function undo() {
	// skip if this is the first word!
	var ti = this.currentTextIndex;
	var wi = this.currentWordIndex
	
	if( this.wordWin.totalPreviousWords( ti, wi ) > 0 ) {
		this.wordWin.removeFocus( ti, wi );

		// go back to the last word index that was acted upon 
		do {
			// if the current word index is zero then reset the seed
			if( this.currentWordIndex == 0 && this.currentTextIndex > 0 ) {
				this.currentTextIndex--;
				this.currentWordIndex = this.wordWin.totalWords( this.currentTextIndex )-1;
				if( this.currentWordIndex < 0 ) this.currentWordIndex = 0;
			} else {
				if( this.currentWordIndex > 0 ) {
					this.currentWordIndex--;
				}
			}
		} while ( 
			this.wordWin.totalWords( this.currentTextIndex ) == 0
			|| this.wordFlags[this.currentTextIndex][this.currentWordIndex] == this.fromIgnrAll
			|| this.wordFlags[this.currentTextIndex][this.currentWordIndex] == this.fromReplAll
		); 

		var text_idx = this.currentTextIndex;
		var idx = this.currentWordIndex;
		var preReplSpell = this.wordWin.originalSpellings[text_idx][idx];
		
		// if we got back to the first word then set the Undo button back to disabled
		if( this.wordWin.totalPreviousWords( text_idx, idx ) == 0 ) {
			this.controlWin.disableUndo();
		}
	
		// examine what happened to this current word.
		switch( this.wordFlags[text_idx][idx] ) {
			// replace all: go through this and all the future occurances of the word 
			// and revert them all to the original spelling and clear their flags
			case this.replAllFlag :
				for( var i = text_idx; i < this.wordWin.textInputs.length; i++ ) {
					for( var j = 0; j < this.wordWin.totalWords( i ); j++ ) {
						if(( i == text_idx && j >= idx ) || i > text_idx ) {
							var origSpell = this.wordWin.originalSpellings[i][j];
							if( origSpell == preReplSpell ) {
								this._setWordText ( i, j, origSpell, undefined );
							}
						}
					}
				}
				break;
				
			// ignore all: go through all the future occurances of the word 
			// and clear their flags
			case this.ignrAllFlag :
				for( var i = text_idx; i < this.wordWin.textInputs.length; i++ ) {
					for( var j = 0; j < this.wordWin.totalWords( i ); j++ ) {
						if(( i == text_idx && j >= idx ) || i > text_idx ) {
							var origSpell = this.wordWin.originalSpellings[i][j];
							if( origSpell == preReplSpell ) {
								this.wordFlags[i][j] = undefined; 
							}
						}
					}
				}
				break;
				
			// replace: revert the word to its original spelling
			case this.replWordFlag :
				this._setWordText ( text_idx, idx, preReplSpell, undefined );
				break;
		}

		// For all four cases, clear the wordFlag of this word. re-start the process
		this.wordFlags[text_idx][idx] = undefined; 
		this._spellcheck();
	}
}

function _spellcheck() {
	var ww = this.wordWin;
	
	// check if this is the last word in the current text element
	if( this.currentWordIndex == ww.totalWords( this.currentTextIndex) ) {
		this.currentTextIndex++;
		this.currentWordIndex = 0;
		// keep going if we're not yet past the last text element
		if( this.currentTextIndex < this.wordWin.textInputs.length ) {	
			this._spellcheck();
			return;
		} else {
			this.terminateSpell();
			return;
		}
	}
	
	// if this is after the first one make sure the Undo button is enabled
	if( this.currentWordIndex > 0 ) {
		this.controlWin.enableUndo();
	}

	// skip the current word if it has already been worked on
	if( this.wordFlags[this.currentTextIndex][this.currentWordIndex] ) {
		// increment the global current word index and move on.
		this.currentWordIndex++;
		this._spellcheck();
	} else {
		var evalText = ww.getTextVal( this.currentTextIndex, this.currentWordIndex );
		if( evalText ) {
			this.controlWin.evaluatedText.value = evalText;
			ww.setFocus( this.currentTextIndex, this.currentWordIndex );
			this._getSuggestions( this.currentTextIndex, this.currentWordIndex );
		}
	}
}

function _getSuggestions( text_num, word_num ) {
	this.controlWin.clearSuggestions();
	// add suggestion in list for each suggested word.
	// get the array of suggested words out of the
	// three-dimensional array containing all suggestions.
	var a_suggests = this.wordWin.suggestions[text_num][word_num];	
	if( a_suggests ) {
		// got an array of suggestions.
		for( var ii = 0; ii < a_suggests.length; ii++ ) {	
			this.controlWin.addSuggestion( a_suggests[ii] );
		}
	}
	this.controlWin.selectDefaultSuggestion();
}

function _setAsIgnored( text_num, word_num, flag ) {
	// set the UI
	this.wordWin.removeFocus( text_num, word_num );
	// do the bookkeeping
	this.wordFlags[text_num][word_num] = flag;
	return true;
}

function _getTotalReplaced() {
	var i_replaced = 0;
	for( var i = 0; i < this.wordFlags.length; i++ ) {
		for( var j = 0; j < this.wordFlags[i].length; j++ ) {
			if(( this.wordFlags[i][j] == this.replWordFlag )
			|| ( this.wordFlags[i][j] == this.replAllFlag )
			|| ( this.wordFlags[i][j] == this.fromReplAll )) {
				i_replaced++;
			}
		}
	}
	return i_replaced;
}

function _setWordText( text_num, word_num, newText, flag ) {
	// set the UI and form inputs
	this.wordWin.setText( text_num, word_num, newText );
	// keep track of what happened to this word:
	this.wordFlags[text_num][word_num] = flag;
	return true;
}

function _getFormInputs( inputPattern ) {
	var inputs = new Array();
	for( var i = 0; i < document.forms.length; i++ ) {
		for( var j = 0; j < document.forms[i].elements.length; j++ ) {
			if( document.forms[i].elements[j].type.match( inputPattern )) {
				inputs[inputs.length] = document.forms[i].elements[j]; 
			}	
		}
	}
	return inputs;
}


END
  close(DET);
  chmod 0664, $spellck_file;
  writelog("* Rewritten 'spellChecker.js' in '$spellck_file'\n");
 }

###########################################################################
###########################################################################
sub cmp_eq
 {
  my ($cmp, $ret) = @_;
  return "$cmp" eq "$ret" ? 1 : 0;
 }

###########################################################################
###########################################################################
sub writelog
 {
  my ($msg) = (@_);
  open (LOG, '>>', "$IG::logs_dir${S}log.cache");
  print LOG $msg;

  if (!$ENV{'REQUEST_METHOD'})
   {
    $msg =~ s/^-/  -/;
    print $msg;
   }

  close (LOG);
 }

############################################################################
############################################################################
sub _ck_privileges
 {
  ## check user privileges
  return 1 if $IG::request_method eq 'commandline';
  return 1 if CheckPrivilege('sys_user_admin');
  
  return 0;
 }
