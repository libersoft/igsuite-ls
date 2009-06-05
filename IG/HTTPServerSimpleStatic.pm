## IGSuite 4.0.0
## Procedure: HTTPServerSimpleStatic.pm
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

package HTTP::Server::Simple::Static;
use strict;
#use warnings; #XXXIG

use IG::FileMMagic;			##XXXIG
use IG::MIMETypes;			##XXXIG
use IG::URIEscape;			##XXXIG
use IG::FileSpecFunctions qw(canonpath);##XXXIG
use IO::File     ();

use base qw(Exporter);
our @EXPORT = qw(serve_static);

our $VERSION = '0.06';

my $mime  = MIME::Types->new();
my $magic = File::MMagic->new();

sub serve_static {
    my ( $self, $cgi, $base ) = @_;
    my $path = $cgi->url( -absolute => 1, -path_info => 1 );

    # Sanitize the path and try it.
    $path = $base.
            File::Spec::Functions::canonpath( URI::Escape::uri_unescape($path) );

    my $fh = IO::File->new();
    if ( -e $path and $fh->open($path) ) {
        binmode $fh;
        binmode $self->stdout_handle;

        my $content;
        {
            local $/;
            $content = <$fh>;
        }
        $fh->close;

        my $content_length;
        if ( defined $content ) {
            use bytes;    # Content-Length in bytes, not characters
            $content_length = length $content;
        }
        else {
            $content_length = 0;
            $content        = q{};
        }

        # If a file has no extension, e.g. 'foo' this will return undef
        my $mimeobj = $mime->mimeTypeOf($path);

        my $mimetype;
        if ( defined $mimeobj ) {
            $mimetype = $mimeobj->type;
        }
        else {

            # If the file is empty File::MMagic will give the MIME type as
            # application/octet-stream' which is not helpful and not the
            # way other web servers act. So, we default to 'text/plain'
            # which is the same as apache.

            if ($content_length) {
                $mimetype = $magic->checktype_contents($content);
            }
            else {
                $mimetype = 'text/plain';
            }
        }

        print "HTTP/1.1 200 OK\015\012";
        print 'Content-type: ' . $mimetype . "\015\012";
        print 'Content-length: ' . $content_length . "\015\012\015\012";
        print $content;
        return 1;
    }
    return 0;
}

1;
__END__

=head1 NAME

HTTP::Server::Simple::Static - Serve static files with HTTP::Server::Simple

=head1 SYNOPSIS

    package MyServer;

    use base qw(HTTP::Server::Simple::CGI);
    use HTTP::Server::Simple::Static;

    sub handle_request {
	my ( $self, $cgi ) = @_;
	return $self->serve_static( $cgi, $webroot );
    }

    package main;

    my $server = MyServer->new();
    $server->run();

=head1 DESCRIPTION

this mixin adds a method to serve static files from your HTTP::Server::Simple
subclass.


=head1 SUBROUTINES/METHODS

=over 4

=item  serve_static

Takes a base directory and a web path, and tries to serve a static
file. Returns 0 if the file does not exist, returns 1 on success.

=back

=head1 BUGS AND LIMITATIONS

Bugs or wishlist requests should be submitted via http://rt.cpan.org/

=head1 SEE ALSO

=head1 AUTHOR

Stephen Quinney C<sjq-perl@jadevine.org.uk>

Thanks to Marcus Ramberg C<marcus@thefeed.no> and Simon Cozens for
initial implementation.

=head1 LICENSE AND COPYRIGHT

Copyright 2006, 2007. Stephen Quinney C<sjq-perl@jadevine.org.uk>

You may distribute this code under the same terms as Perl itself.

=cut
