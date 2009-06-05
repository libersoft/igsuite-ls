#!/usr/bin/perl
# Procedure: install.pl
# Last Update: 10/01/2006
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

## Try to load database module interface
BEGIN
 {
  use vars qw( $NoDbiModule $NoPgModule );
  eval 'use DBI';
  $NoDbiModule++ if $@;

  eval 'use Pg';
  $NoPgModule++  if $@;
 }

use strict;
use ExtUtils::Command;
use Config;

use vars qw(	%privileges	%timezones	%countries	$www_user
		%in		%on		%cookie		%set_cookie
		$S		$OS		@ISA		@EXPORT

		$crypt_key      $login_admin	%users		$auth_user
		$remote_host	$pwd_admin	$webpath	$img_url
		%htdocs_path	%menu_item	$user_dir	$htaccess_contacts

		$client_browser	$client_os	$tema		$link
		$screen_size	$page_results	$list_order	$date_format
		$timeoffset	$lang		$default_lang	%default_lang
		%attr		%languages	@task_list_content
		$cgi_path	$cgi_dir	$cgi_url	$logs_dir
		$conf_dir	$htdocs_dir	$temp_dir	$query_string
		$request_method $app_nspace	$task_list_cols	$task_list_rows
		$page_tabindex	$cgi_name	$cgi_ref	%lang
		$env_path	%docs_type	$demo_version   $debug

		%pop3_conf	%smtp_conf	$folderquota	$attlimit
		$homedirspoolname 		$homedirspools  $server_name
		$mailspooldir	$hashedmailspools %ldap_conf	$hosts_allow

		@row		@errmsg		%debug_info	%ext_app

		$def_wiki_show	$def_wiki_edit  %user_conf	%plugin_conf

		$soc_name	$soc_address	$soc_email	$soc_city
		$soc_zip	$soc_prov	$soc_tel	$soc_fax
		$soc_logo	$soc_country	$soc_site

		$db_name	$db_driver	$db_login	$db_password
		$db_host	$db_port	@db_fields_name	$db_fields_num

		$hylafax_host	$hylafax_port	$hylafax_login	$hylafax_pwd
		$hylafax_dir

		%executed	%months		%tv		$session_timeout
		@days		$thousands_separator $decimal_separator
		$currency	%offers_category		$prout_page

		$choice 	$perl		$install_mode   $db_driver_available
	   );

## find some system value
_check_system();

## fancy term color if Operating system is different from Windows
my $color_green = "\033[1;32m" if $OS ne 'WINDOWS';
my $color_white = "\033[0;39m" if $OS ne 'WINDOWS';

## try to set some value
_set_defaults();

## select requested install mode
if ( $ARGV[0] )
 {
  ## load pre-set install configuration file ( we need $cgi_dir )
  do $ARGV[0]
    or die("ABORT: Can't load install configuration file: $ARGV[0]\n");

  ## to proceed we need $cgi_dir
  die("ABORT: Can't find \$cgi_dir value! I need it! try to insert its ".
      "value manually inside your '$ARGV[0]' configuration file.\n"
     ) if !$cgi_dir;

  ## load previous config file ( from $cgi_dir )
  ## (we need a base configuration with all options)
  _load_previous_config_file();

  ## load pre-set install configuration file again 
  ## ( overwrite previuos config )
  do $ARGV[0]
    or die("ABORT: Can't load install configuration file: $ARGV[0]\n");

  ## start an automatic installation 
  $install_mode = 'automatic';
  mk_install();
 }
else
 {
  ## ask to user to collect info
  _collect_info();

  ## start a manual installation
  $install_mode = 'manual';
  mk_install();

  ## OK Done!
  print "Press Enter to continue...\n";
  $choice  = <STDIN>;

  ## In Window system start the browser
  qx(start http://localhost/$webpath) if $OS eq 'WINDOWS';
 }


###########################################################################
###########################################################################
sub _collect_info
 {
  $choice = '';
  while (!$choice)
   {
    _clear_screen();

    print "\n(en)English".
          "\n(es)Espanol".
          "\n(fr)French".
          "\n(it)Italian".
          "\n(nl)Dutch".
          "\n(pt)Portuguese\n\n".
          "Set your IGSuite default language ? [$default_lang]: ";

    chomp( $choice = <STDIN> );

    $choice = $default_lang if !$choice && $default_lang;
    $choice = '' if $choice !~ /^(it|en|es|fr|nl|pt)$/;
   }

  $default_lang = $choice;

  require "lang${S}$default_lang${S}default_lang";
  die( "ABORT: Can't open ${S}$default_lang${S}default_lang ".
       "language file. Is this an original IGSuite package?\n" ) if $@;

                          #####################
      #############################################################
                       ############################
  _clear_screen();
  if ($default_lang eq 'it')
   {
    print <<FINE;
$color_green
############################################################################
##                                                                        ##
##                              IGSuite 3.2                               ##
##                       Integrated Groupware Suite                       ##
##                  www.igsuite.org - staff\@igsuite.org                   ##
##                                                                        ##
############################################################################
$color_white
Grazie  per  aver  creduto  in  questo progetto e benvenuti nel programma di
installazione di IGSuite 3.2.

Il programma ti fara' qualche  semplice domanda necessaria sia ad installare
che  configurare parte  dell'ambiente di IGSuite.  Ti saranno proposte delle
scelte di default per le quali potrai semplicemente premere invio.

Nel  caso  ancora  non  si  e' letto  il  file  che riaguarda i prerequisiti
all'installazione si consiglia di farlo adesso, ancor prima di procedere.

ATTENZIONE : Questa procedura  aggiornera' il file di configurazione attuale
(igsuite.conf) sovrascrivendo eventuali modifiche effettuate precedentemente.

Premere un tasto per continuare...
FINE
   }
  else
   {
    print <<FINE;
############################################################################
##                                                                        ##
##                             IGSuite 3.2.                               ##
##                       Integrated Groupware Suite                       ##
##                  www.igsuite.org - staff\@igsuite.org                   ##
##                                                                        ##
############################################################################


Thank you to believing  in this project and welcome to  IGSuite installation
program.

The  program  will answer you some simple questions, they are necessary both
to install and to configure IGSuite environment.
It will be suggest some default choice only you have to do is press "enter".
If you have  not  read the file regarding the installation requirements, you
should to do it now, before you proceed. 

ATTENTION: This procedure will update the configuration file  (igsuite.conf)
and it will overwrite every changes made before. 

Press a key to continue...

FINE
   }
  $choice = <STDIN>;

                          #####################
      #############################################################
                       ############################

  _clear_screen();
  if ($default_lang eq 'it')
   {
    print <<FINE;
$color_green
Step 1.
$color_white
  
Specificare  la directory configurata in Apache per contenere tutti i cgi e
dove quindi copiare tutti gli script necessari al funzionamento di IGSuite.

Accertarsi  che  la  directory  specificata  abbia  impostati i permessi di
lettura e scrittura per l'utente  $www_user che esegue il server Apache.
Questo script per motivi di sicurezza non cambiera' i permessi delle
directory del sistema.

FINE
   }
  else
   {
    print <<FINE;
$color_green 
Step 1.  
$color_white
  
Specify  the  directory  configured  in Apache in order to contain all cgi
and where I will copy all scripts needed by IGSuite.

You have to assess that the directoy  specified had set up the permissions
of  reading  and writing for the user $www_user who exec Apache.
This script for security reasons will not change the permissions of the
directories.
FINE
   }
  $choice = '';
  while (!$choice)
   {
    print "\nCGI Directory [$cgi_dir]: ";
    chomp( $choice = <STDIN> );

    $choice = $cgi_dir if !$choice && $cgi_dir;
   }
  $cgi_dir = $choice;
  $cgi_dir =~ s/(\\|\/)$//g;

                          #####################
      #############################################################
                       ############################

  ## save this options to prevent overwriting by config_file
  my $choosen_lang    = $default_lang;
  my $choosen_cgi_dir = $cgi_dir;

  ## We load previous configuration file to apply settings
  _load_previous_config_file();

  ## restore choosen options
  $default_lang = $choosen_lang;
  $cgi_dir      = $choosen_cgi_dir;

                          #####################
      #############################################################
                       ############################

  _clear_screen();
  if ($default_lang eq 'it')
   {
    print <<FINE;
$color_green
Step 2.
$color_white
  
Mi  occorre  sapere  login (massimo 32 caratteri) e password ( massimo 72
caratteri) che usera' l'amministratore di  sistema  sia  per creare nuovi
utenti di IGSuite ma anche per impostarne i permessi.

Questo account sara' anche quello da utilizzare al primo avvio di IGSuite.


FINE
   }
  else
   {
  print <<FINE;
$color_green
Step 2.
$color_white

I need to know the  login (min 2 max 32 chars) and password (min 4 max 72
chars ) that will use the system administrator,  it is in order to create
new  IGSuite users but also to set their permissions.

You have to use this account for the first start of IGSuite.


FINE
   }

  ## Login
  $choice = '';
  while (!$choice)
   {
    print "Login [$login_admin]: ";
    chomp($choice=<STDIN>);

    $choice = $login_admin if !$choice && $login_admin;
    if ( length($choice) > 32)
     { $choice = ''; print "too loong! max 32 chars\n"; }
    if ( length($choice) < 2)
     { $choice = ''; print "too short! min 2 chars\n"; }
   }
  $login_admin = $choice;

  ## Password
  $choice = '';
  while (!$choice)
   {
    print "\nPassword [$pwd_admin]: ";
    chomp( $choice = <STDIN> );

    $choice = $pwd_admin if !$choice && $pwd_admin;
    if ( length($choice) > 72)
     { $choice =''; print "too loong! max 72 chars\n"; }
    if ( length($choice) < 4)
     { $choice =''; print "too short! min 4 chars\n"; }
   }
  $pwd_admin = $choice;

                          #####################
      #############################################################
                       ############################

  _clear_screen();
  if ($default_lang eq 'it')
   {
    print <<FINE;
$color_green
Step 3.
$color_white
  
Specificare  l'utente  che  esegue  Apache  in  modo che si possano settare
i permessi di esecuzione degli script copiati nella directory dei cgi.

Questo utente deve essere lo stesso identificato nel file di configurazione
di Apache all'interno della  variabile "User", vale a dire lo stesso utente
che esegue il server Web.

In alcuni sistemi l'utente e' ad esempio "wwwrun".

FINE
   }
  else
   {
    print <<FINE;
$color_green
Step 3.
$color_white

Specify  the  user  who  starts  Apache  to  setting script permissions.

This user is the same identified in the Apache configuration file inside
"User" variable.

FINE
   }

  $choice = '';
  while (!$choice && $OS ne 'WINDOWS')
   {
    print "\nWeb User [$www_user]: ";
    chomp($choice=<STDIN>);

    $choice = $www_user if !$choice && $www_user;
   }
  $www_user = $choice;

                          #####################
      #############################################################
                       ############################

  _clear_screen();
  $choice = '';
  if ( !$NoDbiModule )
   {
    my @drivers = grep {/pg|mysql|sqlite/i} DBI->available_drivers();
    $db_driver_available  = join ' ', @drivers;
   }
  if ( !$NoPgModule )
   {
    $db_driver_available .= " postgres";
   }

  if (!$db_driver_available)
   {
    if ($default_lang eq 'it')
     {
      print "ATTENZIONE: Impossibile procedere, ".
            "nessun modulo perl (dbd::Pg; dbd::mysql; dbd::SQLite; Pg.pm) disponibile per ".
            "accedere ad un Database.\n Prova a leggere la documentazione ".
            "prima di procedere.\n";
     }
    else
     {
      print "WARNING: script aborted; no perl modules ".
            "found (dbd::Pg; dbd::mysql; dbd::sqlite; Pg.pm) to Database access\n";
     }

    print "Press Enter to continue...\n";
    $choice = <STDIN>;
    exit(0);
   }
  elsif ( $db_driver_available =~ /pg/i )  
   { $db_driver ||= 'pg'; }
  elsif ( $db_driver_available =~ /mysql/i )
   { $db_driver ||= 'mysql'; }
  elsif ( $db_driver_available =~ /sqlite/i )  
   { $db_driver ||= 'sqlite'; }
  elsif ( $db_driver_available =~ /postgres/i )
   { $db_driver ||= 'postgres'; }

  print $color_green . "Step 4.$color_white\n\n";
  while (!$choice)
   {
    if ($default_lang eq 'it')
     {
      print "\nQuale driver per DataBase userai mysql o postgres?\n\n".
            "attualmente hai disponibili i moduli per: ".
            "$db_driver_available [$db_driver]: ";
     }
    else
     {
      print "\nWhich DataBase driver will you use mysql or postgres?\n\n".
            "at moment you have only module for: ".
            "$db_driver_available [$db_driver]: ";
     }

    chomp( $choice = <STDIN> );
    
    $choice = $db_driver if !$choice && $db_driver;
 
    if ( $db_driver_available !~ /$choice/i )
     {
      _clear_screen();
      if ($default_lang eq 'it')
       {
        print "\nNon hai il modulo perl necessario a supportare ".
              "il driver '$choice' da te scelto\n";
       }
      else
       {
        print "\nYou haven't got module to use driver '$choice' you choose\n";
       }

      $choice = '';
     }    
   }
  $db_driver = lc($choice);

                          #####################
      #############################################################
                       ############################

  _clear_screen();
  if ($default_lang eq 'it')
   {
    print <<FINE;
$color_green
Step 5.
$color_white
 
Specificare il nome del database che verra' creato all'interno del RDBMS.

FINE
   }
  else
   {
    print <<FINE;
$color_green
Step 5.
$color_white

Specify the database name that IGSuite will create on RDBMS.


FINE
   }
  $choice = '';
  while (!$choice)
   {
    print "\nDB Name [$db_name]: ";
    chomp($choice=<STDIN>);
    $choice = $db_name if !$choice && $db_name;
   }
  $db_name = $choice;

                          #####################
      #############################################################
                       ############################

  _clear_screen();
  if ($default_lang eq 'it')
   {
    print <<FINE;
$color_green
Step 6.
$color_white
 
Specificare  l'utente  che  ha i  diritti di usare $db_driver per  creare
il Database $db_name e le relative Tabelle.
Successivamente ti chiedero' ulteriori dati necessari per collegarmi al
Database (password, host, porta).

n.b. potrai ignorare questi dati nel caso utilizzi SQLite come RDBMS

FINE
   }
  else
   {
    print <<FINE;
$color_green
Step 6.
$color_white

Specify the user name who have privileges to use $db_driver to create
Database $db_name and Tables needed by IGSuite.

n.b. ignore these requests if you are using SQLite as RDBMS

FINE
   }
  $choice = '';
  while (!$choice)
   {
    print "\nDB User [$db_login]: ";
    chomp($choice=<STDIN>);
    $choice = $db_login if !$choice && $db_login;
   }
  $db_login = $choice;

                          #####################
      #############################################################
                       ############################

  $choice = '';
  if ($default_lang eq 'it')
   { print "\nInserire la Password per accedere al DataBase [$db_password]: ";}
  else
   { print "\nInsert the Password to DataBase access [$db_password]: ";}

  chomp( $choice = <STDIN> );
  $db_password = $choice if $choice;
  $db_password = '' if $db_password eq 'yourDbPwd';

                          #####################
      #############################################################
                       ############################

  $choice = '';
  while (!$choice)
   {
    if ($default_lang eq 'it')
     { print "\nNome dell'Host o IP dove risiede il database [$db_host]: ";}
    else
     { print "\nDatabase Host name or IP [$db_host]: ";}

    chomp( $choice = <STDIN> );
    if (!$choice && $db_host) { $choice = $db_host; }
   }

  $db_host = $choice;

                          #####################
      #############################################################
                       ############################

  $choice = '';
  $db_port ||= $db_driver eq 'postgres' || $db_driver eq 'pg' ? 5432 : 3306;

  while (!$choice)
   {
    if ($default_lang eq 'it')
     { print "\nPorta tcp/ip del Database [$db_port]: "; }
    else
     { print "\nTcp Port to connect to Database [$db_port]: "; }

    chomp( $choice = <STDIN> );
    $choice = $db_port if !$choice && $db_port;
   }
  $db_port = $choice;

                          #####################
      #############################################################
                       ############################

  _clear_screen();
  if ($default_lang eq 'it')
   {
    print <<FINE;
$color_green
Step 7.
$color_white

Bene, ora mi occorre sapere la directory nella  quale  IGSuite  creera' le
cartelle  che  conterranno  tutti  i  documenti  archiviati. Considera che
questa  directory  deve  coincidere  con la variabile "DocumentRoot" della
configurazione  di  Apache  ( o  della  configurazione  del VirtualHost di
Apache  dedicato a IGSuite ) e  deve  anche  poter  essere letta e scritta
dall'utente che avvia Apache "$www_user".

Non solo!  questa  directory dovra' essere configurata come una "SHARE" di
Samba il  quale  dovra'  sempre  operare come utente "$www_user" al fine di
permettere la lettura  e  la  scrittura degli  stessi file sia dal web che
tramite cartelle condivise dai client.

Accertarsi  che  la  directory  specificata  abbia impostati i permessi di
lettura e  scrittura  per l'utente  $www_user . Questo script per motivi di
sicurezza non cambiera' i permessi delle directory.

N.B. E' qui' che verra' creato il file index.html di partenza!!

FINE
   }
  else
   {
    print <<FINE;
$color_green
Step 7.
$color_white

Now I need to know the directory where IGSuite will create the folders that
will contain all filed documents.
You  have to  know  that  this directory have to  coincide with the variable
"DocumentRoot"  in Apache  configuration file ( or in the VirtualHost Apache
configuration file ) and  it  must  therefore  be  able to be read and to be
written from the user who starts Apache "$www_user".

This  directory  will have to be  configured like a " SHARE " of Samba which
will have  always to  operate like  user " $www_user " to the aim to allow to
the  reading  and the  writing of  the same  files from the web that through
shared folders.

You have to assess that the directory specified had set up the reading and
writing permissions for  the  user "$www_user".  This script  for  security
reasons will not change the directory permission.

In this directory I'll copy the index.html file to start IGSuite! 

FINE
   }
  $choice = '';
  while (!$choice)
   {
    print "\nDirectory dei dati [$htdocs_dir]: ";
    chomp( $choice = <STDIN> );
    $choice = $htdocs_dir if !$choice && $htdocs_dir;
   }
  $htdocs_dir = $choice;
  $htdocs_dir =~ s/(\/|\\)$//g;

                          #####################
      #############################################################
                       ############################

  _clear_screen();
  if ($default_lang eq 'it')
   {
    print <<FINE;
$color_green
Step 8.
$color_white

Mi occorre sapere se il DocumentRoot di IGSuite si trova in un sottopercorso
rispetto a quello principale.

Ad Esempio nel caso tu avessi http://www.miosito.it/Demo/ il sottopercorso
che devi indicare e' /Demo.

Se non esiste nessun sottopercorso e quindi chiamerai IGSuite direttamente
con http://www.miosito.it/ puoi' indicare '/'.

FINE
   }
  else
   {
    print <<FINE;
$color_green
Step 8.
$color_white

I need to know if the DocumentRoot of IGSuite is located in a sub-location
different from the Root.

For example if you have http://www.mysite.com/Demo/ you have to write /Demo
as sub-location.

If there isn't any sub-location just '/'.

FINE
   }
  $choice = '';
  $webpath ||= '/';
  while (!$choice)
   {
    print "IGSuite web-path [$webpath]: ";
    chomp( $choice = <STDIN> );
    $choice = $webpath if !$choice && $webpath;
   }
  $webpath = $choice;
  $webpath =~ s/^(\/|\\)//;
  $webpath =~ s/(\/|\\)$//;
  $webpath = "/" . $webpath;

                          #####################
      #############################################################
                       ############################

  _clear_screen();
  if ($default_lang eq 'it')
   {
    print <<FINE;
$color_green
Step 9.
$color_white

IGSuite  e'  anche  un  ottimo  client  per  HylaFax (diffuso server di FAX)
specificare di seguito l'IP o il nome dell'host dove HylaFax e' installato
e accessibile dagli utenti che poi si creeranno su IGSuite.

Se non si vuole utilizzare Hylafax premere semplicemente INVIO.

FINE
   }
  else
   {
    print <<FINE;
$color_green
Step 9.
$color_white

IGSuite is a good client for HylaFax (famous server fax) you have to specify
the IP or the host name where a Hylafax server is installed and where
IGSuite user can access.

If you don't want to install Hylafax just press "enter".

FINE
   }
  $choice = '';
  print "Hylafax Ip / Host name [$hylafax_host]: ";
  chomp( $choice = <STDIN> );
  $hylafax_host = $choice if $choice;

                          #####################
      #############################################################
                       ############################

  _clear_screen();
  if ($default_lang eq 'it')
   {
    print <<FINE;
Bene  ora  procedero' ad  aggiornare  il  file  "igsuite.conf"  e  a copiarlo
nella directory $cgi_dir${S}conf, dopodiche' copiero'
tutti i cgi e avviero' lo script "mkstruct.pl". Accertarsi che "$db_driver"
sia attivo. Lo script mkstruct.pl provvedera':
- a creare  se non  esiste la struttura di directory necessaria a IGSuite per
  funzionare sotto la directory "$htdocs_dir".
- a creare o ad aggiornare se gia' esistono tutti i database e le tabelle che
  occorrono alla suite all'interno di "$db_driver" con l'account "$db_login".
- a creare un file index.html nella directory "$htdocs_dir".

Login di Amministrazione di IGSuite      :  $login_admin
Password di Amministrazione di IGSuite   :  $pwd_admin
Utente che esegue Apache                 :  $www_user
Login:Password per accedere al Database  :  $db_login:$db_password
Driver del Database da usare             :  $db_driver
Nome del database                        :  $db_name
Host e porta di collegamento al Database :  $db_host $db_port
Directory dei CGI                        :  $cgi_dir
Directory dei Documenti                  :  $htdocs_dir
Percorso sul web                         :  $webpath
Host di HylaFax                          :  $hylafax_host
$color_green
Vuoi continuare con l'installazione [S/n]: $color_white
FINE
   }
  else
   {
  print <<FINE;
If  the  specified  data  are  exact  I will proceed  to update  the file
"igsuite.conf" and to copy it in the directory "$cgi_dir${S}conf",
after I will copy all the cgi's and I will start the script "mkstruct.pl"
The script mkstruct.pl will:
- create  if doesn't  exist  the directory structure needed by IGSuite to
  work under the directory "$htdocs_dir".
- create or update if don't exist  all the databases and tables that need
  inside "$db_driver" by "$db_login" account login.
- create a file called index.html in the directory $htdocs_dir

IGSuite Administrator login          :   $login_admin
IGSuite Administrator password       :   $pwd_admin
User who own Apache                  :   $www_user
Login:Password to Database access    :   $db_login:$db_password
Database Driver to use               :   $db_driver
Database Host and port to connect    :   $db_host $db_port
Database Name                        :   $db_name
Directory of CGI                     :   $cgi_dir
Directory of Documents               :   $htdocs_dir
Web path                             :   $webpath
HylaFax server host                  :   $hylafax_host
$color_green
Do you want to continue [Y/n]: $color_white
FINE
   }

  chomp( $choice = <STDIN> );
  die("ABORT: Interrupted by user\n") if $choice !~ /^(y|s)*$/i; 
 }

###########################################################################
###########################################################################
sub mk_install
 {
  _clear_screen() if $install_mode eq 'manual';

  ## Write a new configuration file #######################################
  print "Write a new configuration file...\n";
  $webpath = '' if $webpath eq '/';

  open ( DAT, '<', ".${S}conf${S}igsuite.conf")
    or die("ABORT: Can't open '.${S}conf${S}igsuite.conf' ".
           "how it's possible? this is a package file. ".
           "Are you executing install.pl from the unpacked package?\n");
  my @conf_rows = <DAT>;
  close(DAT);

  my @procs =qw(soc_fax		soc_name	soc_email	soc_address
		soc_city	soc_zip		soc_prov	soc_tel
		soc_country	soc_logo	soc_site	debug

		default_lang	login_admin	pwd_admin	crypt_key
		webpath		www_user	hosts_allow     server_name
		htdocs_dir	cgi_dir		temp_dir	logs_dir

		db_login	db_password	db_driver	db_host
		db_port		db_name

                htdocs_path{'konqueror-linux'}  htdocs_path{'mozilla-win'}
                htdocs_path{'msie-win'}         htdocs_path{'mozilla-linux'}
                htdocs_path{'galeon-linux'}     htdocs_path{'opera-linux'}

		hylafax_dir	hylafax_host	hylafax_port	hylafax_login
		hylafax_pwd
	
		def_wiki_show	def_wiki_edit	htaccess_contacts

		ext_app{gs}	  ext_app{convert} ext_app{htmldoc} 
                ext_app{htpasswd} ext_app{tiffcp}  ext_app{sendmail} 
                ext_app{aspell}	  ext_app{dprof}   ext_app{tiff2pdf}
                ext_app{faxinfo}

                plugin_conf{weather}{code}  plugin_conf{weather}{metric_system}
                plugin_conf{sms}{username}  plugin_conf{sms}{password}
                plugin_conf{sms}{sender}
                plugin_conf{news}{rss_url}  plugin_conf{fckeditor}{webpath}
                plugin_conf{voip}{protocol} plugin_conf{voip}{prefix}

                ldap_conf{active}           ldap_conf{hostname}
                ldap_conf{port}             ldap_conf{version}
                ldap_conf{usessl}           ldap_conf{admin_dn}
                ldap_conf{admin_pwd}        ldap_conf{search_base}
                ldap_conf{user_dn}          ldap_conf{auto_create_user}                	

                pop3_conf{host}   pop3_conf{login} pop3_conf{pwd}
                pop3_conf{debug}  pop3_conf{auth}  pop3_conf{usessl}
                pop3_conf{port}   pop3_conf{timeout}

                smtp_conf{host}   smtp_conf{debug}  smtp_conf{port}

		smtp_port	  folderquota	   attlimit	homedirspools
		homedirspoolname  mailspooldir     hashedmailspools );

  ## Set $db_name to 'igsuite'. Beginning from 3.2 default db name
  ## will be igsuite instead of isogest. We can't allow use of 'isogest'
  $db_name = 'igsuite' if !$db_name || $db_name eq 'isogest';

  ## Insert new values inside config file items.
  ## Copy original igsuite.conf to igsuite.conf.orig
  {
   local $^I = '.orig';
   open (DET, '>', ".${S}conf${S}igsuite.conf")
     or die("ABORT: Can't write to '.${S}conf${S}igsuite.conf' ".
            "check file and directory permissions\n");

   for my $i ( 0 .. $#conf_rows )
    {
     for (@procs)
      {
       my $value = eval "\$$_";
          $value =~ s/\'/\\\'/g;

       $conf_rows[$i] =~ s/(\$\Q$_\E[^\=]*\=)[^\'\"]*(\'|\").*\2\;
                          /$1 \'$value\'\;/x;
      } 
     print DET $conf_rows[$i];
    } 
   close(DET);
  }

  ## Make all directories #################################################
  print "Make all directories needed...\n";

  MkDir($_) for ( "$htdocs_dir${S}images",
                  "$htdocs_dir${S}images${S}charts_library",
  		  "$cgi_dir${S}conf",
		  "$cgi_dir${S}IG",
		  "$cgi_dir${S}tema",
		  "$cgi_dir${S}lang${S}it",
		  "$cgi_dir${S}lang${S}en",
		  "$cgi_dir${S}lang${S}es",
		  "$cgi_dir${S}lang${S}fr",
		  "$cgi_dir${S}lang${S}pt",
		  "$cgi_dir${S}lang${S}nl",
		  "$cgi_dir${S}data",
		  "$cgi_dir${S}data${S}igwiki",
		  "$cgi_dir${S}data${S}igwiki${S}templates",
		  "$cgi_dir${S}log" );

  ## Set a right shebang to each script before copying them ###############
  ## $perl now have the path of perl interpreter
  $perl = setshebang();


  ## Copy all files #######################################################
  print "Copy files...\n";
  for (	[".${S}cgi-bin${S}*",
		"$cgi_dir${S}"],
	[".${S}conf${S}*",
		"$cgi_dir${S}conf${S}"],
	[".${S}IG${S}*",
		"$cgi_dir${S}IG${S}"],
	[".${S}tema${S}*",
		"$cgi_dir${S}tema${S}"],
	[".${S}lang${S}it${S}*",
	        "$cgi_dir${S}lang${S}it${S}"],
	[".${S}lang${S}en${S}*",
        	"$cgi_dir${S}lang${S}en${S}"],
	[".${S}lang${S}es${S}*",
        	"$cgi_dir${S}lang${S}es${S}"],
	[".${S}lang${S}fr${S}*",
        	"$cgi_dir${S}lang${S}fr${S}"],        	
	[".${S}lang${S}pt${S}*",
        	"$cgi_dir${S}lang${S}pt${S}"],
	[".${S}lang${S}nl${S}*",
        	"$cgi_dir${S}lang${S}nl${S}"],
	[".${S}images${S}*",
		"$htdocs_dir${S}images${S}"],
	[".${S}charts_library${S}*",
	        "$htdocs_dir${S}images${S}charts_library${S}"],	
	[".${S}templates${S}*",
        	"$cgi_dir${S}data${S}igwiki${S}templates${S}"],
    )
   {
    @ARGV = (@$_[0], @$_[1]);
    my $target_dir = @$_[1];

    ## delete old files (keep unknow files)
    opendir( DIR, substr(@$_[0], 0, length(@$_[0])-2) );
    for( grep !/^\./, readdir DIR )
     {
      next if ! -e "$target_dir$_" || -d "$target_dir$_";
      unlink "$target_dir$_"
        or die("ABORT: Can't delete old file '$target_dir$_' ".
               "to replace with new one.\n");
     }
    close(DIR);

    ## copy new files
    cp();# or die("Can't copy @$_[0] to @$_[1]");
   }

  ## make cgi scripts executable ##########################################
  if ( $OS eq 'UNIX' )
   {
    print "Changing file permissions...\n";
    ## we use original cgies list to chmod new one
    opendir( DIR, ".${S}cgi-bin" )
      or die("ABORT: Can't open .${S}cgi-bin directory.\n");
    for ( grep !/^\./, readdir DIR )
     {
      next if -d ".${S}cgi-bin${S}$_";# to be sure
      CORE::chmod (0755, "$cgi_dir${S}$_")
        or die("ABORT: Can't make cgi $cgi_dir${S}$_ executable!\n");
     }
    close(DIR);
   }

  ## try to install FCKEditor
  push @INC, $cgi_dir;
  eval 'require IG::FileCopyRecursive';
  if ( !$@ )
   {
    File::Copy::Recursive::dircopy( ".${S}fckeditor", "$htdocs_dir${S}fckeditor" )
      or croak( "Can't copy directory ".
                "'.${S}fckeditor' to '$htdocs_dir${S}fckeditor': $!\n");
   }

  ## adjust logo.gif ######################################################
  if (!(-e "$htdocs_dir${S}images${S}logo.gif"))
   {
    @ARGV = (".${S}images${S}logoigsuite.gif",
           "$htdocs_dir${S}images${S}logo.gif");
    cp();
   }

  ## Start mkstruct.pl to continue the work ###############################
  chdir($cgi_dir);
  print "Make/Upgrade database structure...\n";
  SysExec( $perl,
           "$cgi_dir${S}mkstruct.pl",
           "-dbname=$db_name",
           "-mode=update_release"
         ) or die("ABORT: Can't execute script: ".
                  "'$perl ".
                  "$cgi_dir${S}mkstruct.pl ".
                  "-dbname=$db_name ".
                  "-mode=update_release' ".
                  "to complete install work! Try to execute it manually.\n");
 }

###########################################################################
###########################################################################
sub _clear_screen
 {
  print "\n" x 40;
 }

###########################################################################
###########################################################################
sub setshebang
 {
  my @rows;
  my $perl = "/usr/bin/perl";
  return ($perl) if -e $perl;

  for  ("c:\\perl\\bin\\perl.exe",
	"/usr/local/bin/perl",
	"/bin/perl",
	"$^X",
	"$Config{bin}${S}perl",
	"$Config{bin}${S}perl.exe" )
   { ($perl=$_) && last if -e $_ }

  die( "ABORT: Can't find and setting a perl shebang ".
       "in your scripts! where is Perl interpreter?\n" ) if ! -e $perl;

  for (<.${S}cgi-bin${S}*>)
   {
    undef @rows;
    open (IN, '<', $_);
    binmode(IN);
    @rows = <IN>;
    close (IN);
    next if substr($rows[0],0,2) ne "#!";
    $rows[0] = "#! $perl\n";

    if ( $OS eq 'WINDOWS' )
     {
      ## adjust \r\n according to OS
      s/\n$/\r\n/ for @rows;
     }

    open (OUT, '>', $_);
    binmode(OUT);
    print OUT @rows;
    close (OUT);
   }

  return($perl);
 }

###########################################################################
###########################################################################
###########################################################################
sub MkDir
 {
  my $dire = shift;
  my $newdir;
  my $SL = quotemeta($S);

  for ( split /$SL/,$dire )
   {
    if (!$newdir && $OS eq 'WINDOWS')
     { $newdir = $_; }
    else
     { $newdir .= "$S$_"; }

    if ( ! -e $newdir )
     {
      mkdir $newdir,0777
        or die("ABORT: Can't create $newdir check permissions\n");
      print "Make dir: $newdir\n";
     }    
   }  
 }


###########################################################################
###########################################################################
###########################################################################
sub SysExec
 {
  my ($command, @arguments) = @_;

  ##Check and adjust command path
  if (! -e $command)
   {
    my @command = split /\/|\\/, $command;
    $command = pop(@command);

    foreach (split(/:/ , $env_path))
     {
      if (-e "$_$S$command")
       {
        $command = "$_$S$command";
        last;
       }
     }
   }

  ## Ok let's go to execute
  my $oldfh = select(STDERR);
  system( $command, @arguments );
  $| = 1; ## Flush STDOUT
  select($oldfh);
  return $? == -1 ? 0 : 1; ## I know it's not a complete manner
 }

###########################################################################
###########################################################################
sub _set_defaults
 {
  ## Installation and default IG language
  $default_lang = 'it';

  ## Try to find from my self some vars needed to installation
  for my $apache_conf_dir (        "${S}usr${S}local${S}apache${S}conf",
                                   "${S}usr${S}local${S}etc${S}apache",
                                   "${S}usr${S}local${S}etc${S}apache${S}apache.conf",
                                   "${S}usr${S}local${S}etc${S}httpd${S}conf",
                                   "${S}usr${S}local${S}apache2${S}conf",
                                   "${S}usr${S}local${S}psa${S}apache${S}conf",
                                   "${S}www${S}conf",
                                   "${S}var${S}www${S}conf",
                                   "${S}etc${S}apache${S}conf",
                                   "${S}etc${S}apache",
                                   "${S}etc${S}apache2",
                                   "${S}etc${S}httpd${S}conf",
                                   "c:\\Programmi\\Apache Group\\Apache\\conf" )
   {
    foreach my $apache_conf_file ( "httpd.conf",
                                   "uid.conf",
                                   "default-server.conf" )
     {
      my $cgiconf = $apache_conf_dir . $S . $apache_conf_file;
      if ( -f $cgiconf )
       {
        open (HTTPDCONF, '<', $cgiconf) or next;

        while (<HTTPDCONF>)
         {
          if (/^\s*User\s+"?([-\w]+)"?\s*$/)
           {
            $www_user = $1;
           }
          if (/^[^\#]*ScriptAlias\s+[^\s]+\s+([^\s]+)\s*$/)
           {
            $cgi_dir = $1;
            $cgi_dir =~ s/\"//g;
           }
          if (/^\s*DocumentRoot\s+([^\s]+)\s*$/)
           {
            $htdocs_dir = $1;
            $htdocs_dir =~ s/\"//g;
           }
         }
        close(HTTPDCONF);
       }
     }
   }
  
  if ( !$cgi_dir )
   {
    for my $_cgid ( '/srv/www/cgi-bin' )
     {
      next if ! -d $_cgid;
      $cgi_dir = $_cgid;
      last;
     }
   }
 }

###########################################################################
###########################################################################
sub _load_previous_config_file()
 {
  if (-e "$cgi_dir${S}conf${S}igsuite.conf")
   {
    require "$cgi_dir${S}conf${S}igsuite.conf";
   }
  elsif (-e "$cgi_dir${S}conf${S}isogest.conf")
   {
    require "$cgi_dir${S}conf${S}isogest.conf";
   } 
  else
   {
    ## ok none previous configuration file... try to load default one
    require ".${S}conf${S}igsuite.conf";
   }

  die("ABORT: Tried to load default or previous configuration file ".
      "but an error occurred\n") if $@;
 }

###########################################################################
###########################################################################
sub _check_system
 {
  ## Copy & Paste From CGI.pm

  unless ($OS = $^O) { $OS = $Config::Config{'osname'}; }

  if    ( $OS =~ /Win/i     ) { $OS = 'WINDOWS';   }
  elsif ( $OS =~ /vms/i     ) { $OS = 'VMS';       }
  elsif ( $OS =~ /bsdos/i   ) { $OS = 'UNIX';      }
  elsif ( $OS =~ /dos/i     ) { $OS = 'DOS';       }
  elsif ( $OS =~ /^MacOS$/i ) { $OS = 'MACINTOSH'; }
  elsif ( $OS =~ /os2/i     ) { $OS = 'OS2';       }
  else                        { $OS = 'UNIX';      }

  $S = { UNIX=>'/', OS2=>'\\', WINDOWS=>'\\', DOS=>'\\', MACINTOSH=>':', VMS=>'/' }->{$OS};

  $env_path = $ENV{PATH};
 }
