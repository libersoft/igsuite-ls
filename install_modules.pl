#!/usr/bin/perl
# Procedure: install_modules.pl
# Last Update: 10/07/2008
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
 
use CPAN;
use strict;

use vars qw( $OS $S );

## find some system value
_check_system();

## modules available only to UNIX systems
_clear_screen();
die("Sorry this script can be used only on UNIX systems.\n".
    "You have to install required modules manually.\n\n\n")
  if $OS ne 'UNIX';

## Configure cpan
$CPAN::Config{prerequisites_policy}          = 'follow';
$CPAN::Config{build_requires_install_policy} = 'yes'; 
$CPAN::Config{inhibit_startup_message}       = 1; 
$CPAN::Config{inactivity_timeout}            = 10; 


## Set the umask so nothing goes odd on systems which change it.
umask( 0022 );

## collect some info
my $choice = '';
while ( !$choice )
 {
  _clear_screen();

  print "Which driver whould you want to use:\n".
        " pg       -> (DBD::Pg)     Postgres\n".
        " mysql    -> (DBD::Mysql)  Mysql\n".
        " sqlite   -> (DBD::SQLite) SQLite\n\n".
        " ? [pg]: ";
  chomp( $choice = <STDIN> );

  $choice = 'pg' if !$choice || $choice eq 'Postgres' || $choice eq 'postgres';
  $choice = '' if $choice !~ /^(pg|mysql|sqlite)$/i;
 }
my $rdbms = lc($choice);

$choice = '';
while ( !$choice )
 {
  _clear_screen();

  print "Do you want to install optional modules?\n".
        "They are required to activate all IGSuite features [yes]: ";
  chomp( $choice = <STDIN> );

  $choice = 'yes' if !$choice;
  $choice = '' if $choice !~ /^(y|yes|n|no)$/i;
 }
my $optional = lc(substr($choice,0,1));


## Install modules
_clear_screen();
print "Attempting to install PERL modules required by IGSuite...\n";

my %modules = (   'LWP::Simple'      => { min_rel  => '',
                                          required => 'required' },
                  'LWP::UserAgent'   => { min_rel  => '',
                                          required => 'optional' },
                  'Net::LDAP'        => { min_rel  => '',
                                          required => 'optional' },
                  'Data::Dumper'     => { min_rel  => '',
                                          required => 'optional' },
                  'Apache::Htpasswd' => { min_rel  => '',
                                          required => 'optional' },
                  'Unicode::String'  => { min_rel  => '',
                                          required => 'optional' },
                  'Cwd'	             => { min_rel  => '',
                                          required => 'optional' },
                  'Time::HiRes'      => { min_rel  => '',
                                          required => 'optional' },
                  'DBI'              => { min_rel  => '',
                                          required => 'required' },
                                          
                  ( $rdbms eq 'pg'
                    ? 'DBD::Pg'
                    : $rdbms eq 'mysql'
                      ? 'DBD::mysql'
                      : 'DBD::SQLite' )  => { min_rel  => '',
                                              required => 'required' },

                  'Config'           => { min_rel  => '',
                                          required => 'required' },
                  'Archive::Zip'     => { min_rel  => '',
                                          required => 'required' },
                  'Digest::MD5'      => { min_rel  => '',
                                          required => 'required' },
                  'HTML::Parser'     => { min_rel  => '',
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
                  'version'          => { min_rel  => '', # 0.74
                                          required => 'required' },
                );

foreach my $module ( keys %modules )
 {
  next if $optional eq 'n' && $modules{$module}{required} eq 'optional';
  install( $module );
 }

###########################################################################
###########################################################################
sub _clear_screen
 {
  print "\n" x 40;
 }

###########################################################################
###########################################################################
sub _check_system
 {
  ## Copy & Paste From CGI.pm

  unless ($OS = $^O) { $OS = $Config::Config{'osname'}; }

  if ($OS=~/Win/i)	 { $OS = 'WINDOWS'; }
  elsif ($OS=~/vms/i)	 { $OS = 'VMS'; }
  elsif ($OS=~/bsdos/i)	 { $OS = 'UNIX'; }
  elsif ($OS=~/dos/i)	 { $OS = 'DOS'; }
  elsif ($OS=~/^MacOS$/i){ $OS = 'MACINTOSH'; }
  elsif ($OS=~/os2/i)	 { $OS = 'OS2'; }
  else			 { $OS = 'UNIX'; }

  $S = { UNIX      => '/',
         OS2       => '\\',
         WINDOWS   => '\\',
         DOS       => '\\',
         MACINTOSH => ':',
         VMS       => '/'   }->{$OS};
 }
