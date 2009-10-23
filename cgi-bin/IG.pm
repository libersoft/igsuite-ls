## IGSuite 4.0.0
## Procedure: IG.pm
## Last update: 25/05/2009
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

package IG;

## Uncomment under developing
use	strict;
#use    warnings;
#use    diagnostics;
#use    IG::Benchmark ':hireswallclock';
#use    Data::Dumper;

use	Carp qw(verbose croak);
use	IG::CGISimple qw(-no_debug);
use	IG::CGIAjax;


use vars qw(	%privileges	%timezones	%countries	$www_user
		%in		%on		%cookie		%set_cookie
		$S		$OS		@ISA		@EXPORT

		$crypt_key      $login_admin	%users		$auth_user
		$remote_host	$pwd_admin	$webpath	$img_url
		%htdocs_path	%menu_item	$user_dir	$htaccess_contacts
		$server_name    $data_dir

		$client_browser	$client_os	$tema		$link
		$screen_size	$page_results	$list_order	$date_format
		$timeoffset	$lang		$default_lang	%default_lang
		%attr		%languages	@task_list_content
		$cgi_path	$cgi_dir	$cgi_url	$logs_dir
		$conf_dir	$htdocs_dir	$temp_dir	$query_string
		$request_method $app_nspace	$task_list_cols	$task_list_rows
		$page_tabindex	$cgi_name	$cgi_ref	%lang
		%docs_type	$demo_version   $debug		$lang_charset

		%pop3_conf	%smtp_conf	%ldap_conf      $homedirspools
		$folderquota	$attlimit	$homedirspoolname
		$mailspooldir	$hashedmailspools		$hosts_allow

		@errmsg		%debug_info	%ext_app	%plugins

		$def_wiki_show	$def_wiki_edit  %user_conf	%plugin_conf

		$soc_name	$soc_address	$soc_email	$soc_city
		$soc_zip	$soc_prov	$soc_tel	$soc_fax
		$soc_logo	$soc_country	$soc_site

		$db_name	$db_driver	$db_login	$db_password
		$db_host	$db_port	@db_fields_name	@db_fields_num

		$hylafax_host	$hylafax_port	$hylafax_login	$hylafax_pwd
		$hylafax_dir

		%executed	%months		%tv		$session_timeout
		@days		$thousands_separator $decimal_separator
		$currency	$prout_page     %js_code        %offers_category		

		$tasksfontname	$tasksfontsize	$barrafontsize	$barrafontname
		$menufontname	$menufontsize	$buttonfontsize	$buttonfontname
		%clr		%tema           $_IS_MOD_PERL   $use_internal_help
		%lockCount
	   );

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(	HtmlHead	HtmlFoot	TaskHead	TaskFoot
		TaskListMenu	TaskListItem	TaskListFoot	TaskMsg
		CkDate          MkButton	HLayer          CkPath
		MkLink		ParseLink	DirectLink	MkTable
		Blush		Img		HTitle		DbQuery
		FetchRow	DbQuote		FormHead	Input
		MkUrl DeUrl	Br		MkEntities	QuoteParams
		CheckPrivilege	LogD		FormFoot        DbWrite
		MkId		GetTableVal	HttpHead        PrOut

		$auth_user	%lang
		$S		%in		%on		%tv
	    );


## Errors and Warnings trap
##
BEGIN
 {
  ## Defines IG Version
  use vars qw ($VERSION);
  ## Current IGSuite version
  $VERSION = '4.0.0-libersoft0023';

  $SIG{__DIE__} =
   sub {
	## In this sub we cannot use any framework features
	my ( $pack, $file, $line, $sub ) = CORE::caller(0);
	return if $file =~ /eval|Config.pm/;

        my ($msg, $err) = join(' ', @_), $@;
	my %tv;
	my $proc = $0;
	my $req = $ENV{REQUEST_METHOD}; ## we are a cgi or not?

	## Adjusts time and date values
	my ($s, $m, $h, $g, $me, $ye, $wday, $y, $k) = localtime(time);
	$tv{today} = sprintf("%04d-%02d-%02d", (1900+$ye), ($me+1), $g);
	$tv{time}  = sprintf("%02d:%02d", $h, $m);

        ## Print a raw html header
	print "Content-type: text/html\n\n" if $req;
	print qq~<html></head><title>IGSuite Error</title></head>
	   <style>table,td { font-size: 11px }</style>
	   <body style="background:#FFFFFF"><br><br>
	   <table align="center" style="background:#FFFFFF; border:1px solid #000000; width:500px;">
		<td style="color:white; background:#999999; font-size:130%">
		IGSuite Error</td></tr>
		<td>~ if $req;

	if (open (CGI, '<', $ENV{SCRIPT_FILENAME}))
	 {
	  $proc = <CGI>; $proc = <CGI>; $proc .= "last modified".<CGI>;
	  $proc =~ s/(\# Last update\:|\# Procedure\:)//g;
	  $proc =~ s/(\r|\n)/ /g;
	  close(CGI);
	  $proc ||= $ENV{SCRIPT_FILENAME};
	 }

	print ($req ? '<br><table>' : "\nIGSuite Error\n".('-'x13)."\n");
	my %values = (	Description => $req
				    ? "<span style=\"color:#880000;\">".
				      "$msg - $err</span>"
				    : "$msg - $err",
			User	    => $auth_user,
			Server	    => "$ENV{SERVER_NAME} with $OS",
			Procedure   => $proc,
			IG_Version  => $VERSION,
			Mod_Perl    => $ENV{MOD_PERL},
			Perl_Version=> $],
			Date	    => "$tv{today} $tv{time}" 
		     );

        print STDERR "$msg - $err" if $req; ## Apache Error Log

	foreach (keys %values)
	 {
	  next if ! $values{$_};
          print $req
	        ? "<tr><td valign=\"top\"><strong>$_</strong></td>".
	          "<td valign=\"top\">$values{$_}</td></tr>\n"
                : substr("$_          ",0,13) . ": $values{$_}\n";
	 }

	print qq~<tr><td colspan=2 bgcolor="#EEEEEE">
		To obtain more information please contact your System
		Administrator or if you want, try to send this message to
		staff\@igsuite.org
		</td></tr></table>
		</td></tr></table>
		</body></html>~ if $req;

        undef $prout_page;
        undef %executed;

        ## modperl will call Apache::exit() instead
	exit() if ! $HTTP::Server::Simple::VERSION; 
       };

  ## Warnings Trap (to uncomment under development)
  #$SIG{__WARN__} =
  # sub {
  #      my $warn_msg = shift;
  #      return if $warn_msg =~ /Use of uninitialized value/i;
  #      return if $warn_msg =~ /name "(?:.+?)" used only once/i;
  #      return if $warn_msg =~ /Subroutine .+? redefined at/i;
  #      return if $warn_msg =~ /Odd number of elements in hash assignment/i;
  #      warn $warn_msg;
  #     };
 }


## FIGURE OUT THE OS WE'RE RUNNING UNDER (similar to CGI.pm)
##
unless ($OS = $^O)
 {
  require Config;
  $OS = $Config::Config{'osname'};
 }

if    ( $OS =~ /linux/i  ) { $OS = 'UNIX';	$S = '/'  }
elsif ( $OS =~ /^MSWin/i ) { $OS = 'WINDOWS';	$S = '\\' }
elsif ( $OS =~ /^VMS/i   ) { $OS = 'VMS';	$S = '/'  }
elsif ( $OS =~ /^dos/i   ) { $OS = 'DOS';	$S = '\\' }
elsif ( $OS =~ /^MacOS/i ) { $OS = 'MACINTOSH';	$S = ':'  }
elsif ( $OS =~ /^os2/i   ) { $OS = 'OS2';	$S = '\\' }
elsif ( $OS =~ /^epoc/i  ) { $OS = 'EPOC';	$S = '/'  }
elsif ( $OS =~ /^cygwin/i) { $OS = 'CYGWIN';	$S = '/'  }
else 	                   { $OS = 'UNIX';	$S = '/'  }


## Remember, only PerlRun
$_IS_MOD_PERL = $ENV{MOD_PERL}
              ? $ENV{MOD_PERL_API_VERSION} >= 2
                ? 2
                : 1
              : 0 ;

## Misc form flag and vars
my %form = ();

## Page/Window Title
my $page_title = '';
my %page_boxes;

## Reference to database connections
##
my %conn;   # database handles
my @result; # statement handles
my $queryid = 0;

## This is the privilege list. First field is the name of privilege next
## there are an ID and the relative script. If the script is not present
## on the package, IG ignore the privilege
##
%privileges = (
	'archive_view',			[32, 'archive'],
	'archive_edit',			[33, 'archive'],
	'archive_link',			[15, 'archive'],
	'archive_tiff',			[80, 'tiffedit'],
	'archive_alert',		[17, 'archive'],
	'archive_template',		[23, 'archive'],
	'archive_report',		[112,'reports'],

	'contacts_view',		[44, 'contacts'],
	'contacts_new',			[45, 'contacts'],
	'contacts_edit',		[46, 'contacts'],
	'contacts_report',		[95, 'contacts'],
	'contacts_import',              [133,'contacts'],

	'contacts_group_view',		[65, 'contacts'],
	'contacts_group_edit',		[94, 'contacts'],
	'contacts_group_new',		[66, 'contacts'],

	'contracts_revue',		[53, 'contracts'],
	'contracts_revue_c',		[54, 'contracts'],
	'contracts_revue_t',		[55, 'contracts'],
	'contracts_revue_s',		[56, 'contracts'],
	'contracts_view',		[57, 'contracts'],
	'contracts_edit',		[58, 'contracts'],
	'contracts_phases_edit',	[60, 'contracts'],
	'contracts_link',		[71, 'contracts'],
	'contracts_template',		[101,'contracts'],
	'contracts_report',		[106,'contracts'],

	'webmail_view',			[77, 'webmail'],
	'webmail_circulars',		[89, 'webmail'],
	'webmail_new',			[90, 'webmail'],
	'webmail_edit',			[91, 'webmail'],
	'webmail_extra',		[92, 'webmail'],
	'webmail_template',		[102,'webmail'],
	'webmail_link',			[120,'webmail'],

	'equipments_view',		[11, 'equipments'],
	'equipments_edit',		[12, 'equipments'],
	'equipments_extra',		[13, 'equipments'],
	'equipments_alert',		[14, 'equipments'],
	'equipments_link',		[119,'equipments'],

	'igfax_view',			[79, 'igfax'],
        'igfax_edit',			[100,'igfax'],
	'igfax_send',			[31, 'igfax'],

	'fax_received_view',		[28, 'fax_received'],
       	'fax_received_edit',		[30, 'fax_received'],
	'fax_received_report',		[111,'reports'],
	'fax_received_link',		[121,'fax_received'],

	'fax_sent_view',		[88, 'fax_sent'],
	'fax_sent_edit',		[29, 'fax_sent'],
	'fax_sent_report',		[110,'reports'],
	'fax_sent_link',		[122,'fax_sent'],

	'filemanager_view',		[81, 'filemanager'],
	'filemanager_superuser',	[82, 'filemanager'],
	'filemanager_edit',		[59, 'filemanager'],
	'filemanager_limit_to_home',    [128,'filemanager'],

	'letters_view',			[41, 'letters'],
	'letters_edit',			[42, 'letters'],
	'letters_link',			[93, 'letters'],
	'letters_template',		[43, 'docmaker'],
	'letters_report',		[109,'reports'],

	'nc_ext_view',			[8,  'nc_ext'],
	'nc_ext_edit',			[9,  'nc_ext'],
	'nc_ext_template',		[10, 'docmaker'],
	'nc_ext_link',			[98, 'nc_ext'],
	'nc_ext_alert',			[84, 'nc_ext'],
	'nc_ext_report',		[105,'reports'],

	'nc_int_alert',			[83, 'nc_int'],
	'nc_int_view',			[74, 'nc_int'],
	'nc_int_edit',			[75, 'nc_int'],
	'nc_int_template',		[76, 'docmaker'],
	'nc_int_link',			[68, 'nc_int'],
	'nc_int_report',		[108,'nc_int'],

	'offers_view',			[48, 'offers'],
	'offers_edit',			[51, 'offers'],
	'offers_template',		[52, 'docmaker'],
	'offers_link',			[96, 'offers'],
	'offers_report',		[107,'offers'],

	'opportunities_view',		[103,'opportunities'],
	'opportunities_edit',		[104,'opportunities'],
	'opportunities_report',		[114,'reports'],

	'orders_view',			[61, 'orders'],
	'orders_alert',			[62, 'orders'],
	'orders_edit',			[63, 'orders'],
	'orders_template',		[64, 'docmaker'],
	'orders_link',			[97, 'orders'],
	'orders_report',		[113,'reports'],

	'products_view',		[34, 'products'],
	'products_edit',		[35, 'products'],
	'products_new',			[36, 'products'],
	'products_history',		[37, 'products'],
	'products_articles_view',	[38, 'articles'],
	'products_articles_edit',	[39, 'articles'],
	'products_articles_new',	[40, 'articles'],

	'users_view',			[19, 'users'],
	'users_edit',			[20, 'users'],
	'users_new',			[21, 'users'],

	'users_groups_view',		[116,'users_groups'],
	'users_groups_edit',		[117,'users_groups'],
	'users_groups_new',		[118,'users_groups'],

	'documentation_view',		[5,  'documentation'],
	'documentation_edit',		[6,  'documentation'],
	'documentation_new',		[7,  'documentation'],
	'documentation_editor',		[18, 'documentation'],
	'documentation_link',		[22, 'documentation'],

	'services_view',		[24, 'services'],
	'services_edit',		[25, 'services'],
	'services_extra',		[26, 'services'],
	'services_report',		[27, 'services'],
	'services_alert',		[85, 'services'],

	'sys_user_admin',		[1,  'users'],
	'sys_help_edit',		[72, 'help'],
	'sys_tickler_view',		[47, 'tickler'],
	'sys_log_view',			[70, 'system_log'],
	'sys_delete_comments',		[16, 'igsuite'],
	'sys_preferences_edit',		[49, 'preferences'],
	'sys_sms_send',			[115,'igsms'],
        'sys_limit_calendar',		[87, 'calendar'],

	'todo_view',			[73, 'todo'],
	'todo_alert',			[78, 'todo'],

	'vendors_view',			[2,  'vendors'],
	'vendors_edit',			[3,  'vendors'],
	'vendors_report',		[4,  'vendors'],

	'igwiki_edit',			[67, 'igwiki'],
	'igwiki_view',			[69, 'igwiki'],
	'igwiki_writer',		[86, 'igwiki'],

	'postit_edit',			[50, 'postit'],
        'postit_view',			[99, 'postit'],

        'igchats_view',			[123,'igchats'],
        'igchats_change_room',		[124,'igchats'],
        'igchats_available_to_chat',	[125,'igchats'],

        'igforms_view',                 [126,'igforms'],
        'igforms_edit',                 [127,'igforms'],
        
        'binders_view',                 [129,'binders'],
        'binders_new',                  [130,'binders'],
        'binders_edit',                 [131,'binders'],
        'binders_report',               [132,'binders'],
        
     'nc_ph_new',				[134, 'nc_ph'],
     'nc_ph_confirm',			[135, 'nc_ph'],
     'nc_ph_validate',			[136, 'nc_ph'],
	);

## Time zones
##
%timezones = qw(   ACDT +1030
                   ACST +0930
                   ADT  -0300
                   AEDT +1100
                   AEST +1000
                   AHDT -0900
                   AHST -1000
                   AST  -0400
                   AT   -0200
                   AWDT +0900
                   AWST +0800
                   AZST +0400
                   BAT  +0300
                   BDST +0200
                   BET  -1100
                   BST  -0300
                   BT   +0300
                   BZT2 -0300
                   CADT +1030
                   CAST +0930
                   CAT  -1000
                   CCT  +0800
                   CDT  -0500
                   CED  +0200
                   CET  +0100
                   CST  -0600
                   EAST +1000
                   EDT  -0400
                   EED  +0300
                   EET  +0200
                   EEST +0300
                   EST  -0500
                   FST  +0200
                   FWT  +0100
                   GMT  +0000
                   GST  +1000
                   HDT  -0900
                   HST  -1000
                   IDLE +1200
                   IDLW -1200
                   IST  +0530
                   IT   +0330
                   JST  +0900
                   JT   +0700
                   MDT  -0600
                   MED  +0200
                   MET  +0100
                   MEST +0200
                   MEWT +0100
                   MST  -0700
                   MT   +0800
                   NDT  -0230
                   NFT  -0330
                   NT   -1100
                   NST  +0630
                   NZ   +1100
                   NZST +1200
                   NZDT +1300
                   NZT  +1200
                   PDT  -0700
                   PST  -0800
                   ROK  +0900
                   SAD  +1000
                   SAST +0900
                   SAT  +0900
                   SDT  +1000
                   SST  +0200
                   SWT  +0100
                   USZ3 +0400
                   USZ4 +0500
                   USZ5 +0600
                   USZ6 +0700
                   UT   +0000
                   UTC  +0000
                   UZ10 +1100
                   WAT  -0100
                   WET  +0000
                   WST  +0800
                   YDT  -0800
                   YST  -0900
                   ZP4  +0400
                   ZP5  +0500
                   ZP6  +0600);

## International country codes
##
%countries = (
		AF => 'Afghanistan',
		AL => 'Albania',
		DZ => 'Algeria',
		AS => 'American Samoa',
		AD => 'Andorra',
		AO => 'Angola',
		AG => 'Antigua & Barbuda',
		AR => 'Argentina',
		AM => 'Armenia',
		AU => 'Australia',
		AT => 'Austria',
		AJ => 'Azerbaydzhan',
		BS => 'Bahamas',
		BH => 'Bahrain',
		BD => 'Bangladesh',
		BB => 'Barbados',
		BE => 'Belgium',
		BZ => 'Belize',
		BJ => 'Benin',
		BT => 'Bhutan',
		BO => 'Bolivia',
		BA => 'Bosnia & Hercegovina',
		BW => 'Botswana',
		BR => 'Brazil',
		BN => 'Brunei',
		BG => 'Bulgaria',
		BF => 'Burkina Faso',
		BI => 'Burundi',
		BY => 'Byelorussia',
		KH => 'Cambodia',
		CM => 'Cameroon',
		CA => 'Canada',
		CV => 'Cape Verde',
		CF => 'Central African Rep.',
		TD => 'Chad',
		IC => 'Channel Islands',
		CL => 'Chile',
		CN => 'China',
		CO => 'Colombia',
		KM => 'Comores',
		CG => 'Congo',
		ZR => 'Congo (Dem.Rep.)',
		CR => 'Costa Rica',
		HR => 'Croatia',
		CU => 'Cuba',
		CY => 'Cyprus',
		CZ => 'Czech Republic',
		DK => 'Denmark',
		DJ => 'Djibouti',
		DM => 'Dominica',
		DO => 'Dominican Republic',
		EC => 'Ecuador',
		EG => 'Egypt',
		SV => 'El Salvador',
		GQ => 'Equatorial Guinea',
		ER => 'Eritrea',
		EE => 'Estonia',
		ET => 'Ethiopia',
		FO => 'Faeroe Islands',
		FK => 'Falklands',
		FJ => 'Fiji',
		FI => 'Finland',
		FR => 'France',
		GF => 'French Guiana',
		FP => 'French Polynesia',
		GA => 'Gabon',
		GM => 'Gambia',
		GE => 'Georgia',
		DE => 'Germany',
		GH => 'Ghana',
		GI => 'Gibraltar',
		GR => 'Greece',
		GD => 'Grenada',
		GP => 'Guadeloupe',
		GT => 'Guatemala',
		GU => 'Guernsey',
		GN => 'Guinea',
		GW => 'Guinea-Bissau',
		GY => 'Guyana',
		HT => 'Haiti',
		HN => 'Honduras',
		HK => 'HongKong',
		HU => 'Hungary',
		IS => 'Iceland',
		IN => 'India',
		ID => 'Indonesia',
		IR => 'Iran',
		IQ => 'Iraq',
		IE => 'Ireland',
		IL => 'Israel',
		IT => 'Italy',
		CI => 'Ivory Coast',
		JM => 'Jamaica',
		JP => 'Japan',
		JE => 'Jersey',
		JO => 'Jordan',
		KZ => 'Kazakhstan',
		KE => 'Kenya',
		KG => 'Kirghizia',
		KW => 'Kuwait',
		LA => 'Laos',
		LV => 'Latvia',
		LB => 'Lebanon',
		LS => 'Lesotho',
		LR => 'Liberia',
		LY => 'Libya',
		LI => 'Liechtenstein',
		LT => 'Lithuania',
		LU => 'Luxembourg',
		MO => 'Macau',
		MK => 'Macedonia',
		MG => 'Madagascar',
		MW => 'Malawi',
		MY => 'Malaysia',
		ML => 'Mali',
		MT => 'Malta',
		MI => 'Man Island',
		MQ => 'Martinique',
		MR => 'Mauritania',
		MU => 'Mauritius',
		YT => 'Mayotte',
		MX => 'Mexico',
		MD => 'Moldova',
		MC => 'Monaco',
		MN => 'Mongolia',
		MS => 'Montserrat',
		MA => 'Morocco',
		MZ => 'Mozambique',
		MM => 'Myanmar',
		NA => 'Namibia',
		NP => 'Nepal',
		NL => 'Netherlands',
		AN => 'Netherlands Antilles',
		NZ => 'New Zealand',
		NI => 'Nicaragua',
		NE => 'Niger',
		NG => 'Nigeria',
		KP => 'North Korea',
		NO => 'Norway',
		OM => 'Oman',
		PK => 'Pakistan',
		PA => 'Panama',
		PG => 'Papua New Guinea',
		PY => 'Paraguay',
		PE => 'Peru',
		PH => 'Philippines',
		PL => 'Poland',
		PT => 'Portugal',
		PR => 'Puerto Rico',
		QA => 'Qatar',
		RE => 'Reunion',
		RO => 'Romania',
		RU => 'Russia',
		RW => 'Rwanda',
		KN => 'Saint Kitts & Nevis',
		LC => 'Saint Lucia',
		VC => 'Saint Vincent',
		SM => 'San Marino',
		ST => 'Sao Tome & Principe',
		SA => 'Saudi Arabia',
		SN => 'Senegal',
		SL => 'Sierra Leone',
		SG => 'Singapore',
		SK => 'Slovakia',
		SI => 'Slovenia',
		SO => 'Somalia',
		ZA => 'South Africa',
		KR => 'South Korea',
		ES => 'Spain',
		LK => 'Sri Lanka',
		SD => 'Sudan',
		SR => 'Suriname',
		SZ => 'Swaziland',
		SE => 'Sweden',
		CH => 'Switzerland',
		SY => 'Syria',
		TJ => 'Tadzhikistan',
		TW => 'Taiwan',
		TZ => 'Tanzania',
		TH => 'Thailand',
		VA => 'The Vatican',
		TG => 'Togo',
		TT => 'Trinidad & Tobago',
		TN => 'Tunisia',
		TR => 'Turkey',
		TM => 'Turkmenistan',
		TV => 'Tuvalu',
		UG => 'Uganda',
		UA => 'Ukraine',
		AE => 'United Arab Emirates',
		UK => 'United Kingdom',
		UY => 'Uruguay',
		US => 'USA',
		UZ => 'Uzbekistan',
		UE => 'Venezuela',
		VN => 'Vietnam',
		WA => 'Wallis and Futuna',
		WS => 'Western Samoa',
		YE => 'Yemen',
		YU => 'Yugoslavia',
		ZM => 'Zambia',
		ZW => 'Zimbabwe',
	       );


###########################################################################
###########################################################################
###########################################################################

=head1 ALL FRAMEWORK PROCEDURES

All IG.pm procedures have capitalized words to differ them from standard or
external procedures.

=head2 Generic procedures

=cut

###########################################################################
###########################################################################

=head3 MkEnv(appnamespace)

Generates the IG Environment.

=cut

sub MkEnv
 {
  ## Read application package name (in mod_perl it isn't main!)
  $app_nspace = shift || caller || 'main';

  ## Can't execute mkenv twice unless mod_perl!
  die("Can't execute MkEnv() twice.\n")
    if $executed{mkenv}++ && ! $_IS_MOD_PERL;

  ## Some mod_perl actions
  if ( $_IS_MOD_PERL )
   {
    ## Check mod_perl handler
    die("Can't execute IGSuite under ModPerl::Registry, ".
        "try to configure ModPerl::PerlRun.\n") if ! $ModPerl::PerlRun::VERSION;

    ## reset $^T
    $^T = time();

    ## set default CHLD signal value
    $SIG{CHLD} = 'DEFAULT';

    ## Close all database connections
    ## (only if ther'are persistent connections)
    DbDisconnect();
   }

  ## Take script start time to have a benchmark
  $tv{start_script} = new Benchmark if $Benchmark::VERSION;

  ## Undef user env
  undef $tema;

  ## Undef users preferences
  undef %user_conf;
  
  ## Undef prout_page content
  undef $prout_page;

  ## undef misc form flag and vars
  undef %form;

  ## undef errors buffer
  undef @errmsg;

  ## Page/Window Title & Boxes
  undef $page_title;
  undef %page_boxes;

  ## delete debug info
  undef %debug_info;

  ## Undef Parameters from forms (We love old style!:)
  undef %on;
  undef %in;
  undef $query_string;
  undef %cookie;
  undef %set_cookie;
  undef %attr;
  $executed{htmlhead} = '';
  $executed{htmlfoot} = '';

  ## Undef Users and authentication parameters
  undef %users;
  undef $auth_user;
  undef $login_admin;
  undef $remote_host;

  ## Undef lock count
  undef %lockCount;

  ## Obtain temporary cgi dir
  $ENV{SCRIPT_FILENAME} ||= $0;
  if ( (my @script_part = split( /\\|\//, $ENV{SCRIPT_FILENAME} )) > 1 )
   {
    $cgi_name = pop @script_part;
    ($cgi_path) = $ENV{REQUEST_URI} =~ /\/(.+)\/$cgi_name/;
    $cgi_dir  = substr( $ENV{SCRIPT_FILENAME},
                        0,
                        length($ENV{SCRIPT_FILENAME}) - length($cgi_name)-1 );
    $cgi_dir ||= '.';
   }
  else
   {
    $cgi_name = $0;
    $cgi_dir  = '.';
    $cgi_path = '';
   }

  if ( $cgi_dir =~ /^\./ )
   {
    ## we want an absolute path
    require Cwd;
    my $dir  = Cwd::getcwd();
    $cgi_dir = $dir if -e "$dir${S}IG.pm";
   }

  ## Set configuration files directory
  $conf_dir = "$cgi_dir${S}conf";

  ## Insert cgi dir in @INC
  push @INC, $cgi_dir;

  ## Load igsuite configuration file
  require "$conf_dir${S}igsuite.conf";

  ## Set a default session timeout if not defined by igsuite.conf
  $session_timeout ||= 8/24; ## default: 1.5 hours

  ## Set logs directory (temp)
  $logs_dir ||= "$cgi_dir${S}log";

  ## Set data directory (temp)
  $data_dir ||= "$cgi_dir${S}data";

  ## Set a temporary dir (temp)
  $temp_dir ||= "$data_dir${S}temp";

  ## Set a server name if not specified in igsuite.conf
  $server_name ||= $ENV{SERVER_NAME};

  ## Try to load available plugins list
  eval 'require "$cgi_dir${S}data${S}plugins${S}index.pm"';

  ## Debug Mode (there are cases where we cannot execute a debug)
  undef $debug if    $debug ##to avoid loop
                  && (    $ENV{IG_DEBUG_ID}
                       || $cgi_name =~ /^(checkmsg|igsuited|mkstruct.pl|rssticker|spellpack)$/
                       || $HTTP::Server::Simple::VERSION );

  if ( $debug )
   {
    die("Can't debug IGSuite on mod_perl1/2 environment.\n") if $_IS_MOD_PERL;
    $ENV{IG_DEBUG_ID} .= MkId(20);
    $ENV{PERL_DPROF_OUT_FILE_NAME} = $temp_dir.$S.$ENV{IG_DEBUG_ID}.'.dprof';
    SysExec( command   => GetShebang(),
             stdout    => 'active',
             arguments => [( '-d:DProf',
                             "$cgi_dir$S$cgi_name" )] )
      or die("Can't exec: $ext_app{perl} -d:DProf '$cgi_dir$S$cgi_name' - ".
             (pop @errmsg) ."\n");

    ## this is not a mod_perl context so at this point we can
    ## exit because all job is done;
    CORE::exit(); 
   }

  ## Set default database connection params
  die("You have to specify a right db_driver ".
      "in IGSuite configuration file!\n") if !$db_driver;
  $db_name     ||= 'igsuite';
  $db_host     ||= 'localhost';
  $db_port     ||= $db_driver eq 'mysql' ? 3306 : 5432;
  $date_format ||= 'German';

  ## Build Cgi Environment
  MkCgiEnv();

  ## Read parameters from commandline
  if ( @ARGV )
   {
    $on{action} = 'help' if $ARGV[0] eq '--help' || $ARGV[0] eq '/help';
    my %argv_options = $app_nspace->can( 'setargv' )
		     ? $app_nspace->setargv()
		     : ( 'auth_user:s' => \$auth_user,
			 'action=s'    => \$on{action} );
    ReadArgv(%argv_options);
   }

  ## Looks for a valid session
  if ( _valid_session() )
   {
    ## Extract user login 
    ## The  account  name must begin with an alphabetic character and the rest
    ## of the string should be from the POSIX portable character class
    ## (* from 'man adduser')
              
    ($auth_user) =  $cookie{igsuiteid}
                 =~ /^([A-Za-z\_][A-Za-z0-9\_\.\-]{1,31})\-session\-.+$/;

    ## Touch session file to store last access time
    if ($on{action} ne 'showmsg' && $on{action} ne 'checkmsg')
     { utime time(), time(), CkPath("$logs_dir${S}$cookie{igsuiteid}"); }

    ## Load values stored in session file
    do "$logs_dir${S}$cookie{igsuiteid}";
   }
  elsif ( $request_method ne 'commandline' && $cgi_name ne 'mkstruct.pl')
   {
    ## Remove old sessions and create the newone
    require IG::Utils;
    CleanSessions();

    ## Detect client browser and os
    require IG::HTTPBrowserDetect;
    my $browser = new HTTP::BrowserDetect( $ENV{HTTP_USER_AGENT} );
    $client_browser = lc $browser->browser_string();
    $client_os      = lc $browser->os_string();

    ## Find client host name
    $remote_host = _get_remote_host();

    die("Error! - IGSuite can't verify client IP or host name. ".
        "IGSuite need it! Check you DNS server configuration ".
        "or your 'hosts' file.\n") if !$remote_host;

    ## create a guest session 
    MkUserSession('guest');
   }

  ## If authentication fails we have a GUEST user
  $auth_user ||= 'guest';

  ## Authenticated user home dir
  $user_dir = UserDir();

  ## If ther's a personal configuration file we load it
  for ( "$user_dir${S}$remote_host.cf",
	"$user_dir${S}$auth_user.cf" )
   { do $_ && last if -e $_; }

  ## Load specific tema choosed by user
  if    ( $on{print} )
   { $tema = 'printable_'; }
  elsif ( $on{tema} && -e "$cgi_dir${S}tema${S}$on{tema}_tema" )
   { $tema = "$on{tema}_"; }
  elsif ( !$tema || $auth_user eq 'guest' )
   { $tema = 'deepblue_'; }
  do "$cgi_dir${S}tema${S}${tema}tema";

  if ( $on{action} =~ /^(findshow|checkmsg|nopopup|blank|quickfinder)$/ )
   {
    ## force color inside search engine and checkmsg areas
    $clr{bg}   = $clr{bg_link}   = $clr{bg_menu};
    $clr{font} = $clr{font_link} = $clr{font_menu};
   }

  ## Set default value for undefined vars
  $crypt_key		||= $pwd_admin; #XXX2FIX DANGEROUS!
  $link			||= 'http';
  $screen_size		||= 'large';
  $page_results		||= 13;
  $list_order		||= 'desc';
  $thousands_separator	||= '.';
  $decimal_separator	||= ',';
  $currency		||= 'Eur';

  ## Force Iso date format in case of sqlite RDBMS use
  ## overriding general and _user_ preferences 
  $date_format = 'Iso' if $db_driver eq 'sqlite';

  ## Set and load a base and a specific language dictionaries
  $lang = lc(substr($ENV{HTTP_ACCEPT_LANGUAGE},0,2))
	  if !$lang || $lang eq 'auto';
  $lang = $on{lang} if $on{lang};
  $lang = ($default_lang || 'en') if !$lang || ! -e "$cgi_dir${S}lang$S$lang";
  do "$cgi_dir${S}lang${S}$lang${S}base_lang";
  do "$cgi_dir${S}lang${S}$lang${S}${cgi_name}_lang";

  ## load default language (used to make directory structure)
  require "$cgi_dir${S}lang${S}$default_lang${S}default_lang";

  ## Set Time values (we have to stay here because we need sessionyear
  ## cookie to set time values, and a right lang file to set months name)
  _set_time_values();

  ## Set a default images path if not defined yet
  $img_url ||= "$webpath/images";

  ## This is the company logo used inside documents header
  $soc_logo ||= Img(	href	=> 'javascript:self.print()',
			target	=> 'mainf',
			src	=> "$img_url/logo.gif",
			border	=> '0',
			title	=> 'Print this page',
			height	=> 67,
			width	=> 670 );

  ## this is the favicon
  $tema{task}{favicon}  ||= 'favicon.gif';
 }


## Check if this is a valid session
sub _valid_session
 {
  ## check if session file exists
  return 1 if    $cookie{igsuiteid}
              && -e "$logs_dir${S}$cookie{igsuiteid}"
              && -M "$logs_dir${S}$cookie{igsuiteid}" < $session_timeout;

  ## if user has a cookie we needn't to preceed
  return 0 if $cookie{igsuiteid};

  ## try to look into session files to discover guest session
  ## that doesn't use cookies (slow procedure)
  my $new_remote_host = _get_remote_host();
  opendir( DIR, $logs_dir )
    or die( "Can't read from log directory '$logs_dir'. ".
            "Check directory permissions ".
            "or try to execute 'mkstruct.pl' as user 'root'.\n" );
                              
  for my $session ( grep /^guest\-session\-/, readdir(DIR) )
   {
    open( FH, '<', "$IG::logs_dir${S}$session" );
    my $old_remote_host = <FH>;
       $old_remote_host =~ /^\$remote_host \= \'([^\']+)\'\;/;
    close(FH);
    if ( $1 eq $new_remote_host )
     {
      $cookie{igsuiteid} = $session;
      return 1;
     }
   }

  close(DIR);
  return 0;
 }


## Get and adjusts time and date vars
sub _set_time_values
 {
  my ($s, $m, $h, $g, $me, $ye, $wday, $y, $i) = localtime(time);
  $tv{year}	= 1900 + $ye;		    # Year 4 digits
  $tv{ye}	= substr($tv{year}, 2 ,2);  # Year last 2 digits
  $tv{month}	= sprintf("%02d", ($me+1)); # Month
  $tv{day}	= sprintf("%02d", $g);      # Day of the month
  $tv{minuts}	= sprintf("%02d", $m);      # Minuts
  $tv{seconds}	= sprintf("%02d", $s);      # Seconds
  $tv{hours}	= sprintf("%02d", $h);      # Hours
  $tv{wday}	= $wday;		    # Day of the week

  ## Timeoffset
  if (!$timeoffset)
   {
    require IG::TimeZone;
    $timeoffset = Time::Zone::tz_name() || 'GMT';
   }
  $tv{time_offset} = $timezones{$timeoffset} || '+0100';

  if ( $i )
   {
    my @tzarray = split(//, $tv{time_offset});
    $tzarray[0] eq '+' ? $tzarray[2]++ : $tzarray[2]--;
    $tv{time_offset} = join('', @tzarray);
   }  

  $tv{session_year}	= $cookie{session_year}	||= $tv{year};
  $tv{end_year}		= GetDateByFormat(31, 12, $tv{session_year});
  $tv{start_year}	= GetDateByFormat(1, 1, $tv{session_year});
  $tv{empty_date}	= GetDateByFormat(1, 1, 2999);
  $tv{today}		= GetDateByFormat($tv{day}, $tv{month}, $tv{year});
  $tv{time}		= "$tv{hours}:$tv{minuts}:$tv{seconds}";
 }


## Find client host name
sub _get_remote_host
 {
  my $r_host = $ENV{'REMOTE_HOST'} || '';

  if ( !$r_host || $ENV{'REMOTE_HOST'} eq $ENV{'REMOTE_ADDR'} )
   {
    $r_host = pack("C4", (split(/\./, $ENV{'REMOTE_ADDR'})));
    $r_host = gethostbyaddr( $r_host, 2 );
    $r_host ||= $ENV{'REMOTE_ADDR'};
    $ENV{'REMOTE_HOST'} = $r_host;
   }

  return $r_host;
 }

##############################################################################
##############################################################################
sub UsrInf
 {
  my ($info, $user) = @_;
  return \%users if !$info;

  $user ||= $auth_user;

  my %infos = ( name          => 0,
                login         => 1,
                igprivileges  => 2,
                status        => 3,
                passwd        => 4,
                initial       => 5,
                acronym       => 6,
                function      => 7,
                email         => 8,
                pop3login     => 9,
                pop3pwd       => 10 );

  if ( ! defined $users{$user}[$infos{$info}] )
   {
    if ( ! $users{guest}[0] )
     {
      ## the first time we will memoize all basic users info
      my $cid = DbQuery( query => "SELECT name, login, igprivileges, status ".
                                  "FROM users WHERE login<>''",
                         type  => 'UNNESTED' );
      my @row;
      @{$users{$row[1]}} = @row while @row = FetchRow($cid);
      @{$users{guest}  } = ( 'Guest User', 'guest', '', 1 );

      UsrInf( $info, $user ) if $info !~ /^(name|login|igprivileges|status)$/;
     }
    elsif ( $user ne 'guest' )
     {
      my $cid = DbQuery( query => "select $info from users ".
                                  "where login='$user' limit 1",
                         type  => 'UNNESTED' );
      $users{$user}[$infos{$info}] = FetchRow($cid);
     }
   }

  return $users{$user}[$infos{$info}];
 }

##############################################################################
##############################################################################
sub GetShebang
 {
  my @rows;
  my $perl;
       
  for ( $ext_app{perl},
        '/usr/bin/perl',
        '/usr/local/bin/perl',
        '/bin/perl',
        "$^X" )
   { ($perl = $ext_app{perl} = $_) && last if $_ && -e $_ && -x $_ }

  die( "Can't find an executable perl shebang! ".
       "where is Perl?\nYou can set it inside igsuite.conf\n" ) if ! -x $perl;

  return $perl;
 }

##############################################################################
##############################################################################

=head3 CkExtPlugins

Parse function output by external plugins.
Only some core function is hookable by an external plugin:
HtmlHead, HtmlFoot, DocHead, HttpHead, TaskHead, MkComments
TaskFoot, MkButton, FormHead, FormFoot, ParseLink, TabPane, DTable

=cut

sub CkExtPlugins
 {
  no strict 'refs';
  my ( $core_function, $html_ref, $argument_ref) = @_;
  my $html = $$html_ref;

  foreach my $plugin ( keys %plugins )
   {
    ## is not an autovivification because HooksFunctions already exists
    my $hook_function = $plugins{$plugin}{HooksFunctions}{$core_function};
    next if    !$hook_function
            || (    $plugins{$plugin}{LimitToScripts}
                && !$plugins{$plugin}{LimitToScripts}{$cgi_name} )
            || (    $plugins{$plugin}{LimitToActions}
                && !$plugins{$plugin}{LimitToActions}{$on{action}} );

    eval "require \"$cgi_dir${S}data${S}plugins${S}$plugin.pm\"";
    die("Can't load external plugin '$plugin'\n") if $@;
    
    my $no_html = !$html;
    $html = &{$hook_function}($html, %$argument_ref);
    die("Plugin '$plugin' fails!") if !$html && !$no_html;
   }

  return $html;
 }
 
##############################################################################
##############################################################################

=head3 CkPath()

Check path to avoid to read or write from/to indesiderable files

=cut

sub CkPath
 {
  my $path = shift;

  die("This is an insecure request. What are you doing?\n")
    if    $path =~ /(\\|\/)\.\.|\.\.(\\|\/)|\*|\?|\||\>|\<|\$|\&/
       || $path =~ /^\Q$conf_dir\E/i
       || (    $path !~ /^\Q$temp_dir\E/i
            && $path !~ /^\Q$htdocs_dir\E/i
            && $path !~ /^\Q$logs_dir\E/i
            && $path !~ /^\Q$cgi_dir\E/i
            && $path !~ /^\Q$data_dir\E/i
            && $path !~ /^\Q$user_dir\E/i );

  return $path;
 }

##############################################################################
##############################################################################

=head3 PrOut()

It's used to manage cgi application output

=cut

sub PrOut
 {
  $prout_page .= join('',@_);
  return 1;
 }

##############################################################################
##############################################################################

=head3 MkUserSession($user)

Create a new user session

=cut

sub MkUserSession
 {
  my $user = shift;

  $cookie{igsuiteid}     =
  $set_cookie{igsuiteid} = "$user-session-".
                           (time).'-'.
                           substr( MkId(25), -10, 10 );

  open (SESSION, '>', CkPath("$logs_dir${S}$set_cookie{igsuiteid}") )
    or die("Can't create '$set_cookie{igsuiteid}' file ".
           "to register session on '$logs_dir' check directory permissions\n");

  ## store some client info to speed up next requests
  print SESSION "\$remote_host = '$remote_host';\n".
                "\$client_os = '$client_os';\n".
                "\$client_browser = '$client_browser';\n";
  close(SESSION);

  LogD("$set_cookie{igsuiteid},$ENV{HTTP_USER_AGENT}",
       'login', 'users', $user );
 }

##############################################################################
##############################################################################

=head3 ReadArgv(%options)

Convert commanline parameters to IG Framework values

=cut

sub ReadArgv
 {
  my %argv_options = @_;
  require IG::GetoptLong;

  Getopt::Long::Configure('pass_through');
  Getopt::Long::GetOptions(%argv_options);
 }

##############################################################################
##############################################################################

=head3 UserDir($user)

Get an IG user home dir. Generally: /cgi-bin/data/users/[user_name]

=cut

sub UserDir
 {
  my $user = shift || $auth_user || 'guest';
  return $data_dir . ${S} . 'users' . ${S} . $user;
 }

##############################################################################
##############################################################################

=head3 ConfigParam($param, $user)

Get per user configuration parameters

=cut

sub ConfigParam
 {
  my ($param, $user) = @_;
  $user ||= $auth_user;

  if ( !$user_conf{$user} )
   {
    my $config_file = UserDir($user) . $S . 'preferences.conf';
    return if ! -e $config_file;
    require IG::ConfigSimple;
    Config::Simple->import_from( $config_file, \%{$user_conf{$user}} );
   }

  return   $user_conf{$user}{$param} eq 'true'  ? 1
         : $user_conf{$user}{$param} eq 'false' ? 0
         : $user_conf{$user}{$param} eq '0'     ? '0'
         : $user_conf{$user}{$param};
 }

##############################################################################
##############################################################################

=head3 TextPluralize($template, $count)

See on cpan module Text::Pluralize documentation.

=cut

sub TextPluralize
 {
  my ($template, $count) = @_;
  require IG::TextPluralize;
  return Text::Pluralize::pluralize($template, $count);
 }

##############################################################################
##############################################################################

=head3 MkUrl($TextToUrlize)

Get a string you can use in a Url address

=cut

sub MkUrl
 {
  my @ulinks = @_;
  s#([^0-9a-zA-Z_.-/])#sprintf("%%%02X", ord($1))#ge for @ulinks;
  return (wantarray ? @ulinks : $ulinks[0]);
 }

##############################################################################
##############################################################################

=head3 DeUrl($UrlToText)

Decode a Url to a string

=cut

sub DeUrl
 {
  my @ulinks = @_;
  s/%([[:xdigit:]]{2})/chr hex "0x$1"/eg for @ulinks;
  return (wantarray ? @ulinks : $ulinks[0]);
 }

##############################################################################
##############################################################################

=head3 MkEntities( $TextToEscape, $UnsafeChars )

Return a string with unsafe chars encoded in html entities

=cut

sub MkEntities
 {
  require IG::HTMLEntities;
  my ($string, $unsafe_chars) = @_;
  return HTML::Entities::encode_entities( $string, 
                                          $unsafe_chars eq 'all'
                                          ? ''
                                          : $unsafe_chars || '<>"\'' );
 }

##############################################################################
##############################################################################

=head3 WrapText()

Wrap a text string

=cut

sub WrapText
 {
  my %data = @_;
  $data{text} ||= shift;
  require IG::TextWrap;

  $Text::Wrap::columns   = $data{columns}   || 78;
  $Text::Wrap::separator = $data{separator} || "\n";
  $Text::Wrap::break     = $data{break}     || '\s';

  return Text::Wrap::wrap( $data{initial_tab},
			   $data{subsequent_tab},
			   $data{text} );
 }

##############################################################################
##############################################################################

=head3 MkLink($TextToLink)

Pharse text to change some wiki tags (only a short range). Inside it call
ParseLink function to pharse all links available.and MkEntities to convert
all unsafe characters

=cut

sub MkLink
 {
  my $text = shift || return '&nbsp;';

  ## We can't allow html tags in our Framework
  $text = MkEntities( $text );
  $text =~ s/\n/<br>/g;
  $text =~ s/ {2}/ &nbsp;/g;

  ## Some tag according to IGWiki style
  foreach(
	["(\&\#39\;){3}",
	 "<span style=\"font-weight:bold\">",
	 "</span>"],
	["(\&\#39\;){2}",
	 "<i>",
	 "</i>"],
	["(,){3}",
	 "<span style=\"background:$clr{bg_evidence}\">",
	 "</span>"],
	["(,){2}",
	 "<u>",
	 "</u>"],
	["(%red%)",
	 "<span style=\"color:\#ff3300\">",
	 "</span>"],
	  )
   {
    1 while $text =~ s/(@$_[0])(.*?)\1/@$_[1]$3@$_[2]/m;
   }

  $text = ParseLink($text);
  return ($text);
 }
##############################################################################
##############################################################################

=head3 ParseLink($TextToLink)

Make automatic links to IG documents, e-mails, wiki pages, web-sites
and others, according to user privileges.

=cut

sub ParseLink
 {
  my $text = shift || return;
  return $text if $tema eq 'printable_';
  $on{ig} = 1 if $cgi_name ne 'igwiki';

  ## Link to wikipedia words and to igwiki page links
  $text =~ s/\[\[*([^\]]{1,300})\]\]*/_parse_square_bracket_links($1)/eg;

  ## Net protocols. 
  $text=~ s/(\s|>|^)(https|http|ftp)(\:\/\/)([^\/\s]+)([^\s\"\'\r\n<>\(\)]*)(\s|$)/
            $1 . ( $on{ig}
		   ? BuildLink("$2$3$4$5",$4)
		   : BuildLink("$2$3$4$5")
		 ) . $6
	   /eg;

  ## Link a dir or a file with web filemanager
  while ($text=~ /(dir\:\/|file\:\/)([^ \r\n]+\/)*([^ \r\n\/]+)/i)
   {
    my $match_type = $1;
    my $match_path = $2.$3;
    my $match_dir  = $2;
    my $match_file = $3;

    my $repository = $cgi_name eq 'igwiki' && $match_dir !~ /^\//
		   ? "&amp;repid=". MkUrl($on{name}).
		     "&amp;repapp=igwiki"
		   : '';

    if ($match_type eq 'dir:/')
     {
      my $dir = MkUrl($match_path);
      $text =~ s/dir\:\/\Q$match_path\E
                /<a href=\"javascript\:winPopUp\(\'filemanager\?dir=$dir$repository\'\,760\,550\,\'filemanager\'\)\">$match_path<\/a>/xgi;
     }
    else
     {
      my $dir  = MkUrl($match_dir);
      my $file = MkUrl($match_file);
      $text =~ s/file\:\/\Q$match_path\E
                /<a href=\"filemanager\/$file\?dir=$dir&amp;action=openfile&amp;file=$file$repository\" target=\"mainf\">$match_path<\/a>/xgi;
     }
   }

  if ($auth_user ne 'guest')
   {
    ## Mailto
    $text =~ s/(\s|^)([\w._%-]+@[\w._%-]+\.\w{2,4})(\s|$)/
		"$1<a href=\"javascript:winPopUp('webmail?action=composemessage&amp;onsend=close&amp;to=$2',700,600,'compose')\" style=\"white-space: nowrap;\">".
		"<img src=\"$img_url\/unreadmsg.gif\" border=0 align=\"absmiddle\">&nbsp;".
		"$2<\/a>$3"/eg;
 
    ## Parse IGSuite documents link
    $text =~ s/\b([EF123456789])(\d{5})\.(\d\d)\b
	      /_protocol_to_link($1,$2,$3)
	      /xeg;
   }
  else
   {
    ## Mailto 
    $text =~ s/(\s|^)([\w._%-]+@[\w._%-]+\.\w{2,4})(\s|$)/
		"$1<a href=\"mailto:$2\" style=\"white-space: nowrap;\">".
		"<img src=\"$img_url\/unreadmsg.gif\" border=0 align=\"absmiddle\">&nbsp;".
		"$2<\/a>$3"/eg;
   }

  $text =~ s/([EF123456789]\d\d\d\d\d),(\d\d)/$1\.$2/g;

  ## Check external plugins
  $text = CkExtPlugins( 'ParseLink', \$text, undef ) if %plugins;

  return $text; 
 }

###########################################################################
###########################################################################
sub _parse_square_bracket_links
 {
  my $text = shift;

  ## Link to a wiki page tag
  if    ( $text =~ /^([1-9EF]\d\d\d\d\d)\.(\d\d)\|(.+)$/ )
   { return BuildLink("$1,$2", $3); }
  elsif ( $text =~ /^([1-9EF]\d\d\d\d\d)\.(\d\d)$/ )
   { return BuildLink("$1,$2"); }
  elsif ( $text =~ /^([^\|]+)\|(.+)$/ )
   { return BuildLink($1, $2); }
  elsif ( $text =~ /^wikipedia\:(.+)$/ )
   {
    ## Link wikipedia word
    return Img( href    => "http:\/\/$lang.wikipedia.org\/wiki\/" . MkUrl($1),
                target  => '_blank',
                title   => 'Wikipedia Link',
                src     => "$img_url\/wikipedia.gif",
                style   => 'vertical-align:baseline; margin: 0 2px 0 1px;',
                caption => $1 );
   }
  else
   { return BuildLink($text); }
 }
 
###########################################################################
###########################################################################
sub _protocol_to_link
 {
  my ($idcode, $protocol, $pyear) = @_;
  $protocol = $idcode . $protocol;

  if ( $idcode eq 'E' )
   {
    ## it's an email protocol
    if ( CheckPrivilege('webmail_view') )
     {
      return _protocol_infobox( href   => "webmail?".
                                          "action=readmessage&amp;".
                                          "pid=$protocol.$pyear",
                                target => 'mainf',
                                link   => "$protocol,$pyear" );
     }
   }
  elsif ( $idcode =~ /[F123456789]/ )
   {
    my $doc_type = ProtocolToDocType( $idcode );

    if (CheckPrivilege($doc_type.'_view'))
     {
      return _protocol_infobox( href   => "$doc_type?".
				 	  "action=docview&amp;".
					  "id=$protocol,$pyear",
				target => 'mainf',
				link   => "$protocol,$pyear");
     }
   }
  return "$protocol\,$pyear";
 }

###########################################################################
###########################################################################

=head3 DirectLink($protocol_id)

Get a direct link to a document.

=cut

sub DirectLink
 {
  my $protocol_id = shift;

  my ( $idcode,
       $protocol,
       $p_year )    = $protocol_id =~ /(([123456789])\d{5})\.(\d\d)/;

  my ( $file_name,
       $file_dir,
       $file_proc ) = ProtocolToFile($protocol_id);

  if ( $file_name && CheckPrivilege($file_proc.'_view') )
   {
    my $path_part = $file_dir =~ /$p_year$/
		  ? "$p_year/$file_name" 
		  : $file_name;

    my $href   = GetHref($file_proc, $path_part);
    my $target = $file_name =~ /html*$/ ? '_blank' : 'mainf';

    my $direct_link = "<a title=\"$lang{view_document}\"".
                      " href=\"$href\"".
                      " target=\"$target\"".
                      ">$protocol_id</a>";

    return wantarray
           ? ( $direct_link, $href, $target )
           : $direct_link;
   }

  return $protocol_id;
 }

###########################################################################
###########################################################################
sub WebDavLink
 {
  my $protocol_id = shift;
  return if !$ENV{APACHE_CONFIGURED_BY_IGSUITE};

  my ( $idcode,
       $protocol,
       $p_year )    = $protocol_id =~ /(([123456789])\d{5})\.(\d\d)/;

  my ( $file_name,
       $file_dir,
       $file_proc ) = ProtocolToFile($protocol_id);

  if ( $file_name && CheckPrivilege($file_proc.'_view') )
   {
    my $href   = $webpath . '/DAV/'.
                 $default_lang{$file_proc}.
                 "/$p_year/$file_name";

    my $target = $file_name =~ /html*$/ ? '_blank' : 'mainf';

    my $direct_link = "<a title=\"$lang{view_document}\"".
                      " style=\"font-size:10px; display:block; text-align:center;\"".
                      " href=\"$href\"".
                      " target=\"$target\"".
                      ">WebDav Link</a>";

    return wantarray
           ? ( $direct_link, $href, $target )
           : $direct_link;
   }

  return $protocol_id;
 }

###########################################################################
###########################################################################
sub GetHref
 {
  my ($procedure, $path_part) = @_;
  my $href;
  die("Any \$procedure or \$path_part") if !$procedure || !$path_part;
  $path_part = MkUrl("/$default_lang{$procedure}/$path_part");

  if ($link ne 'igfile')
   {
    $procedure = 'webmail' if $procedure eq 'email_msgs';
    $href = $link eq 'auto' && CheckPrivilege($procedure.'_link')
	    ? $htdocs_path{"$client_browser-$client_os"} . $path_part
	    : $webpath . $path_part;
   }
  else
   {
    $path_part =~ /^(.+)\/([^\/]+)$/;
    $href = "filemanager?action=openfile&amp;".
	    "file=$2&amp;".
	    "dir=$1";
   }

  return $href;
 }

###########################################################################
###########################################################################
sub _protocol_infobox
 {
  my %data = @_;
  my $div_name = $data{link};
  $div_name =~ s/[\.\,]//g;
  $data{target}   ||= '_self';
  $page_boxes{$div_name}++;

  return
   "<a".
      " onMouseOut=\"clearTimeout(infoBoxTime); setTimeout('hideThisPopup(\\'$div_name\\')',4000);\"".
      " onMouseOver=\"protocolInfoBox('$data{link}','$div_name', event);\"".
      " href=\"$data{href}\" target=\"$data{target}\">".
   "$data{link}<\/a>";
 }

###########################################################################
###########################################################################

=head3 BuildLink($Link,$Label)

Build an html Link

=cut

sub BuildLink
 {
  my ($slink, $label) = @_;
  my $target = $on{ig} == 1 ? 'mainf' : $on{ig} == 2 ? '_self' : '_top';

  if ( $slink =~ /^(http|https|ftp)\:\/\// )
   {
    $label ||= length($slink) > 50 && $tema ne 'printable_'
	     ? substr($slink,0,50) . '...'
	     : $slink;

    return "<a href=\"$slink\" style=\"white-space: nowrap;\" target=\"$target\">".
	   $label.
	   ( $tema eq 'printable_' || $on{ig} || $cgi_name eq 'webmail'
	     ? ''
	     : " <img src=\"$img_url\/external\.gif\" alt=\"link\">"
	   ).
	   "<\/a>";
   }
  else
   {
    ## it's a wiki page name
    my $pagename;
    if ( $slink =~ /^([^\#]*)\#(.+)$/ ) 
     {
      $label ||= "$1 - $2";
      $pagename = $1;
      my $anchor = $2;
      $anchor =~ s/[^A-Za-z0-9_\-\.]/_/g;
      $slink = "$pagename#$anchor";
     }
    else 
     {
      $label ||= $slink;
      $pagename = $slink;
     }

    return 'Broken Tag!' if length($pagename) > 50;
    $slink =~ s/\s/\_/g;
    my $wiki_name = MkUrl($slink);
    $wiki_name =~ s/\%23/\#/g;

    my $href = $wiki_name =~ s/^\#//
	     ? "$ENV{REQUEST_URI}#$wiki_name" ## it's an anchor
	     : $on{ig}
	       ? "$cgi_url/igwiki?ig=$on{ig}&amp;name=$wiki_name"
	       : $on{action} eq 'getpdf'
		 ? "$cgi_url/igwiki/$wiki_name?action=getpdf"
		 : "$cgi_url/igwiki/$wiki_name";

    my $wiki_class = _isWikiPageMissing( $slink ) ? 'wikimiss' : 'wiki';
      
    return "<a href=\"$href\" class=\"$wiki_class\" target=\"$target\">".
           "$label<\/a>";
   }
 }

sub _isWikiPageMissing
 {
  my $name = shift;
  return 0 if $name =~ /^\#/; # if start with # is an anchor to the same page
  return 1 if !$name;         # empty page

  ## strip anchor parts
  $name =~ s/\#.+$//;

  $name =~ s/\_|\+/ /g;
  my $cid = DbQuery( query => "select count(*) from pages ".
                              "where name='".DbQuote($name)."' limit 1",
                     type  => 'UNNESTED' );
  
  return FetchRow($cid) ? 0 : 1;
 }
 
#############################################################################
#############################################################################

=head3 CallMeter($field_name)

Link a 'file' field to an Upload meter

=cut

sub CallMeter
 {
  my $field_name = shift;
  return if !$CGI::Simple::UPLOAD_HOOK;

  my $html = "winPopUp('igsuite?".
                       "action=upload_meter',".
                       "300,180,'meter');";

  $html = "if (!$field_name) { return false; }; $html" if $field_name;
  return $html;
 }

#############################################################################
#############################################################################

=head3 GetDayByDate($day,$month,$year)

Returns a day of the week by a date.

=cut

sub GetDayByDate
 {
  my ( $day, $month, $year ) = (@_);
  $day   ||= $tv{day};
  $month ||= $tv{month};
  $year  ||= $tv{year};
  my @d = (0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4);
  $year-- if $month < 3;
  return ( (	  $year + int( $year/4 )
		- int( $year/100 )
		+ int( $year/400 )
		+ $d[$month-1]
		+ $day
	   ) % 7 );
 }

##############################################################################
##############################################################################

=head3 GetDateExtended( $day, $month, $year, $hours, $minuts, $seconds )

Returns an extended date as in RFC822

=cut

sub GetDateExtended
 {
  my ( $day, $month, $year, $hours, $minuts, $seconds, $offset ) = @_;
  $day		||= $tv{day};
  $month	||= $tv{month};
  $year		||= $tv{year};
  $hours	||= $tv{hours};
  $minuts	||= $tv{minuts};
  $seconds	||= $tv{seconds};
  $offset       ||= $tv{time_offset};

  my @MON   = qw/undef Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
  my @WDAY  = qw/Sun Mon Tue Wed Thu Fri Sat/;
  return sprintf(	"%s, %02d %s %04d %02d:%02d:%02d %s",
			$WDAY[ GetDayByDate($day, $month, $year) ],
			$day,
			$MON[$month],
			$year,
			$hours,
			$minuts,
			$seconds,
			$offset );
 }

##############################################################################
##############################################################################

=head3 GetValuesByDate($date)

Returns day month and year from a date according to $date_format.

=cut

sub GetValuesByDate
 {
  my $date = shift;
  if ( ($date_format eq 'European' || $date_format eq 'German' )
       && $date=~ /(\d\d)\D(\d\d)\D(\d\d\d\d)/ )
   { return ($1,$2,$3) }
  elsif ($date_format eq 'Sql' && $date=~ /(\d\d)\D(\d\d)\D(\d\d\d\d)/)
   { return ($2,$1,$3) }
  elsif ($date_format eq 'Iso' && $date=~ /(\d\d\d\d)\D(\d\d)\D(\d\d)/)
   { return ($3,$2,$1) }
 }

##############################################################################
##############################################################################

=head3 GetDateFromTime($time)

Returns a formatted date according to $date_format from a time value

=cut

sub GetDateFromTime
 {
  my $time = shift;
  $time ||= time();

  ## Adjusts time and date vars
  my ($s, $m, $h, $g, $me, $ye, $wday, $y, $i) = localtime($time);

  return GetDateByFormat($g, $me+1, $ye+1900);
 }

##############################################################################
##############################################################################

=head3 GetDaysInMonth($month,$year)

Returns days in a month

=cut

sub GetDaysInMonth
 {
  my ($month, $year) = (@_);
  $month   ||= $tv{month};
  $year    ||= $tv{year};

  return $month == 2
         ? ( (($year-1988)%4) == 0 ? 29 : 28 ) ## Leap Year
         : ( 0,31,28,31,30,31,30,31,31,30,31,30,31 )[$month];
 }

##############################################################################
##############################################################################

=head3 GetDateByFormat($day,$month,$year)

Returns a formatted date according to $date_format

=cut

sub GetDateByFormat
 {
  my ($day, $month, $year) = (@_);
  $day   ||= $tv{day};
  $month ||= $tv{month};
  $year  ||= $tv{year};

  if    ( $year < 40  ) { $year = '20'.$year }
  elsif ( $year < 100 ) { $year = '19'.$year }

  $day   = sprintf("%02d", int($day)   );
  $month = sprintf("%02d", int($month) );

  return if    $month < 1
            || $month > 12
	    || $day   < 1
	    || $day   > GetDaysInMonth($month, $year);

  return   $date_format eq 'European' ? "$day-$month-$year"
	 : $date_format eq 'German'   ? "$day.$month.$year"
	 : $date_format eq 'Sql'      ? "$month/$day/$year"
	 : $date_format eq 'Iso'      ? "$year-$month-$day"
	 : die('No valid $date_format');
 }

##############################################################################
##############################################################################

=head3 GetNiceDate($year, $month, $day)

Difference between two dates

=cut

sub GetNiceDate
 {
  my ($day, $month, $year) = @_;
  my $today_diff = DateDifferences($day, $month, $year);
  return   $today_diff == 0  ? $lang{today}
         : $today_diff == -1 ? $lang{yesterday}
         : (    $today_diff < -1
             && $today_diff > -7 ) ? $IG::days[ GetDayByDate($day,
                                                             $month,
                                                             $year) ]
         : GetDateByFormat($day, $month, $year); 
 }
 
##############################################################################
##############################################################################

=head3 DateDifferences($day1, $month1, $year1, $day2, $month2, $year2)

Returns difference between two dates

=cut

sub DateDifferences
 {
  my ($day1, $month1, $year1, $day2, $month2, $year2) = @_;
  (($year2, $month2, $day2) = ($tv{year}, $tv{month}, $tv{day})) if !$year2;

  return   _date_diff($year1, $month1, $day1 )
         - _date_diff($year2, $month2, $day2 );
 }

sub _date_diff
 {
  my ($y,$m,$d) = @_;
  $m = ($m + 9) % 12;
  $y = $y - int($m/10);
  return  365*$y +
          int($y/4) -
          int($y/100) +
          int($y/400) +
          int(($m*306 + 5)/10) +
          $d - 1;
 }

##############################################################################
##############################################################################

=head3 SumDate($day,$month,$year,-4)

Returns a formatted date obtained by a date plus 'n' or '-n' days months or
years.
Es. +1y (add 1 year)
+3m (add 3 months)
-50 (less 50 days)

=cut

sub SumDate
 {
  my ( $day, $month, $year, $dd ) = (@_);
  my ( $i, $k, $ck_month );
  $day   ||= $tv{day};
  $month ||= $tv{month};
  $year  ||= $tv{year};

  if ( $dd=~ /(\-|\+)?(\d+)(d|m|y)?/ )
   {
    if ($3 eq 'y')
     { $year = $1 eq '-' ? $year-$2 : $year+$2 }
    elsif ( $3 eq 'm')
     {
      $i = int($2/12);
      $k = $2-($i*12);
      $month = $1 eq '-' ? $month-$k : $month+$k;
      $year  = $1 eq '-' ? $year-$i  : $year+$i;
      if    ($month>12) { $month -= 12; $year++ }
      elsif ($month<1)  { $month += 12; $year-- }
     }
    else
     {
      while (1)
       { 
        $ck_month = GetDaysInMonth($month, $year);

        $i = $day + $dd;
        if ( $i > $ck_month )
         {
          $dd  = $i - $ck_month - 1;
          $day = 1;
          ++$month;
         }
        elsif( $i < 1 )
         {
          $dd = $i;
          --$month;

          if ( $month == 0 )
           {
            $month = 12;
            --$year;
           }

          $day = GetDaysInMonth($month, $year);
         }
        else
         {
          $day = $i;
          last;
         }

        if ( $month > 12 )
         {
          $month = '01';
          ++$year;
         }
       }
     }
   }

  $ck_month = GetDaysInMonth($month, $year);
  $day = $ck_month if $day > $ck_month;

  return ( GetDateByFormat($day, $month, $year) );
 }

##############################################################################
##############################################################################

=head3 CompareDate($firstdate, $seconddate)

Compare two dates and return 1 if the first date is greater than the second
-1 if the first date is minor than the second 0 if they are equal.

=cut

sub CompareDate
 {
  my ($first_date, $second_date) = @_;
  $second_date ||= $tv{today};
  my $fdate = join '', reverse GetValuesByDate($first_date);
  my $sdate = join '', reverse GetValuesByDate($second_date);

  return $fdate < $sdate ? -1 : $fdate > $sdate ? 1 : 0;
 }

##############################################################################
##############################################################################

=head3 CkDate($mydate,$flag)

Check and complete a date passed by $mydate according to $date_format
configuration parameter.
If any of above date format is specified it returns a '0' value, otherwise
it returns a completed date.

=cut

sub CkDate
 {
  my ($data, $blank) = (@_);
  my ($ck_date_g, $ck_date_m, $ck_date_y);
  $data =~ s/\s+$//; ## trim end spaces

  return '' if CompareDate($data, $tv{empty_date}) == 0 && !$blank;
  return $tv{empty_date} if $blank && (!$data || $data eq 'null');

  if ($date_format eq 'Iso' &&                                  ## yyyy.mm.dd
      ( $data=~ /^(\d\d\d\d).(\d\d).(\d\d)$/ ||
        $data=~ /^(\d\d\d\d)(\d\d)(\d\d)$/   ||
        $data=~ /^(\d\d).(\d\d).(\d\d)$/     ||
        $data=~ /^(\d\d)(\d\d)(\d\d)$/       ||
	$data=~ /^(\d\d).(\d\d)$/            ||
	$data=~ /^(\d\d)(\d\d)$/             ||
	$data=~ /^(\d\d)$/
      )
     )
   {
    ($ck_date_y, $ck_date_m, $ck_date_g) = ($1, $2, $3);
   }
  elsif ( $data=~ /^(\d\d).(\d\d).(\d\d\d\d)$/ ||
          $data=~ /^(\d\d)(\d\d)(\d\d\d\d)$/   ||
          $data=~ /^(\d\d).(\d\d).(\d\d)$/     ||
          $data=~ /^(\d\d)(\d\d)(\d\d)$/       ||
	  $data=~ /^(\d\d).(\d\d)$/            ||
	  $data=~ /^(\d\d)(\d\d)$/             ||
	  $data=~ /^(\d\d)$/
        )
   {
    if ($date_format eq 'European' || $date_format eq 'German') ## dd.mm.yyyy
     {
      ($ck_date_g, $ck_date_m, $ck_date_y) = ($1,$2,$3);
     }
    elsif ($date_format eq 'Sql')
     {
      ($ck_date_g, $ck_date_m, $ck_date_y) = ($2,$1,$3);        ## mm.dd.yyyy
     }
   }
  else
   { return; }

  $ck_date_y ||= $tv{year};
  $ck_date_m ||= $tv{month};
  $ck_date_g ||= 1;

  if    ( $ck_date_y < 40)		    { $ck_date_y = '20'.$ck_date_y }
  elsif ( $ck_date_y >39 && $ck_date_y<100) { $ck_date_y = '19'.$ck_date_y }

  return if    $ck_date_y < 1900
            || $ck_date_m < 1
            || $ck_date_m > 12
            || $ck_date_g < 1
            || $ck_date_g > GetDaysInMonth($ck_date_m, $ck_date_y);

  return ( GetDateByFormat($ck_date_g, $ck_date_m, $ck_date_y) );
 }

##############################################################################
##############################################################################

=head3 DTable( %dispatch_table_hash )

Check $on{action} value and execute a procedure according to Dispatch Table. 

=cut

sub DTable
 {
  return if $debug;
  die("Can't call DTable recursively\n") if $executed{dtable}++;
  die("You have to call MkEnv() first in your script\n") if !$executed{mkenv};

  my (%data) = @_;
  my $action = $on{action} ||= 'default_action';

  my $condition = $data{$action};
     $condition = &$condition if ref($condition) eq 'CODE';

  if ( !$condition )
   {
    if ( $auth_user eq 'guest' && $request_method ne 'commandline')
     {
      IG::Redirect("igsuite?".
                   "action=summary&amp;".
                   "errmsg=".
                   MkUrl($lang{Err_you_have_to_login} || "You have to login!").
                   (    $IG::screen_size =~ /^noframe/
                     && ($cgi_name eq 'igwiki' || $cgi_name eq 'webmail')
                     ? "&amp;caller=$cgi_name&amp;caller_action=$on{action}"
                     : '')
                  );
     }
    else
     {
      Warn($lang{Err_privileges});
     }
   }
  elsif ( exists $data{$action} && $app_nspace->can( $action ) )
   {
    no strict 'refs';
    undef @_;
    &{"${app_nspace}::$action"};

    $prout_page = CkExtPlugins( 'DTable', \$prout_page, undef ) if %plugins;
   } 
  else
   {
    Warn("Requested action: $action is not defined in dispatch table");
   }

  if ( !$executed{redirect} && !$on{list2xls} && !$on{list2csv} )
   {
    ## print page out to screen
    print STDOUT $prout_page;

    ## print out box div
    print STDOUT _build_infobox_div() if %page_boxes;
   }

  $| = 1; ## Flush STDOUT

  ## if we have a print view request
  ## write the page in a temp file (to use it)
  if ( $on{print} && !$executed{redirect} )
   {
    my $temp_file_name = $temp_dir . $S . $auth_user . '_printview.htm';
    open( PRN, '>', CkPath($temp_file_name) )
      or die("Can't write on '$temp_file_name'.\n");
    binmode(PRN);

    ## strip http head
    $prout_page =~ s/.*(^<\!DOCTYPE html.+)/$1/sm;

    ## strip taskhead icons
    $prout_page =~ s/<\!\-\-\sSTART\sTASKHEAD\sICONS\s\-\->
                     .+
                     <\!\-\-\sEND\sTASKHEAD\sICONS\s\-\->//sx;

    print PRN $prout_page;
    close(PRN);
   }

  ## Close all database connections
  DbDisconnect();

  undef $prout_page;
  undef %executed;
  undef $ENV{IG_DEBUG_ID};
 }

##############################################################################
##############################################################################

=head3 CheckPrivilege($my_privilege, $user_to_check)

It returns '1' if user can execute procedure, or '0'
if he can't, without stopping execution. With any parameters
we ask to checks if we have a guest user or not, so it returns
'0' if we have a guest user, '1' if we have an authenticated user.
It also checks if ther's the script we want execute otherwise return '0'.

=cut

{
 ## MEMOIZATION
 my %stored_privileges;

 sub CheckPrivilege
  {
   my ($proc, $user) = @_;
   $user ||= $auth_user;

   ## prevent old memoized values. Needed by mod_perl
   undef %stored_privileges if !$executed{checkprivilege}++;

   if (! defined $stored_privileges{$proc}{$user})
    {
     if ( $user ne 'guest'     
           &&
          (   !$proc
           || ( $proc eq 'sys_user_admin' && $user eq $login_admin )
           || substr( UsrInf('igprivileges',$user), $privileges{$proc}[0], 1) == 1
	   || _check_group_privilege( $user, $proc )
          )
           &&
          ( -e "$cgi_dir${S}$privileges{$proc}[1]" )
        )
      { $stored_privileges{$proc}{$user} = 1; }
     else
      { $stored_privileges{$proc}{$user} = 0; }
    }
   return $stored_privileges{$proc}{$user};
  }
}


{
 ## MEMOIZATION
 my %stored_group_privileges;

 sub _check_group_privilege
  {
   my ($user, $proc) = @_;

   ## prevent old memoized values. Needed by mod_perl
   undef %stored_group_privileges if !$executed{check_group_privilege}++;

   if (! defined $stored_group_privileges{$user} )
    {
     my @fake_privileges;
     my $cid 
     = DbQuery( query => "select users_groups.igprivileges ".
  	                 "from users_groups_link ".
	                 "left join users_groups ".
	  	         "on users_groups_link.groupid=users_groups.groupid ".
		         "where users_groups_link.userid='$user'",
	        type  => 'UNNESTED' );
     while ( my $privileges = FetchRow($cid) )
      {
       ## Do an OR logic of all group privileges
       my $cnt;
       $fake_privileges[$cnt++] ||= $_ for split //, $privileges;
      }

     $stored_group_privileges{$user} = join '', @fake_privileges;
    }

   return substr($stored_group_privileges{$user}, $privileges{$proc}[0], 1);
  }
}

##############################################################################
##############################################################################

=head3 CheckSameMembership($user1, $user2)

Check if two user have the same group membership

=cut

{
 ## MEMOIZATION
 my %stored_users_membership;

 sub CheckSameMembership
  {
   my ($user1, $user2) = @_;
   my $membership = 0;
   my %result;

   ## prevent old memoized values. Needed by mod_perl
   undef %stored_users_membership if !$executed{checksamemembership}++;

   return $stored_users_membership{"$user1-$user2"}
      if exists $stored_users_membership{"$user1-$user2"};
   return $stored_users_membership{"$user2-$user1"}
      if exists $stored_users_membership{"$user2-$user1"};

   my $cid = DbQuery( query => "select userid, groupid ".
                               "from users_groups_link ".
		               "where userid='$user1' or userid='$user2'",
	              type  => 'UNNESTED' );
   while (my ($userid, $groupid) = FetchRow($cid) )
    { $result{$userid}{$groupid}++ }

   foreach ( keys %{$result{$user1}} )
    { $membership++ if $result{$user2}{$_}; }

   ## Memoize result
   $stored_users_membership{"$user1-$user2"} = 
   $stored_users_membership{"$user2-$user1"} = 
   $membership;

   return $membership;
  }
}

##############################################################################
##############################################################################

=head3 CheckResourcePrivileges(%arguments)

Check if an user can access (r or rw) to a resource ( protocol id )
two user have the same group membership. Return a document status where:
-1 Document doesn't exist
0  Document exists but user can't access it
1  Document exists and user can access it

=cut

sub CheckResourcePrivileges
 {
  ## Remember Administrators can bypass document privileges!!!
  my %data = @_;

  return -1 if ! $data{id};

  $data{mode}    ||= 'r';
  $data{user}    ||= $auth_user;

  ## Find resource info
  ( $data{resource_cgi},
    $data{resource_dbtable} ) = ( ProtocolToDocType( $data{id} ) )[1,2]
                                if     ! $data{resource_cgi}
                                    || ! $data{resource_dbtable};
  return -1 if !$data{resource_dbtable};

  ## Find resource owner
  my $cid = DbQuery( query => "select owner from $data{resource_dbtable} ".
                              "where id='$data{id}' limit 1",
                     type  => 'UNNESTED' );
  my $resource_owner = FetchRow($cid);
  return -1 if !$resource_owner;

  ## check default owner share mode
  my $share_mode = ConfigParam( "$data{resource_cgi}.share_mode",
                                 $resource_owner );
  
  if ( $share_mode eq 'all_users' )
   {
    ## share with all users
    return 1;
   }
  elsif ( $share_mode eq 'same_group' )
   {
    ## share with same group users
    return 1 if CheckSameMembership( $auth_user, $resource_owner );
   }
  else
   {
    ## share customized per protocol
    ## resolve common cases
    my $cid = DbQuery( query => "select count(*), owner ".
                                "from users_privileges ".
                                "where resource_id='$data{id}' group by owner",
                       type  => 'UNNESTED' );
    my ( $rules, $doc_owner ) = FetchRow($cid);
    DbFinish($cid);
    return 1 if !$rules || $doc_owner eq $data{user};

    ## remember if a user have 'w' privilege he also have 'r' privilege
    $cid =
    DbQuery(query =>"select users.login, users_privileges.privilege_type ".
                    "from users_groups_link, users_privileges, users ".
                    "where users_privileges.resource_id = '$data{id}'".
                    " and ( users_privileges.who=users.login".
                          " or (users_privileges.who=users_groups_link.groupid".
                               " and users.login=users_groups_link.userid)) ".
                    "group by users.login, users_privileges.privilege_type",
            type  =>'UNNESTED' );

    while ( my @row = FetchRow($cid) )
     {
      DbFinish($cid) && return 1
        if    $row[0] eq $data{user}
           && ( $row[1] eq $data{mode} || $row[1] eq 'w' );
     }
   }
  
  ## Finally check administration privileges
  return 1 if CheckPrivilege('sys_user_admin', $data{user});

  ## Return '0' according to the call
  return (0) if wantarray;
  undef $prout_page;
  $request_method eq 'commandline'
  ? print STDOUT "$lang{Err_privileges}\n"
  : Warn( $lang{Err_privileges} );
  return 0;
 }
 
##############################################################################
##############################################################################

=head2 Gui rendering procedures

=cut

##############################################################################
##############################################################################

=head3 DocHead()

Make a valid Http head to a non html document.

=cut

sub DocHead
 {
  my %data = @_;
  my $html;

  if ($HTTP::Server::Simple::VERSION)
   {
    ## it's a standalone request #XXX?
    $html = "HTTP/1.0 200 OK\r\n";
    $data{nph}++
   }

  my %params = ( -type       => $data{type},
                 -target     => $data{target},
                 -status     => $data{status},
                 -expires    => $data{expires},
                 -charset    => $data{charset} || $lang_charset,
                 -attachment => $data{attachment} );

  ## Content-length (non standard)
  $params{'-content_length'} = $data{content_length} if $data{content_length};

  ## Build header
  $html .= $cgi_ref->header( %params );

  ## Check external plugins
  $html = CkExtPlugins( 'DocHead', \$html, \%data ) if %plugins;

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 HttpHead()

Make a valid Http head.

=cut

sub HttpHead
 {
  my %data = @_;
  my @cookies;
  my $html;

  ## Send cookies value.
  foreach (keys %set_cookie)
   {
    no strict 'refs';
    push @cookies, $cgi_ref->cookie( -name =>   $_,
				     -value=>   $set_cookie{$_}{value}   ||
					        $set_cookie{$_},
				     -path =>   $set_cookie{$_}{path}    ||
					        '/',
				     -expires=> $set_cookie{$_}{expires} ||
					        '');
   }


  if ($HTTP::Server::Simple::VERSION)
   {
    ## it's a standalone request
    $html = "HTTP/1.0 200 OK\r\n";
    $data{nph}++
   }
  elsif ( $data{expires} eq 'now' || !$data{expires} )
   {
    ## we want preventing browser caching
    $cgi_ref->no_cache(1);
   }
 
  $html .= $cgi_ref->header(	-type 	=> $data{type}	  || 'text/html',
				-target => $data{target}  || '_self',
				-status => $data{status}  || '200 OK',
				-cookie => \@cookies,
				-nph	=> $data{nph}	  || 0,
				-expires=> $data{expires} || 'now',
				-charset=> $data{charset} || $lang_charset,
				-attachment=>$data{attachment},
			     );

  ## Check external plugins
  $html = CkExtPlugins( 'HttpHead', \$html, \%data ) if %plugins;

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 HtmlHead()

Make a valid Html head.

=cut

sub HtmlHead
 {
  my %data = @_;
  my $html;

  ## make sure to print header only once
  return if $executed{htmlhead}++ && !$data{reprint};

  $data{expire}     ||= 30000;
  $data{charset}    ||= $lang_charset;
  $data{onevent}    ||= ''; ## only to remember it, as an avalaible option
  $data{target}     ||= '_self';
  $data{base_target}||= '_self';
  $data{base_href}  ||= "$cgi_url/";
  $data{align}      ||= $data{shortcuts} && $screen_size eq 'large'
			? 'left'
			: 'center';
  $data{padding}    ||= 6;
  $page_title       ||= $data{title};
  $data{title}        = MkEntities( $data{title} || "IGSuite $VERSION" );
  $data{searchkeys}   = $data{searchkeys}
		      ? MkEntities($data{searchkeys})
		      : $data{title};

  if ($tema eq 'printable_')
   { $data{robots} = 'noindex, nofollow' }
  else
   { $data{robots} ||= 'index, follow' }

  ## Needed to index each field of a form or a field id
  $page_tabindex = '';

  ## Make a date expired to prevent page reload from the client cache
  my $date   = GetDateExtended( $tv{day},
                                $tv{month},
                                $tv{year},
                                $tv{hours},
                                $tv{minuts},
                                $tv{seconds} );

  my $expire = $cgi_name eq 'igwiki'
	     ? '0'
	     : GetDateExtended( $tv{day},
	                        $tv{month},
	                        $tv{year}-1,
	                        $tv{hours},
	                        $tv{minuts},
	                        $tv{seconds} );

  ## Make Http Head
  $html = HttpHead( charset=> $data{charset} )
          if $request_method ne 'commandline' && !$data{nohttp};

  ## Make Html Head
  $html .= <<END;
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<HTML><HEAD><TITLE>$data{title}</TITLE>

<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=$data{charset}">
<META HTTP-EQUIV="author" CONTENT="Luca Dante Ortolani">
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
<META HTTP-EQUIV="Cache-Control" CONTENT="no-cache">
<META HTTP-EQUIV="Expires" CONTENT="$expire">
<META HTTP-EQUIV="Last-Modified" CONTENT="$date">
<META HTTP-EQUIV="Content-Script-Type" CONTENT="text/javascript">
<META HTTP-EQUIV="Window-target" CONTENT="$data{target}">
<META HTTP-EQUIV="refresh" CONTENT="$data{expire}">
<META NAME="generator" CONTENT="IGSuite $VERSION">
<META NAME="language" CONTENT="$lang">
<META NAME="keywords" CONTENT="$data{searchkeys}">
<META NAME="robots" CONTENT="$data{robots}">
<META NAME="googlebot" CONTENT="$data{robots}">
<META NAME="revisit-after" CONTENT="1 days">
<LINK REL="icon" HREF="$IG::img_url/favicon.ico" TYPE="image/x-icon">
<BASE HREF="$data{base_href}" TARGET="$data{base_target}">


<STYLE type="text/css" media="print">
<!--
body
 {
                background: white;
                font-size: 12pt;         }

.noprint
 {
		visibility: hidden;      } 
-->
</STYLE>

<STYLE type="text/css">
<!--
html, body
 {
                height:100%;
                padding: 0;
                margin: 0;
                border-width: 0;     }

body
 {		background: $clr{bg};
		color: $clr{font};	}

body,p,strong,em,dt,dd,dl,sl,th,tr,td,div,li,ul,ol,input,select,textarea 
 {		font-family: $tasksfontname;
		font-size: $tasksfontsize;	}

a:link, a:visited, a:active
 {		color: $clr{font_link};
		text-decoration: none; }

a.wiki, a.wiki:visited
 {		color: #ff7908; }

a.wiki:hover, a.wikimiss:hover
 {		background: #F0F0F0; }

a.wikimiss, a.wikimiss:visited
 {              color: #ff1133; }

div.floatbox
 {		background: $clr{bg_task};
		position:relative;
		float: right;
		white-space: normal;
		padding: 5px;
		margin: 0 0 10px 10px;
		border: 2px solid $clr{bg_barra}; }

form, img, .formcheck
 {		margin: 0px;
		padding: 0px;
		border-width: 0px;	}

.formcheck
 {              margin:2px;
                width:14px;
                height:12px;	}

h1,h2,h3,h4,h5
 {		border-bottom: 1px #CCCCCC solid;
		color: $clr{font_link};
		background-color: transparent;
		text-shadow: #CCCCCC 0.2em 0.2em 3px;
		font-family: "Trebuchet MS", $tasksfontname;
		display:block;
		padding: 0px 0px 5px 0px;
		margin: 1.4em 0px 8px 0px; }

h1, h1 a {	font-size: 140%; }
h2, h2 a {	font-size: 130%; }
h3, h3 a {	font-size: 120%; }
h4, h4 a {	font-size: 110%; }
h5, h5 a {	font-size: 105%;
		border-bottom: 0px;
		font-weight: bold; }

ul
 {		margin: 0.3em 0 0 15px;
		padding: 0 0 0 15px;
		list-style-type: square;
		list-style-image: url("$IG::img_url/bullet.gif"); }

ol
 {		margin: 0.3em 0 0 15px;
		padding: 0 0 0 15px;
		list-style-image: none; }
 
li
 {		margin: 0 0 0.1em 0; }
 
hr
 {		margin: 0;
		padding: 0; 
		height: 0px;
		color: #8cacbb; }

p
 {		text-align: justify; }
 
pre
 {		font-family: monospace;
		max-width: 500px;
		overflow: auto;
		margin: 5px 5px 5px 30px;
		font-size: 10px;
		line-height: 1.1em;
		padding: 8px;
		border: 1px #999999 dashed;
		color: #3B3B3B;
		background: #f4f4f4; }

.forminput, .formselect
 {		padding: 0px; 
		margin: 0px;
		border: 1px $clr{border_low} solid;
		border-right: 1px $clr{border} solid;
		border-bottom: 1px $clr{border} solid;
		background-color: #f4f4f4; }

.forminput
 {		height: 20px; }

.formselect
 {		height: 20px;
                color: $clr{font_button}; }

.formbutton
 {		margin: 0px;
		height: 20px;
		text-align: center;
		border: 1px solid #b5b5b5;
		border-bottom: 1px solid #000000;
		border-right: 1px solid #999999;
		color: $clr{font_button};
                background-image: url($img_url/shadow.gif);
                background-repeat: repeat-x;
                background-position: right bottom;
		background-color: $clr{bg_button}; }

textarea
 {		padding: 0px;
                font-size: 12px;
		border-width: 0px;
		margin: 0px;
		background-color: #f4f4f4; }
 
.forminput:focus, .formselect:focus, textarea:focus, .formbutton:focus
 {		background-color: $clr{bg_low_evidence} }

.label
 {		display: block;
                line-height: 16px;
		float: left;
		width: 100px;
		margin: 2px 3px 2px 4px;
		padding: 2px;
		border: 1px solid $clr{border_low};
		background: $clr{bg_link};
		vertical-align: top;
		color: $clr{font};
		font-size: $tasksfontsize;
		font-family: $tasksfontname; }

.field
 {		display: block;
		white-space: nowrap;
		float: left;
		padding: 0px;
		margin: 2px 2px 2px 0px;
		background-color: transparent;
		vertical-align: top;
		color: $clr{font};
		font-size: $tasksfontsize;
		font-family: $tasksfontname; }

.newsclass
 {
                height: 60px;
                overflow: hidden; }

.pframe
 {		border: 1px solid #999999; }
 
.fileicon 
 {		display: block; 
		line-height: 1.0em;
		white-space: normal; 
		float: left;
		width: 100px;
		height: 70px;
		margin: 5px 5px 5px 5px;
		text-align: center;
		vertical-align: top;
		color: $clr{font};
		font-size: 10px;
		font-family: $tasksfontname; }

div.tabpane
 {              clear:both;
                width:100%;
                background-color:$clr{bg_task};
                visibility: visible;
                display:none; }

div.navon
 {		border: 1px solid #000000;
		border-bottom: 0px;
		border-top: 2px solid #FFA500;
		border-left: 1px solid #A5A5A5;
		-moz-border-radius: 5px 5px 0px 0px;
		margin: 0px 2px -3px 0px;
		padding:1px 2px 1px 2px;
		position:relative;
		top:0px;
		float:left;
		width:auto;
		min-width:30px;
		height:26px;
                text-align: center;
		cursor: pointer;
		font-size:10px;
		letter-spacing:0pt;
		background-color: $clr{bg_task}; }
                
div.navoff, div.navdisabled
 {		border: 1px solid #a5a5a5;
		border-bottom: 0px;
		border-left: 1px solid #DDDDDD;
		-moz-border-radius: 5px 5px 0px 0px;
		margin: 0px 2px 0px 0px;
		padding:1px 2px 1px 2px;
		width: auto;
		min-width:30px;
                text-align: center;
                letter-spacing:0pt;
		height:26px;
		cursor: pointer;
		float:left;
		color:#777777;
		background-image: url($img_url/shadow.gif);
		background-repeat: repeat-x;
		background-position: right top;
		background-color: #EFEFEF;
		font-size:10px;
		 }

div.navdisabled
 {		color: #CCCCCC;
		cursor: default;
		border: 1px solid #DDDDDD;
		border-bottom: 0px; }

.msgbox
 {		border: 1px solid #FFFFFF;
		border-top: 1px solid #dddddd;
		border-left: 1px solid #dddddd;
		padding: 3px;
		background-image: url($img_url/box_bgnd.jpg);
		background-repeat: repeat-y;
		background-position: right top; }

.infobox
 {		position: absolute;
                -moz-border-radius: 7px;
		left:0px;
		top:0px;
		overflow: visible;
		white-space: normal;
		visibility: hidden; 
		display:none;
		background-color: $clr{bg_low_evidence};
		border-left: 1px solid #999999;
		border-top: 1px solid #999999;
		border-bottom: 2px solid #000000;
		border-right: 2px solid #000000;
		padding: 5px;
		z-index: 200; }

.tooltipig
 {		position: absolute;
		font-size: $tasksfontsize;
		visibility: hidden; 
		left:0px;
		top:0px ;
		z-index: 150; }

.tooltipbody
 {		float:left;
                padding: 8px 4px 10px 4px; }
 
.tooltipbody a:link, .tooltipbody a:visited
 {		color:$clr{font}; }
  
td.bar, td.littlebar, .tooltipbar,
td.littlebar a, td.littlebar a:visited
 {		color: $clr{font_barra};
		font-weight: bold;
		padding-left: 2px;
		font-size: $barrafontsize;
		font-family: $barrafontname; }

td.littlebar, .tooltipbar, td.littlebar a, td.littlebar a:visited
 {		font-size: 11px; }

td.menu, th
 {		white-space: nowrap;
		background: $clr{bg_menu_task};
		color: $clr{font_menu_task};
		border-bottom: 2px $clr{bg_barra} solid;
		border-right: 1px $clr{bg_barra} solid;
		font-size: $tasksfontsize;
		font-family: $tasksfontname; }

td.menu a, td.menu a:visited
 {		color: $clr{font_menu_task};
		font-size: $tasksfontsize;
		font-family: $tasksfontname; }

table.tasklist
 {		width: 100%;
		border-width: 0px;
		clear: left;
		margin: 5px 0px 5px 0px;
		padding: 0px;
		background: $clr{bg_task};
		empty-cells: show; }

td.link, td.list, td.lgray, td.hgray
 {		vertical-align: top;
		border-bottom: 1px $clr{bg_task} solid;
		padding: 1px;
		font-size: $tasksfontsize;
		font-family: $tasksfontname; }

td.link
 {		background: $clr{bg_link};
		color: $clr{font_link};
		font-size: 110%; }

td.lbl
 {		background: $clr{bg_link};
                vertical-align: top;
                padding: 3px;
		font-size: $tasksfontsize;
		font-family: $tasksfontname;
		color: $clr{font_low_evidence};
		text-align:right;
		border-bottom: 1px solid $clr{border};
		white-space: nowrap; }

td.list
 {		background: $clr{bg_list};
		color: $clr{font}; }

.menu_title
 {		white-space: nowrap;
                width:82px;
                padding:0;
                border:0;
                cursor: pointer;
                display: block;
                letter-spacing:-0.5pt;
		margin: 8px 0px 2px 0px;
		background: $clr{bg_menu_title};
		-moz-border-radius: 0px 10px 0px 0px;
                text-shadow: #AAAAAA 0.1em 0.1em 1px;
		color: $clr{font_menu_title};
		font-weight: bold;
		text-align: left;
		font-size: 110%;
		font-family: $menufontname; }

.menu_title_active
 {		color: #ffffff; }

.menu_title_content
 {		overflow: hidden;
                width:82px;
                margin:0;
                padding:0;
                border:0;
                display: block; }

a.item:link, a.item:visited
 {		color: $clr{font_menu};
		background: $clr{bg_menu_item};
		line-height: 1.3em;
		text-align:left;
		white-space: nowrap;
		font-size: $menufontsize;
		font-family: $menufontname;
		padding: 0px 0px 0px 2px;
		border-bottom: 1px solid $clr{bg_menu};
		margin:0px;  
		display: block;}
a.item:hover
 {		background: $clr{font_menu};
		color: $clr{bg_menu_item}; }
 
td.minilist
 {		empty-cells: show;
		vertical-align: top;
		color: $clr{font_low_evidence};
		font-size: 10px;
		font-weight: normal;
		font-family: $tasksfontname;
		line-height: 1.0em; }

td.button
 {		white-space: nowrap;
		background-color: transparent;
		text-shadow: #999999 0.2em 0.2em 3px;
		vertical-align: middle;
		color: $clr{font_button};
		font-size: $buttonfontsize;
		font-weight: bold;
		font-family: $buttonfontname;
		line-height: 1.1em; } 

div.autocomplete
 {
  font-size:10px;
  position:absolute;
  background-color:white;
  border:1px solid #888;
  margin:0px;
  padding:0px; }

div.autocomplete ul
 {
  list-style-type:none;
  margin:0px;
  padding:0px; }

div.autocomplete ul li.selected
 { background-color: $clr{bg_low_evidence}; }

div.autocomplete ul li
 {
  font-size:10px;
  list-style-type:none;
  list-style-image: none;
  display:block;
  margin:0;
  padding:1px;
  cursor:pointer;
  border-bottom:1px solid #888; }

-->
</STYLE>
END

  ## Add external css
  $html .= $data{css};

  ## Plugin common Ajax features
  my %ajax_req = ( ajaxrequest => 'igsuite?action=ajaxrequest' );

  ## Plug dprof if debug is active
  $ajax_req{getdprof} = 'dprof' if $ENV{IG_DEBUG_ID};
   
  %ajax_req = (%ajax_req, %{$data{ajax_req}}) if $data{ajax_req};
  my $pjx = new CGI::Ajax( %ajax_req );
  $html .= "\n<!-- START CGI AJAX JS -->\n".
	   $pjx->show_javascript().
	   "\n<!-- END CGI AJAX JS -->\n";

  ## Common JavaScript Features
  $html .= "\n<!-- INCLUDE EXTERNAL JAVASCRIPT -->\n".
           JsExec( src => "$IG::img_url/ig.js" ).
           JsExec( src => "$IG::img_url/prototype.js" ).
           JsExec( src => "$IG::img_url/scriptaculous.js" );

  ## Add external javascript
  $html .= $data{javascript};

  ## Close HEAD section
  $html .= "\n</HEAD>\n\n";

  $html .= "\n<!-- START BODY PART -->\n";
  if ($cgi_name ne 'igwiki' &&
      $IG::screen_size =~ /^noframe/ &&
      $tema ne 'printable_'
     )
   {
    require IG::Menu;
    $html .= "<body $data{onevent} style=\"background: $clr{bg_menu}\">\n"; 
    $html .= JsExec( src => "$IG::img_url/wz_tooltip.js" ); ## QuickHelp js
    $html .= IG::MkMenu().Br() if $screen_size eq 'noframe2';
    $html .= "<table cellspacing=2 cellpadding=0".
             " style=\"width:100%; background-color:$clr{bg_menu}\"><tr>";

    $html .= "<td style=\"background-color:$clr{bg_menu}; vertical-align:top; width:130px\">\n".
	     IG::MkMenu().
	     "</td>" if $screen_size eq 'noframe';

    $html .= "<td width=\"100%\" valign=\"top\" align=\"$data{align}\">\n";
   }
  else
   {
    $html .= "<body $data{onevent}>\n"; 
    $html .= JsExec( src => "$IG::img_url/wz_tooltip.js" ); ## QuickHelp js
    $html .= "<table cellspacing=$data{padding} cellpadding=0".
             " style=\"height:100%; width:100%\">".
	     "<tr>";
    $html .= _shortcuts($data{shortcuts}) if    $data{shortcuts}
					     && $screen_size eq 'large'
					     && $tema ne 'printable_';

    $html .= "<td style=\"width:100%; height:100%; vertical-align:top;\"".
             " align=\"$data{align}\">\n";
   }

  ## Check external plugins
  $html = CkExtPlugins( 'HtmlHead', \$html, \%data ) if %plugins;

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 QuickCreator()

Build a little form to quickly create a document or an event

=cut

sub QuickCreator
 {
  my $html = CheckPrivilege()
    	     ? ( TaskHead(  title      => $lang{create_quickly},
		 	    icon       => 2,
			    width      => 180 ).

	         Input(     type       => 'quickcreator',
			    fieldstyle => 'width:100%',
			    style      => 'width:100%' ).

   	         TaskFoot(). "<div style=\"line-height:5px\"><br></div>" )

             : '';

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################
sub _shortcuts
 { 
  my $html = "<div id=\"iglogodiv\" style=\"border:1px solid #999999; background:#FFFFFF; margin-bottom: 5px; width:100%; display:none;\">\n".
             "<a href=\"$cgi_name\">".
	     "<img src=\"$IG::img_url/igsuite_logo.gif\" style=\"width:160px; padding: 5px;\"></a></div>\n".
	     "<script defer type=\"text/javascript\">\n".
	     "if (window.top == window)\n {\n".
	     "\tiglogodiv.style.display = 'block';\n}\n".
	     "</script>\n".

	     shift;

  return "<td valign=\"top\" style=\"padding-left:4px;\">$html</td>";
 }

##############################################################################
##############################################################################

=head3 HtmlFoot()

Close <html> and <body> tag and flush output buffer.

=cut

sub HtmlFoot
 { 
  ## To print htmlfoot only once
  return if $executed{htmlfoot}++;
  my $html = "</td></tr></table>\n";

  ## Build a fake div to redirect some useless ajax content
  $html .= "\n<!-- GHOSTS DIV -->\n".
           "<div id=\"fake_div\" style=\"display:none;\"></div>\n";

  ## Build infoboxes div
  $html .= _build_infobox_div();

  ## Debug mode
  if ( $ENV{IG_DEBUG_ID} && $on{action} ne 'findshow' )
   {
    require IG::Utils;
    $html .= IG::Debug( id => $ENV{IG_DEBUG_ID} );
   }

  ## Show errors
  for (@errmsg, $on{errmsg})
   {
    $html .= ToolTip( width    => '300px',
                      visible  => 'true',
                      position => 'center', 
                      show     => '',
                      fgcolor  => '#666666',
                      bgcolor  => $clr{bg_low_evidence},
                      body     => TaskMsg( MkEntities($_)."<br>\n", 0 )
                    ) if $_;
   }

  ## Take script end-time to benchmark
  if ( $tv{start_script} )
   {
    $tv{end_script} = new Benchmark;
    my $time_diff = Benchmark::timediff( $tv{end_script}, $tv{start_script} );
    $html .= Benchmark::timestr( $time_diff );
   }

  ## Common javascripts
  $html .= "\n<!-- COMMON JAVASCRIPTS -->\n".
           "<script defer type=\"text/javascript\">\n\n";

  ## Add JsExec "footer" Calls
  $html .= "//JsExec calls\n$js_code{footer}\n\n";
  delete $js_code{footer};
           
  ## Fix IE bug on PNG transparency
  $html .= "//Fix IE bug on PNG\n".
           "correctPNG();\n\n" if $client_browser eq 'msie';

  ## Forms autofocus
  $html .= "// Form Autofocus\n".
           ( $form{focusthis}
             ? "Event.observe(window, \"load\", function()".
               " { $form{focusthis}.focus(); } );\n"
             : $form{autofocus} eq 'true'
               ? "Event.observe(window, \"load\", function()".
                 " { if(document.forms[0]) ".
                 "{ Form.focusFirstElement(document.forms[0]); }} );\n"
               : "// no autofocus\n" );

  ## Ensure that chkmsg frame is up to date
  my $currenttime = time;
  $html .= <<CHKMSG if $cgi_name ne 'checkmsg';
if (parent.chkmsg) 
 {
  var updatetime = parent.chkmsg.document.getElementById("chkmsg_updatetime")
                   ? parent.chkmsg.document.getElementById("chkmsg_updatetime").innerHTML
		   : 0;
  if( updatetime && $currenttime - updatetime > 300 ) 
    parent.chkmsg.location.reload();
 }
CHKMSG

  $html .= "</script>\n\n</body>";

  ## IE Hack to disable page cache
  $html .= "<META HTTP-EQUIV=\"pragma\" CONTENT=\"no-cache\">"
           if $client_browser eq 'msie';

  $html .= "</html>\n";

  ## Check external plugins
  $html = CkExtPlugins( 'HtmlFoot', \$html, undef ) if %plugins;

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################
sub _build_infobox_div
 {
  ## Build infoboxes div
  my $html;
  foreach my $id ( keys %page_boxes )
   {
    $html .= "<div ".
                   "style=\"width:300px;\" ".
                   "class=\"infobox\" ".
                   "id=\"$id\" ".
                   "onClick=\"event.cancelBubble = true;\">".
             "Loading...</div>\n";
   }
  undef %page_boxes;
  defined wantarray ? return $html : PrOut $html;  
 }

##############################################################################
##############################################################################

=head3 TaskHead(options)

A Task is a GUI element. It can contains data forms, data lists and many
IG others elements. An IG 'Task' is like a window
manager 'task', with 'task-bar', 'menu-bar' etc.

=cut

sub TaskHead
 {
  my %data = @_;
  my ($bar_class, $html);
  my $icon_width = $tema eq 'microview_' ? 16 : 23;

  ## According to the tema we can display a background image in the taskbar
  my $imgbgbarra = $tema{task}{barra_bg_image}
                 ? "style=\"background:url($IG::img_url/${tema}bgbarra.gif);\""
                 : '';

  $data{bgcolor}  ||= $clr{bg_task};
  $data{padding}  ||= $data{icon} < 2 ? 7 : 2;
  $data{title}    ||= $lang{$cgi_name} || ucfirst($cgi_name);
  $page_title     ||= $data{title};
  $data{align}    ||= 'left';
  if ( $IG::screen_size =~ /^noframe/ && $data{width} > 320 )
   { 
    $data{width} = 'auto';
    $data{minwidth} = '';
    $data{minheight} = '';
   } 
  $data{width}  &&= "width: $data{width}; "; 
  $data{height} &&= "height: $data{height}; ";
  my $border_task = $tema{task}{corner_image} ? 0 : 1;
  
  ## Task Size
  $html .= "\n<!-- START TASKHEAD -->\n";
  $html .= "<table cellspacing=0 cellpadding=0 border=0".
           " style=\"border:0; $data{width}$data{height}$data{style}\">\n".
           "<tr><td>";

  ## Task Border & background
  $html .= "<table cellspacing=0 cellpadding=0 border=0".
           " style=\"border-spacing: 0; width: 100%; ".
           ( $data{height} eq 'height: 100%; ' ? $data{height} : '').
           " border: ${border_task}px $clr{line_task} solid;".
           " background-color:$data{bgcolor}; -moz-border-radius:5px;\">\n".
           "<tr><td valign=\"top\">";

  ## Task Title Bar
  $html .= "<table cellspacing=0 cellpadding=0".
           " style=\"border-spacing: 0; border: 0px; width: 100%;".
           " background: $clr{bg_barra};\">\n<tr>";


  ## Set title font size
  $bar_class = ($data{icon}<2 || $data{icon}==5) && length($data{title}) < 35
	     ? 'bar'
	     : 'littlebar';

  if ($tema{task}{corner_image} && $bar_class eq 'bar')
   { $html .= "<td width=12><img alt=\"s\" src=\"$IG::img_url/${tema}angolosx.gif\"></td>";}

  $html .= "<td class=\"$bar_class\" $imgbgbarra><table border=0 cellspacing=0 cellpadding=0><tr>";

  ## IG Logo (IGBox)
  $html .= ( $data{icon}==5 || $tema eq 'microview_'
	     ? "<td valign=\"top\" width=2>"
	     : "<td valign=\"top\" width=$icon_width>".
               ( !$executed{htmlhead}  ||
                 $auth_user eq 'guest' ||
                 $screen_size =~ /^noframe/
 
                 ? Img( href  => $cgi_name,
                        width => $icon_width,
                        src   => "$img_url/$tema{task}{favicon}",
                        title => 'IGSuite' )

	         : ToolTip( title   => 'IGBox',
	                    onclick => "ajaxrequest(['NO_CACHE',".
	                                            "'ajaxaction__binder',".
	                                            "'a__1'],".
	                                           "['binder_body']);",
                            id      => 'binder', 
                            body    => '<br><br><br>',
                            show    => Img( alt   => 'IGBox',
                                            width => $icon_width,
                                            src   => "$img_url/$tema{task}{favicon}" ),
                            width   => 190 ))
	   ).
	   '</td>' if $data{icon} < 2 && $tema ne 'printable_';

  ## Task Title
  $html .= "<td class=\"$bar_class\">".
           MkEntities( $data{title} ).
           "</td></tr></table></td>\n";

  ## Print Title Bar icons
  $html .= "<td valign=\"top\" align=\"right\" $imgbgbarra nowrap>".
           "<span style=\"line-height:11px;\">&nbsp;</span>";#min-height
  $html .= "\n<!-- START TASKHEAD ICONS -->\n";
  $html .= $data{icons} if $tema ne 'printable_';
  if ($data{icon}==5)
   {
    $html .= "<div style=\"height:27px\"></div>";
   }
  elsif (  $tema eq 'printable_' && $request_method ne 'POST' )
   {
    $html .= Img( href  => 'javascript:self.print()',
                  class => 'noprint',
		  src   => "$IG::img_url/${tema}stampa.gif",
		  style => 'width:15px; height:15px; margin-right:3px',
		  title => $lang{print} );

    $html .= Img( href  => "webmail?action=sendprintview",
                  target=> 'mainf',
                  onclick=> "setTimeout('self.close()',500);",
                  class => 'noprint',
                  style => 'width:13px; height:14px; margin-right:3px; ',
		  src   => "$IG::img_url/email.png",
		  title => $lang{send_by_email}
	        ) if CheckPrivilege('webmail_new');
   }
  elsif ( $data{icon} != 1 &&
	  $data{icon} !=2  &&
	  $data{icon} !=4  &&
	  $request_method ne 'POST'
	)
   {
    ## Attach icon
    $html .= Img( href   =>'postit?'.
                           'action=proto&amp;'.
                           'type=Attach&amp;'.
                           'sharemode=1&amp;'.
                           'link='. MkUrl( "$cgi_url/$cgi_name".
                                           "$ENV{PATH_INFO}?".
                                           $query_string) . '&amp;'.
                           'title=' . MkUrl($page_title),
                  target =>'mainf',
                  width  =>$icon_width,
                  src    =>"$IG::img_url/${tema}attach.gif",
                  title  =>$lang{add_bookmark}
                ) if $data{icon} !=3 && CheckPrivilege('postit_edit');

    ## Print Icon
    $html .= Img( href   => "$cgi_name$ENV{PATH_INFO}?print=1$query_string",
                  target => "_blank",
                  src    => "$IG::img_url/${tema}stampa.gif",
                  width  =>$icon_width,
                  title  => $lang{print_version} );
   }
 
  if ($tema ne 'printable_' && $data{icon} < 2)
   {
    ## Help Icon
    $html .= Img( style => "cursor:help;",
		  href  => "javascript:winPopUp('".
		           "help?action=get_help&amp;".
		                "script=$cgi_name&amp;".
                                "scriptaction=$on{action}".
		           "',700,550,'Help');",
		  title => $lang{can_i_help_you},
                  width => $icon_width,
		  src   => "$IG::img_url/${tema}help.gif" );
   }

  if ($IG::screen_size =~ /^noframe/ &&
      defined(&::findshow) &&
      $tema ne 'printable_' &&
      $data{icon} != 2
     )
   {
    $html .= Img( href  => "$cgi_name?action=findshow",
                  width => $icon_width,
		  src   => "$IG::img_url/${tema}search.gif" );
   }

  $html .= "\n<!-- END TASKHEAD ICONS -->\n";
  $html .= "</td>\n";

  if ($tema{task}{corner_image} && $bar_class eq 'bar')
   { $html .= "<td width=12><img alt=\"d\" src=\"$IG::img_url/${tema}angolodx.gif\"></td>";}

  $html .= "</tr></table>\n"; ## close taskbar

  ## Task content
  $html .= "<table cellpadding=$data{padding}".
           " style=\"width:100%; height:100%\">".
           "<tr><td align=\"$data{align}\" valign=\"top\">\n";
               
  ## Emulate min-width css attribute to fix a minimum task width
  $html .= "<div style=\"line-height:0.1px;".
			"width:$data{minwidth};".
			"border:0;".
			"margin:0;".
			"padding:0;".
	   "\"></div>" if $data{minwidth};

  ## Emulate min-height css attribute to fix a minimum task height
  $html .= "<div style=\"position:absolute;".
			"height:$data{minheight};".
			"width:1px;".
			"border:0;".
			"margin:0;".
			"padding:0;".
	   "\"></div>" if $data{minheight};

  $html .= "\n<!-- START TASKHEAD CONTENT -->\n";

  ## Check external plugins
  $html = CkExtPlugins( 'TaskHead', \$html, \%data ) if %plugins;
 
  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 TaskMsg($my_msg, $my_icon, $my_width, $my_height)

Write a cool Info or Warning message, according to $my_icon.

  # ico=0 Warning Message
  # ico=1 Info Message
  # ico=2 Other Info Message
  # ico=3 Black info message
  # ico=4 Very very nice task message
  # ico=5 Mini task msg
  # ico=6 Shadowed b&w
  # ico=7 Shadowed 2 b&w
  # ico=8 Postit yellow

=cut

sub TaskMsg
 {
  my ($msg, $ico, $width, $height) = @_;
  my $html;
  return if !$msg || $msg eq '&nbsp;';
  $width  ||= '100%';
  my $style_size  = "width:$width; ";
     $style_size .= "height:$height; " if $height;

  if ( $ico==2 )
   {
    $html.="<table style=\"$style_size\" cellspacing=2 cellpadding=2>\n".
	   "<tr><td style=\"$style_size; padding: 7px; background: $clr{bg_task}; border: 2px solid $clr{bg_menu_task}; white-space: normal;\">$msg</td></tr>\n".
	   "</table>\n";
   }
  elsif ( $ico==3 )
   { 
    $html.="<div style=\"$style_size border:2px #DDDDDD solid;".
           " background:#000000; color:#FFFFFF;\">".
           "<div style=\"padding:5px\">$msg</div></div>\n";
   }
  elsif ( $ico==4 )
   {
    $html.="<table style=\"$style_size\" cellpadding=0 cellspacing=0>
	    <tr><td style=\"width:7px; height:7px;\">
	         <img alt=\"lt\" src=\"$IG::img_url/msglefttop.gif\" width=7 height=7></td>
		<td style=\"width:100%; height:7px; background-image: url($IG::img_url/msgtop.gif)\">
		 <img alt=\"t\" src=\"$IG::img_url/msgtop.gif\" width=1 height=7></td>
		<td style=\"width:17px; height:7px;\">
		 <img alt=\"tr\" src=\"$IG::img_url/msgtopright.gif\" width=10 height=7></td>
	    </tr>";

    $html.="<tr><td style=\"width:7px; height:100%; background-image: url($IG::img_url/msgleft.gif)\">
                 <img alt=\"l\" src=\"$IG::img_url/msgleft.gif\" width=7 height=1></td>
 		<td style=\"background-color:#f9f9f9\">$msg</td>
		<td style=\"width:10px; height:100%; background-image: url($IG::img_url/msgright.gif)\">
		 <img alt=\"r\" src=\"$IG::img_url/msgright.gif\" width=10 height=1></td>
	    </tr>";

    $html.="<tr><td style=\"width:7px; height:16px;\">
                 <img alt=\"lb\" src=\"$IG::img_url/msgleftbottom.gif\" width=7 height=16></td>
		<td style=\"width:8px; height:16px; background-image: url($IG::img_url/msgbottom.gif)\">
		 <img alt=\"b\" src=\"$IG::img_url/msgbottom.gif\" width=8 height=16></td>
		<td style=\"width:7px; height:16px;\">
		 <img alt=\"br\" src=\"$IG::img_url/msgbottomright.gif\" width=10 height=16></td>
	    </tr></table>\n";
   }
  elsif ( $ico==5 )
   {
    $html.="<table cellspacing=0 cellpadding=0 style=\"$style_size".
           " background: $clr{bg_task}; border: 1px solid $clr{border_low};\">\n".
	   "<tr><td style=\"font-size:10px; width:100%; padding:5px; white-space:normal;\">$msg</td></tr>\n".
	   "</table>\n";
   } 
  elsif ( $ico==6 )
   { 
    $html.="<table style=\"$style_size\" cellpadding=0 cellspacing=0>
	    <tr><td><img alt=\"lt\" src=\"$IG::img_url/msg2lefttop.gif\"></td>
		<td style=\"background-image: url($IG::img_url/msg2top.gif)\">
		 <img alt=\"t\" src=\"$IG::img_url/msg2top.gif\"></td>
		<td><img alt=\"tr\" src=\"$IG::img_url/msg2topright.gif\"></td>
	    </tr>";
 
    $html.="<tr><td style=\"background-image: url($IG::img_url/msg2left.gif)\">
                 <img alt=\"l\" src=\"$IG::img_url/msg2left.gif\"></td>
 		<td style=\"background:#FFFFFF; width:100%; height:100%\" valign=\"top\">$msg</td>
		<td style=\"background-image: url($IG::img_url/msg2right.gif)\">
		 <img alt=\"r\" src=\"$IG::img_url/msg2right.gif\"></td>
	    </tr>";

    $html.="<tr><td><img alt=\"lb\" src=\"$IG::img_url/msg2leftbottom.gif\"></td>
		<td style=\"background-image: url($IG::img_url/msg2bottom.gif)\">
		 <img alt=\"b\" src=\"$IG::img_url/msg2bottom.gif\"></td>
		<td><img alt=\"br\" src=\"$IG::img_url/msg2bottomright.gif\"></td>
	    </tr></table>";
   }
  elsif ( $ico==7 )
   { 
    $html.="<table cellspacing=0 cellpadding=0
             style=\"background:#FFFFFF; $style_size\">
	    <tr>
	     <td class=\"msgbox\" style=\"width:100%; height:100%\">$msg</td>
	     <td style=\"width:4px; height:100%; background-image: url($img_url/box_leftBorder.gif); background-repeat: repeat-y;\"></td>
	    </tr>
	    <tr>
	     <td style=\"height:4px; background-image: url($img_url/box_bottomBorder.gif); background-repeat: repeat-x;\"></td>
	     <td><img alt=\"bc\" src=\"$img_url/box_corner.gif\"></td>
	    </tr>
	    </table>";
   }
  elsif ( $ico==8 )
   { 
    $html .= "<div style=\"$style_size;".
                          "float:left;".
                          "padding-bottom:5px;".
                          "border-top:1px solid #DDDDDD;".
                          "background-position:right bottom;".
                          "background-repeat:no-repeat;".
                          "background-image:url($img_url/postit_box_shadow.gif);".
                          "\">".
             "<div style=\"float:left;".
                          "width:2px;".
                          "height:100%;".
                          "background-color:#e7d742;".
                          "border-left:1px solid #999999;".
                          "margin-right:8px;".
                          "\">&nbsp;</div>".
             "<div style=\"float:right;".
                          "width:30px;".
                          "height:30px;".
                          "background-position:right top;".
                          "background-repeat:no-repeat;".
                          "background-image:url($img_url/postit_box_corner.gif);".
                          "margin:-1px 0px 0px 0px\">&nbsp;</div>".
             "<div style=\"padding:8px;".
                          "color:$clr{font_low_evidence};\">$msg</div></div>";
                
   }
  else
   {
    $html .= MkTable
              ( style      => "width: $width;".
			      "background:$clr{bg_low_evidence}; padding:15px; ",
                style_c1_r => 'vertical-align:top;width:20px;',
	        style_c2_r => 'vertical-align:top;font-weight:bold;',
	        values     => [([ Img( src   => "$IG::img_url/information.gif",
	                               width => 16,
		                       alt   => 'Information alert' ),
				  $msg ])]
              );
   }

  $html = "<div style=\"margin:5px 0px 5px 0px; clear:both\">$html</div>\n";

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 AutoCloseTask()

Make an auto-close Task

=cut

sub AutoCloseTask
 {
  my %data = @_;
     $data{title} ||= 'IGSuite';

  HtmlHead( onevent => $data{msg} ? '' : "onload=\"self.close();\"",
            title   => $data{title} );

  if ( $data{msg} )
   {
    TaskHead( title   => $data{title} );
    TaskMsg(  $data{msg}, $data{taskmode} || 1);
    FormHead();
    Input(    type    => 'button',
              show    => $lang{close},
	      focus   => 'true',
              onclick => 'self.close();' );
    FormFoot();
    TaskFoot();
   }

  HtmlFoot();
 }

##############################################################################
##############################################################################

=head3 Warn()

Make a Warning box. It accepts only one argument (only plain text)

=cut

sub Warn
 {
  my $msg = shift;
  undef $prout_page;
  $executed{htmlhead} = '';

  PrOut HtmlHead() .
        TaskHead( icon => 1, style => 'margin-top:60px' ) .

        MkTable( style      => "width: 300px; padding:15px; ",
	         style_c1_r => 'vertical-align:top;width:40px;',
	         style_c2_r => 'vertical-align:top;font-weight:bold;',
	         values     => [([ Img( src   => "$IG::img_url/important.png",
                                        width => 32,
		                        alt   => 'Information alert' ),
			           MkEntities( $msg ) ],
                                 [ '',
                                   Input( type   => 'submit',
                                          style  => 'font-size:10px; margin-top:10px',
                                          float  => 'right',
                                          value  => $lang{continue},
                                          onclick=> "javascript:history.go(-1);")]
                                )]
		).
		    
        TaskFoot().
        HtmlFoot();
        
  return $prout_page;
 }

##############################################################################
##############################################################################

=head3 QuickHelp()

Make a quick help to show during an event as a mouse over a link.

=cut

sub QuickHelp
 {
  my %data = @_;
  my $html;

  $data{id}     ||= 'qe'.(++$page_tabindex);
  $data{width}  ||= 'auto';
  return if !$data{anchor};

  $html = ( $data{onclick} ? " onclick=\"$data{onclick}\"" : '').
          " onmouseover=\"TagToTip('$data{id}_content',".
                                  " BGCOLOR, '$clr{bg_low_evidence}')\"".
          " onmouseout=\"UnTip()\"".
          ">$data{anchor}";

  ## this is the quick-help anchor
  $html = $data{href}
        ? "<a id=\"$data{id}\" href=\"$data{href}\"$html</a>\n"
        : "<span id=\"$data{id}\"$html</span>\n";

  ## this is the quick-help content
  $html .= "<div style=\"display:none;width:$data{width}\" id='$data{id}_content'>".
           "$data{alt}</div>\n";

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 ToolTip()

Make a quick help to show during an event as a mouse over a link.

=cut

sub ToolTip
 {
  my %data = @_;

  $data{hpos}     ||= 20;
  $data{vpos}     ||= 20;
  $data{bgcolor}  ||= $clr{bg_task};
  $data{fgcolor}  ||= $clr{bg_menu_task};
  $data{title}    ||= 'IGSuite';
  $data{width}    ||= 'auto';
  $data{id}       ||= 'tt' . ++$page_tabindex;
  $data{onclick}    = "$data{onclick};".
                      "showPopup('$data{id}',event);";
 
  my $html = "\n<!-- Start a ToolTip -->\n".

             ## task shadow
             ( $client_browser eq 'msie'
               ? "<div id=\"$data{id}\" class=\"tooltipig\">"
               : "<div id=\"$data{id}\" class=\"tooltipig\"".
                 " style=\"background: url($img_url/shadow.png) no-repeat bottom right; padding: 0px 6px 6px 0;\">" ).

             ## task container
             "<div style=\"border: 1px solid #000000;overflow:hidden; background-color:$data{bgcolor}; width:$data{width};\">".
             
             ## IE Hack
             ( $client_browser eq 'msie'
               ? "<iframe frameborder=\"0\" src=\"\" style=\"position:absolute; width:100%; height:100%; z-index:-1;\"></iframe>"
               : "").

             ## Tooltip bar
	     "<div class=\"tooltipbar\" id=\"$data{id}bar\"".
	     " style=\"position:relative; height:16px; color:$data{bgcolor}; background:$data{fgcolor}; padding:1px; ".
	      ( $data{draggable} ne 'false' ? 'cursor:move;">' : '">').

	      Img( src     => "$img_url/close_inline.gif",
	           onclick => "hideThisPopup('$data{id}');",
	           width   => 13,
	           title   => $lang{close},
	           style   => "cursor:pointer; position:absolute;right:2px;").
	      $data{title}.
	      "</div>".

             ## Tooltip body
	     "<div class=\"tooltipbody\" id=\"$data{id}_body\"".
	     " style=\"background-color:$data{bgcolor};\">$data{body}</div>".
	     "</div></div>\n";
    
  $html.= "<span onclick=\"$data{onclick};initToolTip_$data{id}()\"".
          " title=\"$data{title}\" style=\"cursor: pointer\">".
	  "$data{show}</span>\n" if $data{show};

  $html .= "<script type=\"text/javascript\">\n".
           "\tfunction initToolTip_$data{id}() {\n".
           "\tgetSize();\n". 
           "\tvar theHandle = document.getElementById(\"$data{id}bar\");\n".
           "\tvar theRoot   = document.getElementById(\"$data{id}\");\n".
           "\tvar rootPos   = getElementDimensions('$data{id}');\n".
      
           ## positioning     
	   ( $data{visible} eq 'true'
	     ? ( $data{position} eq 'center'
                 ? "\tplacePopup('$data{id}',".
                                "((maxWidth / 2) - (rootPos.width / 2)),".
                                "((maxHeight / 2) - (rootPos.height / 2)));\n"
                 : "\tplacePopup('$data{id}', $data{hpos}, $data{vpos});\n" )
	     : '' ).

           ( $data{draggable} ne 'false'
             ? "new Draggable(theRoot,{handle:theHandle});"
             : '').
	   "\n }\n".

	   ( !$data{show}
	     ? "\tinitToolTip_$data{id}()" : '' ).
	   "</script>\n".
	   "<!-- End ToolTip -->\n";

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 TaskFoot()

Close a TaskHead() element;

=cut

sub TaskFoot
 {
  my %data = @_;
  my $html = "\n<!-- END TASKHEAD CONTENT -->\n";

  ## Close content div
  $html .= "</td></tr></table>\n";

  ## Close external border div
  $html .= "</td></tr>\n".
           "<td style=\"background-color:$clr{bg_barra}; height:6px;\">"
             if $tema{task}{corner_image};

  ## Close task container 
  $html .= "</td></tr></table>\n";

  ## Comments
  if ($data{comments} eq 'yes' && $tema ne 'printable_')
   {
    require IG::Utils;
    $html .= MkComments(%data);
   }
 
  $html .= "</td></tr></table>\n";

  ## Check external plugins
  $html = CkExtPlugins( 'TaskFoot', \$html, \%data ) if %plugins;

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 TaskListMenu()

A 'TaskList' is the result of a query displayed in a table. With this
procedures you can organize the columns of the TaskList.

=cut

sub TaskListMenu
 {
  my @item = @_;
  my $html;
  $task_list_cols = 0;
  $task_list_rows = 0;
  $on{sortdirection} ||= $list_order;
  my $sortdirection = $on{sortdirection} eq 'desc' ? 'asc' : 'desc';
 
  $html = "\n<table class=\"tasklist\" cellspacing=1><tr>";
  foreach (@item)
   {
    next if ref($_) ne 'ARRAY';
    $html .= "<td class=\"menu\" @$_[2]>";

    if ( $on{order} && @$_[1] =~ /order\=${on{order}}[^\w]*/ )
     {
      $html .= Img( href  => "$cgi_name?".
                             "sortdirection=$sortdirection&amp;@$_[1]",
                    src   => "$IG::img_url/freccia$on{sortdirection}.gif",
                    width => 7,
                    title => @$_[0] =~ /^[\w]+$/ ? "Order by @$_[0]" : '' );
     }
    elsif (@$_[1])
     {
      $html .= "<a href=\"$cgi_name?".
                         "sortdirection=$on{sortdirection}&amp;@$_[1]\">";
     }

    $html .= @$_[0] =~ /^</ ? @$_[0] : ( MkEntities(@$_[0]) || '&nbsp;' );
    $html .= '</a>' if @$_[1];
    $html .= '</td>';

    ## Store cells to export them inside an Excel File
    if ( $on{list2xls} || $on{list2csv} )
     {
      require IG::Utils;
      $task_list_content[0][$task_list_cols]
      = TextConvert( text     => IG::HtmlUntag( @$_[0] ),
                     fromcode => $IG::lang_charset,
                     tocode   => 'iso-8859-1' );
     }
    ++$task_list_cols;
   }
  $html .= "</tr>\n";

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 TaskListItem()

As TaskListMenu with this procedure you can show row by row.

=cut

sub TaskListItem
 {
  ++$task_list_rows;
  my @item = @_;
  my $cnt = 0;
  my $html = "<tr ".
             "onmouseover=\"setRowBorder(this,'1px $clr{bg_barra} solid'); \"".
             "onmouseout=\"setRowBorder(this,'1px $clr{bg_task} solid');\">\n";

  foreach (@item)
   {
    $_ = [$_] if !ref($_); ## Allow TaskListItem(@array);
    my $rawValue = @$_[0]; ## Keep unchanged value
    if ( ref($rawValue) )
     {
      ## optional: let you pass two version of data
      @$_[0] = @$rawValue[0];    ## 1) to display (string with local format)
      $rawValue = @$rawValue[1]; ## 2) to export in XLS (number)
     }

    @$_[0] =~ s/^\s*$/\&nbsp\;/;
    @$_[3] ||= !$cnt ? 'link' : 'list';
    $html .= "<td class=\"@$_[3]\" @$_[2]>";
    $html .= "<a href=\"@$_[1]\">" if @$_[1];
    $html .= @$_[0];
    $html .= "</a>" if @$_[1];
    $html .= "</td>\n";

    ## Store rows to an Excel filesheet if requested
    if ( $on{list2xls} || $on{list2csv} )
     {
      $rawValue = TextConvert( text     => IG::HtmlUntag( $rawValue ),
                               fromcode => $IG::lang_charset,
                               tocode   => 'iso-8859-1' );
      $rawValue =~ s/ +/ /g;
      $task_list_content[$task_list_rows+1][$cnt] = $rawValue;
     }
    ++$cnt;
   }
  $html .= "</tr>\n";
  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 TaskListFoot($empty_rows_showen_if_any)

Close a TaskListMenu element. You can draw automatic empty rows in the table
if queries doesn't return any data.

=cut

sub TaskListFoot
 {
  my ($rows, $cols, $dont_export) = @_;
  my $html;
  $cols ||= $task_list_cols;
  $rows ||= $page_results;
  $task_list_rows++;

  for ( $task_list_rows .. $rows )
   {
    $html .= "<tr".
             " onmouseover=\"setRowBorder(this,'1px $clr{bg_barra} solid');\"".
             " onmouseout=\"setRowBorder(this,'1px $clr{bg_task} solid');\">\n".
             "<td class=\"link\">&nbsp;</td>";
    $html .= "<td class=\"list\">&nbsp;</td>" for 2 .. $cols;
    $html .= "</tr>\n";
   }
 
  ## Export rows
  if (    $request_method eq 'GET'
       && $tema ne 'printable_'
       && $auth_user ne 'guest'
       && !$on{ajax_request}
       && $task_list_cols)
   {
    if ( $on{list2xls} )
     {
      ## Create a new Excel sheet
      undef $prout_page;
      my $xlsname = "${cgi_name}_$tv{day}$tv{month}$tv{year}.xls";
      print STDOUT IG::DocHead( type       => 'application/msexcel',
                                charset    => 'iso-8859-1',
                                expires    => 'now',
                                attachment => $xlsname );

      require IG::SpreadsheetWriteExcel;
      my $filesheet = Spreadsheet::WriteExcel->new( '-' );
         $filesheet->set_tempdir( $IG::temp_dir );
      my $worksheet = $filesheet->add_worksheet('IG Export');
         $worksheet->keep_leading_zeros();
         $worksheet->set_column(0, $#task_list_content, 20);
         $worksheet->write_col('A1', \@task_list_content);
         $worksheet->set_zoom(75);
      my $formatsheet = $filesheet->add_format();
         $formatsheet->set_bold();
         $formatsheet->set_align('center');

      $filesheet->close();
     }
    elsif ( $on{list2csv} )
     {
      my $csvname = "${auth_user}_${cgi_name}_$tv{day}$tv{month}$tv{year}.csv";
      undef $prout_page;
      print STDOUT IG::DocHead( type       => 'text/plain',
                                charset    => 'iso-8859-1',
                                expires    => 'now',
                                attachment => $csvname );

      for ( @task_list_content)
       { print STDOUT (join("\t", @$_), "\n") if $_; }
     }

    ## show link to export data
    $html .= "<tr><td style=\"border-top:2px $clr{bg_link} solid;\" colspan=$cols>".
             ( $task_list_rows && !$dont_export
               ? "<p style=\"font-size:10px; text-align: right\">Export ".
                 ($task_list_rows-1)." rows to ".
                 "<a href=\"$cgi_name?list2xls=true$query_string\">".
                 "XLS <img src=\"$IG::img_url/xls.gif\" align=\"top\"></a> ".
                 "<a href=\"$cgi_name?list2csv=true$query_string\">".
                 "CSV <img src=\"$IG::img_url/cvs.gif\" align=\"top\"></a>".
                 "\n</p>"
               : '' ).
             "</td></tr>";
   }

  $html .= "</table>\n";
  $task_list_cols = 0;
  $task_list_rows = 0;
  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 ShowProtocolInfo()

Show protocol info

=cut

sub ShowProtocolInfo
 {
  my %data = @_;
  my $doc_file = ProtocolToFile( $data{id} );
  my ( $file_type,
       $file_size,
       $file_lasttime,
       $file_lastdate ) = FileStat( $doc_file );

  my $buttons
      = HLayer
        ( bottom_space => 0,
          intra_space  => 3,
          right_layers
           =>[( Img( src   => "$IG::img_url/edit.gif",
                     title => $lang{update_protocol},
                     width => 16,
                     class => 'noprint',
                     href  => "$cgi_name?".
                              "action=protomodi&amp;".
                              "id=$data{id}" ),

                (    $plugin_conf{fckeditor}{webpath}
                  && $client_browser ne 'konqueror'
                  && ( $file_type =~ /html*/i || $doc_file =~ /\.html*$/i )
		  ? Img( title => $lang{edit},
                         width => 16,
                         class => 'noprint',
                         src   => "$IG::img_url/htmleditor.gif",
                         href  => "docmaker?".
                                  "action=edit_html_doc&amp;".
                                  "id=$data{id}" )
		  : Img( title => $lang{edit},
                         class => 'noprint',
                         width => 16,
                         src   => "$IG::img_url/htmleditor_off.gif" ) ),
	
	        (    CheckPrivilege('webmail_new')
	          && ( $file_type ne $lang{unknown} || $data{can_email} )
		  ? Img( title => $lang{send_by_email},
                         width => 16,
                         class => 'noprint',
                         src   => "$IG::img_url/email_go.png",
			 href  => "webmail?".
			          "action=sendigdoc&amp;".
			          "protocol=$data{id}" )
		  : Img( title => $lang{send_by_email},
                         width => 16,
                         class => 'noprint',
                         src   => "$IG::img_url/email_go_off.png") ),

		(    CheckPrivilege('igfax_send')
		  && $file_type =~ /pdf|image\/tiff|postscript/i
		  ? Img( title => $lang{send_by_fax},
                         width => 16,
                         class => 'noprint',
                         src   => "$IG::img_url/mime_mini_fax.png",
			 href  => "igfax?".
			          "action=sendigdoc&amp;".
			          "protocol=$data{id}" )
		  : Img( title => $lang{send_by_fax},
                         width => 16,
                         class => 'noprint',
                         src   => "$IG::img_url/mime_mini_fax_off.png" ) ),
		  
		Img( title => $lang{delete},
                     src   => "$IG::img_url/delete.gif",
                     class => 'noprint',
                     width => 16,
		     href  => "$cgi_name?".
		              "action=delshow&amp;".
		              "id=$data{id}" ),

                ( $file_type =~ /pdf|image\/tiff|html*/i
                  || $doc_file =~ /\.(pdf|html*|tif)$/i
		  ? Img( title => $lang{view_document},
                         width => 16,
                         class => 'noprint',
                         src   => "$IG::img_url/igdocview.png",
                         href  => "docview?".
                                  "action=show_doc&amp;".
                                  "id=$data{id}" )
		  : Img( title => $lang{view_document},
                         width => 16,
                         class => 'noprint',
                         src   => "$IG::img_url/igdocview_off.png" ) ),

                Img( title => $lang{privileges_mng},
                     src   => "$IG::img_url/lock.png",
                     width => 16,
                     class => 'noprint',
                     href  => "javascript:winPopUp(".
                              "'igsuite?".
                              "action=resourcemode&amp;".
                              "id=$data{id}".
                              "',620,550,'resourcemode')" ),

		( CheckPrivilege('sys_log_view')
		  ? Img( title => $lang{system_log},
                         width => 16,
                         class => 'noprint',
                         src   => "$IG::img_url/history.gif",
			 href  => "system_log?".
			          "action=findexec&amp;".
			          "fastfind=1&amp;".
			          "keytofind=$data{id}" )
		  : Img( title => $lang{system_log},
                         width => 16,
                         class => 'noprint',
                         src   => "$IG::img_url/history_off.gif" ) ),

                ( $file_size == 0 || $data{can_zip} eq 'false'
                  ? Img( width => 16,
                         src   => "$IG::img_url/compress_off.gif",
                         class => 'noprint')
                  : $file_type !~ /zip/i
                  
                  ? Img( title => $lang{zip_document},
                         width => 16,
                         class => 'noprint',
                         src   => "$IG::img_url/compress.gif",
                         href  => "igsuite?action=zipdocument&amp;".
                                          "id=$data{id}" )

                  : Img( title => $lang{unzip_document},
                         width => 16,
                         class => 'noprint',
                         href  => "igsuite?action=unzipdocument&amp;".
                                          "id=$data{id}",
                         src   => "$IG::img_url/compress.gif" ) ),

                Img( title => $lang{mark_by_igmsg},
                     width => 16,
                     class => 'noprint',
                     src   => "$IG::img_url/comment_edit.gif",
                     href  => "javascript:winPopUp(".
                              "'isms?".
                              "action=composemessage&amp;".
                              "onsend=close&amp;".
                              "text_msg=$data{id}".
                              "',500,220,'composemessage')" ),
	     )]);

  my $bar = HLayer( bottom_space => 0,
                    right_layers => [( "<div style=\"white-space:nowrap\">".
                                       $data{title}.
                                       "</div>" )],
                    left_layers => [($buttons)],
                    layers => 
                     [( Img( src   => "$IG::img_url/left.gif",
                             class => 'noprint',
                             width => 16,
                             href  => "$cgi_name?".
                                      "action=docview&amp;".
                                      "id=$data{id}&amp;".
                                      "change_id_to=previous"),
                                      
                        "<strong>" . DirectLink($data{id}) . "</strong>",
                        
                        Img( src   => "$IG::img_url/right.gif",
                             class => 'noprint',
                             width => 16,
                             href  => "$cgi_name?".
                                      "action=docview&amp;".
                                      "id=$data{id}&amp;".
                                      "change_id_to=next") )]);

  my $html = MkRepository( id=>$data{id} ).
             ShowData( toolbar => $bar,
                       menubar => $cgi_name eq 'binders'
                               ?  '&nbsp;'
                               :  "$lang{type}: $file_type - ".
                                  "$lang{size}: ".MkByte($file_size)." - ".
                                  "$lang{last_change}: ".
                                  "$file_lastdate $file_lasttime",
                       fields  => $data{fields} );

  defined wantarray ? return $html : PrOut $html;   
 }

##############################################################################
##############################################################################

=head3 ShowData()

Show data

=cut

sub ShowData
 {
  my %data = @_;
  $data{cols} ||= 2;
  my $table_cols = $data{cols} * 2;
  
  my $html  = "<table style=\"width:100%\" cellspacing=1>\n";
     $html .= "<tr><td style=\"background-color:transparent;".
              "height:22px;".
              "\" colspan=$table_cols>$data{toolbar}</td>".
              "</tr>" if $data{toolbar};
     $html .= "<tr><td class=\"menu\"".
              " colspan=$table_cols".
              " style=\"font-size:10px; text-align:right;\">".
              ( $on{print} ? '&nbsp;' : $data{menubar}).
              "</td>\n</tr><tr>\n";

  my $fields_num = @{$data{fields}};
  my $col_cnt = 1;

  for my $idx ( 0 .. $fields_num-1 )
   {
    $html .= "<td width=\"18%\" class=\"lbl\">".
             $data{fields}[$idx][0].
             "&nbsp;</td>\n".
             "<td class=\"list\" style=\"border-bottom:1px solid $clr{border_low}; padding:3px\"";
  
    $html .= " colspan=" . ($table_cols-$col_cnt)
             if !$data{fields}[$idx+1][0] && $table_cols > ($col_cnt*2);
                   
    $html .= ">$data{fields}[$idx][1]&nbsp;</td>\n";
                       
    if ( $data{cols} == $col_cnt++ || ! $data{fields}[$idx+1][0] )
     {
      $html   .= "</tr><tr>\n";
      $col_cnt = 1;
     }
   }
                   
  $html .= "<td colspan=$table_cols".
           " style=\"line-height:2px;".
           "height:2px;".
           "border-top:2px solid $clr{bg_link}\">&nbsp;</td>\n".
           "</table>\n";

  defined wantarray ? return $html : PrOut $html;   
 }
 
##############################################################################
##############################################################################

=head3 SearchProtocolId()

Find next or previous protocol ID of a document

=cut

sub SearchProtocolId
 {
  my %data = @_;
  my $doc_table = ( ProtocolToDocType( $data{id} ) )[2];

  my $id_name   = $doc_table eq 'email_msgs' ? 'pid' : 'id';
  my $pyear     = substr( $data{id}, -2, 2 );

  my $cid = DbQuery( query => $data{direction} eq 'previous'
                           ?  "select $id_name from $doc_table ".
                              "where substr(id,8,2)='$pyear'".
                              " and $id_name<'$data{id}' ".
                              "order by $id_name desc limit 1"

                           :  "select $id_name from $doc_table ".
                              "where substr(id,8,2)='$pyear'".
                              " and $id_name>'$data{id}' ".
                              "order by $id_name asc limit 1",
                     type  => 'UNNESTED' );
             
  return FetchRow($cid) || $data{id};
 }

##############################################################################
##############################################################################

=head3 MkProtocolList(%data)

Generate much values needed to build a view of a protocol list

=cut

sub MkProtocolList
 {
  my %data = @_;
  my $query;

  ## set default values
  $data{table}         ||= $cgi_name;
  $data{search_field}  ||= 'contactname';
  $data{order}         ||= $on{order} ||= 'id';
  $data{sortdirection} ||= $on{sortdirection} || $list_order;
  $data{alphabet}      ||= $on{alphabet}      || 'all';
  $data{view}          ||= $on{view}
                       ||  ConfigParam("$data{table}.default_view")
                       || 'complete_list';
  $on{view}              = $data{view};

  ## define a query relative to selected view
  if ($data{view} eq 'complete_list' || $data{view} eq 'empty_selection')
   {
    $query = "$data{table}.issue>='$tv{start_year}' and ".
	     "$data{table}.issue<='$tv{end_year}'";
   }
  elsif ($data{view} eq 'all')
   {
    $query = '1=1';
   }
  elsif ($data{view} eq 'limited_list')
   {
    $query = "$data{table}.issue>='$tv{start_year}' and ".
	     "$data{table}.issue<='$tv{end_year}' and ".
	     "$data{table}.owner='$auth_user'";
   }
  else
   {
    ## load a selected personal report
    my $cid = DbQuery( query => "select dbquery, orderby from reports ".
                                "where id='$data{view}'".
                                " and type='$data{table}' limit 1",
                       type  => 'UNNESTED' );
    my ($qry, $ord) = FetchRow($cid);
    $query = $qry;
    $data{order} ||= $ord;
   }

  croak("What happen, no query defined.\n") if !$query;

  ## eventually limit query to an "alphabet" letter
  if ($data{alphabet} ne 'all')
   {
    $query = "(substr($data{table}.$data{search_field},1,1)='$data{alphabet}') ".
	     "and ($query)";
   }

  ## create alphabet index with personal reports list
  my (@personal_reports, @reports_rows);
  my $cid = DbQuery( query => "select id, name from reports ".
                              "where owner='$auth_user'".
                              " and type='$data{table}' ".
                              "order by name",
                     type  => 'UNNESTED' );
  push @personal_reports, [@reports_rows] while @reports_rows = FetchRow($cid);

  ## set a view per page
  my $base_query = "SELECT COUNT(*) FROM $data{table} where $query";
  my $base_url   = "$data{table}?".
			"alphabet=$data{alphabet}&amp;".
			"view=$data{view}&amp;".
			"sortdirection=$data{sortdirection}&amp;".
			"order=$data{order}";
  my ( $limit,
       $offset,
       $page_selector ) = MkTaskPaging($base_query, $base_url);

  my $alphabet_selector = IG::AlphabetSelector
    (	param   => 'alphabet',
        default => $data{alphabet},
	link    => "$data{table}?".
		   "view=$data{view}&amp;".
		   "order=$data{order}&amp;".
		   "sortdirection=$data{sortdirection}",
	filter  => Input ( name=>'view',
			   type=>'select',
			   style=>'width: 230px',
			   onchange=>"location.href = '$data{table}?alphabet=$data{alphabet}&amp;view=' + this.options[this.selectedIndex].value;",
			   data=>[([ 'complete_list',
				     ($lang{"$data{table}_protocol"} ||
				      $lang{$data{table}})." $tv{session_year}"],
				   [ 'limited_list',
				     $lang{my_protocols}." $tv{session_year}"],
                                   [ 'all',
                                     $lang{all}],
				   [ 'empty_selection',
				     '-'x50],
				   @personal_reports
				 )] )
   );

  ## add an order to the query
  $query .= " order by $data{table}.$data{order} $data{sortdirection}";

  ## add a limit and offset
  $query .= " limit $limit offset $offset";

  return ($query, $alphabet_selector, $page_selector)
 }

##############################################################################
##############################################################################

=head3 MkTaskPaging($how_many_pages,$base_url)

Split "data list" returned by a query in more pages, and draw a widget to
navigate across pages.

=cut

sub MkTaskPaging
 {
  my ($item_cnt, $base_url, $max_items) = @_;
  my ($page_cnt, $limit, $offset, $html, $cookie_name, %ch);

  ## How many item per page to show
  $max_items ||= $page_results;

  if ($item_cnt =~ /^select count/i)
   {
    my $cid = DbQuery( query => $item_cnt, type => 'UNNESTED' );
    $item_cnt = FetchRow($cid);
   }

  $page_cnt = int( $item_cnt / $max_items );
  $page_cnt++ if ( $item_cnt / $max_items ) > $page_cnt;

  ## According to records number set pages position in a cookies
  $cookie_name = $cgi_name . $on{action};

  if ($cookie{$cookie_name} && !$on{pos})
   { $on{pos} = $cookie{$cookie_name} }
  elsif ($on{pos} eq 'last' || (!$on{pos} && $list_order eq 'asc'))
   { $on{pos} = $page_cnt }
  elsif ( ($on{pos}<1 && $on{pos} ne 'all') || $on{pos}>$page_cnt)
   { $on{pos} = 1 }

  $on{pos} = 1 if $on{pos} > $page_cnt;
  $set_cookie{$cookie_name} = $on{pos};

  if ($tema ne 'printable_')
   {
    $ch{$on{pos}} = 'selected';

    ## Left arrow
    my $previous = ($on{pos}==1 || $on{pos} eq 'all')
	         ? $page_cnt 
	         : $on{pos}-1;
    $html =  "<table cellspacing=0 cellpadding=0><tr><td>".
	     Img( src  => "$IG::img_url/${tema}left.gif",
		  href => "$base_url&amp;pos=$previous",
		  width => $tema ne 'microview_' ? 20 : 16,
		  title=> $lang{previous_page} ).
	     "</td>\n";
 
    ## Select
    $html .= "<td>\n".
             '<select'.
             '  name="pagevalue"
		class="formselect"
		style="height:17px; font-size:10px; width:auto;"
		onChange="document.location = \''.
		         JsQuote("$base_url&amp;pos=").
		         "' + this.options[this.selectedIndex].value\">\n";
    for (1 .. $page_cnt)
     { $html .= "<option value=\"$_\" $ch{$_}>$_/$page_cnt</option>\n"; }

    ## All options
    $html .= "<option value=\"all\" $ch{all}>all</option>\n";
    $html .= "</select></td>\n";

    ## Rigth arrow
    my $next = ( $on{pos}==$page_cnt || $on{pos} eq 'all')
	     ? 1
	     : $on{pos}+1;

    $html .= "	<td>".
	     Img( href => "$base_url&amp;pos=$next",
		  width => $tema ne 'microview_' ? 20 : 16,
		  src  => "$IG::img_url/${tema}right.gif",
		  title=> $lang{next_page}).
	     "</td></tr></table>\n";
   }

  ## Calculate the first and the last record to show according to pages split
  if ($on{pos} eq 'all')
   {
    $offset = 0;
    $limit  = $item_cnt;
   }
  else
   {
    $offset = ($on{pos} * $max_items) - $max_items;
    $limit  = $max_items;
   }

  ## Check external plugins
  $html = CkExtPlugins( 'MkTaskPage',
                        \$html,
                        { item_cnt  => $item_cnt,
                          base_url  => $base_url,
                          max_items => $max_items } ) if %plugins;

  return ( $limit, $offset, $html );
 }

##############################################################################
##############################################################################

=head3 MkButton()

Build a button.

=cut

sub MkButton
 {
  my %data = @_;
  my $cssclass = $tema eq 'microview_' ? '' : ' class="button"';
  my $width    = $tema eq 'microview_' ? 5  : 13;

  return if    ( exists $data{privilege} && !$data{privilege} )
            || $tema eq 'printable_'
            || ( !$data{text} && !$data{icon_src} && !$data{icon} );

  $data{link}       ||= '#';
  $data{icon_width} ||= 20 if ! $data{icon_src} && $tema ne 'microview_';
  $data{icon_width}   = 16 if $data{icon_width} > 16 && $tema eq 'microview_';
  $data{icon_src}   ||= "$IG::img_url/${tema}palla.gif";
  $data{icon}       ||= Img( href    => $data{link},
                             target  => $data{target},
	                     title   => $data{quick_help} || $data{text} || 'icon',
	                     onclick => $data{onclick},
	                     width   => $data{icon_width},
	  	             src     => $data{icon_src} );
  $data{onclick}    &&= " onclick=\"$data{onclick}\"";
  $data{target}     &&= " target=\"$data{target}\"";

  my $html = "<table cellspacing=0 cellpadding=0><tr>";

  $html   .= "<td$cssclass>$data{icon}</td>\n";
	   
  $html   .= "<td$cssclass>".
             "<a href=\"$data{link}\"$data{onclick}$data{target}>$data{text}</a></td>".
             "<td width=$width></td>" if $data{text};

  $html   .= "</tr></table>\n";

  ## Check external plugins
  $html = CkExtPlugins( 'MkButton', \$html, undef) if %plugins;

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 GetTableVal()

Gets values of basic tables

=cut

{
 ## MEMOIZATION
 my %stored_tables;
 
 sub GetTableVal
  {
   my ($table, $value) = @_;

   ## prevent old memoized values. Needed by mod_perl
   undef %stored_tables if !$executed{gettableval}++;

   my @ris;
   if ($value && !$stored_tables{$table}[$value])
    {
     my $cid = DbQuery( query => 'select id, tablevalue, tablename '.
                                 'from basic_tables',
                        type  => 'UNNESTED' );

     $stored_tables{$ris[2]}[$ris[0]] = $ris[1] while @ris = FetchRow($cid);
    }

   return ($stored_tables{$table}[$value]);
  }
} 

##############################################################################
##############################################################################

=head2 Data Forms procedure

=cut

##############################################################################
##############################################################################

=head3 MkCgiEnv()

Make a parsing of a data form and returns %on (whit not quoted values) used to
show data to html response. Also get cookies and store them in %cookie.
Also get hidden values stored in database table 'sessions_cache'.

=cut

sub MkCgiEnv
 { 
  ## When IG run in standalone mode we have already a CGI object
  ## XXX2IMPROVE 
  if ( !$HTTP::Server::Simple::VERSION )
   {
    $CGI::Simple::UPLOAD_HOOK
    = sub {
           ## retrieve session cookie
           if ( !%IG::cookie )
            {
             require IG::CGISimpleCookie;
             %IG::cookie = CGI::Simple::Cookie::raw_fetch();
             $IG::cookie{igsuiteid} =~ s/\.\.|\|//g; ## reclaim value
            }
           return if !$IG::cookie{igsuiteid};
           my ($file_name, $total_size, $current_size) = @_;
           my $hookfile = $IG::temp_dir . $IG::S . $IG::cookie{igsuiteid};
           open(FH, '>', $hookfile)
             or die("Can't write to '$hookfile'\n");
           print FH "$file_name\n$total_size\n$current_size\n";
           close(FH);
          };

    $CGI::Simple::DISABLE_UPLOADS = 0;
    $CGI::Simple::POST_MAX = 1024 * 50000; ## max 50mb posts
    $cgi_ref = new CGI::Simple ;
   }

  ## Form request method
  $request_method = $ENV{'REQUEST_METHOD'};

  ## Adjust webpath
  $webpath &&= "/$webpath" if $webpath !~ /^\//;

  ## check running mode ( if there are command line argument
  ## we hare on a comman line mode )
  if ( !$request_method || @ARGV )
   {
    ## running on commandline
    $remote_host    = 'localhost';
    $auth_user      = $login_admin;
    $request_method = 'commandline';
    return;
   }

  ## Set Cgi url
  $cgi_url = ( $ENV{HTTPS} ? "https://" : "http://" ).
	     $server_name.
	     ( $ENV{SERVER_PORT} && $ENV{SERVER_PORT} ne '80'
	       ? ":$ENV{SERVER_PORT}"
	       : '').
	     ($cgi_path ? "/$cgi_path" : '');

  ## Read param
  for ( $cgi_ref->param() )
   {
    my $ref;
    @$ref = ($cgi_ref->param($_));
    $on{$_} = !@$ref[1]
	    ? $cgi_ref->param($_)
	    : $ref;
   }

  ## XID (Used by Direct email messages)
  if ( $on{xid} )
   {
    ## it means that the receiver has viewed the message
    require IG::WebMail;
    IG::WebMail::UpdateEmailMsgStatus( status     => 'v',
                                       message_id => $on{xid} );
   }

  ## Cookies
  $cookie{$_} = $cgi_ref->cookie($_) for ($cgi_ref->cookie());

  ## Set a session cookie by a parameter
  if ($on{igsuiteid})
   {
    $set_cookie{igsuiteid} = $cookie{igsuiteid} = $on{igsuiteid};
   }

  ## Retrieve hidden values from sessions_cache
  if ( $on{formid} )
   { 
    my $valid_form_id;
    my $cid = DbQuery( query => "select keyname, keyvalue ".
                                "from sessions_cache ".
                                "where formid='". DbQuote($on{formid}) ."'",
                       type  => 'UNNESTED' );

    while ( my @row = FetchRow($cid) )
     {
      $valid_form_id++;
      if ( $row[0] =~ s/^\:(.+)/$1/ )
       {
        ## persistent fields
        $on{$row[0]} ||= $row[1];
       }
      else
       {
        ## hidden fields
        $on{$row[0]} = $row[1];
       }
     } 

    die("Sorry, this request is not autorized!\n",
        "Your session is expired or you have clicked 'back' on your ".
        "browser. Please try again.\n" ) if !$valid_form_id;
   }

  ## Default action
  $on{action} ||= 'default_action';

  ## Set a revisited Query String
  if ($ENV{QUERY_STRING})
   {
    foreach (keys %on)
     {
      next if /attach|formid|list2xls|print/;
      $query_string .= "\&amp;$_=" . MkUrl($on{$_});
     }
   }
 }

##############################################################################
##############################################################################

=head3 FormHead()

With FormHead(), Input() and FormFoot() you can create complex data forms.

=cut

sub FormHead
 {
  my %data = @_;
  my $html;

  undef %form;
  $form{autofocus}  = $data{autofocus} ||= 'true';
  $data{ckchanges}  = 'false' if $data{status} eq 'r';
  $form{ckchanges}  = $data{ckchanges} ||= 'false'; 
  $form{ischanged}  = $data{ischanged} ||= 'false';
  $form{action}     = $data{formaction}||= "$cgi_url/$cgi_name";
  $form{method}     = $data{method}    ||= 'post';
  $form{name}       = $data{name}      ||= 'proto'.$page_tabindex++;
  $form{float}      = $data{float}     ||= 'none';
  $form{mode}       = $data{mode}      ||= 'session';
  $form{labelstyle} = $data{labelstyle};
  $form{fieldstyle} = $data{fieldstyle};
  $form{enctype}    = $data{enctype};

  if ($data{onsubmitask})
   {
    $data{onsubmit} .= ($data{onsubmit} ? '; ' : '').
			JsConfirm( $data{onsubmitask} );
   }

  $data{target}    &&= " target=\"$data{target}\"";
  $data{onsubmit}  &&= " onSubmit=\"$data{onsubmit}\"";
  $data{enctype}   &&= " enctype=\"$data{enctype}\"";

  if ($form{action} eq 'none') 
   {
    $html = "<form name=\"$data{name}\">";
   }
  elsif ($tema eq 'printable_' || $data{status} eq 'r')
   {
    $form{status} = 'r';
   }
  else
   {
    $form{status} = $data{status} ||= 'rw';
    $html  = "\n<!-- START FORMHEAD -->\n";
    $html .= "<form name=\"$data{name}\" $data{onsubmit} action=\"$data{formaction}\" method=\"$data{method}\" $data{enctype}$data{target}>\n";
    $html .= "<input type=\"hidden\" name=\"changedfields\" value=\"$on{changedfields}\">\n" if $form{ckchanges} eq "true";

    if ( $form{mode} eq 'session' )
     {
      ## Make a form id to retrieve hidden values from sessions_cache 
      $form{id} = DbQuote( $on{$form{name}} || MkId() );
      $on{$form{name}} ||= $form{id};
      $html .= "<input type=\"hidden\" name=\"formid\" value=\"$form{id}\">\n";

      DbQuery(query=>[("delete from sessions_cache where formid='$form{id}'",

                       "insert into sessions_cache values".
                       " ('$cookie{igsuiteid}', '$form{id}', 'action',".
                       " '$data{cgiaction}', '$tv{today}')",

                       "insert into sessions_cache values".
                       " ('$cookie{igsuiteid}', '$form{id}', '$form{name}',".
                       " '$form{id}', '$tv{today}')",
                       
                       ( $on{backtoreferer}
                         ? "insert into sessions_cache values".
                           " ('$cookie{igsuiteid}', '$form{id}', 'backtoreferer',".
                           " '". ( $on{backtoreferer} == 1
                                   ? $ENV{HTTP_REFERER}
                                   : $on{backtoreferer} ). "', '$tv{today}')"
                         : '')
                      )],
              type => 'UNNESTED' );
     }
    else
     {
      $html .= "<input type=\"hidden\" name=\"action\" value=\"$data{cgiaction}\">\n";
     }
   }

  ## Check external plugins
  $html = CkExtPlugins( 'FormHead', \$html, \%data ) if %plugins;

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 Input()

With FormHead(), Input() and FormFoot() you can create complex data forms.

=cut

sub Input
 {
  no strict 'refs';
  my %data = @_;
  my ($field, $escapedvalue, $unescapedvalue, %select, $description, $html);

  $page_tabindex++;
  $form{name}      ||= 'proto';
  $data{type}      ||= 'text';
  $data{show}      ||= $data{label}; ## for compatibility
  $data{name}      ||= "$data{type}$page_tabindex";
  $data{id}        ||= $data{name};

  ## Autofocus request
  $form{focusthis} ||= "document.$form{name}.$data{name}" if $data{focus};

  ## Overrite params with %attr values
  for ( keys %{$attr{$data{name}}} )
   {
    next if ! /^(readonly|value|show|blushed)$/;
    $data{$_} = $attr{$data{name}}{$_} if $attr{$data{name}}{$_};
   }
  
  my $_is_readonly = $data{readonly} =~ /^(1|true)$/ || $form{status} eq 'r'
                   ? 1
                   : 0;

  ## Parse autocompletion params
  if ($data{autocompletion} && !$on{print})
   { 
    my $id = $data{autocompletion}{id} || $data{id};
    for ( qw( script_url script_action search_param min_chars tokens ) )
     { $form{autocompletion}{$id}{$_} = $data{autocompletion}{$_}; }
   }

  ## TYPE:FINDABLE First check for findable field because we have fixed values
  if ($data{type} eq 'findable')
   {
    my %item;
    $data{value} = $cgi_name;

    my %findable = ( 
                     system_log   => 'sys_log_view',
                     archive      => 'archive_view',
                     binders      => 'binders_view',
                     calendar     => '',
                     equipments   => 'equipments_view',
                     contacts     => 'contacts_view',
                     contracts    => 'contracts_view',
                     fax_received => 'fax_received_view',
                     fax_sent     => 'fax_sent_view',
                     letters      => 'letters_view',
                     nc_ext       => 'nc_ext_view',
                     nc_int       => 'nc_int_view',
                     opportunities=> 'opportunities_view',
                     orders       => 'orders_view',
                     offers       => 'offers_view',
                     igwiki       => 'igwiki_view',
                     postit       => 'postit_view',
                     products     => 'products_view',
                     services     => 'services_view',
                     tickler      => 'sys_tickler_view',
                     todo         => 'todo_view',
                     webmail      => 'webmail_view',
                     wikipedia    => '',
                     google       => '',
		     						 documentation    => 'documentation_view',
                   );
    foreach (keys %findable)
     { $item{$_} = $lang{$_} ||= ucfirst($_)  if CheckPrivilege($findable{$_}); }

    $data{data} = \%item;
    $data{type} = 'select'; 
    $data{show} ||= "<a style=\"font-size:11px; color:$clr{font_menu_title}; background-color:$clr{bg_menu_title}\"".
                    " href=\"javascript:window.location.reload();\">".
                    "$lang{find}</a>";
    $data{containerstyle} = 'width:auto; white-space:nowrap;';
    $data{onchange} ="location.href = this.options[this.selectedIndex].value + '?action=findshow'";
   }
  ## TYPE:QUICKCREATOR ##
  elsif ($data{type} eq 'quickcreator')
   {
    my %item;
    for ( qw(	archive		equipments	contacts	contracts
		fax		letters		nc_ext		e-mail
		nc_int		opportunities	orders		offers
		postit		services	todo		users
		sms		igmsg           binders         event
	    ) )
     {
      my $value = "$_?action=proto&amp;contactid=$on{contactid}";
      my $label = $lang{$_} || ucfirst($_);
      if ($_ eq 'contacts')
       {
	next if !CheckPrivilege('contacts_new');
        $value = "contacts?action=proto";
       }
      elsif ( $_ eq 'e-mail')
       {
	next if !CheckPrivilege('webmail_new');
        $value = "javascript:winPopUp('".
                         'webmail?'.
                         'action=composemessage&amp;'.
                         'onsend=close&amp;'.
                         "to=". MkUrl($on{email}).
			"',700,600,'sendemail')";
       }
      elsif ( $_ eq 'fax')
       {
	next if !CheckPrivilege('igfax_send');
        $value = "igfax?action=sendfax&amp;contactid=$on{contactid}";
       }
      elsif ( $_ eq 'todo')
       {
	next if !CheckPrivilege('todo_view');
        $value = "todo?action=protomaster&amp;contactid=$on{contactid}";
       }
      elsif ( $_ eq 'sms')
       {
	next if !CheckPrivilege('sys_sms_send');
        $value = "javascript:winPopUp('".
			'igsms?'.
			'action=composemessage&amp;'.
			"',370,250,'composesms')";
       }
      elsif ( $_ eq 'event')
       {
	next if !CheckPrivilege();
        $value = "javascript:winPopUp('".
			'calendar?'.
			'action=proto&amp;'.
			"contactid=$on{contactid}&amp;".
			'onaction=close'.
			"',700,500,'composeevent')";
       }
      elsif ( $_ eq 'igmsg')
       {
        $value = "javascript:winPopUp('".
			'isms?'.
			'action=composemessage&amp;'.
			'onsend=close'.
			"',500,220,'composeigmsg')";
       }
      elsif (!CheckPrivilege($_.'_edit'))
       {
        next;
       }
      $item{$value} = $label;
     }

    $data{data}      = \%item;
    $data{zerovalue} = 'true';
    $data{type}      = 'select'; 
    $data{onchange}  ="location.href = this.options[this.selectedIndex].value; this.value='';";
   }

  ## convert: hash reference, database query or a monodimension array
  ## to a bidimension array used in select field as items
  if ( $data{data} )
   {
    if ( $data{data} =~ /^select.+from/i )
     {
      my $cnt;
      my $cid = DbQuery( query => $data{data}, type => 'UNNESTED' );
      while ( my @row = FetchRow($cid) )
       {
        next if !$row[0];
        $data{data}[$cnt][0] = shift(@row);
        $data{data}[$cnt][1] = $row[0] ? join(' ',@row)
				       : $data{data}[$cnt][0];
        $cnt++;
       } 

      $data{quickhelp} = "Ask to your administrator why this select field ".
                         "is empty! Can you create $data{show} record?"
                       if !$cnt;
     }
    elsif (ref($data{data}) eq 'HASH')
     {
      my $cnt = 0;
      my %dat = %{$data{data}};
      undef $data{data};
      if ($data{order} eq 'byvalue')
       {
        foreach (sort keys %dat)
         {
          $data{data}[$cnt][0]   = $_;
          $data{data}[$cnt++][1] = $dat{$_};
         }
       }
      else
       {
        foreach (sort { $dat{$a} cmp $dat{$b} } keys %dat)
         {
          $data{data}[$cnt][0]   = $_;
          $data{data}[$cnt++][1] = $dat{$_};
         }
       }
     }
    elsif (ref($data{data}) eq 'CODE')
     {
      $data{data} = &{$data{data}};
     }
    elsif (ref($data{data}) eq 'ARRAY')
     {
      for my $i (0 .. $#{$data{data}})
       {
        if( ref($data{data}[$i]) ne 'ARRAY' )
         {
          ## it's a mono-dimensional array
          $data{data}[$i] = [$data{data}[$i], $data{data}[$i]];
         }
       }
     }
   }

  if (	!$on{$data{name}} ||
	 $data{override}  ||
	 $data{type} eq 'checkbox'
     )
   {
    $escapedvalue   = MkEntities( $data{value} );
    $unescapedvalue = $data{value};
   } 
  else
   {
    $escapedvalue   = MkEntities( $on{$data{name}} );
    $unescapedvalue = $on{$data{name}};
   }

  $data{id}	     &&= " id=\"$data{id}\"";
  $data{style}       &&= " style=\"$data{style}\"";
  $data{onchange}    &&= " onChange=\"$data{onchange}\"";
  $data{onfocus}     &&= " onFocus=\"$data{onfocus}\"";
  $data{onblur}      &&= " onBlur=\"$data{onblur}\"";
  $data{onclick}     &&= " onClick=\"$data{onclick}\"";
  $data{onselect}    &&= " onSelect=\"$data{onselect}\"";
  $data{onmouseover} &&= " onMouseOver=\"$data{onmouseover}\"";
  $data{onmouseout}  &&= " onMouseOut=\"$data{onmouseout}\"";
  $data{onkeypress}  &&= " onKeyPress=\"$data{onkeypress}\"";
  $data{onkeyup}     &&= " onKeyUp=\"$data{onkeyup}\"";
  $data{title}       &&= " title=\"$data{title}\"";
  $data{accesskey}   &&= " accesskey=\"$data{accesskey}\"";
  $data{labelstyle}  ||= $form{labelstyle};
  $data{fieldstyle}  ||= $form{fieldstyle};
  $data{float}       ||= $form{float};

  ## Puts all field attributes in a unique scalar
  $description = " tabindex=\"$page_tabindex\"".
		 $data{id}.
		 $data{onfocus}.
		 $data{onkeypress}.
		 $data{onkeyup}.
		 $data{onchange}.
		 $data{onblur}.
		 $data{onclick}.
		 $data{onselect}.
		 $data{onmouseover}.
		 $data{onmouseout}.
		 $data{style}.
                 $data{title}.
                 $data{accesskey};

  ## TYPE:MULTISELECT ##
  if ($data{type} eq 'multiselect')
   {
    $data{style} =~ s/style\=\"(.+)\"/$1/;
    my $style = $1;
       $style .= "; width:180px" 		if $style !~ /width/;
       $style .= "; height:100px;"		if $style !~ /height/;
       $style .= "; background:#f4f4f4"		if $style !~ /background/;
    my @dat1; 
    my @dat2;
    my %dat2;

    ## add "all" value to results
    push @{$data{data}}, ['all',$lang{all}] if $data{allvalue};

    for (0..$#{$data{data}})
     { 
      if ($unescapedvalue =~ /$data{data}[$_][0]/)
       { $dat2{$data{data}[$_][0]} = $data{data}[$_][1]; }
      else
       { push @dat1, [ $data{data}[$_][0], $data{data}[$_][1] ]; }
     }

    for (split /\n/, $unescapedvalue)
     {
      s/\r|\n//g;
      push @dat2, [$_, $dat2{$_}];
     }

    $field = "<input type=\"hidden\" value=\"$escapedvalue\" name=\"$data{name}\">\n";
    $field .= '<table cellpadding=2 cellspacing=0 border=0>';

    $field .= "<tr>".
	      "<td class=\"list\">$data{label1}</td><td></td>".
	      "<td class=\"list\">$data{label2}</td><td></td>".
	      "</tr>" if $data{label1} || $data{label2};

    $field .= '<tr><td>'.
		Input (	type=>'select',
			multiple=>'true',
			name=>"$data{name}1",
			fieldstyle=>"margin: 0px; padding: 0px; $data{fieldstyle}",
			style=>$style,
			data=>\@dat1 );

    $field .= '</td><td class="link" valign="top">'.

		Input (	type=>"button",
			value=>"&gt;&gt;",
			fieldstyle=>'margin: 0px; padding: 0px',
			style=>"width: 30px;",
			onclick=>"moveTo('$form{name}','$data{name}',2,1);").

		Input (	type=>"button",
			value=>"&lt;&lt;",
			style=>"width: 30px;",
			fieldstyle=>'margin: 0px; padding: 0px',
			onclick=>"moveTo('$form{name}','$data{name}',1,2);");

    $field .= '</td><td>'.

		Input (	type=>'select',
			size=>5,
			fieldstyle=>"margin: 0px; padding: 0px; $data{fieldstyle}",
			name=>"$data{name}2",
			style=>$style,
			data=>\@dat2 );

    $field .= '</td><td class="link" valign="top">'.

		Input (	type=>"button",
			value=>"Up",
			fieldstyle=>'margin: 0px; padding: 0px',
			style=>"width: 40px;",
			onclick=>"moveUp('$form{name}','$data{name}',2);").

		Input (	type=>"button",
			value=>"Down",
			fieldstyle=>'margin: 0px; padding: 0px',
			style=>"width: 40px;",
			onclick=>"moveDown('$form{name}','$data{name}',2);");

    $field .= '</td></tr></table>';
    $data{fieldstyle} = $data{style} = '';
   }
  ## TYPE:COMBO ##
  elsif ($data{type} eq 'combo')
   {
    $data{style} =~ s/style\=\"(.+)\"/$1/;
    $data{view_mode} ||= '0'; ## what first select or text field?

    $field = "<input type=\"hidden\" value=\"$escapedvalue\" name=\"$data{name}\">\n";
 
    $field.= "<table cellspacing=0 cellpadding=0>".
             "<tr><td height=23 valign=\"top\">\n";

    $field.= "<div id=\"$data{name}_div0\"
                  style=\"z-index: 100; overflow: visible; visibility: visible; padding: 0px;\">
              <table cellspacing=0 cellpadding=0>
               <tr><td>
                <img align=\"top\"
                     height=20
                     alt=\"view list\"
                     src=\"$IG::img_url/viewlist.gif\"
                     onclick=\"goOver(1,'$data{name}_div')\">
                </td><td>".
             Input( type      => 'text',
                    name      => "$data{name}0",
                    fieldstyle=> "$data{fieldstyle};margin:0;padding:0",
                    style     => $data{style},
                    value     => $unescapedvalue,
                    override  => 1,
                    onchange  => "$form{name}.$data{name}.value=this.value",
                    onblur    => "$form{name}.$data{name}.value=this.value",
                    size      => $data{size} ).
             "</td></tr></table></div>\n";

    $field.= "<div id=\"$data{name}_div1\"
                     style=\"z-index:100; overflow:visible; visibility:hidden; padding:0px;\">
              <table cellspacing=0 cellpadding=0>
               <tr><td>
                <img align=\"top\"
                     alt=\"Back to list\"
                     height=20
                     src=\"$IG::img_url/backlist.gif\"
                     onclick=\"goOver(0,'$data{name}_div')\">
                </td><td>".
             Input( type      => 'select',
                    onchange  => "$form{name}.$data{name}.value=this.value;".
                                 "$form{name}.$data{name}0.value=this.value;".
                                 "goOver(0,'$data{name}_div')",
                    zerovalue => 'true',
                    fieldstyle=> "$data{fieldstyle};margin:0;padding:0",
                    style     => $data{style},
                    name      => "$data{name}1",
                    override  => 1,
                    value     => $unescapedvalue,
                    data      => $data{data} ).
             "</td></tr></table></div>";

    $field .= "</td></tr></table>";
    $field .= JsExec( code => "goOver($data{view_mode},'$data{name}_div');" );
   }
  ## TYPE:LOGINS ##
  elsif ($data{type} eq 'logins')
   {
    $data{size}     &&= " size=\"$data{size}\"";
    $unescapedvalue ||= $auth_user;
    $escapedvalue   ||= $auth_user;
    $select{$data{name}}{$unescapedvalue} = 'selected';

    ## we have to show an eventually selected but disabled user 
    my $disabled_user = UsrInf('status',$unescapedvalue) == 2 
                      ? $unescapedvalue
                      : '';

    $field = "<select name=\"$data{name}\" class=\"formselect\" $data{size}$description>\n";

    $field .= "\t<option value=\"\" $select{$data{name}}{0}>".
	      ( $_is_readonly ? $lang{unselected} : "$lang{select}...") .
	      "</option>\n" if $data{zerovalue} =~ /^(true|1)$/;

    $field .= "\t<option value=\"all\" $select{$data{name}}{all}>".
	      $lang{all}.
	      "</option>\n" if $data{allvalue} =~ /^(true|1)$/;

    $field .= "\t<option value=\"guest\" $select{$data{name}}{guest}>".
	      IG::UsrInf('name','guest').
	      "</option>\n" if $data{guestvalue} =~ /^(true|1)$/;

    foreach ( sort { IG::UsrInf('name',$a) cmp IG::UsrInf('name',$b) }
              keys %{UsrInf()}
            )
     {
      next if    ( UsrInf('status',$_) == 2 && $_ ne $disabled_user )
              || !IG::UsrInf('name',$_)
              || ( $_is_readonly && $select{$data{name}}{$_} ne 'selected' )
              || $_ eq 'guest';

      $field .= "\t<option value=\"$_\" $select{$data{name}}{$_}>".
		IG::UsrInf( 'name', $_ ).
		"</option>\n";

      $escapedvalue = MkEntities( IG::UsrInf( 'name', $_ ) )
                      if $select{$data{name}}{$_} eq 'selected';
     }
    $field .= "</select>\n";
   }
  ## TYPE:GROUPSELECTOR ##
  elsif ($data{type} eq 'groupselector')
   {
    $unescapedvalue ||= $auth_user;
    $escapedvalue   ||= $auth_user;
    $select{$data{name}}{$unescapedvalue} = 'selected';

    ## we have to show an eventually but active disabled user 
    my $disabled_user = UsrInf('status',$unescapedvalue) == 2 
                      ? $unescapedvalue
                      : '';

    $field = "<select name=\"$data{name}\" class=\"formselect\" $description>\n";

    $field .= "\t<option value=\"\" $select{$data{name}}{0}>".
	      ($_is_readonly ? $lang{unselected} : "$lang{select}...") .
	      "</option>\n" if $data{zerovalue} =~ /^(true|1)$/;

    $field .= "\t<option value=\"all\" $select{$data{name}}{all}>".
	      $lang{all}.
	      "</option>\n" if $data{allvalue} =~ /^(true|1)$/;

    $field .= "\t<option value=\"guest\" $select{$data{name}}{guest}>".
	      IG::UsrInf('name','guest').
	      "</option>\n" if $data{guestvalue} =~ /^(true|1)$/;

    my $cid = DbQuery( query => $data{groupid} && $data{groupid} ne 'all'
                             ?  "SELECT users_groups_link.userid,".
                                " users.name, users.status ".
                                "FROM users_groups_link ".
                                "LEFT JOIN users ".
                                "ON users_groups_link.userid = users.login ".
                                "WHERE users_groups_link.groupid='$data{groupid}'".
                                " and users.login <>'' ".
                                "ORDER BY users.name"

                             :  "select login, name, status from users ".
                                "where login<>'' ".
                                "order by name",
                       type  => 'UNNESTED' );

    while ( my @row = FetchRow($cid) )
     {
      next if    ($row[2] == 2 && $row[0] ne $disabled_user)
	      || !$row[1]
	      || $row[0] eq 'guest';

      next if $_is_readonly && $select{$data{name}}{$row[0]} ne 'selected';

      $field .= "\t<option value=\"$row[0]\" $select{$data{name}}{$row[0]}>".
		$row[1].
		"</option>\n";

      $escapedvalue
        = MkEntities($row[1]) if $select{$data{name}}{$row[0]} eq 'selected';
     }
    $field .= "</select>\n";

    $data{style} =~ /style\=\"([^\"]+)\"/;
    my $style = MkUrl($1);
    my $fid = $form{id} || $on{fid};
    my $fnm = $data{name};

    $field = HLayer(bottom_space=>0,
		    layers=>
		     [($field,
		       Img( src    => $data{groupid} && $data{groupid} ne 'all'
			           ?  "$IG::img_url/user.gif"
			           :  "$IG::img_url/user_guest.gif",
			    title  => $lang{show_user_groups},
			    width  => 16,
			    style  => 'margin-left:3px; cursor:pointer;',
			    onclick=> "javascript:ajaxrequest([".
			               "'NO_CACHE',".
			               "'ajaxaction__groupselector',".
				       "'gs_subact__selectgroup',".
				       "'gs_groupid__$data{groupid}',".
				       "'fid__$fid',".
				       "'fnm__$fnm',".
				       "'fvl__' + getVal('$fnm'),".
				       "'style__$style',".
				       "'zerovalue__$data{zerovalue}',".
				       "'allvalue__$data{allvalue}',".
				       "'guestvalue__$data{guestvalue}'".
				       "],['$data{name}_fieldpart'],'GET');")
			 )]
		   ) if !$_is_readonly;
   }
  ## TYPE:TEXT     ##
  ## TYPE:PASSWORD ##
  ## TYPE:EMAIL    ##
  ## TYPE:CURRENCY ##
  elsif ( $data{type} =~ /^(text|password|email|currency)$/ )
   {
    if ($data{type} eq 'currency')
     { 
      $data{type} = 'text';
      require IG::Utils;
      ## keep $unescaped untouch
      $on{$data{name}} = $escapedvalue = Currency( $on{$data{name}} );
     }

    $data{size} ||= $data{maxlen};
    $data{size} ||= 10;
    $data{maxlen} &&= " maxlength=$data{maxlen}";
    $data{size} = $data{style} =~ /width/
		? ''
		: "size=\"$data{size}\" ";

    $field = "<input".
	     " name=\"$data{name}\"".
	     " type=\"$data{type}\"".
	     " value=\"$escapedvalue\"".
	     " class=\"forminput\"".
	     " $data{size}$data{maxlen}$description>";
   }
  ## TYPE:LABEL ##
  elsif ($data{type} eq 'label')
   { 
    $field = $data{value} || $data{data};
   }
  ## TYPE:DATE ##
  elsif ($data{type} eq 'date')
   {
    $data{size} ||= 12;
    $escapedvalue = CkDate($escapedvalue);
    $unescapedvalue .= ' ' if $db_driver eq 'mysql'; #XXX2IMPROVE Ugly TRICK!

    my ( $calendarday,
         $calendarmonth,
         $calendaryear ) = GetValuesByDate( CkDate($on{$data{name}}) );

    $field = HLayer(
               bottom_space=>0,
	       layers =>
	         [( "<input name=\"$data{name}\"".
		    ( !$data{onblur} && CheckPrivilege()
		      ? " onblur=\"ajaxrequest(['NO_CACHE',".
                                               "'ajaxaction__ckdate',".
                                               "'date__' + getVal('$data{name}')],['$data{name}'], 'GET');\""
		      : '').
		    " type=\"text\"".
		    " value=\"$escapedvalue\"".
		    " size=\"$data{size}\"".
		    " maxlength=\"10\"".
		    " class=\"forminput\"$description>\n",

		  ( -e "$cgi_dir${S}calendar"
		     ? Img( onclick=> "getMouseOptions(event);".
                                      "winPopUp(".
                                      " 'calendar?".
		                        "action=minicalendar&amp;".
		                        "field=$data{name}&amp;".
		                        "form=$form{name}&amp;".
		                        "calendarmonth=$calendarmonth&amp;".
		                        "calendaryear=$calendaryear'".
                                      ",210,210,'calendardate');",
			    title  => 'Show calendar',
			    style  => 'cursor:pointer; margin-left:3px',
			    src    => "$IG::img_url/date_finder.gif",
			    width  => 20,
			    height => 20 )
		     : '')
		  )] );
   }
  ## TYPE:COLOUR ##
  elsif ($data{type} eq 'colour')
   {
    $data{size} ||= 10;

    $field
     = HLayer
        ( bottom_space => 0,
          layers
           => [( "<input name=\"$data{name}\"".
                 " type=\"text\"".
                 " value=\"$escapedvalue\"".
                 " size=\"$data{size}\"".
                 " maxlength=\"10\"".
                 ( $escapedvalue =~ /^\#[0-9a-f]{6}$/
                   ? " style=\"background-color:$escapedvalue; color:$escapedvalue\""
                   : '').
                 " class=\"forminput\"$description>\n",

                 Img( href   => "javascript:winPopUp(".
                                  " 'igsuite?".
                                  "action=colourmap&amp;".
		                  "field=$data{name}&amp;".
		                  "form=$form{name}".
                                  "',330,230,'colours');",
                      title  => 'Show colour map',
                      style  => 'margin-left:3px',
                      onclick=> "getMouseOptions(event)",
                      src    => "$IG::img_url/colour_keeper.gif",
                      width  => 20,
                      height => 20 )
               )]
        );
   }
  ## TYPE:MOBILEPHONE ##
  elsif ($data{type} eq 'mobilephone')
   {
    $data{size} ||= 25;

    $field = HLayer( bottom_space=>0,
		     layers=>[( "<input name=\"$data{name}\"".
				" type=\"text\"".
				" value=\"$escapedvalue\"".
				" size=\"$data{size}\"".
				" maxlength=\"$data{maxlen}\"".
				" class=\"forminput\"$description>\n",

				(    $IG::plugin_conf{sms}{username}
 				  && CheckPrivilege('sys_sms_send')
			          ? Img( src=>"$IG::img_url/sms_send.gif",
                                         width=>16,
					 onclick=>"getMouseOptions(event)",
 			                 href=>"javascript:winPopUp('".
                       			          'igsms?'.
                       			          'action=composemessage&amp;'.
						  "to=$escapedvalue',370,250,'composesms')",
					 style=>'margin-left:3px',
			                 title=>'send SMS' )
 			          : '' ) 
			     )] );
   }
  ## TYPE:PHONENUMBER ##
  ## TYPE:FAXNUMBER ##
  elsif ($data{type} eq 'phonenumber' || $data{type} eq 'faxnumber')
   {
    my ($icon, $href, $title);
    $data{size} ||= 25;

    if ($data{type} eq 'faxnumber')
     {
      if (CheckPrivilege('igfax_send'))
       {
        $href  = "igfax?action=sendfax&amp;".
 		 "differentfaxnumber=$escapedvalue&amp;".
 		 "contactid=$on{contactid}&amp;".
 	 	 "sendbyfax=1";
        $icon  = "mime_mini_fax.png";
        $title = $lang{send_by_fax};
       }
      else
       {
        $icon  = 'mime_mini_fax_off.png';
        $title = $lang{Err_you_cant_send_fax};
       }
     }
    else
     {
      $title = $lang{place_a_call};
      $icon = 'telephone.png';

      if ( IG::ConfigParam('asterisk.call_manager_status') eq 'enabled')
       {
        $href = "javascript:winPopUp".
                "('asterisk?action=place_call&amp;".
                           "number=$escapedvalue&amp;".
                           "contactid=$on{contactid}',350,250,'asterisk');";
       }
      elsif ( $IG::plugin_conf{voip}{protocol} )
       {
        $href = $IG::plugin_conf{voip}{protocol}.
 		$IG::plugin_conf{voip}{prefix}.
		$escapedvalue;
       }
      else
       {
        $icon  = 'telephone_off.png';
        $title = $lang{Err_you_cant_place_call};
       }
     }

    $field = HLayer( bottom_space => 0,
		     layers => [( "<input name=\"$data{name}\"".
			 	  " type=\"text\"".
				  " value=\"$escapedvalue\"".
				  " size=\"$data{size}\"".
				  " maxlength=\"$data{maxlen}\"".
				  " class=\"forminput\"$description>\n",

			          Img( src   => "$IG::img_url/$icon",
			               width => 16,
 			               href  => $href,
				       style => 'margin-left:2px',
			               title => $title )
			        )] );
   }
  ## TYPE:FILE ## 
  elsif ($data{type} eq 'file')
   {
    croak("Error in define form enctype. Try multipart/form-data")
      if $form{enctype} ne 'multipart/form-data';
    $data{size} ||= 20;

    $field = "<input name=\"$data{name}\" type=\"file\" size=\"$data{size}\"".
	     " value=\"$escapedvalue\" class=\"forminput\"$description>";
   }
  ## TYPE:TEXTAREA ##
  elsif ($data{type} eq 'textarea')
   {
    $description .= " cols=\"$data{cols}\"" if $data{cols};
    $description .= " rows=\"$data{rows}\"" if $data{rows};

    if ( $data{wrap} eq 'hard' )
     {
      if ($description =~ /style/)
       {
        $description =~ s/(style\=\")([^\"]+)(\")
			 /$1$2;font-family:monospace;$3/x;
       }
      else
       {
        $description .= " style=\"font-family:monospace;\"";
       }
      $description .= " wrap=\"hard\"";
     }
    elsif ( $data{wrap} eq 'soft' )
     {
      $description .= " wrap=\"soft\"";
     }
    elsif ( $data{wrap} eq 'off' )
     {
      $description .= " wrap=\"off\"";
     }

    $field = "<textarea name=\"$data{name}\"$description>".
             $escapedvalue.
             "</textarea>\n";
    
    if ( $executed{htmlhead} )
     {
      $data{toolbar} ||= 'IGBasic';
      
      ## need to load spellchecker javascript (called once)
      if (    !$executed{spellcheker_js}++
           && $IG::ext_app{aspell} )
       {
        $field .= JsExec( src => "$IG::img_url/spellChecker.js" );
       }

      ## need to load fckeditor javascript (called once)
      if (    $data{fckeditor}
           && !$executed{fckeditor_js}++
           && $plugin_conf{fckeditor}{webpath}
           && $client_browser ne 'konqueror'
         )
       {
        $field .= JsExec( src => $plugin_conf{fckeditor}{webpath}.
                                 'fckeditor.js' );
       }

      if (    $plugin_conf{fckeditor}{webpath}
           && $client_browser ne 'konqueror'
           && (    $data{fckeditor} eq 'active'
                || (    $data{fckeditor} eq 'optional'
                     && CkHtml( $unescapedvalue ) ) )
         )
       {
        $data{fckeditor_width}  ||= 530;
        $data{fckeditor_height} ||= 300;

        $field .= JsExec( code => <<END );
window.onload = function()
 {
  var oFCKeditor = new FCKeditor( '$data{name}' ) ;
  oFCKeditor.Config["CustomConfigurationsPath"] = "$img_url/igfckeditor.js";
  oFCKeditor.Config['DefaultLanguage'] = '$lang';
  oFCKeditor.ToolbarSet = '$data{toolbar}';
  oFCKeditor.Height = "$data{fckeditor_height}" ;
  oFCKeditor.Width = "$data{fckeditor_width}" ;  
  oFCKeditor.BasePath = '$plugin_conf{fckeditor}{webpath}';
  // oFCKeditor.DisplayErrors = true; // Debug option
  oFCKeditor.ReplaceTextarea() ;
 }
END
       }
      else
       {
        $field .= "<div style=\"background:$clr{bg_list}; display:block;".
                  " background-image: url($img_url/shadow.gif);".
                  " background-repeat:repeat-x;".
                  " background-position: right top;".
                  " border-top:1px solid #CCCCCC;\">". 

                  ( $data{caption}
                    ? "<div style=\"font-size:10px; color:$clr{font_low_evidence};".
                      " float:right; margin-right:5px\">$data{caption}</div>"
                    : '' ).

		  Img(	style   => "display:inline; cursor:pointer;",
			onclick => "increaseTextArea(document.$form{name}.$data{name},50)",
			src     => "$IG::img_url/increase_area.gif",
			width   => 16,
			title   => $lang{increase_area}).

		  Img(	style   => "display:inline; cursor:pointer;",
			onclick => "decreaseTextArea(document.$form{name}.$data{name},50)",
			src     => "$IG::img_url/decrease_area.gif",
			width   => 16,
			title   => $lang{decrease_area} ).

		  Img(	style   => "display:inline; cursor:pointer;",
			onclick => "document.$form{name}.$data{name}.style.fontSize = '14px'",
			src     => "$IG::img_url/fontbigger.gif",
			width   => 16,
			title   => $lang{increase_text} ).

		  Img(	style   => "display:inline; cursor:pointer;",
			onclick => "document.$form{name}.$data{name}.style.fontSize = '12px'",
			src     => "$IG::img_url/fontsmaller.gif",
			width   => 16,
			title   => $lang{decrease_text} ).

		  (    $IG::ext_app{aspell}
		    && ( CheckPrivilege() || $demo_version )
		    ? Img( style   => "display:inline; cursor:pointer;",
		           onclick => "var speller = new spellChecker(document.$form{name}.$data{name}); speller.openChecker();",
			   src     => "$IG::img_url/ckspelling.gif",
                           width   => 16,
			   title   => $lang{check_spelling} )
                    : '').

		  ( CheckPrivilege() || $demo_version
		    ? Img( style   => "display:inline; cursor:pointer;",
			   onclick => "ajaxrequest(['NO_CACHE','ajaxaction__textbeautify','text__' + getVal('$data{name}')], ['$data{name}'], 'post');",
			   src     => "$IG::img_url/beautify.gif",
                           width   => 16,
			   title   => $lang{beautify_text} )
                    : '').

                  (    $plugin_conf{fckeditor}{webpath}
                    && ($data{fckeditor} eq 'optional' || $data{fckeditor} eq 'available')
                    && $client_browser ne 'konqueror' #XXX2DEVELOPE - Any FCKeditor news?
		    && ( CheckPrivilege() || $demo_version )
		    ? Img( style   => "display:inline; cursor:pointer;",
			   onclick => ($form{ckchanges} eq 'true' ? 'formChanged = 1;' : '').
			              "ajaxrequest(['NO_CACHE',".
			                           "'ajaxaction__htmleditor',".
			                           "'fieldname__$data{name}',".
			                           "'width__$data{fckeditor_width}',".
			                           "'height__$data{fckeditor_height}',".
			                           "'text__' + getVal('$data{name}')],".
			                          "['div_field_$data{name}'],".
			                           "'post');".
                                      "setTimeout('replaceArea(\\'$data{name}\\', \\'$data{toolbar}\\', \\'$data{fckeditor_width})\\', \\'$data{fckeditor_height}\\')', 500);",
			   src     => "$IG::img_url/htmleditor.gif",
                           width   => 16,
			   title   => "Extended html editor" )
                    : '' ).
                    
		  '</div>';
              }
      }

    $field = "<div id=\"div_field_$data{name}\"".
             " style=\"border:1px solid #999999;\">$field".
             "</div>\n";
   }
  ## TYPE:CHECKBOX ##  
  elsif ($data{type} eq 'checkbox')
   {
    my $select_status;
    my $select_value = $escapedvalue ? " value=\"$escapedvalue\"" : '';

    if ( $data{checked} )
     {
      $select_status = ' checked'
     }
    else
     {
      if ( ref($on{$data{name}}) eq 'ARRAY')
       {
        for ( @{$on{$data{name}}} )
         {
          next if $data{value} ne $_ || !$data{value};
          $select_status = ' checked';
          last;
         }
       }
      else
       { 
        $select_status = ' checked'
          if ( $data{value} && $data{value} eq $on{$data{name}} )
             ||  
  	     ( !$data{value} && $on{$data{name}} && !$data{override} );
       }
     } 

    if ( $_is_readonly )
     {
      $field = Img( src    => $select_status eq ' checked'
                           ? "$IG::img_url/close_inline.gif"
                           : "$IG::img_url/open_inline.gif",
                    width  => 16,
                    height => 16 );
     }
    else
     {
      $field = "<input".
		" name=\"$data{name}\"".
		" type=\"checkbox\"".
		" class=\"formcheck\"".
		$select_value.
		$select_status.
	       "$description>";
     }
   }
  ## TYPE:RADIO ##
  elsif ($data{type} eq 'radio')
   {
    $on{$data{name}} ||= $data{value};
    my $selected = $on{$data{name}} eq $data{value} ? ' checked' : '';

    $field = "<input".
		" name=\"$data{name}\"".
		" type=\"radio\"".
		" value=\"$data{value}\"".
		" class=\"formcheck\"".
	     "$selected$description>";
   }
  ## TYPE:SELECT     ## 
  ## TYPE:SENDMODE   ##
  ## TYPE:BASICTABLE ##
  elsif (   $data{type} eq 'select'
	 || $data{type} eq 'sendmode'
	 || $data{type} eq 'basictable' )
   {
    if ($data{type} eq 'sendmode')
     {
      $data{name} = 'sendmode';
      $escapedvalue = $unescapedvalue = $on{sendmode};
      $data{show} ||= $lang{send_mode};
      @{$data{data}} = (['none',    $lang{none}],
			['byfax',   $lang{byfax}],
			['byemail', $lang{byemail}],
			['bymail',  $lang{bymail}],
			['byhand',  $lang{byhand}]);
     }
    elsif ($data{type} eq 'basictable')
     {
      my ($id, $tablevalue, $status);
      my $cnt;
      $data{table} ||= $data{name};
      $data{order} = $data{order} eq 'byvalue' ? 'id' : 'tablevalue';

      my $cid = DbQuery( query => "select id, tablevalue, status ".
                                  "from basic_tables ".
                                  "where tablename='$data{table}' ".
                                  "order by $data{order}",
                         type  => 'UNNESTED' );

      while ( ($id, $tablevalue, $status) = FetchRow($cid) )
       {
        next if $status==1 && $id ne $unescapedvalue;
        $data{data}[$cnt][0]   = $id;
        $data{data}[$cnt++][1] = $tablevalue;
       }

      $data{quickhelp} = "Ask to your administrator to ".
                         "populate this basic table!" if !$cnt;

      if ( $data{show} && CheckPrivilege('sys_user_admin') )
       {
        $data{show} = "<a href=\"tables?table=$data{table}\"".
                      " title=\"$lang{edit}\"".
                      " target=\"mainf\">".
		      "$data{show}</a>";
       }
     }

    $data{size} &&= " size=\"$data{size}\"";
    $data{multiple} &&= ' multiple';

    if (ref($unescapedvalue) eq 'ARRAY')
     { $select{$data{name}}{$_} = ' selected' for @{$unescapedvalue} }
    else
     { $select{$data{name}}{$unescapedvalue} = ' selected' if $unescapedvalue }

    $field = "<select name=\"$data{name}\" class=\"formselect\"$data{multiple}$data{size}$description>\n";

    ## Start the select input from 0 or all value if requested
    $field .= "\t<option value=\"\">".
	      ($_is_readonly ? $lang{unselected} : "$lang{select}...") .
              "</option>\n" if    $data{zerovalue} eq 'true'
                               && (   ( !$_is_readonly )
                                   || ( $_is_readonly && !$unescapedvalue ) );
    $field .= "\t<option value=\"all\" $select{$data{name}}{all}>$lang{all}</option>\n"
              if $data{allvalue};

    for my $i ( 0 .. $#{$data{data}} )
     {
      next if    $_is_readonly
              && ($select{$data{name}}{$data{data}[$i][0]} ne ' selected'
              && !($i == 0 && !$unescapedvalue));

      my $label_value = MkEntities($data{data}[$i][1]);
         $label_value =~ s/ {2}/ \&nbsp;/g;
              
      $field .= "\t<option value=\"".
                MkEntities($data{data}[$i][0]).
                "\" $select{$data{name}}{$data{data}[$i][0]}>".
                "$label_value</option>\n";
                
      $escapedvalue = MkEntities($data{data}[$i][1])
         if $select{$data{name}}{$data{data}[$i][0]} eq " selected";
     }
    $escapedvalue ||= MkEntities($data{data}[0][1]);
    $field.="</select>\n";
   }
  ## TYPE:CONTACTFINDER ##
  elsif ($data{type} eq 'contactfinder')
   {
    $data{size}  ||= 40;
    $data{value} ||= $on{contactid};

    ## Store hidden values
    Input( type=>'hidden', name=>'contactid', value=>$data{value} );
    if ( $data{extraselection} )
     {
      Input( type=>'hidden', name=>'subcontactid');
      Input( type=>'hidden', name=>'contactaddress');
     }
    if ( $data{groupselection} )
     {
      Input( type=>'hidden', name=>'contactcategory');
     }

    ## Retrieve contactname value
    my $cid = DbQuery( query => "select contactname from contacts ".
                                "where contactid='". DbQuote($data{value}) .
                                "' limit 1",
                       type  => 'UNNESTED' );

    $on{contactname} = FetchRow($cid);
    $escapedvalue    = MkEntities($on{contactname});

    my $selector_link = "javascript:winPopUp('contacts?action=contactfinder".
                        "&amp;subact=justview".
			"&amp;contactformname=$form{name}".
			"&amp;contactformid=$form{id}".
			"&amp;falsecontactname=$data{falsecontactname}". 
			"&amp;extraselection=$data{extraselection}".
			"&amp;groupselection=$data{groupselection}".
			"',700,500,'contactfinder');";
   
    $field = HLayer( bottom_space=>0,
		     layers=>[( "<input".
				" name=\"contactname\"".
				" type=\"text\"".
				" value=\"$escapedvalue\"".
				" onKeyPress=\"$selector_link\"".
				" class=\"forminput\"".
				" size=$data{size}$description readonly>",

				Img( href  => $selector_link,
				     style => 'margin-left:3px',
				     title => $lang{select_name},
				     width => 20,
				     src   => "$img_url/contact_finder.gif")
			       )] );
   }
  ## TYPE:HIDDEN ## 
  elsif ( $data{type} eq 'hidden' && $form{status} ne 'r' )
   {
    if ( $data{method} eq 'html' || $form{mode} eq 'html')
     {
      $field = "<input type=\"hidden\"".
               " style=\"visibility: hidden;\"".
               " name=\"$data{name}\"".
               $data{id}.
               " value=\"$escapedvalue\">";
     }
    else
     {
      $data{name} = ":$data{name}" if $data{persistent};
      CGISession( param_name  => $data{name},
                  param_value => $unescapedvalue );
      return;
     }
   }
  ## TYPE:HIDDENS ##
  elsif ( $data{type} eq 'hiddens' && $form{status} ne 'r' )
   {
    for my $i ( 0 .. $#{$data{data}} )
     {
      Input (	type		=> 'hidden',
		persistent	=> $data{persistent},
		name		=> $data{data}[$i][0],
		value		=> $data{data}[$i][1],
		override	=> $data{override}) 
     }
    return;
   }
  ## TYPE:TEMPLATE ##
  elsif ( $data{type} eq 'template' && !$_is_readonly )
   {
    $data{size} &&= " size=\"$data{size}\"";
    $select{$data{name}}{$unescapedvalue} = " selected" if $unescapedvalue;

    $field = "<select name=\"$data{name}\" class=\"formselect\"$data{size}$description>\n";
    $field .= "\t<option value=\"Only_protocol\">$lang{only_protocol}</option>\n";

    ## Make a list of documents template
    if ( ! $_is_readonly )
     {
      my $re = $cgi_name eq 'circular'
             ? qr/html*/
             : qr/html*|odt/;

      opendir (DIR, $data{dir});
      foreach (sort grep /\.($re)$/i, readdir DIR)
       {
        $field .= "\t<option value=\"$_\" $select{$data{name}}{$_}>".
                  "$_</option>\n";
       }
      close (DIR);
     }

    $field.="</select>\n";
   }
  ## TYPE:BUTTON ##
  ## TYPE:SUBMIT ##
  ## TYPE:RESET  ##
  elsif (   !$_is_readonly
         && (   $data{type} eq 'button'
             || $data{type} eq 'submit'
             || $data{type} eq 'reset') )
   {
    $data{show} ||= $data{value} ||= $lang{send};

    $field .= "<input".
	      " type=\"$data{type}\"".
	      " name=\"$data{name}\"".
	      " value=\"$data{show}\"".
	      " class=\"formbutton\"".
	      "$description>";
    $data{show}="";
   }
  ## TYPE:IMAGE ##
  elsif ( !$_is_readonly && $data{type} eq 'image')
   {
    $data{alt}   ||= $data{show};
    $data{alt}   &&= " alt=\"$data{alt}\" title=\"$data{alt}\"";
    $data{src}   &&= " src=\"$data{src}\" border=0 align=\"top\"";
    $data{width} &&= " width=\"$data{width}\"";

    $field .= "<input type=\"image\" name=\"$data{name}\" value=\"$data{show}\"$data{src}$data{alt}$data{width}$description>";
    $data{show} = '';
   }
  else
   {
    ## we have an unknown field type or a field type that in readonly form
    ## must stay hidden
    return;
   }

  ## Blush ondemand
  if ( $data{blushed} )
   {
    $data{labelstyle} =~ s/color\:\s*[^\;\"]+//;
    $data{labelstyle} = "color:#ff3300; $data{labelstyle}";
   }

  ## Adjust some value
  $data{labelstyle}  &&= " style=\"$data{labelstyle};\"";
  $data{fieldstyle}  &&= " style=\"$data{fieldstyle};\"";

  ## Build a Read only version to fields type that dont't have a readonly version
  if (    $_is_readonly
       && $data{type} !~ /multiselect|select|basictable|sendmode|checkbox|radio|label/ )
   {
    my $width   = $data{size} * 8;
       $width ||= $data{cols} * 8;
       $width &&= $width . 'px';
       $width ||= '100%';

    $data{style} =~ s/style\=\"(.+)\"/$1/;
    my $style = $data{style};
    $style .= "; width:$width;" if $style !~ /width/;

    $escapedvalue =~ s/\n/<br>/g;
    $escapedvalue = 'xxxx' if $data{type} eq 'password';
    $field = "<div style=\"white-space:normal; padding:1px; border:1px solid #999999; overflow:auto; $style\">".
	     "${escapedvalue}&nbsp;</div>";
   } 

  ## Store field value when the form is not in readonly mode but the field is
  ## to avoid that user overwrite original value
  if ( $form{status} ne 'r' && $_is_readonly )
   {
    $data{name} = ":$data{name}" if $data{persistent};
    CGISession( param_name  => $data{name},
                param_value => $unescapedvalue );
   }
 
  ## Field container
  $html .= "<div id=\"$data{name}_containerpart\" style=\"".
           ( $data{float} && $data{float} ne 'none'
             ? "float:$data{float};"
             : "clear:left;").
           " display:block; $data{containerstyle}\">\n ";

  ## Label part
  my $label  = $data{show};

     $label .= '<span style="color:#ff3300;"> *</span>'
               if $data{validate} && $data{validate}{mandatory} eq 'true';
  
     $label = QuickHelp( alt    => MkEntities($data{quickhelp}),
                         width  => '200px',
		         anchor => $label ) if $data{quickhelp};

  $html .= "<div".
           " class=\"label\"".
           " id=\"$data{name}_labelpart\"".
           " $data{labelstyle}>\n\t$label</div>\n " if $data{show};

  ## Field part
  $html .= "<div".
           " class=\"field\"".
           " id=\"$data{name}_fieldpart\"".
           " $data{fieldstyle}>\n\t$field\n </div>\n";

  ## Close container
  $html .= "</div>\n\n";

  ## Persistent fields are not really used (only in igwiki_wizard)
  if ($data{persistent} && !$_is_readonly && $form{mode} eq 'session' )
   {
    CGISession( param_name  => ':$data{name}',
                param_value => $unescapedvalue );
   }

  ## Form Validation
  if ( $data{validate} )
   {
    $form{validation} .= "$data{name} => {\n";
    for my $param (qw ( pattern onerror onmissing mandatory type show maxlen) )
     {
      my $val = $data{validate}{$param} || $data{$param};
      next if !$val;
      $val =~ s/(\'|\\)/\\$1/g;
      $form{validation} .= "\t\t$param => '$val',\n";
     }
    $form{validation} .= "               },\n\n";
   }
  
  $html = $data{output} eq 'onlyfield' ? $field
	: $data{output} eq 'onlylabel' ? $data{show}
	: $html;

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 InputDocBox()

Build a multi field to store different types of documents

=cut

sub InputDocBox
 {
  my %data = @_;
  my $box;
  my $spool_file = $htdocs_dir . $S .
                   $default_lang{$cgi_name} . $S .
                   ".print_spool_file_$remote_host";
     ($spool_file) = (<$spool_file.*>);


  if ($spool_file && $spool_file =~ /\.\w\w\w$/ && -w $spool_file)
   {
    ## XXX2DEVELOPE - Protocol from print spool file
    $box =  Input(	type  => 'radio',
			style => 'margin-right: 5px;',
			name  => 'builddoc_choice',
			value => 5).

	    Input(	data  => "Copia da un file di stampa",
			fieldstyle=>'font-size:10px',
			type  => 'label',
			float => 'left' );
   }
  
  $box .=   Input(	type  => 'radio',
			style => 'margin-right: 5px;',
			name  => 'builddoc_choice',
			value => 1).

	    Input(	data  => $lang{only_protocol},
			fieldstyle=>'font-size:10px',
			type  => 'label',
			float => 'left' ).

	    Input(	type  => 'radio',
			style => 'margin-right: 5px;',
			name  => 'builddoc_choice',
			value => 2).

	    Input(	data  => $lang{copy_from_file},
			fieldstyle=>'font-size:10px',
			type  => 'label',
			float => 'left' ).

	    Input(	type  => 'radio',
			name  => 'builddoc_choice',
			value => 3).

	    Input(	show=>$lang{create_from_template},
			name=>'builddoc_source3',
			labelstyle => 'border:0px; font-size:10px; '.
			              'width:auto; background:transparent',
        		style=>'font-size:10px; width: 200px',
			onfocus=>"document.$form{name}.builddoc_choice[2].checked=true;",
        		dir=> $data{dir},
			type=>'template',
			float => 'left' ).

	    Input(	type  => 'radio',
			name  => 'builddoc_choice',
			value => 4).

	    Input(	show=>$lang{copy_from_protocol},
			labelstyle => 'border:0px; font-size:10px; '.
			              'width:auto; background:transparent',
        		name=>'builddoc_source4',
			style=>'font-size:10px;',
			onfocus=>"document.$form{name}.builddoc_choice[3].checked=true;",
			validate => { pattern => '\d\d\d\d\d\d.\d\d|^$' },
			type=>'text',
			float => 'left' );

  my $html = TaskMsg( $box, 7, 350 );
  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 HLayer()

This is a layer to show all buttons in a more pretty way.

=cut

sub HLayer
 { 
  my %data = @_;
  my $html;
  my @layers = (!$data{layers} && !$data{left_layers} && !$data{right_layers})
	     ? @_
	     : $data{layers} ? @{$data{layers}} : (); ## to mantain old system

  $data{valign}		||= 'middle';
  $data{top_space}      ||= 1;
  for my $st ( qw( intra_space top_space bottom_space ) )
   {
    $data{$st}	||= '0';
    $data{$st}   .= 'px' if $data{$st} =~ /\d$/;
   }

  $data{width} = (!$data{left_layers} && !$data{right_layers} && !$data{width})
	       ? ''
	       : $data{width} ? "width=\"$data{width}\" "
			      : "width=\"100%\" ";

  $html  = "\n<table $data{width}cellspacing=0 cellpadding=0".
	   " style=\"clear:both; margin:$data{top_space} 0 $data{bottom_space} 0;\"><tr>";

  if ( $data{left_layers} )
   {
    $html .= "<td align=\"left\" valign=\"$data{valign}\">".
	     "<table cellspacing=0 cellpadding=0><tr>\n";
    $html .= $_
           ? "\n<td valign=\"$data{valign}\" style=\"padding-right:$data{intra_space};$data{layers_style}\">\n$_</td>\n"
	   : '' foreach @{$data{left_layers}};
	   
    $html .= "</tr></table></td>\n";
   }

  if ( @layers )
   {
    $html .= "<td align=\"center\" valign=\"$data{valign}\" width=\"100%\">".
	     "<table cellspacing=0 cellpadding=0><tr>\n";
    $html .= $_
           ? "\n<td valign=\"$data{valign}\" style=\"padding-right:$data{intra_space};$data{layers_style}\">\n$_</td>\n"
	   : '' foreach @layers;
	   
    $html .= "</tr></table></td>\n";
   }

  if ( $data{right_layers} )
   {
    $html .= "<td align=\"right\" valign=\"$data{valign}\">".
	     "<table cellspacing=0 cellpadding=0><tr>\n";
    $html .= $_
           ? "\n<td valign=\"$data{valign}\" style=\"padding-right:$data{intra_space};$data{layers_style}\">\n$_</td>\n"
	   : '' foreach @{$data{right_layers}};
	   
    $html .= "</tr></table></td>\n";
   }

  $html .= "</tr></table>\n";
  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 MkTable()

This is a fast way to build an html table.

=cut

sub MkTable
 {
  my %data = @_;
  $data{style}       &&= " style=\"$data{style}\"";
  $data{class}       &&= " class=\"$data{class}\"";
  $data{cellspacing} ||= '0';
  $data{cellspacing} = " cellspacing=\"$data{cellspacing}\"";
  $data{cellpadding} ||= '0';
  $data{cellpadding} = " cellpadding=\"$data{cellpadding}\"";

  my $html = "<table$data{style}$data{class}$data{cellspacing}$data{cellpadding}>\n";
  my $row_cnt = 0;

  for my $row ( @{$data{values}} )
   {
    $row_cnt++;
    my $col_cnt = 0;
    $html .= "<tr>\n";

    for my $col ( @$row )
     {
      $col_cnt++;
      my $style;
      my $class;
      my $value = $col;

      ($value, $style, $class) = @$col if ref($col) eq 'ARRAY';

      $style ||= $data{"style_c${col_cnt}_r${row_cnt}"}
	     ||  $data{"style_c_r${row_cnt}"}
	     ||  $data{"style_c${col_cnt}_r"}
	     ||  $data{style_c_r};
      $style &&= " style=\"$style\"";

      $class ||= $data{"class_c${col_cnt}_r${row_cnt}"}
	     ||  $data{"class_c_r${row_cnt}"}
	     ||  $data{"class_c${col_cnt}_r"}
	     ||  $data{class_c_r};
      $class &&= " class=\"$class\"";

      $html .= "\t<td$style$class>$value</td>\n";
     }
    $html .= "</tr>\n";
   }
  $html .= '</table>';
  defined wantarray ? return $html : PrOut $html;
 }                                   

##############################################################################
##############################################################################

=head3 Br(n)

It's just a short way to do print "<br />" x n;

=cut

sub Br
 {
  my ($v) = @_;
  $v ||= 1;
  my $html = "<br style=\"line-height:5px;clear:both;\">\n" x $v;
  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 Redirect()

Redirect to another page

=cut

sub Redirect
 {
  die("Can't use Redirect() twice!\n") if $executed{redirect}++;
  my ($url, $status) = @_;

  $url ||= 'igsuite';
  $url   = "$cgi_url/$url" if $url !~ /^(http|\/)/;

  my $reply = $cgi_ref->redirect( -uri    => $url,
                                  -status => $status || 303,
				  -nph    => $HTTP::Server::Simple::VERSION
				           ? 1
				           : 0 );

  defined wantarray ? return $reply : print STDOUT $reply;
 }

##############################################################################
##############################################################################

=head3 BackToReferer()

Redirect to previous referer

=cut

sub BackToReferer
 {
  my %data = @_;
  my $url = $on{backtoreferer} == 1
          ? $ENV{HTTP_REFERER}
          : $on{backtoreferer};

  my $reply = Redirect( $url || $data{default} );

  defined wantarray ? return $reply : print STDOUT $reply;
 }

##############################################################################
##############################################################################

=head3 Img()

It's just a short way to do print '<img src="url">'

=cut

sub Img
 {
  my %data = @_;
  return if !$data{src};
  $data{alt}     ||= $data{title};
  $data{target}  &&= " target=\"$data{target}\"";
  $data{caption} &&= "$data{caption}&nbsp;";

  my $html = '<img'; 
  for (qw( id usemap class src alt title style width onload
           height border align onclick onmouseover onmouseout) )
   {
    $html .= " $_=\"$data{$_}\""
             if defined($data{$_}) && $data{$_} ne 'none';
   }
  $html .= '>';

  if ($data{href})
   { $html = "<a href=\"$data{href}\"$data{target}>$data{caption}$html</a>"; }

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 Blush(string)

It's just a short way to blush a string by html tag

=cut

sub Blush
 {
  my $text = shift;
  my $html = "<span style=\"color:#ff3300;\">$text</span>";
  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 FormFoot()

Close form tag and eventually 'table' tag. We use it to show some javascript
tricks that gets autofocus on first text or textarea field of a form.

=cut

sub FormFoot
 {
  my %data = @_;
  my $html;
  $html .= "</form>\n" if $form{status} ne 'r';
  $html .= "<!-- END FORMHEAD -->\n\n";

  ## Check autocompletion request (scriptacoulous)
  if ( $form{autocompletion} )
   {
    my %ac = %{$form{autocompletion}};
    $html .= "<div id=\"autocompletion_choiches_$form{id}\"".
             " class=\"autocomplete\"></div>\n".
             "<script type=\"text/javascript\">\n";

    foreach ( keys %ac )
     {
      next if    ! $ac{$_}{script_url}
              || ! $ac{$_}{script_action}
              || ! $ac{$_}{search_param};

      $ac{$_}{min_chars} ||= 4;
      $ac{$_}{tokens}    ||= ',';
      $html .= "new Ajax.Autocompleter(".
                           " \"$_\",".
                           " \"autocompletion_choiches_$form{id}\",".
                           " \"$ac{$_}{script_url}\",".
                           " { minChars:$ac{$_}{min_chars},".
                           " paramName:\"$ac{$_}{search_param}\",".
                           " parameters: \"action=$ac{$_}{script_action}\",".
                           " tokens: '$ac{$_}{tokens}'});\n";
     }
    $html .= "</script>\n";
   }

  my $formChangedInit = $form{ischanged} eq 'true' ? '1' : '0';
  $html .= <<END if $form{ckchanges} eq 'true' && $tema ne 'printable_';
<script defer type=\"text/javascript\">

 var formChanged = $formChangedInit;
 var alreadyChangedFields = new Array();

 lookForFormChanges();     

 window.onbeforeunload = function ()
  {
   if (formChanged)
    { return 'Ci sono dati non salvati in questa pagina, procedendo andranno perduti'; }
  }

 function recordFormChange()
  { recordChangedField( this ); }

 function recordFormChangeIfChangeKey(myevent)
  {
   if (myevent.which && !myevent.ctrlKey && !myevent.ctrlKey)
    { recordChangedField( this ); }
  }

 function recordChangedField( obj )
  {
   //XXX2IMPROVE: filter some changes (the wiki toolbar for example)
   formChanged = 1;
   if( obj.name == '' || alreadyChangedFields[obj.name] == 1 )
     return;
   alreadyChangedFields[obj.name] = 1;
   document.$form{name}.changedfields.value += obj.name + ' ';
  }

 function ignoreFormChange()
  { formChanged = 0; }

 function lookForFormChanges()
  {
   var origfunc;
   var count=0;
   for (j = 0; j < document.$form{name}.elements.length; j++)
    {
     var formField=document.$form{name}.elements[j];
     var formFieldType=formField.type.toLowerCase();
     count++;
     if (formFieldType == 'checkbox' || formFieldType == 'radio')
      {
       addFormChangeHandler(formField, 'click', recordFormChange);
      }
     else if (formFieldType == 'text' || formFieldType == 'textarea')
      {
       if (formField.attachEvent)
        { addFormChangeHandler(formField, 'keypress', recordFormChange); }
       else
        { addFormChangeHandler(formField, 'keypress', recordFormChangeIfChangeKey); }
      }
     else if (formFieldType == 'select-multiple' || formFieldType == 'select-one')
      {
       addFormChangeHandler(formField, 'change', recordFormChange);
      }
    }
   addFormChangeHandler(document.$form{name}, 'submit', ignoreFormChange);
  }

 function addFormChangeHandler(target, eventName, handler)
  {
   if (target.attachEvent)
    { target.attachEvent('on'+eventName, handler); }
   else
    { target.addEventListener(eventName, handler, false); }
  }

 </script>
END

  ## Check external plugins
  $html = CkExtPlugins( 'FormFoot', \$html, \%data ) if %plugins;

  ## Store Form validation info
  CGISession( param_name  => 'ig_form_validation',
              param_value => $form{validation}
            ) if $form{validation} && $form{mode} eq 'session';

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 FormValidate()

Validate form values

=cut

sub FormValidate
 {
  my %prms;
  my @errors;
  my $mandatories;

  ## load and parse validation info
  croak('No form validation info') if !$on{ig_form_validation} || !$on{formid};
  eval("%prms = ($on{ig_form_validation})");
  croak("Some strange error in parsing form validation info!\n") if $@;  

  for my $key (keys %prms)
   {
    my $_is_mandatory = $prms{$key}{mandatory} =~ /^(1|true)$/ ? 1 : 0;
    next if ! $_is_mandatory && !$on{$key} && $prms{$key}{type} ne 'date';
    
    if ( $prms{$key}{type} eq 'contactfinder' )
     {
      ## it's a contact field
      my $error = ContactFinder();
      if ( $error && $_is_mandatory )
       {
        $attr{$key}{blushed} = 1;
        push @errors, $error;
       }
     }
    elsif ( $_is_mandatory && !$on{$key} )
     {
      ## field is missing but mandatory
      $attr{$key}{blushed} = 1;
      if ( $prms{$key}{onmissing} || $prms{$key}{onerror} || ! $mandatories )
       {
        $mandatories++; ## we want only one generic alert
        push @errors, (   $prms{$key}{onmissing} 
                       || $prms{$key}{onerror}
                       || $lang{Err_mandatory_fields} );
       }
     }
    elsif (   $prms{$key}{type} eq 'date'
           && !($on{$key} = CkDate( $on{$key}, not($_is_mandatory) )) )
     {
      ## is an invalid field date
      $attr{$key}{blushed} = 1;
      push @errors, (   $prms{$key}{onerror}
                     || "$prms{$key}{show}: $lang{Err_field}" );
     }
    elsif ( $prms{$key}{pattern} && $on{$key} !~ /$prms{$key}{pattern}/ )
     {
      ## field value is not valid
      $attr{$key}{blushed} = 1;
      push @errors, (   $prms{$key}{onerror}
                     || "$prms{$key}{show}: $lang{Err_field}" );
     }
    elsif ( $prms{$key}{type} eq 'email' )
     {
      ## it would be an email address
      require IG::EmailValid;
      next if Email::Valid->address($on{$key});
      $attr{$key}{blushed} = 1;
      push @errors, (   $prms{$key}{onerror}
                     || "$prms{$key}{show}: $lang{Err_field}".
                        ' ['.$Email::Valid::Details.']'
                    );
     }
   }

  return @errors;
 }

##############################################################################
##############################################################################

=head2 Misc system utilities

=cut

##############################################################################
##############################################################################

=head3 CGISession()

This is a simple interface to cache session values

=cut

sub CGISession
 {
  my %data = @_;
  $data{formid}      ||= $form{id};
  $data{action}      ||= 'insert';
  $data{sessionid}   ||= $cookie{igsuiteid};
  $data{param_name}  &&= DbQuote( $data{param_name} );
  $data{param_value} &&= DbQuote( $data{param_value} );
  $data{formid}        = DbQuote( $data{formid} );

  if ( $data{action} eq 'insert' )
   { 
    DbQuery( query => "insert into sessions_cache values ".
                      "('$data{sessionid}', '$data{formid}',".
                      " '$data{param_name}',".
                      " '$data{param_value}', '$tv{today}')",
             type  => 'UNNESTED' );
    }
  elsif ( $data{action} eq 'clear' )
   { 
    DbQuery( query => "delete from sessions_cache ".
                      "where formid='$data{formid}'".
                      " or sessionid~*'$data{sessionid}'".
                      " or keydate+2 < current_date",
             type  => 'UNNESTED' );
   }   
  elsif ( $data{action} eq 'update' )
   {
    DbQuery( query => [( "delete from sessions_cache ".
                         "where formid='$data{formid}'".
                         " and sessionid='$data{sessionid}'".
                         " and keyname='$data{param_name}'",
                                
                         "insert into sessions_cache values ".
                         "('$data{sessionid}', '$data{formid}',".
                         " '$data{param_name}',".
                         " '$data{param_value}', '$tv{today}')" )],
             type  => 'UNNESTED' );
   }
 }

##############################################################################
##############################################################################

=head3 LogD()

This is a simple interface to log IG events.

=cut

sub LogD
 {
  my ($logs, $level, $ttable, $tid) = @_; 
  my $id = MkId(); 
  my $user = $level eq 'login' || $level eq 'logout'
           ? $tid
           : $auth_user || 'system';

  $tid   = DbQuote($tid);
  $logs .= " changed fields: $on{changedfields}" if $on{changedfields};
  $logs  = DbQuote($logs);

  ## Adjusts time and date values
  _set_time_values();

  DbQuery( query => $level eq 'view' || $level eq 'search'

		 ?  "insert into last_elements_log values ('$tid',".
		    " '$logs', '$ttable', '$user', '$tv{today}',".
		    " '$tv{time}')"

		 :  "insert into system_log values ('$id', '$level',".
		    " '$ttable', '$tid', '$tv{today}', '$tv{time}',".
		    " '$user', '".DbQuote($remote_host)."',".
		    " '$logs')",

	   type  => 'UNNESTED' );
 }

##############################################################################
##############################################################################

=head3 SysExec()

Execute an esternal application. It looking for all values from user 
environment paths if it can't find the executable.

=cut

sub SysExec
 {
  ## Used by..
  ## IG.pm (in debug mode $debug==1)
  ## igfax  (gs) store cover and fax and to show documents;
  ## igsuited (perl igsuited) to execute daemon
  ## igsuited (perl webmail) to retrieve messages
  ## igsuited (perl mkstruct.pl) to mk struct after an upload
  ## igwiki (htmldoc) to get pdf version of a wiki page
  ## mkstruct.pl (chown)
  ## tiffedit (tiffcp)
  ## IG::DocView (convert)
  ## IG::Thumbnails (convert)
  ## IG::Utils (htpasswd)
   
  require IG::System;

  my %data = @_;

  ## Check and try to fix command path
  if ( ! -e $data{command} )
   {
    my @command = split /\/|\\/, $data{command};
    $data{command} = pop(@command);

    for ( split /:/ , $ENV{PATH} )
     {
      if (-e "$_$S$data{command}")
       {
        $data{command} = "$_$S$data{command}";
        last;
       }
     }
   }

  ## Ok let's go to execute command
  my $exec_status = IG::System::run
                     ( valid_signals => $data{valid_signals},
                       command       => $data{command},
                       stdout        => $data{stdout},
                       arguments     => $data{arguments} );
  return $exec_status;
 }

##############################################################################
##############################################################################
##############################################################################
##############################################################################

=head2 Javascript functions

=cut

##############################################################################
##############################################################################

=head3 JsExec()

Insert javascript calls

=cut

sub JsExec
 {
  my %data = @_;
  my $html;
  $data{position} ||= 'inline';

  if ( $data{position} eq 'footer' && !$data{src} )
   {
    ## store javascript code
    $js_code{$data{position}} .= $data{code} . "\n";
   }
  else
   {
    ## It's an inline javascript
    $html = "\n<script type=\"text/javascript\" ".
            ( $data{src}
              ? "src=\"$data{src}\">"
              : "language=\"javascript\">\n<!--\n$data{code}\n//-->\n" ).
            "</script>\n";

    defined wantarray ? return $html : PrOut $html;
   }
 }

##############################################################################
##############################################################################

=head3 JsQuote($TextToQuote)

Quote a string to correctly insert it as a javascript var

=cut

sub JsQuote
 {
  my (@row) = @_;
  for (@row)
   {
    $_ = MkEntities($_);
    s/\&#39\;/\'/g;
    s/(\’|\'|\\)/\\$1/g;
    s/\n/\\n/g;
    s/\r/\\r/g;
   }
  return (wantarray ? @row : $row[0]);
 }

##############################################################################
##############################################################################

=head3 JsConfirm($TextToAlert)

Write a right and well quoted javascript confirm('string')

=cut

sub JsConfirm
 {
  my $message = shift;
  $message = JsQuote($message);
  return "return confirm('$message');";
 }

##############################################################################
##############################################################################

=head3 TextConvert($TextToConvert)

Convert text from/to different encodings

=cut

sub TextConvert
 {
  ## we have to disable traps beacuse some old release of Encode.pm use eval {}
  local $SIG{__DIE__};
  local $SIG{__WARN__};

  my %data = @_;
  my $converted = $data{text};
  $data{tocode} ||= $IG::lang_charset;  

  if ( !$data{fromcode} || $data{fromcode} eq 'auto' )
   {
    ## try to guess fromcode by contenttype
    ( $data{fromcode} ) = $data{content_type} =~ /^text\/(?:plain|html)
                                                  .+
                                                  charset\s*\=[\'\"\s]*
                                                  ([^\'\"\s\;]+)/ixs;
   }

  if ( $data{content_type} =~ /^text\/html/i || CkHtml( $data{text} ) )
   {
    ## it's an html page guess fromcode from html meta tag
    $converted =~ s/(<meta\s)
                    ([^>]+)
                    (text\/html\;\s*charset\s*\=[\s\'\"]*)
                    ([^\'\"\>\s]+)
                    ([^>]*)
                   /$1$2$3$data{tocode}$5/xi;

    $data{fromcode} = $4 if !$data{fromcode} || $data{fromcode} eq 'auto';
   }

  return $data{text} if     $data{fromcode} eq 'auto'
                        || !$data{fromcode}
                        || !$data{text};

  ## try to use Encode
  eval { require Encode };
  if ( !$@ )
   {
    $data{fromcode} = 'utf8' if $data{fromcode} =~ /utf\-8/i;
    my $_from = Encode::find_encoding( $data{fromcode} );
    my $_to   = Encode::find_encoding( $data{tocode} );
    if ( $_from && $_to )
     {
      eval { no strict "subs";
             Encode::from_to( $converted,
                              $data{fromcode}, $data{tocode},
                              520 ); }; # 520 = Encode::FB_HTMLCREF

      return $converted if !$@;
     }
   }

  ## try to convert text by iconv
  eval { require Text::Iconv };
  if ( !$@ )
   {
    my $_conv_tmp;
    eval { Text::Iconv->raise_error(1);
           my $converter = Text::Iconv->new( $data{fromcode},$data{tocode} );
           $_conv_tmp = $converter->convert( $converted ); };

    return $_conv_tmp if !$@;
   }

  ## no available modules to convert between encoding
  ## we will use last chance... dirty convert from utf8
  $data{text} =~ s/([\xC2\xC3])([\x80-\xBF])
                  /chr(ord($1)<<6&0xC0|ord($2)&0x3F)/egx;

  return $data{text};
 }

##############################################################################
##############################################################################
##############################################################################
##############################################################################

=head2 DataBase access

=cut

##############################################################################
##############################################################################

=head3 DbQuote($TextToQuote)

Quote the string you pass to be inserted correctly in the database

=cut

sub DbQuote
 {
  my (@row) = @_;
  for (@row)
   {
    s/(\’|\')/\'\'/g;
    s/\\/\\\\/g if $db_driver ne 'sqlite';
   }
  return (wantarray ? @row : $row[0]);
 }

##############################################################################
##############################################################################

=head3 QuoteParams()

Quote all %on values to %in

=cut

sub QuoteParams
 {
  undef %in;
  foreach my $k ( keys %on )
   {
    next if ref($on{$k});
    $in{$k} = DbQuote($on{$k});
    $in{$k} =~ s/\s+$//; ## trim end spaces
   } 
 }

##############################################################################
##############################################################################

=head3 DbQuery()

Simple DataBase query interface. You can pass your query as a string and it
do the rest according to db_xxxxx parameters in configuration file. You can specify
a connection_id if you want make more connections to database to do different queries.

=cut

sub DbQuery
 {
  my %data = @_;

  ## set a connection id
  $data{connection_id} ||= $data{type} eq 'UNNESTED' ? 12
                         : $data{type} eq 'NESTED'   ? 14
                         : undef;

  my $dbconn   = $data{connection_id};
     $dbconn ||=    (defined wantarray && $data{type} ne 'DEFAULT')
                 || $data{type} eq 'AUTO'
               ? ++$queryid
               : '0';

  ## reduce if possible!
  die("Internal error: To many database connection!\n")
    if $queryid > 10; 

  ## Parse arguments for single query or transaction query
  my $qry; ## SQL query string
  if ( $data{query} )
   {
    if ( ref($data{query}) eq 'ARRAY')
     {
      ## we need the same dbconn_id to use in all queries
      DbQuery ( query         => 'BEGIN',
                connection_id => $dbconn );

      DbQuery ( query         => $_,
		connection_id => $dbconn ) for grep {$_} @{$data{query}};

      DbQuery ( query         => 'COMMIT',
                connection_id => $dbconn );
      return $dbconn;
     }
    else
     {
      $qry = $data{query};
     }
   }
  else
   {
    ($qry) = @_;
   }

  ## set a database connection reference using the connection id
  my $dbase = $db_name . $dbconn;

  ## Check action in the query (we accept only this subset of sql language)
  $qry =~ /^(insert|delete|select|update|copy|commit|begin|rollback)/i;
  croak('Wrong Sql query') if !$1;
  my $qry_action = lc($1);

  if ( $db_driver eq 'mysql' )
   {
    ## MYSQL DRIVER #################################################
    eval 'require DBI';
    die("No DBI module found!\n") if $@; 

    if (!$conn{$dbase}{connection})
     {
      if ( $ENV{IG_DEBUG_ID} )
       { push @{$debug_info{db_queries}}, [$dbconn, 'New connection']; }

      $conn{$dbase}{connection}
        = DBI->connect( "DBI:mysql:".
                         "database=$db_name:".
                         "host=$db_host:".
                         "port=$db_port",
 			$db_login,
			$db_password, { PrintError => 0,
				  	RaiseError => 0,
					AutoCommit => 1
				      }
                      ) or die( "Can't connect to DataBase '$db_name'. ".
                                "When my query was: '$qry'. Server return: ".
                                "'$DBI::errstr'" );
     }

    ## Traslate query from postgres to Mysql
    $qry =~ s/\'(\d\d)\-(\d\d)\-(\d\d\d\d)\'/\'$3\-$2\-$1\'/g
            if $date_format eq 'European';
    $qry =~ s/\'(\d\d)\.(\d\d)\.(\d\d\d\d)\'/\'$3\.$2\.$1\'/g
            if $date_format eq 'German';
    $qry =~ s/\'(\d\d)\/(\d\d)\/(\d\d\d\d)\'/\'$3\/$1\/$2\'/g
            if $date_format eq 'Sql';

    if ( $qry_action ne 'insert' )
     {
      $qry =~ s/substr\(/substring\(/gi;
      $qry =~ s/\s*\~\*\s*\'/ regexp \'/g;
      $qry =~ s/random\(\)/rand\(\)/gi;
     }

    $result[$dbconn] = $conn{$dbase}{connection}->prepare($qry);
    if (!$result[$dbconn])
     {
       my $mes = $conn{$dbase}{connection}->errstr;
       $conn{$dbase}{connection}->rollback;
       die("IG Database Error: [$mes in Query: $qry; ID: $dbconn]\n".
	   "Try to execute 'mkstruct.pl' script.\n");
     }

    $result[$dbconn]->execute();
    my $ris = $result[$dbconn]->err;
    if ( $ris )
     {
      my $mes = $conn{$dbase}{connection}->errstr;
      $conn{$dbase}{connection}->rollback;
      die("IG Database Error: [$ris:$mes in Query: $qry; ID: $dbconn]\n".
          "Try to execute 'mkstruct.pl' script.\n");
     }

    if ($qry_action eq 'select')
     {
      $db_fields_num[$dbconn] = $result[$dbconn]->{NUM_OF_FIELDS};
      for ( 0 .. $db_fields_num[$dbconn] )
       {
        $db_fields_name[$dbconn][$_]
	   = $result[$dbconn]->{mysql_type_name}->[$_];
       }
     }
   }
  elsif ( $db_driver eq 'pg' )
   {
    ## DBD::PG DRIVER #################################################
    eval 'require DBI';
    die("No DBI module found!\n") if $@; 

    if ( ! $conn{$dbase}{connection} || ! $conn{$dbase}{connection}->ping )
     {
      if ( $ENV{IG_DEBUG_ID} )
       { push @{$debug_info{db_queries}}, [$dbconn, 'New connection']; }

      ## try to re-connect
      $conn{$dbase}{connection}
        = DBI->connect( "dbi:Pg:".
                         "dbname=$db_name;".
                         "host=$db_host;".
                         "port=$db_port",
 			$db_login,
			$db_password, { PrintError => 0,
				  	RaiseError => 0,
					AutoCommit => 1
				      }
                      ) or die( "Can't connect to DataBase '$db_name'. ".
                                "When my query was: '$qry'. Server return: ".
                                "'$DBI::errstr'" );

      my $fake_date_format = $date_format eq 'European'
                           ? 'European, SQL'
                           : $date_format;

      ## change date format
      $result[$dbconn]
        = $conn{$dbase}{connection}->do("set DateStyle='$fake_date_format'");
      $result[$dbconn]=$conn{$dbase}{connection}->do("SET CLIENT_ENCODING='$IG::postgres_charset'");

     }

    if ( $qry eq 'COMMIT' )
     {
      $conn{$dbase}{connection}->commit();
     }
    elsif ( $qry eq 'BEGIN')
     {
      $conn{$dbase}{connection}->begin_work();
     }
    else
     {
      $result[$dbconn] = $conn{$dbase}{connection}->prepare( $qry );
      if ( !$result[$dbconn] )
       {
        my $mes = $conn{$dbase}{connection}->errstr;
        $conn{$dbase}{connection}->rollback();
        die("IG Database Error: ".
            "['$mes' in prepare Query: '$qry'; ID: $dbconn]\n".
            "Try to execute 'mkstruct.pl' script.\n");
       }

      $result[$dbconn]->execute();
      my $ris = $result[$dbconn]->err;
      if ( $ris )
       {
        my $mes = $conn{$dbase}{connection}->errstr;
        $conn{$dbase}{connection}->rollback();
        die("IG Database Error: ".
            "[$ris:$mes in execute Query: $qry; ID: $dbconn]\n".
            "Try to execute 'mkstruct.pl' script.\n");
       }
     }
   }
  elsif ( $db_driver eq 'sqlite' )
   {
    ## SQLITE DRIVER ################################################
    eval 'require DBI';
    die("No DBI module found!\n") if $@; 

    if ( !$conn{$dbase}{connection} )
     {
      if ( $ENV{IG_DEBUG_ID} )
       { push @{$debug_info{db_queries}}, [$dbconn, 'New connection']; }

      $conn{$dbase}{connection}
         = DBI->connect( "DBI:SQLite:".
			  "dbname=$cgi_dir${S}data${S}$db_name.sqlite",
      			 $db_login,
			 $db_password, { PrintError => 0,
				         RaiseError => 0,
					 AutoCommit => 1 }
                       ) or die( "Can't connect to DataBase '$db_name'. ".
                                 "When my query was: '$qry'. Server return: ".
                                 "'$DBI::errstr'" );
     }

    if ( $qry_action ne 'insert' )
     {
      $qry =~ s/\~\*\s*\'([^\']*)\'/ like \'\%$1\%\'/g;
     }

    $result[$dbconn] = $conn{$dbase}{connection}->prepare($qry);
    if (!$result[$dbconn])
     {
       my $mes = $conn{$dbase}{connection}->errstr;
       $conn{$dbase}{connection}->rollback;
       die( "IG Database Error: [$mes in Query: $qry; ID: $dbconn]\n".
	    "Try to execute 'mkstruct.pl' script.\n" );
     }

    $result[$dbconn]->execute();
    my $ris = $result[$dbconn]->err;
    if ( $ris )
     {
      my $mes = $conn{$dbase}{connection}->errstr;
      $conn{$dbase}{connection}->rollback;
      die( "IG Database Error: [$ris:$mes in Query: $qry; ID: $dbconn]\n".
           "Try to execute 'mkstruct.pl' script.\n" );
     }
    undef $result[$dbconn] if $qry_action ne 'select';
   }
  else
   {
    ## POSTGRESQL DRIVER ############################################
    eval 'require Pg';
    Pg->import;
    die("No 'Pg.pm' perl module found! remember Pg.pm is different ".
        "from DBD::Pg!\n") if $@; 

    if ( !$conn{$dbase}{connection} )
     {
      if ( $ENV{IG_DEBUG_ID} )
       { push @{$debug_info{db_queries}}, [$dbconn, 'New connection']; }

      $conn{$dbase}{connection} = Pg::setdbLogin( $db_host,
      				                  $db_port,
				                  '',
				                  '',
				                  $db_name,
				                  $db_login,
				                  $db_password );

      die( "Can't connect to DataBase $db_name queryid $dbconn ".
           "check IGSuite or RDBMS configuration files.\n")
        if $conn{$dbase}{connection}->status ne Pg->PGRES_CONNECTION_OK;

      my $fake_date_format = $date_format eq 'European'
                           ? 'European, SQL'
                           : $date_format;

      $result[$dbconn]
        = $conn{$dbase}{connection}->exec("set DateStyle='$fake_date_format'");
			$result[$dbconn]=$conn{$dbase}{connection}->exec("SET CLIENT_ENCODING='$IG::postgres_charset'");
     }

    $result[$dbconn] = $conn{$dbase}{connection}->exec($qry);

    my $ris = $result[$dbconn]->resultStatus;
    if ( $ris ne Pg->PGRES_COMMAND_OK && $ris ne Pg->PGRES_TUPLES_OK )
     {
      my $mes = $conn{$dbase}{connection}->errorMessage || 'No error message';
      croak("IG Database Error: [$ris:$mes; in Query: '$qry'; Id: $dbconn]\n".
            "Try to execute 'mkstruct.pl' script.\n");
     }
   }

  ## store debug info if requested
  if ( $ENV{IG_DEBUG_ID} )
   { push @{$debug_info{db_queries}}, [$dbconn, $qry]; }

  return $dbconn if defined wantarray;
 }

##############################################################################
##############################################################################

=head3 DbWrite()

Simple DataBase query interface to insert or update records.

=cut

sub DbWrite
 {
  my @queries;
  my %data = @_;

  $data{action} ||= 'insert';
  die("Table name is missing!\n") if !$data{table};

  if ( $data{action} eq 'insert' )
   {
    ## Check overwrite clause
    push @queries, "DELETE FROM $data{table} ".
                   "WHERE $data{overwrite_clause}" if $data{overwrite_clause};

    ## Build query
    if ( ref( $data{values} ) eq 'HASH' )
     {
      my $key    = join ',', keys %{$data{values}};
      my $values = join ',',
                   map { "'".DbQuote( $_ )."'" } values %{$data{values}};

      push @queries, "INSERT INTO $data{table} ($key) VALUES ($values)";
     }
    elsif ( ref( $data{values} ) eq 'ARRAY' )
     {
      my $values = join ',',
                   map { "'".DbQuote($_)."'" } @{$data{values}};

      push @queries, "INSERT INTO $data{table} VALUES ($values)";
     }
    else
     {
      die("Invalid 'values' data!\n");
     }
   }

  ## Execute query by DbQuery
  my $cid = DbQuery( query         => $data{overwrite_clause}
                                   ?  \@queries
                                   :  $queries[0], ## to avoid transaction
                     connection_id => $data{connection_id},
                     type          => $data{connection_id}
                                   ?  ''
                                   :  defined wantarray
                                      ? 'AUTO'
                                      : 'UNNESTED' );

  return $cid;
 }

##############################################################################
##############################################################################

=head3 FetchRow()

After a query with DbQuery() gets an array for each rows returned from
DataBase.

=cut

sub FetchRow
 {
  my $dbconn = shift || 0;
  my @results;

  if ($db_driver eq 'mysql' || $db_driver eq 'sqlite')
   {
    if ( @results = ($result[$dbconn]->fetchrow_array()) )
     {
      for ( 0 .. $db_fields_num[$dbconn] )
       {
        if ( $db_fields_name[$dbconn][$_] eq 'date' )
         {
          if    ($date_format eq 'European')
	   { $results[$_] =~ s/(....).(..).(..)/$3\-$2\-$1/; }
          elsif ($date_format eq 'German')
           { $results[$_] =~ s/(....).(..).(..)/$3\.$2\.$1/; }
          elsif ($date_format eq 'Sql')
           { $results[$_] =~ s/(....).(..).(..)/$2\/$3\/$1/; } 
         }
       }
      return wantarray ? @results : join "\t", @results;
     }
   }
  elsif ($db_driver eq 'pg')
   {
    if ( @results = ($result[$dbconn]->fetchrow_array()))
     {
      return wantarray ? @results : join "\t", @results;
     }
   }
  else
   {
    return wantarray ? ($result[$dbconn]->fetchrow)
		     : join "\t", ($result[$dbconn]->fetchrow);
   }

  ## No more data then Finish
  DbFinish($dbconn);
  return;
 }

##############################################################################
##############################################################################

=head3 FetchGroupedRows() 

Filters rows returned by FetchRow() to group rows according to given columns 
(like SQL 'GROUP BY') data variation, one or more column can be string 
concatenated with a given separator.

To be used to concat one ore more column data when a LEFT JOIN for a 1 to n 
table relation. 

Parameters: 
groupByIndexes    => index | [index1, index2, ...] 
                     the indexes of the column to be checked for variation
                     (like the column listed in a GROUP BY sql statement. 

to_concat_indexes => index | [index1, index2, ...] 
                     the indexes of the column to be concatenated in the
                     returned row 

concat_separator  => ', ' 
                     the separator to be used in column concatenation,
                     the default is ', ' 

connection_id     => the connection number used with DbQuery()

=cut

sub FetchGroupedRows
 {
  my %data = @_; 
  my $dbconn = $data{connection_id} || 0;
  my $dbase  = $db_name . $dbconn;

  ## "grouprows_status" 0 = initial status, 
  ##                    1 = previous data stored in {grouprows_next_result}
  ##                    2 = no more data 

  if ( $conn{$dbase}{grouprows_status} == 2 ) 
   { 
    ## no more data, reinit FetchGroupedRows 
    $conn{$dbase}{grouprows_status} = 0;
    return ();
   }

  ## indexes of columns to group by (when one or more columns of these change 
  ## grouped row is returned 
  my $group_by_indexes = $data{group_by_indexes}; 
     $group_by_indexes = [$group_by_indexes] if !ref($group_by_indexes); 

  ## indexes of column to concat in the returned row 
  my $to_concat_indexes = $data{to_concat_indexes}; 
     $to_concat_indexes = [$to_concat_indexes] if !ref($to_concat_indexes); 
                     
  my $concat_separator = $data{concat_separator} || ', '; 

  my @groupedRow; ## the data that will be returned 

  if ( $conn{$dbase}{grouprows_status} == 0 ) ## first GroupRows call 
   {
    ## load first row
    @groupedRow = FetchRow($dbconn); 

    ## mark we have already got first row
    $conn{$dbase}{grouprows_status} = 1 if @groupedRow;
   } 
  else
   {
    ## resume row fetched on previous FetchGroupedRows call 
    @groupedRow = @{$conn{$dbase}{grouprows_next_result}};
   }

  while ( @groupedRow ) 
   { 
    ## read next row 
    @{$conn{$dbase}{grouprows_next_result}} = FetchRow($dbconn);

    if ( !@{$conn{$dbase}{grouprows_next_result}} ) ## no more rows 
     { 
      ## next call to FetchGroupedRows will returns 0 
      ## exit from the "while" and return @groupedRow 
      $conn{$dbase}{grouprows_status} = 2; 
      last;                  
     } 
 
    my $changed = 0; ## flag to check grouped columns 
                     ## check if any of the columns whose indexes are listed in
                     ## $group_by_indexes is changed 

    foreach my $i (@$group_by_indexes) 
     { 
      if ( $conn{$dbase}{grouprows_next_result}[$i] ne $groupedRow[$i] ) 
       { 
        $changed = 1;         ## we found a changed column 
        last;                 ## we need no more checks 
       } 
     }

    last if $changed; ## {grouprows_next_result} is for next GroupRows() call 
                      ## concat columns

    foreach my $i (@$to_concat_indexes)
     {
      $groupedRow[$i] .= $concat_separator.
                         $conn{$dbase}{grouprows_next_result}[$i];
     }
   }
  return @groupedRow;
 }

##############################################################################
##############################################################################

=head3 DbFinish()

Only needed when you have not fetched all the possible rows

=cut

sub DbFinish
 {
  my $dbconn = shift || 0;
  $result[$dbconn]->finish() if    defined $result[$dbconn]
                                && $db_driver ne 'postgres';
  undef $result[$dbconn];
  return 1;
 }

##############################################################################
##############################################################################

=head3 DbDisconnect()

Close all Database connections

=cut

sub DbDisconnect
 {
  if ( $db_driver ne 'postgres')
   {
    foreach my $con_id ( keys %conn )
     {
      $con_id =~ /(\d+)$/;
      DbFinish($1);
      $conn{$con_id}{connection}->disconnect();
     }
   }

  undef %conn;
  $queryid = 0;
  @result = ();
 }

##############################################################################
##############################################################################

=head3 DbDump()

Dump out a database query result.

=cut

sub DbDump
 {
  my ($query) = (@_);
  my $results;
  croak('Bad Sql query to dump') if $query !~ /^select/i;
  my $cid = DbQuery( query => $query, type => 'UNNESTED' );
  PrOut "$results\n" while ($results = FetchRow($cid));
 }

##############################################################################
##############################################################################

=head3 MkLastNum()

MkLastNum() make a new sequential document protocol.
Example: I<200123.02> (where 02 rappresenting 2002 year)

=cut

sub MkLastNum
 {
  my $table = shift;
  my $year  = substr( $tv{session_year}, -2, 2);

                                    #prefix     #field  #ckdir
  my %doc_info = ( contracts	=> [ 1,		'id',	'yes'],
		   offers	=> [ 2,		'id',	'yes'],
		   nc_int	=> [ 3,		'id',	'yes'],
		   nc_ext	=> [ 4,		'id',	'yes'],
		   letters	=> [ 5,		'id',	'yes'],
		   fax_sent	=> [ 6,		'id',	'yes'],
		   fax_received	=> [ 7,		'id',	'yes'],
		   archive	=> [ 8,		'id',	'yes'],
		   orders	=> [ 9,		'id',	'yes'],
		   email_msgs	=> [ 'E',	'pid',	''   ],
		   binders      => [ 'F',       'id',   ''   ],
		 );

  my $cid = DbQuery( query => "SELECT $doc_info{$table}[1] ".
                              "FROM $table ".
                              "WHERE substr($doc_info{$table}[1],8,2)='$year' ".
                              "ORDER BY $doc_info{$table}[1] desc LIMIT 1",
                     type  => 'UNNESTED' );

  my $new_num = FetchRow($cid);
     $new_num ||= $doc_info{$table}[0] . '00000.' . $year;

  unless ( $new_num =~ s/(\w)(\d\d\d\d\d)\.(\d\d)
                        /$1.substr("00000".($2+1),-5,5).".$3"/ex )
   {
    die("Ther's a wrong protocol number '$new_num' in table '$table'. ".
        "You have to try to delete it manually");
   } 

  ## Check document protocol directory
  CkProtocolDir($table, $year) if $doc_info{$table}[2];

  return $new_num;
 }

##############################################################################
##############################################################################

=head3 MkId()

Generate an unique and random Id number.

=cut

sub MkId
 {
  my $len = shift || 15;
  my $id = time;
  $id .= ('0'..'9','a'..'z', 'A'..'Z')[rand(62)] for 11..$len;
  return $id;
 }

1;

=head1 TODO

Features to do are written on our Wiki site www.igsuite.org.

=head1 AUTHORS

This module was created by Luca Dante Ortolani E<lt>lucas@igsuite.orgE<gt>
in October 1998.

=head1 COPYRIGHT

Copyright (c) 1998-2004.
This is free software; see the source for copying conditions.
There is NO warranty; not  even  for  MERCHANTABILITY  or FITNESS FOR A
PARTICULAR PURPOSE.

=head1 SEE ALSO

perl(1), DBI(3), Mysql(3), Postgres, and sure http://www.igsuite.org

=cut

##############################################################################
##############################################################################
### From here in next future we could use SelfLoader                       ###
##############################################################################
##############################################################################

=head3 HTitle(%data)

Make a title

=cut

sub HTitle
 {
  my %data = @_;
  return if !$data{title};
  $data{level} ||= 5;
  $data{style} &&= " style=\"$data{style}\"";
  my $html = "<h$data{level}$data{style}>$data{title}</h$data{level}>\n";

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 RelatedTo($doc_id)

Make a task list containing document related to $doc_id.

=cut

sub RelatedTo
 {
  my ($id, $contactid) = @_;
  my $query;
  my @related =
      ( ["contracts?action=proto&amp;docref=$id&amp;contactid=$contactid",
         $lang{contract} ],
        ["offers?action=proto&amp;note1=$id&amp;contactid=$contactid",
         $lang{offer} ],
        ["nc_int?action=proto&amp;docref=$id&amp;contactid=$contactid",
         $lang{nc_int} ],
        ["nc_ext?action=proto&amp;docref=$id&amp;contactid=$contactid",
         $lang{nc_ext} ],
        ["letters?action=proto&amp;docref=$id&amp;contactid=$contactid",
         $lang{letter} ],
        ["archive?action=proto&amp;docref=$id&amp;contactid=$contactid",
         $lang{archive} ],
        ["orders?action=proto&amp;docref=$id&amp;contactid=$contactid",
         $lang{order} ],
        ["binders?action=proto&amp;note=$id&amp;contactid=$contactid",
         $lang{binder} ],
      );

  my $html
     = $on{print}
     ? "<strong>$lang{related_documents}</strong>"
     : HLayer
        ( left_layers
          => [( HTitle( title => $lang{related_documents},
	                style => "margin:0; padding:0; line-height:0px" ) )],
          right_layers
          => [( "<div style=\"font-size:10px; margin-right:3px;\">".
                "$lang{new_related_document}</div>",
                Input(  name      => 'add_related',
                        style     => 'font-size:10px',
                        type      => 'select',
                        zerovalue => 'true',
                        data      => \@related,
                        onchange  => "location.href = this.options[this.selectedIndex].value;") )]
        );

  $html .= TaskListMenu([$lang{number}],
			[$lang{contact_name}],
			[$lang{document_type}],
			[$lang{rif}],
			[$lang{references}],
			[$lang{issue}],
			[$lang{rif}],
			[$lang{due_date}],
		 );
 
  $id = DbQuote($id);
  
  ## to optimize speed we will use a default connection id!
  DbQuery("SELECT id, contactname, 'contracts', issue, docref, expire,".
	  " owner, note, '', expire-current_date ".
	  "FROM contracts where docref~*'$id' or note~*'$id' ".
	  "UNION ".
	  "SELECT id, contactname, 'offers', issue, '', expire,".
	  " owner, note1, note, expire-current_date ".
	  "FROM offers where note1~*'$id' or note~*'$id' ".
	  "UNION ".
	  "SELECT id, contactname, 'nc_int', issue, '',".
	  " '$tv{empty_date}', owner, note, '', 0 ".
	  "FROM nc_int where docref~*'$id' or note~*'$id' ".
	  "UNION ".
	  "SELECT id, contactname, 'nc_ext', issue, '',".
	  " '$tv{empty_date}', owner, note, '', 0 ".
	  "FROM nc_ext where docref~*'$id' or note~*'$id' ".
	  "UNION ".
	  "SELECT id, contactname, 'letters', issue, '',".
	  " '$tv{empty_date}', owner, note, '', 0 ".
	  "FROM letters where docref~*'$id' or note~*'$id' ".
	  "UNION ".
	  "SELECT id, contactname, type, issue, docref, expire,".
	  " owner, note, '', expire-current_date ".
	  "FROM archive where docref~*'$id' or note~*'$id' ".
	  "UNION ".
	  "SELECT id, contactname, 'orders', issue, docref, expire,".
	  " owner, note, '', expire-current_date ".
	  "FROM orders where docref~*'$id' or note~*'$id' ".
	  "UNION ".
	  "SELECT id, contactname, 'fax_received', issue, '',".
	  " '$tv{empty_date}', owner, note, '', 0 ".
	  "FROM fax_received where docref~*'$id' or note~*'$id' ".
	  "UNION ".
	  "SELECT id, contactname, 'fax_sent', issue, '',".
	  " '$tv{empty_date}', owner, note, '', 0 ".
	  "FROM fax_sent where docref~*'$id' or note~*'$id' ".
          "UNION ".
          "SELECT binders.id, binders.name, 'binders', binders.issue,".
          " '', '$tv{empty_date}', binders.owner, binders.note, '', 0 ".
          "FROM binders ".
          "LEFT JOIN bindeddocs ON binders.id=bindeddocs.binderid ".
          "WHERE bindeddocs.docid='$id' ".

	  "ORDER by issue desc");

  while ( my @row = FetchRow() )
   {
    $row[5] = CkDate($row[5]);
    $row[5] = IG::Blush($row[5]) if $row[9]<1;
    $row[2] = $lang{$row[2]} ? $lang{$row[2]} : $docs_type{$row[2]};

    $html .= TaskListItem( [ ParseLink($row[0]) ],
                           [ $row[1] ],
                           [ $row[2] ],
                           [ UsrInf('initial',$row[6]) ],
                           [ MkLink("$row[7] $row[8]") ],
                           [ $row[3], '', 'nowrap' ],
                           [ MkLink($row[4]) ],
                           [ $row[5], '', 'nowrap' ],
                         );
   }
  $html .= TaskListFoot(2);

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 BuildDoc()

Build and save in the protocol a new document.

=cut

sub BuildDoc
 {
  my %data = @_;
  $data{type}    ||= $cgi_name;
  $data{id}      ||= $on{id};
  $data{choice}  ||= $on{builddoc_choice};
  $data{source}  ||= $on{'builddoc_source'.$data{choice}};

  if ( $data{choice} == 2 )
   {
    ## build doc from an external file

    HtmlHead();
    TaskHead(   title => $lang{$data{type} . '_protocol'} );

    FormHead(	enctype=>'multipart/form-data',
		formaction=>'igsuite',
		name=>'docupload',
		cgiaction=>'documentupload');

    Input (	type=>'hidden',
		name=>'id' );

    Input (	type=>'file',
		label=>$lang{import_filename},
		name=>'upfile',
		size=>20);

    Input (	type=>'submit',
		name=>'import',
		onclick=>IG::CallMeter('docupload.upfile.value'),
		show=>$lang{send});

    Input (	type=>'submit',
		name=>'abort',
		float=>'left',
		value=>$lang{abort});
    FormFoot();
    TaskFoot();
    HtmlFoot();
    return;
   }
  elsif ( $data{choice} == 3 )
   {
    ## build doc from an html template
    if ( $data{source} ne 'Only_protocol' )
     {
      require IG::Utils;
      IG::ParseDoc( $data{type},
                    $data{source},
                    $data{id} ) or return;
     }
   }
  elsif ( $data{choice} == 4 )
   {
    ## build doc from an existing protocol
    my ($docfile, $docpath, $doctype) = IG::ProtocolToFile( $data{source} );

    push @IG::errmsg,
         $lang{Err_nodocument} if !$docfile;

    ## Check document accessibility
    IG::CheckResourcePrivileges( $data{source}, 'r' ) if $data{source};

    push @IG::errmsg,
         $lang{Err_privileges} if !CheckPrivilege($doctype.'_view');
    
    if ( @IG::errmsg )
     {
      $on{id} = $data{id};
      $app_nspace->proto();
      return;
     } 

    my ($ext) = $docfile =~ /\.([^\.]+)$/;
    die("We need an extension! check '$docfile' file or rename it\n") if !$ext;
    $data{id} =~ /(\d\d\d\d\d\d)\.(\d\d)/;

    ## Check document protocol directory
    CkProtocolDir($data{type}, $2);

    IG::TrashDoc("$1.$2");
    IG::FileCopy($docpath . $S . $docfile,

		 $htdocs_dir . $S .
		 $IG::default_lang{$data{type}} . $S .
		 $2 . $S .
		 Crypt($data{id}) . '.' . $ext,

		 0);
    LogD("Copy document from $data{source}",
	 'update',
	 $data{type},
	 "$1.$2");
   }
  elsif ( $data{choice} == 5 )
   {
    ## copy doc from an existing print file spool
    my $docfile = $htdocs_dir . $S . $default_lang{$data{type}} .
                  $S . '.print_spool_file_' . $remote_host;
    my ($docfilename) = (<$docfile.*>);
    croak("Any print spool file in '$docfile'") if ! -e $docfilename;
    my ($ext) = $docfilename =~ /\.([^\.]+)$/;
    die("We need an extension! ".
        "check '$docfilename' file or rename it.\n") if !$ext;

    $data{id} =~ /(\d\d\d\d\d\d)\.(\d\d)/;

    ## Check document protocol directory
    CkProtocolDir($data{type}, $2);

    IG::TrashDoc("$1.$2");
    IG::FileCopy($docfilename,

		 $htdocs_dir . $S .
		 $IG::default_lang{$data{type}} . $S .
		 $2 . $S .
		 Crypt($data{id}) . '.' . $ext,

		 1);
    LogD('Copy document from print file spool',
	 'update',
	 $data{type},
	 "$1.$2");
   }

  IG::Redirect(    $on{backtoreferer} 
                || "$data{type}?action=docview&amp;id=$data{id}" );
 }

##########################################################################
##########################################################################

=head3 Logout()

Delete user session file.

=cut

sub Logout
 {
  my ($user, $session) = @_;
  $user    ||= $auth_user;
  $session ||= "$user-session-";

  opendir (DIR, $logs_dir)
    or die("Can't open directory '$logs_dir' to read session files. ".
           "Try to check the directory privileges.\n");
           
  foreach (grep /^$session/, readdir DIR)
   {
    unlink "$logs_dir$S$_"
      or die("Can't delete '$user' session file '$_' from '$logs_dir'.\n");

    CGISession( sessionid => $session,
                action    => 'clear' );

    LogD( "$_ from $remote_host",
	  'logout',
	  'users',
	  $1 ) if /^([A-Za-z\_][A-Za-z0-9\_\-\.]{1,31})\-session\-.+$/;
   }

  close (DIR);
 }

##########################################################################
##########################################################################

=head3 FileTouch($filename)

Touch a file

=cut

sub FileTouch
 {
  my $file = shift;
  return if !$file;
  CkPath( $file );

  if ( -e $file )
   {
    utime(time(), time(), $file) or croak("Can't touch file '$file'.");
   }
  else
   {
    open(TOUCH, '>', $file) or croak("Can't touch file '$file'.");
    close(TOUCH) or croak("Can't touch file '$file'.");
   }
 }

##########################################################################
##########################################################################

=head3 DirWalk($dir_to_walk, $action)

Walk across a dir and return a list of directory total space and total files

=cut

sub DirWalk
 {
  my ($dir, $action) = @_;
  croak('You have to specify a directory') if !$dir;
  my $cached_dir_path = $temp_dir . $S . Crypt( $dir ) . '.dir';
  my @dirs;
  my $space;
  my $files_total = 0;

  if (    $action eq 'cache'
       && -e $cached_dir_path
       && -M $cached_dir_path < ( 1/24 ) # expire after 1 hour
     )
   {
    ## read data from cache
    open ( my $FH, '<', $cached_dir_path )
      or die("Can't read from '$cached_dir_path'.\n");
    $space       = <$FH>;
    $files_total = <$FH>;
    @dirs = map { chomp; $_ } <$FH>;
    close $FH;
   }
  else
   {
    ## walk dir && write data on a new cache file
    require IG::FileFind;
    File::Find::find( sub{ ( -d && $File::Find::name !~ /(\/|^)\./ )
                             ? push( @dirs, $File::Find::name )
                             : ! /^\./
			       ? do{ $space += (stat($_))[7]; $files_total++ }
			       : 0
                         }, $dir);
    @dirs = sort @dirs;
    
    if ( $action eq 'cache' || $action eq 'update' )
     {
      open ( my $FH, '>', $cached_dir_path )
        or die("Can't write on '$cached_dir_path'.\n");
      print $FH "$space\n$files_total\n";
      print $FH "$_\n" for @dirs;
      close $FH;
     }
   }

  return ($space, $files_total, @dirs);
 }

##########################################################################
##########################################################################

=head3 FileStat( $file_path )

Get a file content type by File::MMagic

=cut

sub FileStat
 {
  my ($file_type, $file_size, $file_lasttime, $file_lastdate);
  require IG::FileMMagic;
  my ($file_doc, $arg_type) = @_;
  my $mm = new File::MMagic;

  if ( $arg_type eq 'content' )
   {
    $file_type = $mm->checktype_contents( $file_doc );
    $file_size = length( $file_doc );
   }
  else
   {
    ## we have a file path
    $file_type = $mm->checktype_filename( $file_doc );
    $file_type = $lang{unknown} if $file_type =~ /x\-system\/x\-error/;

    ## fix opendocuments viewed as zipped files
    if ( $file_type eq 'application/x-zip' )
     {
      $file_type = 'application/msword'  if $file_doc =~ /\.(odt|sxw|doc)$/i;
      $file_type = 'application/msexcel' if $file_doc =~ /\.(ods|xls|sxc)$/i;
     }

    my @file_info = stat( $file_doc );

    ## Adjust last update date and time
    my ($s1,$m1,$h1,$g1,$me1,$a1,$w1,$y1,$i1) = localtime($file_info[9]);
    $file_lasttime = sprintf("%02d:%02d:%02d", $h1, $m1, $s1);
    $file_lastdate = GetDateByFormat( $g1, ($me1+1), (1900+$a1) );
    $file_size     = $file_info[7];
   }

  return ($file_type, $file_size, $file_lasttime, $file_lastdate);
 }

##########################################################################
##########################################################################

=head3 FileCopy( $old_file, $new_file, $flag )

Copy a file from $old_file to $new_file and remove $old_file if $flag is
equal to '1'

=cut

sub FileCopy
 {
  my ($filein, $fileout, $remove) = @_;
  croak('You have to specify origin and target file in FileCopy()')
    if !$filein || !$fileout;

  my $lck = AutoReleasedLock->new( resource=>$fileout );

  require IG::FileCopy;
  File::Copy::copy( CkPath($filein), CkPath($fileout) )
    or croak("Can't copy '$filein' to '$fileout': $!\n");

  if ($remove) { unlink($filein) or croak("Can't delete file '$filein'\n"); }
  return 1;
 }

##########################################################################
##########################################################################

=head3 DirCopy( dir_in => $original_dir, dir_out => $new_dir )

Copy files and directories recursively

=cut

sub DirCopy
 {
  my %data = @_;
  croak('You have to specify origin and target dir in DirCopy()')
    if !$data{dir_in} || !$data{dir_out};

  require IG::FileCopyRecursive;
  if ( $data{skipflop} )
   { local $File::Copy::Recursive::SkipFlop = 1; }

  if ( $data{keepmode} eq 'false')
   { local $File::Copy::Recursive::KeepMode = 0; }

  File::Copy::Recursive::dircopy( $data{dir_in}, $data{dir_out} )
    or croak("Can't copy '$data{dir_in}' to '$data{dir_out}': $!\n");

  return 1;
 }

##########################################################################
##########################################################################

=head3 FileUnlink( $file_path )

Delete a file. Return true if the file doesn't exist or if the file was
correctly deleted

=cut

sub FileUnlink
 {
  local $!;
  my ($file_path) = @_;
  croak('You have to specify target file in FileUnlink()') if !$file_path;
  CkPath( $file_path );

  -e $file_path
  ?  unlink $file_path
  :  undef $!;
       
  my $msg = $!
            ? "Can't remove '$file_path': $!"
            : "File '$file_path' removed successfully.";
                             
  return wantarray
         ? ($msg, $! ? 0 : 1)
         : $! ? 0 : 1;
 }

##############################################################################
##############################################################################

=head3 AlphabetSelector

Create an alphabet index to select records

=cut

sub AlphabetSelector
 {
  my %data = @_;
  my $html;
  my $alphabet = '&nbsp;';
  $data{pos}        ||= $on{pos} eq 'all' ? 'all' : '1';
  $data{param}      ||= 'alphabet';
  $on{$data{param}} ||= $data{default} || 'A';
  $data{link}       ||= "$cgi_name?action=default_action";
  $data{link}        .= "&amp;pos=$data{pos}&amp;$data{param}=";

  ## Create alphabet index
  for ('A'..'Z', 'all')
   {
    $alphabet .= "<a href=\"$data{link}$_\"".
                 ( $_ ne 'all' ? " accesskey=\"$_\"" : '').
                 " style=\"height:15px; display:inline; padding:1px;".
                 " margin-right:1px; border:1px solid #b5b5b5;".
                 ( $_ eq $on{$data{param}}
                   ? "background:$clr{bg_evidence};\">"
                   : "background:$clr{bg_task};\">").
                 ( $_ eq 'all' ? $lang{all} : $_). "</a>";
   }

  $alphabet = "<span style=\"font-size: 10px\">$alphabet</span>";

  $html
  = TaskMsg(HLayer( bottom_space => 0,
		    left_layers  => [($alphabet)],
		    right_layers => [($data{filter})]
                  ),7 );

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 MkRepository

Create a repository

=cut

sub MkRepository
 {
  my %data = @_;
  my $html;
  $data{application} ||= $cgi_name;
  $data{background}  ||= $clr{bg_menu_task};
  $data{width}       ||= 650;
  $data{height}      ||= 250;

  my $repdir = "$cgi_dir${S}data${S}repository${S}".
	       "$data{application}${S}$data{id}";

  if ($data{id} && ! -e $repdir )
   { $lang{open_repository} = $lang{make_repository}; }

  if (!$data{id} ||
      ($auth_user eq 'guest' &&
       $lang{make_repository} eq $lang{open_repository} )
     )
   {
    $html = "<div style=\"clear:both; margin:3px 0 3px 0; height:18px;".
            " width:100%; background:$data{background}\"></div>\n";
   }
  else
   { 
    my ($space, $total_files, @dirs) = DirWalk($repdir);
    my $repdesc = $lang{make_repository} ne $lang{open_repository}
		? "$lang{total_files}: $total_files - ".
		  "Sub-directories: $#dirs - ".
		  "$lang{total_space}: " . MkByte($space)
                : '';
    $data{id} = MkUrl($data{id});

    ##XXX2IMPROVE use MkTable or a simple <div>
    $html = "<table class=\"tasklist\" style=\"clear:both;margin-bottom:3px;\">
		<tr><td width=\"100%\" class=\"menu\" style=\"text-align:right; font-size:10px; background:$data{background}\">
		<div style=\"float:left\">$repdesc</div>
		<script type=\"text/javascript\">
		 pv('$cgi_url/filemanager?repid=$data{id}&amp;repapp=$data{application}','1', $data{width}, $data{height}, '[$lang{open_repository}]', '[$lang{close_repository}]');
		</script>
		</td></tr>
	     </table>\n" if $tema ne 'printable_';
   }

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 TrashDoc($protocol_id)

Trash an IG document

=cut

sub TrashDoc
 {
  my $protocol = shift;

  my ($filename, $filedir, $fileproc) = ProtocolToFile($protocol);

  return 0 if !$filename || !CheckPrivilege($fileproc . '_edit');

  $filename =~ /^(.+)(\....)$/;
  my $newfilename = length($1) > 9
                  ? Crypt( $1, 'decrypt' ) . $2
                  : $filename;

  FileCopy(	$filedir . $S . $filename,
  
		$htdocs_dir . $S .
		$IG::default_lang{basket} . $S .
		$newfilename,
		
		1 );
  return 1;
 }

##############################################################################
##############################################################################

=head3 CkProtocolDir($doctype, $docyear)

Make a new dir for a new document protocol year.

=cut

sub CkProtocolDir
 {
  my ($doctype, $docyear) = @_;
  return if !$doctype;
  $docyear ||= $tv{ye};

  ## Check if directory exists
  my $doc_dir = "$htdocs_dir${S}$IG::default_lang{$doctype}${S}$docyear";
  if ( ! -e $doc_dir )
   { mkdir($doc_dir, 0777) or croak("Can't mkdir '$doc_dir'\n"); }
 }

##############################################################################
##############################################################################

=head3 LastDocuments()

Return a task with last documents link.

=cut

sub LastDocuments
 { 
  my ($element_desc, $element_href, $image_src);
  my $cnt;
  my %dejavu;
  my $html = '<br><table width="100%" cellspacing=0 cellpadding=0>';

  my %docs
   =(
     archive	  => ['mime_mini_archive.png',	$lang{archive}],
     webmail      => ['unreadmsg.gif',		$lang{email}],
     contracts    => ['mime_mini_contract.png', $lang{contract}],
     fax_received => ['mime_mini_fax.png',      'Fax'],
     fax_sent	  => ['mime_mini_fax.png',      'Fax'],
     letters      => ['mime_mini_letter.png',   $lang{letter}],
     nc_ext	  => ['mime_mini_document.png', $lang{ncext}],
     nc_int	  => ['mime_mini_document.png', $lang{ncint}],
     offers	  => ['mime_mini_offer.png',    $lang{offer}],
     orders	  => ['mime_mini_order.png',    $lang{order}],
     binders      => ['mime_mini_folder.png',   $lang{binder}],
     equipments   => ['equipments.png',
                      $lang{equipment},
                      'equipments?action=protomodi&amp;id='],
     opportunities=> ['opportunity.gif',
		      $lang{opportunities},
		      'opportunities?action=protoview&amp;id='],
     contacts	  => ['contact.gif',
		      $lang{contact},
		      'contacts?action=showrecord&amp;contactid='],
     contacts_group=> ['group.gif',
		      $lang{group}, 
		      'contacts?action=showgroup&amp;contactid='],
     products     => ['product.gif',
		      $lang{products},
		      'products?action=revisione&amp;contactid='],
     pages	  => ['mime_mini_wiki.png',
		      'IGWiki',
		      'igwiki?ig=1&amp;id='],
     reports	  => ['report.gif',
		      'Report',
		      'reports?action=loadreport&amp;id='],
     users	  => ['user.gif',
		      $lang{staff},
		      'users?action=protomodi&amp;userid='],
     users_group  => ['group.gif',
		      $lang{group},
		      'users_groups?action=protomodi&amp;groupid='],		      
	      );

  my $cid = DbQuery( query => "select id, description, type ".
                              "from last_elements_log ".
                              "where owner='$auth_user' ".
                              "order by issuedate desc, issuetime desc ".
                              "limit 30",
                     type  => 'NESTED' ); ## nested because ther's ParseLink inside!

  while ( my @row = FetchRow($cid) )
   {
    next if $dejavu{$row[0].$row[2]}++;
    DbFinish($cid) && last if $cnt++ == 8;

    if ( $row[2] =~ /^search\_(.+)$/ )
     {
      my $doc_type  = $1;
      $row[1]       =~ /keytofind\=([^\&]+)/;
      my $query     = DeUrl($1);
      $element_desc = "$lang{$doc_type}: " . ( $query || $lang{unknown} );
      $image_src    = "$IG::img_url/search.png";
      $element_href = "<a href=\"$doc_type?q=1$row[1]\">$lang{research}</a>";
     }
    else
     {
      $element_desc = $row[1];
      $image_src    = "$IG::img_url/".
                      ( $docs{$row[2]}[0] || 'mime_mini_document.png');
      $element_href = $docs{$row[2]}[2]
	            ? "<a href=\"$docs{$row[2]}[2]".
                      MkUrl($row[0]).
                      "\">$docs{$row[2]}[1]</a>"
                    : "$docs{$row[2]}[1] " . ParseLink($row[0]);
     }

    $html .= '<tr><td valign="top">'.

	     Img( src   => $image_src,
		  style => 'margin-right:3px',
		  width => 16,
		  title => $docs{$row[2]}[1],
		  align => 'top').

	     '</td><td style="border-bottom: 1px dotted #dddddd;">'.
	     $element_href.
	     '</td></tr><tr><td></td>'.
	     "<td style=\"color:$clr{font_low_evidence}; font-size:10px;\">".
             WrapText( text => $element_desc, columns => 25 ).
	     "</td></tr>\n".
	     "<tr><td></td><td style=\"line-height:8px\"><br></td></tr>\n";
   }

  $html .= "<td>$lang{none}</td>" if !$cnt;
  $html .= "</table>\n";

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 Crypt($text, $action, $key)

Encrypt (or Decrypt) a text with Des alghoritm, then convert the
string in base64 and substitute '/+' with '_-'.

=cut

sub Crypt
 {
  my ($text, $action, $key) = @_;
   
  require IG::Mydes;
  require IG::MimeBase64;
  $key ||= $crypt_key;
  my $ref = Mydes->new($key);
         
  if ($action eq 'decrypt')
   {
    ## decrypt
    $text =~ s/(.{76})\-/$1\n/g;
    $text =~ tr/\_\-/\/\+/;
    $text = Mime::Base64::decode_base64($text);
    $text = $ref->decrypt($text);
   }
  else
   {
    ## encrypt
    $text = $ref->encrypt($text);
    chomp( $text = Mime::Base64::encode_base64($text) );
    $text =~ tr/\/\+/\_\-/;     ## needed if we want to use string as filename
    $text =~ s/([^\n]{76})\n/$1-/g; ## needed to join all multiple lines
   }

  return $text;
 }

##############################################################################
##############################################################################

=head3 ProtocolToDocType($protocol_id)

Return a document type a cgi and a table name of a document id

=cut

sub ProtocolToDocType
 {
  my $protocol  = substr(shift, 0, 1);
  my $doc_type  = $protocol =~ /\d/
                ? (qw(	undef 		contracts	offers
			nc_int		nc_ext		letters
			fax_sent	fax_received	archive
			orders))[$protocol]
                : $protocol eq 'E'
                ? 'email'
                : $protocol eq 'F'
                ? 'binders'
                : undef;
  my $doc_cgi   = $doc_type eq 'email' ? 'webmail'    : $doc_type;
  my $doc_table = $doc_type eq 'email' ? 'email_msgs' : $doc_type;

  return wantarray ? ($doc_type, $doc_cgi, $doc_table) : $doc_type;
 }
 
##############################################################################
##############################################################################

=head3 ProtocolToFile($protocol_id)

Return a file path to access to a protocol number given.

=cut

sub ProtocolToFile
 {
  my $doc_id = shift;
  if ( $doc_id !~ /^([1-9])(\d\d\d\d\d)(\.|\_)(\d\d)$/ )
   { return wantarray ? (undef, undef, undef) : undef; }

  my ($file_name, $file_dir);
  my $doc_protocol   = $1;
  my $doc_year       = $4;
  my $plain_doc_id   = "$1$2_$4";
  my $crypted_doc_id = Crypt("$1$2.$4");
  my $doc_type       = ProtocolToDocType( $1 );

  if ($doc_type eq 'binders')
   { return wantarray ? ( undef, undef, 'binders' ) : 0; }

  ## first try to find document inside $doc_type directory
  ## by a plain_name and then a crypted name
  $file_dir = $htdocs_dir . $S . $default_lang{$doc_type};
  chdir($file_dir)
    or croak("Can't change working directory to '$file_dir'.".
             "Try to execute 'mkstruct.pl' script.\n");
  ($file_name) = (<$plain_doc_id.*>);
  ($file_name) = (<$crypted_doc_id.*>) if !$file_name;

  ## next try to find document inside $doc_year directory
  ## by a plain_name and then a crypted name
  if (!$file_name)
   {
    $file_dir .= $S . $doc_year;
    if ( -d $file_dir )
     {
      chdir($file_dir) or die("Can't change working directory to '$file_dir'.\n");
      ($file_name) = (<$plain_doc_id.*>);
      ($file_name) = (<$crypted_doc_id.*>) if !$file_name;
     }
   }

  return wantarray
         ? ( $file_name
             ? ( $file_name, $file_dir, $doc_type )
	     : ( undef,      undef,     $doc_type ) )
	 : ( $file_name
	     ? "$file_dir$S$file_name"
	     : 0 );
 }

##############################################################################
##############################################################################

=head3 Sign()

Sign a document.

=cut

sub Sign
 {
  my %data = @_;
  my $sign_key;
  my $file_name;
  my $md5;
  my ( $original_key, $original_issue, $original_owner );

  ## check if we have content to digest
  return -2 if    ! $data{content}
               && ! ( $file_name = ProtocolToFile( $data{id} ) );

  if ( $data{action} ne 'update' )
   {
    ## read signatur status
    my $cid = DbQuery( query => "select md5key, issue, owner from signatures ".
                                "where id='$data{id}' limit 1",
                       type  => 'UNNESTED' );
    ( $original_key, $original_issue, $original_owner ) = FetchRow( $cid );
    return 0 if !$original_key;
   }

  ## select a right MD5 module (first try to XS module)
  eval("require Digest::MD5");
  if ( $@ )
   {
    require IG::DigestPerlMD5;
    $md5 = Digest::Perl::MD5->new;
   }
  else
   {
    $md5 = Digest::MD5->new;
   }

  ## read content signature
  if ( $data{content} )
   {
    $md5->add( $data{content} );
    $sign_key = $md5->hexdigest;
   }
  else
   {
    ## assume we have a file to digest
    open (DOC, '<', $file_name)
      or croak("Can't open '$file_name' to check document integrity.");
    binmode(DOC);
    $md5->addfile(*DOC);
    $sign_key = $md5->hexdigest;
    close(DOC);
   }

  if ( $data{action} eq 'update' )
   {
    ## perform signature update
    DbWrite( action           => 'insert',
             table            => 'signatures',
             overwrite_clause => "id = '$data{id}'",
             values           => [ $data{id},
                                   $tv{today},
                                   $sign_key,
                                   $auth_user ] );

    return UsrInf('name'). ' '. $tv{today};
   }
  else
   {
    ## return a signature status
    return $original_key eq $sign_key 
	   ? UsrInf('name', $original_owner). ' '. $original_issue
	   : -1;
   }
 }

##############################################################################
##############################################################################

=head3 Md5Digest()

MD5 Algorithm

=cut

sub Md5Digest
 {
  my $string = shift;

  ## select a right MD5 module (first try to XS module)
  eval { require Digest::MD5 };
  if ( $@ )
   {
    require IG::DigestPerlMD5;
    return Digest::Perl::MD5::md5_hex( $string )
   }
  else
   {
    return Digest::MD5::md5_hex( $string );
   }
 }

##############################################################################
##############################################################################

=head3 CkSign()

Check a document Sign.

=cut

sub CkSign
 {
  my %data = @_;
  my $html;
  my $integrity = IG::Sign( id=>$data{id} );
  $data{sign_action} ||= "$cgi_name?action=sign&amp;id=$data{id}";

  my $tosign = $data{owner} eq $auth_user
             ? "<a href=\"$data{sign_action}\">[$lang{sign}]</a>"
             : '';

  if ( !$integrity )
   {
    $html = "$lang{unsigned} $tosign";
   }
  elsif ( $integrity == -2 )
   {
    $html = $lang{no_document};
   }
  elsif ( $integrity == -1 )
   {
    $html = Blush("$lang{corrupted} !!!") . ' ' . $tosign;
   }
  else
   {
    $html = $lang{signed}.
	    " <span style=\"font-size:10px; color:#666666;\">".
	    "($integrity)</span>";
   }

  defined wantarray ? return $html : PrOut $html;
 }
##############################################################################
##############################################################################

=head3 SendIsms()

Send an Isms message. Parameters needed are: sender, receiver, body, msgtoreply
delrepliedmsg and type. 

=cut

sub SendIsms
 {
  my %data = @_;
  $data{sender} ||= $auth_user;
  return if !$data{body} || ! UsrInf( 'name', $data{receiver} );

  FileTouch( UserDir( $data{receiver} ) . "${S}isms" );
  my $uniqueid = MkId();

  if ($data{msgtoreply})
   {
    my $cid = DbQuery( query => "select body, sender from isms ".
                                "where id='". DbQuote($data{msgtoreply}) .
                                "' limit 1",
                       type  => 'UNNESTED' );
    my ($texttoreply, $sendertoreply) = FetchRow($cid);

    if ( $data{delrepliedmsg} )
     {
      ## move replied message to "deleted" folder
      DbQuery ( query => "UPDATE isms set status='D' ".
                         "WHERE id='". DbQuote($data{msgtoreply}) ."'",
                type  => 'UNNESTED' );
     }

    $texttoreply =~ s/\%red\%//g;
    $data{body}  = '%red% '.
                   UsrInf( 'name', $sendertoreply ).
                   ": $texttoreply : %red% $data{body}";
   }

  $data{body} = DbQuote($data{body});

  ## check if message already exists and it's unread
  my $cid = DbQuery( query => "SELECT id from isms ".
                              "WHERE sender='$data{sender}'".
                              " and receiver='$data{receiver}'".
                              " and status=''".
                              " and body='$data{body}' ".
                              "LIMIT 1",
                     type  => 'UNNESTED' );

  ## send message
  DbQuery( query => "INSERT INTO isms ".
		    "VALUES ('$uniqueid', '$tv{today}', '$data{sender}',".
		    " '$data{receiver}', '$data{body}', '',".
		    " '$tv{hours}:$tv{minuts}', '$data{type}')",
           type  => 'UNNESTED' ) if !FetchRow($cid);

  return;
 }
 
##############################################################################
##############################################################################

=head3 MkByte($file_size)

This function takes a byte size value and convert it in a shorten and more
human readable format. We use it to show files size.

=cut

sub MkByte
 {
  my $size = shift;

  if ($size >= 1073741824)
   { return (sprintf("%.1f", $size/1073741824).' Gb') }
  elsif ($size >= 1048576)
   { return (sprintf("%.1f", $size/1048576).' Mb') }
  elsif ($size >= 1024)
   { return (sprintf("%.1f", $size/1024).' Kb') }
  return (($size ? $size : '0').' byte');
 }

###########################################################################
###########################################################################

=head3 ParseByte( $file_size )

This function converts from human readable format to byte format.

=cut

sub ParseByte
 {
  my $size = shift;
  return if ! $size;
  return $1 * 1024 if $size =~ /^\s*(\d+)\s*kb?\s*$/i;
  return $1 * 1024 * 1024 if $size =~ /^\s*(\d+)\s*mb?\s*$/i;
  return $1 * 1024 * 1024 * 1024 if $size =~ /^\s*(\d+)\s*gb?\s*$/i;
  return $1 if $size =~ /^\s*(\d+)\s*$/i;
  return;
 }

##############################################################################
##############################################################################

=head3 ContactFinder()

Return a form field to find/show a contact and return all data of the wich one
selected by user

=cut

sub ContactFinder
 {
  my $showen_contact = shift;

  if (!$on{contactid})
   {
    $lang{$showen_contact} = Blush($lang{$showen_contact});
    return $lang{select_name};
   }
  else
   {
    ## Read contact data from db and adjust apostrofi
    my $addrtype = $on{contactaddress} ||= 1;

    $in{contactid} = DbQuote( $on{contactid} );
    DbQuery( query => "update contacts set lastupdate='$tv{today}' ".
		      "where contactid = '$in{contactid}'",
             type  => 'UNNESTED' );

    my $cid = DbQuery( query => "SELECT contactname, fax, city1, city2,".
                                " city3, prov1, prov2, prov3, address1,".
                                " address2, address3, zip1, zip2, zip3,".
                                " rea, istat, employees, employername,".
                                " taxidnumber, tel1, email, contactvalue,".
                                " jobtitle ".
                                "FROM contacts ".
                                "WHERE contactid = '$in{contactid}' ".
                                "LIMIT 1",
                       type  => 'UNNESTED' );

    my @row = FetchRow($cid);

    if ($row[0])
     {
      $on{contactname}	= $row[0];
      $on{address}	= $row[7+$addrtype];
      $on{zip}		= $row[10+$addrtype];
      $on{city}		= $row[1+$addrtype];
      $on{prov}		= $row[4+$addrtype];
      $on{fax}		= $row[1];
      $on{header1}	= "$row[9] $row[3] ($row[6]) $lang{zip_code} $row[12]";
      $on{header2}	= "$row[10] $row[4] ($row[7]) $lang{zip_code} $row[13]";
      $on{header3}	= "$row[8] $row[2] ($row[5]) $lang{zip_code} $row[11]";
      $on{rea}		= $row[14];
      $on{istat}	= $row[15];
      $on{employees}	= $row[16];
      $on{employer}	= $row[17];
      $on{taxidnumber}	= $row[18];
      $on{tel}		= $row[19];
      $on{email}	= $row[20];
      $on{contactvalue}	= $row[21] ||= '0';
      $on{jobtitle}	= ucfirst(lc($row[22]));

      if ($on{subcontactid})
       {
        $in{subcontactid} = DbQuote( $on{subcontactid} );
	my $cid = DbQuery( query => "SELECT contactname, fax, email, city1,".
	                            " prov1, address1, zip1 ".
                                    "FROM contacts ".
                                    "WHERE contactid = '$in{subcontactid}' ".
                                    "LIMIT 1",
                           type  => 'UNNESTED' );

  	my @row = FetchRow($cid);

        $on{header4}	        = "$row[5] $row[3] ($row[4]) $lang{zip_code} $row[6]";
	$on{subcontactname} 	= $row[0];
        $on{fax} 		= $row[1] if $row[1];
        $on{email} 		= $row[2] if $row[2];
       }
     }
    else
     {
      ## We have a false number of contact
      $lang{$showen_contact} = Blush($lang{$showen_contact});
      return($lang{Err_contact_name});
     }
   }
  return;
 }

##############################################################################
##############################################################################

=head3 FileUpload()

Upload File from forms.

=cut

sub FileUpload
 {
  no strict 'refs';
  my %data = @_;
  my $status;
  my $upload_fh;

  return if !$on{$data{param_name}}; ## nothing to upload!

  croak("Can't upload file without param_name ".
      "or a valid target_dir '$data{target_dir}'.")
    if !$data{target_dir} || ! -d $data{target_dir};

  if (!$HTTP::Server::Simple::VERSION)
   { $upload_fh = $cgi_ref->upload($cgi_ref->param($data{param_name})) }
  else
   { $upload_fh = $on{$data{param_name}} }

  ## needed by win32 systems
  binmode($upload_fh);

  $data{target_dir}   =~ s/$S$//;
  $data{target_file} ||= $on{$data{param_name}};
  $data{target_file}  =~ s/^.*(\\|\/|\:)//; # trim path

  if (($data{deny_pattern} && $data{target_file} =~ /$data{deny_pattern}/i)
      ||
      ($data{allow_pattern} && $data{target_file} !~ /$data{allow_pattern}/i)
      ||
      ($data{target_file} =~ /\.\.|\<|\>|\*|\?|\|/ ))
   {
    $status = $lang{Err_wrong_name}
   }
  else
   {
    my $target_file = CkPath("$data{target_dir}$S$data{target_file}");

    if ( $data{can_overwrite} || ! -e $target_file )
     {
      if ( open (FILEUP, '>', $target_file) )
       {
        binmode(FILEUP);
        if ($data{filter})
         {
          my $filecontent;
          $filecontent .= $_ while (<$upload_fh>);
          $filecontent = $data{filter}->($filecontent,
					 $on{$data{param_name}});

          if ($filecontent) 
           {
            print FILEUP $filecontent;
           }
          else
           {
            close(FILEUP);
            unlink($target_file);
            return "Filter has rejected your file '$data{target_file}'";
           }
         }
        else
         { print FILEUP $_ while (<$upload_fh>) }

        close (FILEUP);
        chmod 0664, $target_file;
        $status = $lang{upload_ok};
       }
      else
       { $status = "Can't write destination file $target_file" }
     }
    else
     {
      $status = "$data{target_file} - $lang{Err_file_exists}";
     }
   }

  return $status;
 }

##############################################################################
##############################################################################

=head3 Lock() UnLock()

Lock or Unlock a resource (a file or a feature etc)

=cut

sub Lock
 {
  return if $OS eq 'WINDOWS';
  my %data = @_;
  $data{resource_id} ||= Crypt( $data{resource} );
  $data{timeout}     ||= 4;
  $data{tries}       ||= 5;

  my $lock_dir = $temp_dir . $S . $data{resource_id} . '.lck';
  my $tries = $data{tries};

  while ( $tries )
   {
    if ( -e $lock_dir )
     {
      ## check lock timeout
      opendir( RLCK, $lock_dir );
      foreach ( grep /^\d+$/, readdir RLCK )
       { UnLock( $data{resource_id} ) if (time - $_) > $data{timeout}; }
      closedir(RLCK);
     }

    if ( ! -e $lock_dir )
     {
      ## create a new lock dir
      mkdir($lock_dir, 0775)
        or croak("Can't create this lock directory '$lock_dir'\n");

      open(WLCK, '>', "$lock_dir${S}" . time )
        or croak("Can't create a resource lock info file");
      close(WLCK);
      return $data{resource_id};
     }

    sleep(1);
    $tries--;
   }

  croak( "Can't lock resource '$data{resource}' by creating '$lock_dir' ".
         "directory after '$data{tries}' attempts.\n");
 }

sub UnLock
 {
  return if $OS eq 'WINDOWS';
  my $resource_id = shift;
  my $lock_dir = $temp_dir . $S . $resource_id . '.lck';

  if ( -e $lock_dir )
   {
    ## delete all files inside lock dir
    opendir( RLCK, $lock_dir );
    foreach ( grep !/^\.\.*$/, readdir RLCK )
     {
      FileUnlink( "$lock_dir$S$_" )
        or croak("Can't remove '$lock_dir$S$_' ".
                 "to free a lock for resource id '$resource_id'.\n");
     }
    closedir(RLCK);

    ## delete lock directory
    rmdir ($lock_dir)
      or croak("Warning: Unable to remove a lock for resource id ".
               "'$resource_id': '$!' can't remove '$lock_dir' ".
               "lock directory.\n");
   }
  return 1;
 }

##############################################################################
##############################################################################

=head3 CkHtml

Check if a text is an html document

=cut

sub CkHtml
 {
  my $text = shift;
  return $text =~ /^\s*(<html|<\!DOCTYPE HTML)/i ? 1 : 0;
 }

##############################################################################
##############################################################################

=head3 PluginRegister

Register new plugins

=cut

sub PluginRegister
 {
  my %data = @_;
  return '' if !$data{functions};

  $data{version}     ||= $VERSION;
  $data{description}   =~ s/(\'|\\)/\\$1/g;
  $data{description} ||= 'No description';
  $data{name}          =~ s/\.pm$//;

  my $text = <<END;
    $data{name}
      => {
          PluginDescription => '$data{description}',
          NeedIgSuiteVersion => '$data{version}',
          HooksFunctions
           => {
END

  foreach my $func ( sort keys %{$data{functions}} )
   {
    next if    $func !~ /^(HtmlHead|HtmlFoot|DocHead|HttpHead|
                           TaskHead|MkComments|TaskFoot|MkButton|
                           FormHead|FormFoot|ParseLink|TabPane|DTable)$/x
            && $func !~ /^IGWiki\_/;

    $text .= ( ' 'x16 ) . "$func => '$data{functions}{$func}',\n";
   }

  if ( $data{limit_to_scripts} )
   {
    my $lts = '';
    foreach my $script ( sort keys %{$data{limit_to_scripts}} )
     { $lts .= ( ' 'x16 )."$script => '$data{limit_to_scripts}{$script}',\n"; }
    $text .= (' 'x14)."},\n".
             (' 'x10). "LimitToScripts\n".
             (' 'x11)."=> {\n".
             $lts if $lts;
   }

  if ( $data{limit_to_actions} )
   {
    my $lta = '';
    foreach my $action ( sort keys %{$data{limit_to_actions}} )
     { $lta .= ( ' 'x16 )."$action => '$data{limit_to_actions}{$action}',\n"; }
    $text .= (' 'x14)."},\n".
             (' 'x10). "LimitToActions\n".
             (' 'x11)."=> {\n".
             $lta if $lta;
   }

  return $text . (' 'x14) . "}\n". (' 'x9) . "},\n";
 }

##############################################################################
##############################################################################


#############################################################################
#############################################################################
## class to put a lock on bookinigs. The lock will be autoreleased when the
## class instance go out of scoope

package AutoReleasedLock;

sub new
 { 
  my $class = shift;
  my $self = {};
  my %data = @_;
  $self->{resource_id} = $data{resource_id} || IG::Crypt( $data{resource} );;
  $data{timeout}     ||= 4;
  $data{tries}       ||= 5;

  IG::Lock( resource_id => $self->{resource_id},
            timeout     => $data{timeout},
	    tries       => $data{tries} )
      unless $IG::lockCount{$self->{resource_id}};
      
  $IG::lockCount{$self->{resource_id}}++;
  bless($self, $class);
  return $self;
}

sub DESTROY
 {
  my $self = shift;
  $IG::lockCount{$self->{resource_id}}--;
  die 'IG::lockCount{$self->{resource_id}} < 0' if $IG::lockCount{$self->{resource_id}} < 0;
  IG::UnLock( $self->{resource_id} ) unless $IG::lockCount{$self->{resource_id}};
}

1;
