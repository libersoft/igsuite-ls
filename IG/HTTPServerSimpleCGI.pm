## IGSuite 4.0.0
## Procedure: HTTPServerSimpleCGI.pm
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

package HTTP::Server::Simple::CGI;
use IG::HTTPServerSimple; #XXXIG
use IG::HTTPServerSimpleCGIEnvironment; #XXXIG
use base qw(HTTP::Server::Simple HTTP::Server::Simple::CGI::Environment);
use strict;
#use warnings; #XXXIG

use CGI ();

use vars qw($VERSION $default_doc);
$VERSION = $HTTP::Server::Simple::VERSION;

=head1 NAME

HTTP::Server::Simple::CGI - CGI.pm-style version of HTTP::Server::Simple

=head1 DESCRIPTION

HTTP::Server::Simple was already simple, but some smart-ass pointed
out that there is no CGI in HTTP, and so this module was born to
isolate the CGI.pm-related parts of this handler.


=head2 accept_hook

The accept_hook in this sub-class clears the environment to the
start-up state.

=cut

sub accept_hook {
    my $self = shift;
    $self->setup_environment(@_);
}

=head2 post_setup_hook



=cut

sub post_setup_hook {
    my $self = shift;
    $self->setup_server_url;
    CGI::initialize_globals();
}

=head2 setup

This method sets up CGI environment variables based on various
meta-headers, like the protocol, remote host name, request path, etc.

See the docs in L<HTTP::Server::Simple> for more detail.

=cut

sub setup {
    my $self = shift;
    $self->setup_environment_from_metadata(@_);
}

=head2 handle_request CGI

This routine is called whenever your server gets a request it can
handle.

It's called with a CGI object that's been pre-initialized.
You want to override this method in your subclass


=cut

$default_doc = ( join "", <DATA> );

sub handle_request {
    my ( $self, $cgi ) = @_;

    print "HTTP/1.0 200 OK\r\n";    # probably OK by now
    print "Content-Type: text/html\r\nContent-Length: ", length($default_doc),
        "\r\n\r\n", $default_doc;
}

=head2 handler

Handler implemented as part of HTTP::Server::Simple API

=cut

sub handler {
    my $self = shift;
    my $cgi  = new CGI();
    eval { $self->handle_request($cgi) };
    if ($@) {
        my $error = $@;
        warn $error;
    }
}

1;

__DATA__
<html>
  <head>
    <title>Hello!</title>
  </head>
  <body>
    <h1>Congratulations!</h1>

    <p>You now have a functional HTTP::Server::Simple::CGI running.
      </p>

    <p><i>(If you're seeing this page, it means you haven't subclassed
      HTTP::Server::Simple::CGI, which you'll need to do to make it
      useful.)</i>
      </p>
  </body>
</html>
