## IGSuite 4.0.0
## Procedure: HTTPServerSimpleCGIEnvironment.pm
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

package HTTP::Server::Simple::CGI::Environment;

use strict;
#use warnings; #XXXIG
use IG::HTTPServerSimple; #XXXIG

use vars qw($VERSION %ENV_MAPPING);
$VERSION = $HTTP::Server::Simple::VERSION;

my %clean_env = %ENV;

=head1 NAME

HTTP::Server::Simple::CGI::Environment - a HTTP::Server::Simple mixin to provide the CGI protocol

=head1 DESCRIPTION

This mixin abstracts the CGI protocol out from HTTP::Server::Simple::CGI so that 
it's easier to provide your own CGI handlers with HTTP::Server::Simple which 
B<don't> use CGI.pm

=head2 setup_environment

C<setup_environemnt> is usually called in the superclass's accept_hook

This routine in this sub-class clears the environment to the
start-up state.

=cut

sub setup_environment {
    %ENV = (
        %clean_env,
        SERVER_SOFTWARE   => "HTTP::Server::Simple/$VERSION",
        GATEWAY_INTERFACE => 'CGI/1.1'
    );
}

=head2 setup_server_url

Sets up the SERVER_URL environment variable

=cut

sub setup_server_url {
    $ENV{SERVER_URL}
        ||= ( "http://" . ($ENV{SERVER_NAME} || 'localhost') . ":" . ( $ENV{SERVER_PORT}||80) . "/" );
}

=head2 setup_environment_from_metadata

This method sets up CGI environment variables based on various
meta-headers, like the protocol, remote host name, request path, etc.

See the docs in L<HTTP::Server::Simple> for more detail.

=cut

%ENV_MAPPING = (
    protocol     => "SERVER_PROTOCOL",
    localport    => "SERVER_PORT",
    localname    => "SERVER_NAME",
    path         => "PATH_INFO",
    request_uri  => "REQUEST_URI",
    method       => "REQUEST_METHOD",
    peeraddr     => "REMOTE_ADDR",
    peername     => "REMOTE_HOST",
    query_string => "QUERY_STRING",
);

sub setup_environment_from_metadata {
    no warnings 'uninitialized';
    my $self = shift;

    # XXX TODO: rather than clone functionality from the base class,
    # we should call super
    #
    while ( my ( $item, $value ) = splice @_, 0, 2 ) {
        if ( my $k = $ENV_MAPPING{$item} ) {
            $ENV{$k} = $value;
        }
    }

}

=head2  header

C<header> turns a single HTTP headers into CGI environment variables.

=cut

sub header {
    my $self  = shift;
    my $tag   = shift;
    my $value = shift;

    $tag = uc($tag);
    $tag =~ s/^COOKIES$/COOKIE/;
    $tag =~ s/-/_/g;
    $tag = "HTTP_" . $tag
        unless $tag =~ m/^(?:CONTENT_(?:LENGTH|TYPE)|COOKIE)$/;

    if ( exists $ENV{$tag} ) {
        $ENV{$tag} .= "; $value";
    }
    else {
        $ENV{$tag} = $value;
    }
}

1;
