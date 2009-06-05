#! /usr/bin/perl
# Procedure: igpacman.pl
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


## PASS PHRASE PASS PHRASE PASS PHRASE PASS PHRASE PASS PHRASE PASS PHRASE ##
##                                                                         ##
## You have to set at least a passphrase to start installation.            ##
## Please remember this is Perl code! you have to respect quoting ad all   ##
## code rules to avoid errors.                                             ##
##                                                                         ##
## Example: my $pass_phrase = 'lucas';                                     ##

my $pass_phrase = '';

## BASE CONFIGURATION - ( Optional! you can leave it blank)                ##
##                                                                         ##
## try to modify these parameters according to this documentation:         ##
## (Italian) http://www.igsuite.org/cgi-bin/igwiki?name=Configurare_IG     ##
## If you leave this parameters blank here, the script will ask you about  ##
## values by a web gui.                                                    ##

my $temp_dir     = '';

my $cgi_dir      = '';
my $www_user     = '';
my $htdocs_dir   = '';
my $webpath      = ''; 

my $default_lang = '';
my $login_admin  = '';
my $pwd_admin    = '';

my $db_driver    = '';
my $db_name      = '';
my $db_login     = '';
my $db_password  = '';
my $db_host      = '';
my $db_port      = '';

#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################
#############################################################################

BEGIN
 {
  ## Errors trap .Show them in a pretty manner
  $SIG{__DIE__} =
   sub {
	my ( $pack, $file, $line, $sub ) = caller(0);
	return undef if $file =~ /eval|Config.pm/;
	delete $SIG{__DIE__};

        die if $_[0] =~ /silently/;

        my ($msg, $err) = @_, $@;
	my %tv;

	## Adjusts time and date values
	my ($s, $m, $h, $g, $me, $ye, $wday, $y, $k) = localtime(time);
	$tv{today} = sprintf("%04d-%02d-%02d", (1900+$ye), ($me+1), $g);
	$tv{time}  = sprintf("%02d:%02d", $h, $m);

        ## Print a raw html header
	print "Content-type: text/html\n\n";
	print qq~<html></head><title>IGSuite Error</title></head>
	   <style>table,td { font-size: 11px }</style>
	   <body style="background:#FFFFFF"><br><br>
	   <table align="center" style="background:white; border:1px solid black; width:400px;">
		<td style="color:white; background:gray; font-size:130%">
		IGSuite Error</td></tr>
		<td><br><table>~;

	my %values = (	Description => "<span style=\"color: #880000; ".
	                                             "font-weight:bold\">".
				       "$msg $err</span>",
			Procedure   => 'igpacman.pl',
			Perl_Version=> $],
			Date	    => "$tv{today} $tv{time}" 
		     );

	foreach (keys %values)
	 {
          print  "<tr><td valign=\"top\"><strong>$_</strong></td>".
	         "<td valign=\"top\">$values{$_}</td></tr>\n";
	 }

	print qq~<tr><td colspan=2 bgcolor="#EEEEEE">To obtain more
		information please contact your System Administrator
		or if you want, try to send this message to staff\@igsuite.org
		</td></tr></table>
		</td></tr></table>
		</body></html>~;

	die; ## silently
       };
 }

use strict;
    no strict 'refs';
use CGI qw/:standard -no_debug/;

## declare private vars
my ($OS, $S) = _ck_os();
my $perl = _find_shebang();
my @err_msg;
my $config_file;
my $action_cookie;
my @parameters = ## parameters handled by this script
    ( [ 'cgi_dir',
        'Directory where the CGI\'s are located'],
      [ 'www_user',
        'User who executes the web-server (usually: wwwrun)'],
      [ 'htdocs_dir',
        'Directory that generally coincide with your web-server DOCUMENT_ROOT'],
      [ 'webpath',
        'Path extension inside the URL (http://www.igsuite.org/<strong>extension</strong>/) if it exists.'],
      [ 'default_lang',
        'Default suite language [ en | it | fr | es | pt | nl ]'],
      [ 'login_admin',
        'IGSuite administrator access login'],
      [ 'pwd_admin',
        'IGSuite administrator access password'],
      [ 'db_driver',
        'Driver used to connect to the database server [ pg | mysql | sqlite | postgres ]'],
      [ 'db_name',
        'IGSuite Database name (default: igsuite)'],
      [ 'db_login',
        'Database server access login'],
      [ 'db_password',
        'Database server access password (if you want an empty password write "none")'],
      [ 'db_host',
        'Database server host'],
      [ 'db_port',
        'Database server port']
   );

## verify execute mode (commandline vs cgienv)
_ck_execute_mode();

## Check some system characteristic
_some_system_check();

## try to set default values only to empty ones
_set_defaults();

## check/authenticate session
my $session_cookie = _ck_session();

## load values from existing config file and overwrite
## defaults and user pre-set (in this file) values
_load_config_file();

## dispatch table
my $action_dir = param('action_dir');
my $action     =    param('action')
                 || param("action_".$action_dir)
                 || cookie('last_action')
                 || 'default_action';

if ( $action =~ /default\_action
                |collect\_values
                |write\_conf
                |ck\_values
                |ck\_database
                |preload\_package
                |install\_package
                |install\_end
                |get\_iglogo
                |htdocs\_test
                /x )
 { &{$action}; }
else
 { die("This is not a valid action!.\n");}

############################################################################
############################################################################
## STEP 1
sub default_action
 {
  ## we have to disable traps beacuse some old release of Encode.pm use eval {}
  local $SIG{__DIE__};
  local $SIG{__WARN__};

  my $errors;
  Header("<strong>STEP 1/6</strong> <u>Perl modules needed by IGSuite</u>");

  print "<div style=\"padding:5px; border:2px solid #999999; font-size:11px;".
                     "text-align:center; color:#666666; background:#CCCCCC;".
                     "width:730px;\">".
        "Detected a $OS server. Remember, to obtain Perl modules refer to ".
        "http://www.cpan.org".
        ( $OS eq 'UNIX'
          ? " or try to execute 'install_modules.pl' before this script."
          : " or try to execute 'ppm' from your Perl package." ).
        "</div>";

  print "<div style=\"width:742px; height:300px; overflow-x:visible; overflow-y:scroll;\">".
        "<table ".
        " style=\"font-size:11px; width:100%; text-align:left; color:#000000; background:#DDDDDD;\">";

  my %modules = ( 'LWP::Simple'    => { min_rel  => '',
                                        required => 'required' },
                  'LWP::UserAgent' => { min_rel  => '',
                                        required => 'optional' },
                  'Net::LDAP'      => { min_rel  => '',
                                        required => 'optional' },
                  'Data::Dumper'   => { min_rel  => '',
                                        required => 'optional' },
                  'Apache::Htpasswd' => { min_rel  => '',
                                        required => 'optional' },
                  'Unicode::String'=> { min_rel  => '',
                                        required => 'optional' },
                  'Cwd'	           => { min_rel  => '',
                                        required => 'optional' },
                  'Time::HiRes'    => { min_rel  => '',
                                        required => 'optional' },
                  'Pg'	           => { min_rel  => '',
                                        required => 'required for postgres driver' },
                  'DBD::Pg'        => { min_rel  => '',
                                        required => 'required for pg driver' },
                  'DBD::SQLite'    => { min_rel  => '',
                                        required => 'required for sqlite driver' },
                  'DBD::mysql'     => { min_rel  => '',
                                        required => 'required for mysql driver' },
                  'Config'         => { min_rel  => '',
                                        required => 'required' },
                  'Archive::Zip'   => { min_rel  => '',
                                        required => $OS eq 'WINDOWS'
                                                  ? 'required'
                                                  : 'optional' },
                  'Digest::MD5'    => { min_rel  => '',
                                        required => 'required' },
                  'HTML::Parser'   => { min_rel  => '',
                                        required => 'optional' },
                  'HTML::TreeBuilder'=> { min_rel  => '',
                                          required => 'optional' },
                  'HTML::FormatText' => { min_rel  => '',
                                          required => 'optional' },
                  'Encode'           => { min_rel  => '',
                                          required => 'optional' },
                  'Net::SMTP'        => { min_rel  => '',
                                          required => 'optional' },
                  'Net::SMTP::SSL'   => { min_rel  => '',
                                          required => 'optional' },
                  'Authen::SASL'     => { min_rel  => '',
                                          required => 'optional' },
                );

  foreach my $module ( sort keys %modules )
   {
    eval ("require $module;");
    my $availability = $@ ? 0 : 1;
    $errors++ if $modules{$module}{required} eq 'required' && !$availability;

    print "<tr><td style=\"background-color:#BBBBBB;\">$module</td>",

          "<td style=\"background-color:#CCCCCC;text-align:center;\">Version ".
          (${$module.'::VERSION'} || 'unknown')."</td>",

          "<td style=\"". ( $modules{$module}{required} eq 'required'
                            ? 'font-weight:bold;'
                            : 'font-weight:normal;').
                        "text-align:center; background-color:#CCCCCC;\">".
                        "$modules{$module}{required}</td>",

          "<td style=\"white-space:nowrap; color:#FFFFFF; width:150px; text-align:center\">",
          ( $availability
            ? '<div style="background-color:#00cc00;">AVAILABLE</div>'    
            : $modules{$module}{required} eq 'required'
              ? '<div style="background-color:#ff3300;">NOT AVAILABLE</div>'
              : '<div style="background-color:#ff9900;">NOT AVAILABLE</div>' ),
          "</td></tr>\n";
   }

  print "</table></div>";

  if ($errors)
   {
    print "<div style=\"border:2px solid #FFFFFF; background-color:#ff3300;".
          " color:#FFFFFF; padding:3px; width:730px; margin-top:15px;\">".
          "ABORT! you have to install some required Perl modules ".
          "on your system. Refere to www.cpan.org documentation ".
          "to know how to download and install missing Perl modules. ".
          "In order to have all available features from the suite please ".
          "install lacking 'optional' modules too.</div>";

    print submit( -name  => 'action_dir',
                  -value => 'Try Again',
                  -style => 'float:right; margin:20px 3px 0px 3px;'),

          hidden( -name     => 'action_Try Again',
                  -default  => 'default_action',
                  -override => 1 );
   }
  else
   {
    print "<div style=\"border:2px solid #FFFFFF; background-color:#00cc00;".
          " color:#FFFFFF; padding:3px; width:730px; margin-top:15px;\">".
          "Ok! you have all 'required' Perl modules to execute IGPacMan ".
          "and to use IGSuite. Remember if there are 'optional' ".
          "unavailable modules some features may not work correctly! ".
          "Refere to www.cpan.org documentation to know how to download ".
          "and install lacking Perl modules. </div>";

    print submit( -name  => 'action_dir',
                  -value => 'Next',
                  -style => 'float:right; margin:20px 3px 0px 3px;'),

          hidden( -name     => 'action_Next',
                  -default  => 'collect_values',
                  -override => 1 );
   }

  Footer();
 }

############################################################################
############################################################################
## STEP 2
sub collect_values
 {
  $action_cookie = cookie( -name  => 'last_action',
                           -path  => '/',
                           -value => 'collect_values' );

  Header("<strong>STEP 2/6</strong> <u>All values are mandatory!</u>");

  print "<table cellpadding=2".
        " style=\"text-align:left; width:750px; color:#000000;".
        " background:#DDDDDD;\">";

  for ( @parameters )
   {
    my ($key, $desc) = @$_;
    my $value = eval("\$$key");

    print "<tr><td style=\"vertical-align:top; background-color:#BBBBBB;\">".
          "<strong>\$$key</strong></td>".
          "<td style=\"vertical-align:top; background-color:#CCCCCC; font-size:12px\">".
          "$desc</td><td>",
          textfield(  -name      => $key,
                      -default   => $value,
                      -size      => 40,
                      -maxlength => 100 ),
          "</td></tr>";
   }
  print "</table>";

  print hidden(-name     => 'action_Next',
               -default  => 'write_conf',
               -override => 1 ),
               
        hidden(-name     => 'action_Previous',
               -default  => 'default_action',
               -override => 1 ),

        submit( -name  => 'action_dir',
                -value => 'Previous',
                -style => 'float:left; margin:20px 3px 0px 3px;' ),

        submit( -name  => 'action_dir',
                -value => 'Next',
                -style => 'float:right; margin:20px 3px 0px 3px;' );
  
  Footer();
 }
              
############################################################################
############################################################################
sub write_conf
 {
  ## open and overwrite config file
  open ( FH, '>', $config_file) 
    or die("Can't write on '$config_file'.\n");

  for ( @parameters )
   {
    my ($key, $desc) = @$_;
    my $value = $key eq 'db_password'
                && param('db_password') eq 'none' ? ''
              : $key eq 'db_port'
                && param('db_port') == 5432
                && param('db_driver') eq 'mysql'  ? 3306
              : param($key);

    print FH "\$$key = '$value';\n";
   }

  print FH "\n\n1;\n";
  close(FH) or die("Can't write on '$config_file'.\n");

  ## go to step 3
  _load_config_file();
  ck_values();
 }

############################################################################
############################################################################
## STEP 3
sub ck_values
 {
  my $errors = 0;

  $action_cookie = cookie( -name  => 'last_action',
                           -path  => '/',
                           -value => 'ck_values' );

  Header("<strong>STEP 3/6</strong> <u>Check values</u>");

  print "<table cellpadding=3 style=\"width:100%; text-align:left;".
        " color:#000000; background:#DDDDDD;\">";

  ## Check values
  $errors += _ck_result( (! -d $cgi_dir || ! -w $cgi_dir),
                        'cgi_dir',
                        "Is not a directory or is not writable by $www_user");

  $errors += _ck_result( $www_user !~ /^[A-Za-z\_][A-Za-z0-9\_\.\-]{1,31}$/,
                        'www_user',
                        "Invalid or empty web server user name");

  $errors += _ck_result( (! -d $htdocs_dir || ! -w $htdocs_dir),
                        'htdocs_dir',
                        "Is not a directory or is not writable by $www_user",
                        "OK! <a href=\"igpacman.pl?action=htdocs_test\" target=\"new\">( Test Me! )</a>" );

  $errors += _ck_result( $webpath && $webpath !~ /^[a-zA-Z0-9\_\.\-\/]{1,100}$/,
                        'webpath',
                        "Invalid or empty path extension");

  $errors += _ck_result( $default_lang !~ /^(it|en|es|pt|fr|nl)$/,
                        'default_lang',
                        "It's not a valid lang or it's empty");

  $errors += _ck_result( $login_admin !~ /^[A-Za-z\_][A-Za-z0-9\_\.\-]{1,31}$/,
                        'login_admin',
                        "Login admin must be > 2 chars and <= 32 chars");

  $errors += _ck_result( $pwd_admin !~ /^[a-zA-Z0-9\_\.\-]{4,72}$/,
                        'pwd_admin',
                        "Password admin must be > 4 chars and <= 72 chars");

  $errors += _ck_result( _is_dbdriver_unavailable(),
                        'db_driver',
                        "Invalid database driver or you don't have ".
                        "the Perl module needed by '$db_driver' driver");

  $errors += _ck_result( $db_name !~ /^[a-zA-Z0-9\_]+$/,
                        'db_name',
                        "Invalid or empty database name");
                        
  $errors += _ck_result( $db_login !~ /^[A-Za-z\_][A-Za-z0-9\_\.\-]{1,31}$/,
                        'db_login',
                        "Invalid or empty database Login");

  $errors += _ck_result( $db_password !~ /^[a-zA-Z0-9\_]{2,72}$/,
                        'db_password',
                        "Invalid or empty database Password");

  $errors += _ck_result( $db_host !~ /^[a-zA-Z0-9\_\.\-]+$/,
                        'db_host',
                        "Invalid or empty database host");

  $errors += _ck_result( $db_port !~ /^[0-9]+$/,
                        'db_port',
                        "Invalid or empty database port");

  print "</table>\n";

  print hidden( -name     =>'action_Previous',
                -default  => 'collect_values',
                -override => 1 ),

        hidden( -name     =>'action_Next',
                -default  => 'ck_database',
                -override => 1 );

  print submit( -name  => 'action_dir',
                -value => 'Previous',
                -style => 'float:left; margin:20px 3px 0px 3px;' );

  print submit( -name  => 'action_dir',
                -value => 'Next',
                -style => 'float:right; margin:20px 3px 0px 3px;'
              ) if !$errors;

  Footer();
 }

############################################################################
############################################################################
## STEP 4
sub ck_database
 {
  ## clean test_logo.gif
  if ( -e "$htdocs_dir${S}images${S}test_logo.gif" )
   {
    unlink "$htdocs_dir${S}images${S}test_logo.gif"
      or die("Can't delete '$htdocs_dir${S}images${S}test_logo.gif'.\n");
   }

  $action_cookie = cookie( -name  => 'last_action',
                           -path  => '/',
                           -value => 'ck_database' );

  Header("<strong>STEP 4/6</strong> ".
         "<u>Check access to the Database Server</u>");

  print "<table cellpadding=3".
        " style=\"text-align:left; width:100%;".
        " color:#000000; background:#DDDDDD;\">";

  my $errors = _ck_db_connection();

  print "<tr><td style=\"height:100%\"></td><td></td><td></td></tr></table>";

  print hidden( -name     => 'action_Previous',
                -default  => 'collect_values',
                -override => 1 ),

        hidden( -name     => 'action_Next',
                -default  => 'preload_package',
                -override => 1 );

  print submit( -name  => 'action_dir',
                -value => 'Previous',
                -style => 'float:left; margin:20px 3px 0px 3px;' );

  print submit( -name  => 'action_dir',
                -value => 'Next',
                -style => 'float:right; margin:20px 3px 0px 3px;'
              ) if !$errors;

  Footer();
 }

############################################################################
############################################################################
## STEP 5
sub preload_package
 {
  ## check if we have Archive::Zip
  eval ( "require Archive::Zip;" );
  my $_is_archive_zip_installed = $@ ? 0 : 1;

  my $package_file_format = $OS eq 'UNIX' && ! $_is_archive_zip_installed
                          ? '.tar.gz'
                          : '.zip';

  $action_cookie = cookie( -name  => 'last_action',
                           -path  => '/',
                           -value => 'preload_package' );

  Header("<strong>STEP 5/6</strong> <u>Load and install package</u>");

  print "<table cellpadding=13 style=\"text-align:left; width:750px; color:#000000; background:#DDDDDD;\">";

  if ( _is_internet_alive() )
   {
    print "<tr><td>URL from which to download IGSuite package in ".
          "<strong>$package_file_format format</strong></td><td>",
          textfield(-name      => 'package_url',
                    -default   => 'http://downloads.sourceforge.net/isogest/igsuite-4.0.0'.
                                  $package_file_format,
                    -size      => 50,
                    -style     => 'width:400px',
                    -maxlength => 200 ),
          "</tr>";
   }
  else
   {
    print "<tr><td style=\"font-size:10px\">".
          "It seems you don't have an active Internet connection to ".
          "download last IGSuite package. Please insert a Server File Path ".
          "from where copy and unpack a local IGSuite package or try to ".
          "reload this page again to check your Internet connection.</td>".
          "<td valign=\"top\">",
          textfield(-name      => 'package_path',
                    -default   => $OS eq 'UNIX'
                               ?  '/tmp/igsuite-4.0.0'.$package_file_format
                               :  'c:\\Temp\\igsuite-4.0.0'.$package_file_format,
                    -size      => 50,
                    -style     => 'width:400px',
                    -maxlength => 200 ),
          "</tr>";
   }

  if ( $OS eq 'UNIX' && ! $_is_archive_zip_installed )
   {
    print "<tr><td>Unpack application (we need 'tar')</td><td>".
          textfield(  -name      => 'unpack_app',
                      -default   => _find_unpack_app(),
                      -size      => 50,
                      -style     => 'width:400px',
                      -maxlength => 200 ).
          "</td></tr>";
    ## otherwise we will use Archive::Zip
   }

  print "<tr><td colspan=2 style=\"text-align:center; color:#ff3300; font-weight:bold\">".
        "&gt; This step may take a while! Several minutes! Be patient! &lt;</td></tr></table>";

  print hidden( -name     => 'action_Previous',
                -default  => 'ck_database',
                -override => 1 ),

        hidden( -name     => 'action_Next',
                -default  => 'install_package',
                -override => 1 );

  print submit( -name  => 'action_dir',
                -value => 'Previous',
                -style => 'float:left; margin:20px 3px 0px 3px;' );

  print submit( -name  => 'action_dir',
                -value => 'Next',
                -style => 'float:right; margin:20px 3px 0px 3px;' );

  Footer();
 }
 
############################################################################
############################################################################
sub install_package
 {
  my $unpack_app   = param('unpack_app');
  my $package_path = param('package_path');

  ## check if we have Archive::Zip
  eval ( "require Archive::Zip;" );
  my $_is_archive_zip_installed = $@ ? 0 : 1;

  my $package_file_format = $OS eq 'UNIX' && ! $_is_archive_zip_installed
                          ? '.tar.gz'
                          : '.zip';

  ## check unpack application if needed
  if (    $OS eq 'UNIX'
       && ! $_is_archive_zip_installed
       && ( !$unpack_app || ! -e $unpack_app || ! -x $unpack_app )
     )
   {
    push @err_msg, "Missing or invalid unpack application please ".
                   "insert a right 'tar' application.";
    preload_package();
    return;
   }

  ## set a target file name (where download or copy IGSuite package file)
  my $target_file = $temp_dir . ${S} .
                    'igsuite' . $package_file_format;

  ## delete previous package (if exists)
  if ( -e $target_file )
   {
    unlink( $target_file )
      or die("Can't delete previous old package '$target_file'. ".
             "Please do it manually!\n");
   }

  if ( $package_path )
   {
    ## copy package file from a specified path
    if ( -e $package_path && $package_path =~ /\.(tar\.gz|zip)$/ )
     {
      FileCopy( $package_path, $target_file ) if $package_path ne $target_file;
     }
    else
     {
      push @err_msg, "You specified an invalid file path. Plase be sure ".
                     "file '$package_path' exists on your server and it's an ".
                     "official IGSuite package ($package_file_format format)!.\n";
      preload_package();
      return;
     }
   }
  else
   {
    ## download package
    eval ( "require LWP::Simple;" );
    die("Can't load Perl module LWP::Simple we need it to download package. ".
        "Please install it and try again.\n") if $@;

    my $rc = LWP::Simple::getstore( param('package_url'), $target_file );

    if ( LWP::Simple::is_error($rc) || ! -e $target_file )
     {
      push @err_msg, "Can't download package! Error:$rc";
      preload_package();
      return;
     }
   }

  ## unpack package
  if ($OS eq 'UNIX' && ! $_is_archive_zip_installed)
   {
    ## unpack by an external 'tar' application
    chdir($temp_dir) or die("Can't chdir to '$temp_dir'.\n");
    my $unpack_status = `$unpack_app -zxvf "$target_file"`;
   }
  else
   {
    ## unpack by Archive::Zip
    no strict 'subs';
    require Archive::Zip;
    chdir($temp_dir) or die("Can't chdir to '$temp_dir'.\n");
    my $zip = Archive::Zip->new();
    unless ( $zip->read( $target_file ) == Archive::Zip::AZ_OK )
     { die "whoops! Can't read '$target_file'.\n"; }
    unless ($zip->extractTree() == Archive::Zip::AZ_OK )
     { die "whoops! Can't extract files from '$target_file'.\n"; }
   }

  ## check unpacked package
  my $pack_release = param('package_url') || param('package_path');
     $pack_release =~ /(igsuite\-)([abc0-9\.]+)(\.tar\.gz|\.zip)$/;
     $pack_release = $1 . $2; 
  my $release_num  = $2;

  if ( !$pack_release || ! -e "$temp_dir${S}$pack_release${S}install.pl" )
   {
    push @err_msg, "I don't think this is a real IGSuite package! ".
                   "I can't find install.pl script inside the package. ".
                   "Is '$pack_release' release an original IGSuite package?\n";
    preload_package();
    return;
   }

  ## check pack release number
  die("ABORT! you can't install a release of IGSuite previous 3.2.3 ".
      "by IGPacMan.\n") if compare_release( '3.2.3', $release_num );

  ## install package
  _clean_some_env();
  chdir("$temp_dir${S}$pack_release")
    or die("Can't change dir to '$temp_dir${S}$pack_release'.\n");
  my $install_status = `$perl install.pl "$config_file" 2>&1`;
     $install_status =~ s/^prototype mismatch.*[\n\r]*//mgi;

  install_end($install_status);
 }

############################################################################
############################################################################
sub install_end
 {
  my $install_status  = shift;
  my $install_success = $install_status =~ /Error|ABORT|ALERT|ATTENTION|syntax error/m
                      ? 0
                      : 1;

  Header("<strong>STEP 6/6</strong> <u>Installation end.</u>");

  ## clean config file
  unlink( $config_file )
    or die("Can't delete config file '$config_file'.\n");
  
  if ( $install_success )
   {
    ## success case
    print <<END;
          <div style="text-align:justify;
                      color:#000000;
                      border:1px solid #000000;
                      background:#DDDDDD;
                      padding:5px;
                      width:600px">
          Congratulations!!!<br>
          you have installed IGSuite correctly. Please press 'Start IGSuite'
          and make your first connection as administrator with the user login
          and password inserted by you during this installation.<br><br>
END
   }
  else
   {
    ## failure case
    print <<END;
          <div style="text-align:justify;
                      color:#000000;
                      border:1px solid #000000;
                      background:#DDDDDD;
                      padding:5px;
                      width:600px">
          Sorry we have got some problems!!!<br>
          One or more errors occurred while processing the installation.
          You can read installation logs below and try to fix the problem
          or if you want you can try anyway to type on 'Start IGSuite'
          and make your first connection as administrator with the user login
          and password inserted by you during this installation.<br><br>
END
   }

  print "Look below at installation logs...<br><br>".
        "</div><br><br>Installation logs",

        "<div style=\"width:610px; overflow:scroll; border:1px solid #000000;".
        " background:#DDDDDD; color:#000000; height:150px; text-align:left;\">".
        "<pre style=\"font-size:11px\">$install_status</pre></div>\n",
  
        submit(     -name=>'next',
                    -style => 'margin:20px 3px 0px 3px; float:right;',
                    -onclick=>"document.location='igsuite'",
                    -value=>'Start IGSuite...');

  Footer('noabort');
 }

############################################################################
############################################################################
sub _set_defaults
 {
  ## set webpath
  $webpath ||= '/';

  ## we need a temporary directory to unpack IGSuite package
  $temp_dir ||= _find_temp_dir();
  $temp_dir =~ s/[\\\/]$//g if $temp_dir ne $S;

  ## we can simply obtain $cgi_dir value in this way because this is
  ## a cgi script! and user want (and must!) install IGSuite here
  if ( !$cgi_dir )
   {
    ## try to use Cwd
    eval ("require Cwd;");
    $cgi_dir = $@
             ? $ENV{PWD}
             : $OS eq 'UNIX' ? Cwd::getcwd()
                             : Cwd::getdcwd();
   }

  ## In CGI Environment we have DOCUMENT_ROOT
  $htdocs_dir ||= _try_find_htdocs();

  ## Use browser language to guess $default_language
  $default_lang ||= lc(substr($ENV{HTTP_ACCEPT_LANGUAGE},0,2));
  $default_lang = 'en' if $default_lang !~ /^(it|en|es|fr|pt|nl)$/;

  ## because this is a CGI script only www user can execute it!
  $www_user ||= getlogin() || getpwuid( $< );

  ## Database defaults
  $db_driver   = 'pg' if $db_driver !~ /^(mysql|pg|postgres|sqlite)$/;
  $db_name   ||= 'igsuite';
  $db_host     = '127.0.0.1';
  $db_port   ||= $db_driver eq 'postgres' || $db_driver eq 'pg'
               ? 5432
               : 3306;

  ## set config file name
  $config_file = $temp_dir . $S . 'install.cfg';
 }

############################################################################
############################################################################
sub _ck_execute_mode
 {
  ## don't execute this sub on cgi environment
  return if $ENV{'REQUEST_METHOD'};

  ## ok we are on a commandline
  my $passphrase;
  print "\nIGPacMan - IGSuite Package Manager\n".
        "Type the pass-phrase you will use to access to the web interface.\n";
  while (!$passphrase)
   {
    print "\nPass-phrase: ";
    $passphrase = <STDIN>;
    $passphrase =~ s/[\r\n\s]+$//g;
   }

  ## read this script
  open (DET, '<', $0)
    or die("Can't open '$0'.\n");
  my @rows = <DET>;
  close (DET);

  ## set a right shebang
  $rows[0] = "#! $perl\n";

  ## set a passphrase
  for my $i (1..50)
   {
    if ( $rows[$i] =~ /^my \$pass\_phrase \=/ )
     {
      $rows[$i] = "my \$pass_phrase = '$passphrase';";
      last;
     }
   }

  ## save the new script
  open (DET, '>', $0)
    or die("Can't write '$0'.\n");
  print DET @rows;
  close (DET);

  print "\n\nOK! now you can start you browser and call this script!\n".
        "You should open an URL like: http://127.0.0.1/cgi-bin/igpacman.pl\n".
        "Press Enter to continue...\n";
  my $enter = <STDIN>; 

  exit(0);
 }

############################################################################
############################################################################
sub _some_system_check
 {
  #XXX2TEST igpacman under mod_perl
  die("Can't execute IGSuite under ModPerl::Registry, try ModPerl::PerlRun.\n")
    if exists $ENV{MOD_PERL_API_VERSION} && ! $ModPerl::PerlRun::VERSION;
 }

###########################################################################
###########################################################################
sub compare_release
 {
  my ($rel1, $rel2) = @_;
  my $iterator_A = _mk_compare_iterator( $rel1 );
  my $iterator_B = _mk_compare_iterator( $rel2 );

  return _compare();

  sub _compare
   {
    my $a1 = $iterator_A->();
    my $b1 = $iterator_B->();
     
    return 0 if $a1 < $b1 || ! defined $a1;
    return 1 if $a1 > $b1 || (! defined $b1 && $a1);         
    _compare();
   }

  sub _mk_compare_iterator
   {
    my @values = split /\D/, shift;
    return sub { shift @values };
   }
 }

###########################################################################
###########################################################################
sub _clean_some_env
 {
  ## these env value make problems when we execute from a cgi a script
  ## as a command line application
  delete $ENV{SCRIPT_FILENAME};
  delete $ENV{REQUEST_URI};
  delete $ENV{REQUEST_METHOD};
 }
 
###########################################################################
###########################################################################
sub _find_shebang
 {
  my @rows;
  my $perl = '/usr/bin/perl';
  return($perl) if -e $perl;

  for  ('/usr/local/bin/perl',
	'/bin/perl',
        "c:\\perl\\bin\\perl.exe",
	"$^X")
   { ($perl=$_) && last if -e $_ && -x $_ }

  $perl ||= do {
                eval("require Config");
                 $@
                 ? ''
                 : $Config::Config{'bin'}.
                   ( $OS eq 'UNIX' ? '/perl' : "\\perl.exe")
               };

  die( "Can't find an executable perl shebang ".
       "for your scripts! where is Perl ?\n" ) if ! -e $perl;

  return $perl;
 }

############################################################################
############################################################################
sub _ck_os
 {
  my $OS = $^O || do {
                      eval("require Config");
                      $@ ? '' : $Config::Config{'osname'}
                     };
     
  if    ($OS=~/Win/i)    { $OS = 'WINDOWS'; }
  elsif ($OS=~/vms/i)    { $OS = 'VMS'; }
  elsif ($OS=~/bsdos/i)  { $OS = 'UNIX'; }
  elsif ($OS=~/dos/i)    { $OS = 'DOS'; }
  elsif ($OS=~/^MacOS$/i){ $OS = 'MACINTOSH'; }
  elsif ($OS=~/os2/i)    { $OS = 'OS2'; }
  else                   { $OS = 'UNIX'; }

  die("You can't install IGSuite ".
      "on system different from Unix or Windows\n") if    $OS ne 'UNIX'
                                                       && $OS ne 'WINDOWS';

  my $S = $OS eq 'UNIX' ? '/' : '\\';
  return ($OS, $S);
 }
 
############################################################################
############################################################################
sub _find_temp_dir
 {
  for my $tdir ( $temp_dir,
                 $ENV{'TEMP'},
                 $ENV{'TMP'},
                 "${S}tmp",
                 "${S}temp",
                 "${S}usr${S}tmp",
                 "${S}var${S}tmp",
                 "c:${S}temp",
                 "d:${S}temp",
                 "c:${S}system${S}temp",
                 "c:${S}WINDOWS${S}temp",
                 "$cgi_dir${S}data${S}temp" )
   {
    stat($tdir);
    return $tdir if -d _ && -w _;
   }

  die("Not valid or available temporary directory. Please edit this script ".
      "by your preferred text editor and insert a path of a temporary ".
      "directory where user who executes the web server can write. Insert ".
      "the path inside \$temp_dir variable.\n");
 }

############################################################################
############################################################################
sub _ck_session
 {
  my $sessionid = cookie('presessionid');
  my $in_pass_phrase = param('pass_phrase');

  if ( !$pass_phrase )
   {
    ## invite user to insert a passphrase inside this script
    die("Any Pass-Phrase!. Please edit this script file by your ".
        "preferred text editor and insert a secret Pass-phrase inside ".
        "\$pass_phrase variable then execute this script again.\n");
   }
  elsif ( $sessionid )
   {
    ## oh oh a sessionid different from passphrase!
    die("You don't have right privileges to execute this script because ".
        "you have a wrong sessionid please delete cookies on your browser.\n")
      if $sessionid ne $pass_phrase;
   }
  elsif ( $in_pass_phrase && $in_pass_phrase eq $pass_phrase ) 
   {

    ## ok authenticated! return session cookie
    return cookie( -name  => 'presessionid',
                   -path  => '/',
                   -value => $pass_phrase ); 
   }  
  else
   {
    ## we have to ask a passphrase to the user 
    
    if ( $in_pass_phrase && $in_pass_phrase ne $pass_phrase )
     {
      ## wrong passphrase
      push @err_msg, 'Wrong Pass-Phrase! try again';
     }
     
    if ( param('abort') && -e $config_file )
     {
      unlink $config_file or die("Can't delete '$config_file'.\n");
     }
    
    Header( '<span style="margin-left:15px;font-size:22px; font-weight:bold">'.
            'IGPacMan 4.0.0.</span>' );

    print "<div style=\"text-align:left; color:#000000; background:#DDDDDD;
           border:1px solid #99999; padding:8px; width:700px\">
           Thank you for believing in this project and welcome to IGSuite
           Package Manager.<br><br>
           The  program  will ask you some values, they are necessary both
           to install or upgrade, and to configure IGSuite environment. 
           We will suggest you some default choice but if you have not read
           the file regarding the installation requirements,
           you  should do it now.<br><br>
           To authenticate yourself you have to edit this script with your 
           preferred text editor and insert a \"Pass-Phrase\" at the first rows
           of the script. Then insert the same pass-phrase in this form and
           type 'next'.<br><br>
           <div style=\"font-size:14px; color:#ff3300; font-weight:bold; text-align:center;\">
           &gt; ATTENTION! THIS IS A BETA RELEASE PROCEED AT YOUR OWN RISK &lt;
           </div></div><br>",
    

          'Insert your Pass-Phrase ',

          textfield(  -name=>'pass_phrase',
                      -value=>'',
                      -size=>30,
                      -maxlength=>30 ),

          submit(     -name=>'next',
                      -style => 'margin:20px 3px 0px 3px; float:right;',
                      -value=>'Next');

    Footer('noabort');
    exit();
   }

  ## return session cookie
  return cookie( -name  => 'presessionid',
                 -path  => '/',
                 -value => $sessionid );
 }

############################################################################
############################################################################
sub _load_config_file
 {
  my $config_file_content;
  if ( -e $config_file )
   {
    ## read config file content
    open( FH, '<', $config_file) or die("Can't open '$config_file'.\n");
    while (<FH>)
     {
      ## clean unwanted perl code
      next if    ! /^\$[a-z\_]+ \= \'[^\']*\'\;$/
              && ! /^1\;$/;

      $config_file_content .= $_;
     }
    close(FH);

    ## execute config file content
    eval( $config_file_content )
      or die("Can't parse '$config_file' config file! ".
             "try to edit or remove it manually.\n");
   }
  elsif ( open (FH, '<', "$cgi_dir${S}conf${S}igsuite.conf" ) )
   {
    while (<FH>)
     {
      next if ! /\$temp\_dir
                |\$cgi\_dir
                |\$www\_user
                |\$htdocs\_dir
                |\$webpath
                |\$default\_lang
                |\$login\_admin
                |\$pwd\_admin
                |\$db\_driver
                |\$db\_name
                |\$db\_login
                |\$db\_password
                |\$db\_host
                |\$db\_port/x;

      $config_file_content .= $_ ;
     }
    close(FH);
    $config_file_content .= "\n1;";

    ## execute config file content
    eval( $config_file_content )
      or die("Can't parse '$cgi_dir${S}conf${S}igsuite.conf' config file! ".
             "try to edit or remove it manually or if you want rename it.\n");
   }

  ## adjust some value
  $db_password ||= 'none';
  $webpath ||= '/';
 }

############################################################################
############################################################################
sub _try_find_htdocs
 {
  my @dir_parts = split(/\/|\\/, $cgi_dir);
  my $cgi_name = pop @dir_parts;
  my $www_root = substr( $cgi_dir, 0, length($cgi_dir)-length($cgi_name)-1 );
  my $htdocs   = -e "$www_root${S}htdocs" ? "$www_root${S}htdocs"
               : -e "$www_root${S}html"   ? "$www_root${S}html"
               : undef;

  ## use DOCUMENT_ROOT apache environment value
  if (!$htdocs)
   {
    $htdocs = $ENV{DOCUMENT_ROOT};
    $htdocs =~ s/\//\\/g if $OS eq 'WINDOWS';
   }

  return $htdocs;
 }

############################################################################
############################################################################
sub _is_dbdriver_unavailable
 {
  my %driver_modules = ( mysql    => 'DBD::mysql',
                         sqlite   => 'DBD::SQLite',
                         pg       => 'DBD::Pg',
                         postgres => 'Pg' );
  eval("require $driver_modules{$db_driver}");
  return $@ ? 1 : 0;
 }

############################################################################
############################################################################
sub _ck_result
 {
  my ($status, $key, $fail_result, $ok_message) = @_;

  my $cflag = $status eq 'skip'
            ? '<div style="text-align:center; width:100px; color:#FFFFFF;'.
              ' background:#ff9900;">SKIP</div>'
            : $status
            ? '<div style="text-align:center; width:100px; color:#FFFFFF;'.
              ' background:#ff3300;">ERROR</div>'
            : '<div style="text-align:center; width:100px; color:#FFFFFF;'.
              ' background:#00cc00;">PASS</div>';

  my $result = $status
             ? $fail_result
             : ($ok_message || 'OK!');

  my $value =    eval("\${$key}")
              || '<span style="color:#ff3300;">empty value</div>';
          
  print ( (caller(1))[3] ne 'main::_ck_db_connection'
        ? "<tr>".
          "<td style=\"background-color:#BBBBBB; vertical-align:top;".
          " font-weight:bold;\">\$$key</td>".
          "<td style=\"white-space:nowrap; background-color:#CCCCCC;".
          " vertical-align:top;\"> = '$value'</td>".
          "<td style=\"background-color:#CCCCCC; vertical-align:top;\">".
          "$result</td>".
          "<td style=\"width:105px; vertical-align:top;\">$cflag</td>".
          "</tr>\n"
          
        : "<tr>".
          "<td style=\"background-color:#BBBBBB; vertical-align:top;".
          " font-weight:bold;white-space:nowrap;\">$key</td>".
          "<td style=\"background-color:#CCCCCC; vertical-align:top;\">".
          "$result</td>".
          "<td style=\"background-color:#CCCCCC; vertical-align:top;\">".
          "$cflag</td>".
          "</tr>\n" );

  return $status;
 }

############################################################################
############################################################################
sub _ck_db_connection
 {
  ## check db_password value
  $db_password = '' if $db_password eq 'none';

  my ($conn, $result);
  my $can_drop_database;

  #### POSTGRES DRIVER ###################################################  
  if ( $db_driver eq 'postgres' )
   {
    ## try to load module
    eval 'require Pg';
    Pg->import;
    _ck_result( $@,
               'Load module',
               "No 'Pg.pm' module found! ".
               "remember I don't want DBD::Pg but Pg.pm!"
              ) && return 1;

    ## check connection
    $conn = Pg::setdbLogin(	$db_host,
				$db_port,
				'',
				'',
				'template1',
				$db_login,
				$db_password );

    _ck_result( _cmp_eq( Pg->PGRES_CONNECTION_OK, $conn->status ) == 0,
                'Connect',
                "Attention! you have to check:<br>\n".
    	        " - that user '$db_login' with password '$db_password' can ".
    	          " create databases with name '$db_name';<br>\n".
                " - that Postgres is running on server '$db_host' ".
                  " and can accept remote connection;<br>\n".
                " - that perl module for '$db_driver' you are using ".
                  " is compatible with IGSuite (remember IG wants Pg.pm ".
                  " not DBD::Pg!)<br>\n"
              ) && return 1;

    ## try to create a Database (first try to connect to it)
    $conn = Pg::setdbLogin(	$db_host,
				$db_port,
				'',
				'',
				$db_name,
				$db_login,
				$db_password );

    if (_cmp_eq(Pg->PGRES_CONNECTION_OK, $conn->status) == 0)
     {
      ## ok doesn't exist now we can create it

      $conn = Pg::setdbLogin(	$db_host,
				$db_port,
				'',
				'',
				'template1',
				$db_login,
				$db_password );

      $result = $conn->exec("CREATE DATABASE $db_name");

      _ck_result( _cmp_eq( Pg->PGRES_COMMAND_OK, $result->resultStatus) == 0,
                  'Create database',
                  "Panic!: I tried to connect to 'postgres' and create ".
	 	  "'$db_name' database, but an unknown error occurred, ".
		  "pheraps I haven't right privileges to access or to create ".
		  "database in postgres!\nCheck login and password! "
                ) && return 1;

      $can_drop_database++;
     }
    else
     {
      _ck_result( 'skip',
                  'Create database',
                  'Already exists!' );
     }

    ## Make a tables (connect again but now to new database!)
    $conn = Pg::setdbLogin( 	$db_host,
				$db_port,
				"",
				"",
				$db_name,
				$db_login,
				$db_password );

    _ck_result( _cmp_eq(Pg->PGRES_CONNECTION_OK, $conn->status) == 0,
                'Connect to new database',
                "Attention! Can't connect to '$db_name' database\n"
              ) && return 1;

    ## try to create a table (but first try to connect)
    $result = $conn->exec("SELECT * FROM igsuitetable where 0=1");

    if ( _cmp_eq(Pg->PGRES_TUPLES_OK, $result->resultStatus) == 0 )
     {
      $result = $conn->exec("CREATE TABLE igsuitetable (name varchar(10))");

      _ck_result( _cmp_eq( Pg->PGRES_COMMAND_OK, $result->resultStatus) == 0,
                  'Create a table',
                  "I can't create a new table"
                ) && return 1;
     }
    else
     {
      _ck_result( 'skip',
                  'Create a table',
                  'Already exists!' );
     }

    ## drop the table
    $result = $conn->exec("drop table igsuitetable");
    _ck_result( _cmp_eq( Pg->PGRES_COMMAND_OK, $result->resultStatus) == 0,
                'Drop a table',
                "I can't drop tables"
                ) && return 1;

    ## we drop database only if we created it
    if ( $can_drop_database )
     {
      ## first reconnect to template1
      $conn = Pg::setdbLogin(	$db_host,
				$db_port,
				'',
				'',
				'template1',
				$db_login,
				$db_password );
      ## drop database
      $result = $conn->exec("drop database $db_name");
      _ck_result( _cmp_eq( Pg->PGRES_COMMAND_OK, $result->resultStatus) == 0,
                  'Drop database',
                  "I can't drop database"
                ) && return 1;
     }
    else
     {
      _ck_result( 'skip',
                  'Drop database',
                  'Already exists!' );
     }
   }

  #### PG DRIVER #####################################################
  elsif ( $db_driver eq 'pg' )
   {
    my ($drh , $dbh, $sth);
    require DBI;
    _ck_result( $@,
                'Load module',
                "No DBI module found!") && return 1; 

    $drh = DBI->install_driver('Pg');
    _ck_result( !$drh,
                'Test module',
                "Attention! you have to check:\n".
	        " - that Postgres is running on server '$db_host'".
	          " on port '$db_port';<br>\n".
	        " - that perl module for '$db_driver' you are using".
	          " is compatible with IGSuite (DBD::Pg)<br>\n"
              ) && return 1;

    ## Make Database ( but first try to connect )
    $dbh = DBI->connect("dbi:Pg:".
                        "database=$db_name;".
                        "host=$db_host;".
                        "port=$db_port",

			$db_login,
			$db_password,  {	PrintError => 0,
						RaiseError => 0,
						AutoCommit => 1
			               }
			);
    if (!$dbh)
     {
      ## ok it doesn't exist we can create it

      $dbh = DBI->connect("dbi:Pg:".
                          "database=template1;".
                          "host=$db_host;".
                          "port=$db_port",

			  $db_login,
			  $db_password,  {	PrintError => 0,
						RaiseError => 0,
						AutoCommit => 1
					 }
			);

      _ck_result( !$dbh,
                  'Connect',
                  "I can't connect to mysql on '$db_host' with port '$db_port' ".
                  "to create '$db_name' database. Please check that user ".
                  "'$db_login' with password '$db_password' has ".
		  "right privileges to access or to create ".
		  "database in mysql!!!\n"
                ) && return 1;

      ## create igsuite database
      my $result = $dbh->do( "CREATE DATABASE $db_name" );

      _ck_result( !$result,
                  'Create database',
                  "Cant' create '$db_name' database make sure '$db_login' ".
	          "user has all privileges needed and Postgres is running\n"
                ) && return 1;

      $can_drop_database++;
     }
    else
     {
      _ck_result( 'skip',
                  'Create database',
                  'Already exists');
     }

    ## Make Tables (check if already exists)
    $dbh = DBI->connect("dbi:Pg:".
                        "database=$db_name;".
                        "host=$db_host;".
                        "port=$db_port",

			$db_login,
			$db_password, {	PrintError => 0,
					RaiseError => 0,
					AutoCommit => 1
				      }
		       );
    _ck_result( !$dbh,
                'Connect to database',
                "Attention! can't connect to '$db_name' database!"
              ) && return 1;

    $sth = $dbh->prepare("select * from igsuitetable where 0=1");
    $sth->execute();

    my $err = $dbh->err;
    my $errstr = $dbh->errstr;
    my $state = $dbh->state;
 
    ## try to create a test table
    if ($err)
     {
      $result = $dbh->do("CREATE TABLE igsuitetable (name varchar(10))");
      $err = $dbh->err;
      _ck_result( $err,
                  'Create table',
                  "Can't create test table"
                ) && return 1;
     }
    else
     {
      _ck_result( 'skip',
                  'Create table',
                  'Already exists');
     }

    ## drop table
    $result = $dbh->do("DROP TABLE igsuitetable");
    $err = $dbh->err;
    _ck_result( $err,
                'Drop table',
                "Can't drop test table"
                ) && return 1;

    ## drop database only if we created it
    if ( $can_drop_database )
     {
      ## drop database
      $result = $dbh->do("DROP DATABASE $db_name");
      $err = $dbh->err;
      _ck_result( $err,
                  'Drop database',
                  "Can't drop test database"
                ) && return 1;
     }
    else
     {
      _ck_result( 'skip',
                  'Drop database',
                  'Already exists!' );
     }
   }

  #### MYSQL DRIVER #####################################################
  elsif ( $db_driver eq 'mysql' )
   {
    my ($drh , $dbh, $sth);
    require DBI;
    _ck_result( $@,
                'Load module',
                "No DBI module found!") && return 1; 

    $drh = DBI->install_driver('mysql');
    _ck_result( !$drh,
                'Test module',
                "Attention! you have to check:\n".
	        " - that Mysql is running on server '$db_host'".
	          " on port '$db_port';<br>\n".
	        " - that perl module for '$db_driver' you are using".
	          " is compatible with IGSuite<br>\n"
              ) && return 1;

    ## Make Database ( but first try to connect )
    $dbh = DBI->connect("DBI:mysql:".
                        "database=$db_name:".
                        "host=$db_host:".
                        "port=$db_port",

			$db_login,
			$db_password,  {	PrintError => 0,
						RaiseError => 0,
						AutoCommit => 1
			               }
			);
    if (!$dbh)
     {
      ## ok it doesn't exist we can create it

      $dbh = DBI->connect("DBI:mysql:".
                          "database=mysql:".
                          "host=$db_host:".
                          "port=$db_port",

			  $db_login,
			  $db_password,  {	PrintError => 0,
						RaiseError => 0,
						AutoCommit => 1
					 }
			);
      if (!$dbh)
       {
        $dbh = DBI->connect("DBI:mysql:".
                            "database=test:".
                            "host=$db_host:".
                            "port=$db_port",

			    $db_login,
			    $db_password,	{	PrintError => 0,
							RaiseError => 0,
							AutoCommit => 1
						}
			   );

        _ck_result( !$dbh,
                    'Connect',
                    "I can't connect to mysql on '$db_host' with port '$db_port' ".
                    "to create '$db_name' database. Please check that user ".
                    "'$db_login' with password '$db_password' has ".
		    "right privileges to access or to create ".
		    "database in mysql!!!\n"
		  ) && return 1;
       }

      my $rc = $dbh->func('createdb',
			  $db_name,
			  'admin');
			  
      _ck_result( !$rc,
                  'Create database',
                  "Cant' create '$db_name' database make sure '$db_login' ".
	          "user has all privileges needed and Mysql is running\n"
                ) && return 1;

      $can_drop_database++;
     }
    else
     {
      _ck_result( 'skip',
                  'Create database',
                  'Already exists');
     }

    ## Make Tables (check if already exists)
    $dbh = DBI->connect("DBI:mysql:".
                        "database=$db_name:".
                        "host=$db_host:".
                        "port=$db_port",

			$db_login,
			$db_password, {	PrintError => 0,
					RaiseError => 0,
					AutoCommit => 1
				      }
		       );
    _ck_result( !$dbh,
                'Connect to database',
                "Attention! can't connect to '$db_name' database!"
              ) && return 1;

    $sth = $dbh->prepare("select * from igsuitetable where 0=1");
    $sth->execute();

    my $err = $dbh->err;
    my $errstr = $dbh->errstr;
    my $state = $dbh->state;
 
    ## try to create a test table
    if ($err)
     {
      $result = $dbh->do("CREATE TABLE igsuitetable (name varchar(10))");
      $err = $dbh->err;
      _ck_result( $err,
                  'Create table',
                  "Can't create test table"
                ) && return 1;
     }
    else
     {
      _ck_result( 'skip',
                  'Create table',
                  'Already exists');
     }

    ## drop table
    $result = $dbh->do("DROP TABLE igsuitetable");
    $err = $dbh->err;
    _ck_result( $err,
                'Drop table',
                "Can't drop test table"
                ) && return 1;

    ## drop database only if we created it
    if ( $can_drop_database )
     {
      ## drop database
      $result = $dbh->do("DROP DATABASE $db_name");
      $err = $dbh->err;
      _ck_result( $err,
                  'Drop database',
                  "Can't drop test database"
                ) && return 1;
     }
    else
     {
      _ck_result( 'skip',
                  'Drop database',
                  'Already exists!' );
     }
   }

  #### SQLITE DRIVER ####################################################
  elsif ( $db_driver eq 'sqlite' )
   {
    my ($drh , $dbh, $sth);
    my $db_file = "$temp_dir${S}$db_name.sqlite";

    require DBI;
    _ck_result( $@,
                'Load module',
                "No DBI module found!") && return 1; 

    $drh = DBI->install_driver('SQLite');
    _ck_result( !$drh,
               'Test module',
               "Attention! you have to check ".
               "that perl module for '$db_driver' you are using is ".
               "compatible with IG\n"
              ) && return 1;

    ## Make Database
    $can_drop_database++ if ! -e $db_file;
    $dbh = DBI->connect( "DBI:SQLite:".
			 "dbname=$db_file",
      			 '',
			 '',
			 { PrintError => 0,
			   RaiseError => 0,
			   AutoCommit => 1
  			 }
		       );

    _ck_result( !$dbh,
                'Connect to database',
                "Panic!: I tried to connect to sqlite or to create ".
		 "'$db_name' database, but an unknown error occurred, ".
		 "pheraps I haven't right privileges to access or to create ".
		 "an sqlite database or I can't write on ".
		 "'$temp_dir${S}$db_name.sqlite' !!!\n"
              ) && return 1;

    $dbh->{AutoCommit} = 1;
    $dbh->{PrintError} = 0;
    $dbh->{RaiseError} = 0;

    ## Make Tables
    $sth = $dbh->prepare("select * from igsuitetable where 0=1");
    $sth->execute() if $sth;
    my $err = $dbh->err;
    my $errstr = $dbh->errstr;
    my $state = $dbh->state;

    if ($err)
     {
      $result = $dbh->do("CREATE TABLE igsuitetable (name varchar(10))");
      $err = $dbh->err;
      _ck_result( $err,
                  'Create table',
                  "Can't create test table"
                ) && return 1;
     }
    else
     {
      _ck_result( 'skip',
                  'Create table',
                  "Already exists" );
     }

    ## drop table
    $result = $dbh->do("DROP TABLE igsuitetable");
    $err = $dbh->err;
    _ck_result( $err,
                'Drop table',
                "Can't drop test table"
                ) && return 1;

    ## drop database only if we created it
    if ( $can_drop_database )
     {
      ## drop database
      _ck_result( ! unlink( $db_file ),
                  'Drop Database',
                  "Can't delete $db_file database"
                ) && return 1;
     }
    else
     {
      _ck_result( 'skip',
                  'Drop database',
                  'Already exists!' );
     }
   }
  else
   {
    #### unsupported rdbms driver ########################################
    
    die("Unsupported rdbms driver used! How this ".
        "driver has written in install.conf ?\n");
   }  

  return 0;
 }

############################################################################
############################################################################
sub _cmp_eq
 {
  my ($cmp, $ret) = @_;
  return "$cmp" eq "$ret" ? 1 : 0;
 }

############################################################################
############################################################################
sub _find_unpack_app
 {
  for my $app ( qw( /bin/tar /usr/bin/tar /sbin/tar /usr/sbin/tar ) )
   {
    return $app if -e $app && -x $app;
   }
  return '';
 }

############################################################################
############################################################################
sub Header
 {
  my $step = shift;

  $action_cookie ||= cookie( -name  => 'last_action',
                             -path  => '/',
                             -value => 'default_action' );

  print header( -cookie=> [$session_cookie, $action_cookie],
                -expires=>'now' ),

        start_html( -title=>'IGSuite PreInstaller' ),
        
        "<center>".
        "<table style=\"border:1px solid #000000; width:770px;".
        " color:#FFFFFF; background:#336699; padding:5px;\"><tr>".
        "<td align=\"left\">$step</td>".
        "<td style=\"text-align:right; font-size:22px; font-weight:bold;\">".
        ($session_cookie
         ? "<img src=\"igpacman.pl?action=get_iglogo\"".
           " style=\"vertical-align:middle; width:22px; height:19px;\">"
         : '').
        " IGSuite Package Manager</td></tr>".
        "<td colspan=2 align=\"center\"><br>";

  if ( $step !~ /STEP 6/ )
   {
    print start_form( -method=>'POST',
                      -action=>'igpacman.pl' ),
                    
          hidden(-name     => 'randomvl',
                 -default  => rand(),
                 -override => 1 ); 
   }
 }

############################################################################
############################################################################ 
sub Footer
 {
  my $abort_flag = shift;

  print submit(-name=>'abort',
               -value=>'Abort',
               -onclick=>"document.cookie='presessionid=; path=/';",
               -style=>'float:left; margin-top:20px') if !$abort_flag;
            
  print endform();

  if ( @err_msg )
   {
    print "<div style=\"margin-top:10px;clear:both;border: 2px solid #FFFFFF;".
          " padding:10px; color:#FFFFFF; background-color: #ff3300;\">";
             
    for ( @err_msg )
     {
      print "$_<br>\n";
     }
     
    print "</div>\n";
   }

  print "</td></tr></table></center>", end_html();
 }

############################################################################
############################################################################
sub htdocs_test
 {
  my $images_dir = $htdocs_dir . ${S} . 'images';
  my $logo_test = $images_dir . ${S} . 'test_logo.gif';
  $webpath &&= "/$webpath" if $webpath !~ /^\//;
  $webpath   = '' if $webpath eq '/';
  
  if (! -d $images_dir)
   {
    mkdir $images_dir, 0775
     or die("Can't create $images_dir check privilege ".
            "or '\$htdocs_dir' value.\n");
   }

  if (! -e $logo_test)
   { 
    open( IMG, '>', $logo_test)
      or die("Can't create '$logo_test' image file check file or directory ".
             "privileges or '\$htdocs_dir' value.\n");
    binmode(IMG);
    print IMG _get_iglogo();
    close (IMG);
    chmod 0664, $logo_test;
   }

  Header("<u>Test the \$htdocs_dir and \$webpath values</u>");
  print <<HTML;
<div style="color:#000000; background-color:#DDDDDD">
<table style="border:2px solid #EEEEEE; width:100%" cellspacing=0><tr>
<td><u>Original logo</u><br>Originated by this script</td>
<td><img src="igpacman.pl?action=get_iglogo"></td>
<td style="width:3px; background-color:#EEEEEE"></td>
<td><u>Test logo</u><br>Read from $webpath/images/test_logo.gif</td>
<td><img src="$webpath/images/test_logo.gif"></td></tr>
<tr><td colspan=5 style="text-align:left; padding:5px; background-color:#EEEEEE"><br><br>
If you have set a right \$webpath value you can view two equal
IGSuite logo above (two little and open boxes). The first icon (on the left)
is generated by this script automatically, the second (on the right) is written
from this script on server filesystem on a path composed by \$htdocs_dir value
+ '${S}images${S}' and then read from an url composed by \$webpath value
+ '/images/' + 'test_logo.gif'.<br><br>
Some example:<br>
if \$webpath = 'igsuite' you should have an url equal to:<br>
http://127.0.0.1/igsuite/images/test_logo.gif;<br>
if \$webpath = '' you should have an url equal to:<br>
http://127.0.0.1/images/test_logo.gif;<br><br>
If there isn't an icon on the right, try to close this window, change
\$webpath value and then execute this test again.
</td></tr>
</table></div>
HTML
  print submit(-name=>'close',
               -value=>'Close',
               -onclick=>"self.close();",
               -style=>'float:left; margin-top:20px');
  Footer(1);
 }

############################################################################
############################################################################
sub _is_internet_alive
 {
  eval ('require LWP::UserAgent;');
  return 0 if $@;
  my $ua = LWP::UserAgent->new;
  $ua->agent("IGSuite/$IG::VERSION");
  my $req = HTTP::Request->new(GET => "http://www.google.com" );
  my $r = $ua->request($req);
  return $r->is_success ? 1 : 0;
 }

############################################################################
############################################################################ 
sub FileCopy
 {
  my ($filein, $fileout) = @_;
  die("You have to specify origin and target file in FileCopy()")
    if !$filein || !$fileout;

  open (FILEIN,  '<', $filein)  or die("Can't read $filein");
  open (FILEOUT, '>', $fileout) or die("Can't write to $fileout");

  binmode(FILEIN);
  binmode(FILEOUT);

  print FILEOUT $_ while (<FILEIN>);
  close(FILEOUT);
  close(FILEIN);
 }

############################################################################
############################################################################
sub get_iglogo
 {
  print header( -type => 'image/gif' );
  print _get_iglogo();
 }
 
############################################################################
############################################################################
sub _get_iglogo
 {
  my $logo_img;
  $logo_img .= $_ while(<DATA>);
  return unpack( 'u', $logo_img );
 }

############################################################################
############################################################################ 

__DATA__
M1TE&.#EA%@`3`.>/``<4-P<;1PD@6P<B7`DC8`\D4A\G-0LI?0LL@@TL?0LM
M@B8Q.1(Y7R$[5"8Z6!!$>2-#82A#<AU)<S5'6Q-2D4-.4A59GC92:DQ-24U-
M3DU/3T]/3A5=IB1;C25;C"5;C256LU)23E-333Y8;#1;>CQ9;U-4319CK39?
M@%975U=843!AD%=85SMA@#-CCS=CC%Q<6U-?;DY@>!EOO5U?751A>!ERP#)L
MGUAD9V%C7!MVQAIXQCEPH&5E91MYR1MZRDYN@AQ\S#MPO45PI&=K9U-P@VAJ
M:FIK8UMP@#UYJ$%\J7!R<D=]IW)S<D*`L&-X@G-V=D6#LT6%LGEZ=7I]=G:"
ME$R0O7R&E(6'AX:)B5:BT%:DTEBFTY&5E)B5EY68FYR@J&.WY:>FIJ:HK*FI
MJZVMJ;"QL;6UM[:XMK:XM[BXM[B[O,'!N\#!P,;(PLC(R,O+R\_/RL_0RL_0
MSL_0T,_0T=#1T-'2T-K;V]S<V]W>WN;FY.?HY^CHY^GIY>GIZ>KIZ>KJZNKK
MZNKKZ^WM[>WN[/#P[_#P\/#Q\?'Q\/'R\/+R\?+R\O3T\_3T]/__________
M____________________________________________________________
M____________________________________________________________
M____________________________________________________________
M____________________________________________________________
M____________________________________________________________
M____________________________________________________________
M____________________________________________________________
M_____________________R'Y!`$``/\`+``````6`!,```C^`/\)'&BD29:!
M&I9H&,C0B!$L8NP`.N3(40^!=!PA"H1'C1<H,/[1^%.Q9$4X_U*8-&E&8(:,
M*QUM:!/3$1P6#,E4'/1FS!4#-:J`.5,GD",]1A@*#&%DPA`A(`@H2(#@@```
M#I7^HZ)(4)PN,B($&%#`08PO=_XD*L,P!Z&5?*8LR,,HYAP3_T3XJ5F!`Y*Z
M*_<<^8>!3:.5<EX$L3&B4$DW1)2J6+.HY!,I08+XN-`'30D(6O]%*9+&4!\F
M3C('T2'!@@\/H<.$L0($AQ4EJG-WT(I"MFPK89+D5OV!MV_?-X9GWLU[RW$>
EPW=0:!!:8`LMLEVHGO&`1'6E)+@.K/AQ@H3W[UI),#A?/2``.P``
