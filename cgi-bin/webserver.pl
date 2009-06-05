#! /usr/bin/perl
# Procedure: webserver.pl
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

package CGIServer;

use strict;
use IG;
use IG::Cwd;
use IG::HTTPServerSimpleCGI;
use IG::HTTPServerSimpleStatic;
use base qw( HTTP::Server::Simple::CGI
	     HTTP::Server::Simple::Static );

use vars qw( $port $name $cgi_dir $script_dir);

## First check if we are user root
if ( $IG::OS eq 'UNIX' &&  $< == 0 )
 {
  print STDOUT "\nSorry this daemon can't be executed as user 'root'\n".
               "You have to execute it as the same user who usually\n".
               "execute Apache.\n\n";
  exit(0);
 }

## Load command line options
IG::ReadArgv(	'port:s'	=>\$CGIServer::port,
		'name:s'	=>\$CGIServer::name,
  	    );
    

$CGIServer::cgi_dir    = Cwd::getcwd;
$CGIServer::script_dir = ( split(/\\|\//, $CGIServer::cgi_dir) )[-1];
$CGIServer::port     ||= 13432;
$CGIServer::name     ||= 'localhost';
my $server = CGIServer->new($CGIServer::port);

## Try to start browser
qx(start http://$CGIServer::name:$CGIServer::port/$CGIServer::script_dir/igsuite)
  if $IG::OS eq 'WINDOWS';

## Start HTTP Server
$server->run();

sub print_banner
 {
  _clear_screen();
  print STDOUT  "\nIGSuite HTTP Server ** EXPERIMENTAL **\n\n".
		"Redirect your preferred browser to this address...\n".
		"http://$CGIServer::name:$CGIServer::port/$CGIServer::script_dir/igsuite\n\n";
 }

sub handle_request
 {
  my($self, $cgi) = @_;
  $ENV{SERVER_NAME} = $ENV{HTTP_HOST} = $CGIServer::name;

  if (    $cgi->path_info =~ /^\/$CGIServer::script_dir\/([^\?\/]+)/
       && -e "$CGIServer::cgi_dir/$1" )
   {
    ## It's a dinamic content
    package main;
    my $script = $1 || 'igsuite';
    $ENV{REQUEST_URI}     = "/$CGIServer::script_dir/$script";
    $ENV{SCRIPT_FILENAME} = $0 = "$CGIServer::cgi_dir/$script";
    $ENV{PATH_INFO}       = substr($cgi->path_info, length($script)+5,);
    $IG::cgi_ref          = $cgi;
    do "$CGIServer::cgi_dir/$script";
   }
  else
   {
    ## It's a static file
    $self->serve_static($cgi, $IG::htdocs_dir)
     or print STDOUT "HTTP/1.0 200 OK\r\n\r\nNOFILE";
   }
 }

###########################################################################
###########################################################################
sub _clear_screen
 {
  print STDOUT "\n" x 40;
 }
