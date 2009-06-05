## IGSuite 4.0.0
## Procedure: XMLTreePP.pm
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

=head1 NAME

XML::TreePP -- Pure Perl implementation for parsing/writing xml files

=head1 SYNOPSIS

parse xml file into hash tree

    use XML::TreePP;
    my $tpp = XML::TreePP->new();
    my $tree = $tpp->parsefile( "index.rdf" );
    print "Title: ", $tree->{"rdf:RDF"}->{item}->[0]->{title}, "\n";
    print "URL:   ", $tree->{"rdf:RDF"}->{item}->[0]->{link}, "\n";

write xml as string from hash tree

    use XML::TreePP;
    my $tpp = XML::TreePP->new();
    my $tree = { rss => { channel => { item => [ {
        title   => "The Perl Directory",
        link    => "http://www.perl.org/",
    }, {
        title   => "The Comprehensive Perl Archive Network",
        link    => "http://cpan.perl.org/",
    } ] } } };
    my $xml = $tpp->write( $tree );
    print $xml;

get remote xml file with HTTP-GET and parse it into hash tree

    use XML::TreePP;
    my $tpp = XML::TreePP->new();
    my $tree = $tpp->parsehttp( GET => "http://use.perl.org/index.rss" );
    print "Title: ", $tree->{"rdf:RDF"}->{channel}->{title}, "\n";
    print "URL:   ", $tree->{"rdf:RDF"}->{channel}->{link}, "\n";

get remote xml file with HTTP-POST and parse it into hash tree

    use XML::TreePP;
    my $tpp = XML::TreePP->new( force_array => [qw( item )] );
    my $cgiurl = "http://search.hatena.ne.jp/keyword";
    my $keyword = "ajax";
    my $cgiquery = "mode=rss2&word=".$keyword;
    my $tree = $tpp->parsehttp( POST => $cgiurl, $cgiquery );
    print "Link: ", $tree->{rss}->{channel}->{item}->[0]->{link}, "\n";
    print "Desc: ", $tree->{rss}->{channel}->{item}->[0]->{description}, "\n";

=head1 DESCRIPTION

XML::TreePP module parses XML file and expands it for a hash tree.
And also generate XML file from a hash tree.
This is a pure Perl implementation.
You can also download XML from remote web server
like XMLHttpRequest object at JavaScript language.

=head1 EXAMPLES

=head2 Parse XML file

Sample XML source:

    <?xml version="1.0" encoding="UTF-8"?>
    <family name="Kawasaki">
        <father>Yasuhisa</father>
        <mother>Chizuko</mother>
        <children>
            <girl>Shiori</girl>
            <boy>Yusuke</boy>
            <boy>Kairi</boy>
        </children>
    </family>

Sample program to read a xml file and dump it:

    use XML::TreePP;
    use Data::Dumper;
    my $tpp = XML::TreePP->new();
    my $tree = $tpp->parsefile( "family.xml" );
    my $text = Dumper( $tree );
    print $text;

Result dumped:

    $VAR1 = {
        'family' => {
            '-name' => 'Kawasaki',
            'father' => 'Yasuhisa',
            'mother' => 'Chizuko',
            'children' => {
                'girl' => 'Shiori'
                'boy' => [
                    'Yusuke',
                    'Kairi'
                ],
            }
        }
    };

Details:

    print $tree->{family}->{father};        # the father's given name.

The prefix '-' is added on every attributes' name.

    print $tree->{family}->{"-name"};       # the family name of the family

The array is used because the family has two boys.

    print $tree->{family}->{children}->{boy}->[1];  # The second boy's name
    print $tree->{family}->{children}->{girl};      # The girl's name

=head2 Text node and attributes:

If a element has both of a text node and attributes
or both of a text node and other child nodes,
value of a text node is moved to C<'#text'> like child nodes.

    use XML::TreePP;
    use Data::Dumper;
    my $tpp = XML::TreePP->new();
    my $source = '<span class="author">Kawasaki Yusuke</span>';
    my $tree = $tpp->parse( $source );
    my $text = Dumper( $tree );
    print $text;

The result dumped is following:

    $VAR1 = {
        'span' => {
            '-class' => 'author',
            '#text' => 'Kawasaki Yusuke'
        }
    };

The special node name of C<'#text'> is used because this elements
has attribute(s) in addition to the text node.

=head1 CONSTRUCTOR AND OPTIONS

=head2 $tpp = XML::TreePP->new();

This constructor method returns a new XML::TreePP object.

=head2 $tpp = XML::TreePP->new( %options );

Its first argument is a hash variable to set one or more options
like following:

=head2 $tpp->set( option_name => $option_value );

This method sets a option value for "option_name".
If $option_value is not defined, its option is deleted.
Options below are available:

=head2 $tpp->set( output_encoding => 'UTF-8' );

You can define a encoding of xml file generated by write/writefile
methods. On Perl 5.8.x and later, you can select it from every
encodings supported by Encode.pm. On Perl 5.6.x or before with
Jcode.pm, you can use 'Shift_JIS', 'EUC-JP', 'ISO-2022-JP' and
'UTF-8'. The default value is 'UTF-8'.

=head2 $tpp->set( force_array => [ 'rdf:li', 'item', '-xmlns' ] );

This option allows you to specify a list of element names which
should always be forced into an array representation
The default value is null, it means that context of the elements
will determine to make array or to keep it scalar.

=head2 $tpp->set( first_out => [ 'link', 'title', '-type' ] );

This option allows you to specify a list of element/attribute
names which should always appears at first on output XML code.
The default value is null, it means alphabetical order is used.

=head2 $tpp->set( last_out => [ 'items', 'item', 'entry' ] );

This option allows you to specify a list of element/attribute
names which should always appears at last on output XML code.

=head2 $tpp->set( cdata_scalar_ref => 1 );

This option allows you to convert a cdata section into a reference
for scalar on parsing XML source. If this option is false, per
default, cdata section is converted into a scalar.

=head2 $tpp->set( user_agent => 'Mozilla/4.0 (compatible; ...)' );

This option allows you to specify a HTTP_USER_AGENT string which
is used by parsehttp() method.
The default string is C<"XML-TreePP/#.##">, where C<"#.##"> is
substituted with the version number of this library.

=head2 $tpp->set( attr_prefix => '@' );

This option allows you to specify a prefix character(s) which
is inserted before each attribute names.
The default character is C<'-'>.
Or set C<'@'> to access attribute values like E4X, ECMAScript for XML.
Zero-length prefix C<''> is also available now.

=head2 $tpp->set( text_node_key => '#text' );

This option allows you to specify a hash key for text nodes.
The default key is C<'#text'>.

=head2 $tpp->set( ignore_error => 1 );

This module calls Carp::croak function on an error per default.
This option makes all errors ignored and just return.

=head2 $tpp->set( xml_decl => '' );

This module generates an XML declaration on writing an XML code per default.
This option forces to change or leave it.

=head2 $tpp->set( http_lite => $http );

This option forces pasrsehttp() method to use L<HTTP::Lite> module 
with its instance created like: C<$http = HTTP::Lite-E<gt>new();>

=head2 $tpp->set( lwp_useragent => $ua );

This option forces pasrsehttp() method to use L<LWP::UserAgent> module 
with its instance created like: C<$ua = LWP::UserAgent-E<gt>new();>

=head2 $tpp->set( use_ixhash => 1 );

This option keeps the order for every elements appeared in XML.
L<Tie::IxHash> module is required.
This makes parsing performance slow. (100% slower than default)

=head2 $tpp->get( "option_name" );

This method returns a current option value for "option_name".

=head1 METHODS

=head2 $tree = $tpp->parse( $source );

This method reads XML source and returns a hash tree converted.
The first argument is a scalar or a reference to a scalar.

=head2 $tree = $tpp->parsefile( $file );

This method reads a XML file and returns a hash tree converted.
The first argument is a filename.

=head2 $tree = $tpp->parsehttp( $method, $url, $body, $head );

This method receives a XML file from a remote server via HTTP and
returns a hash tree converted.
$method is a method of HTTP connection: GET/POST/PUT/DELETE
$url is an URI of a XML file.
$body is a request body when you use POST method.
$head is a request headers as a hash ref.
L<LWP::UserAgent> module or L<HTTP::Lite> module is required to fetch a file.

=head2 $source = $tpp->write( $tree, $encode );

This method parses a hash tree and returns a XML source generated.
$tree is a referecen to a hash tree.

=head2 $tpp->writefile( $file, $tree, $encode );

This method parses a hash tree and writes a XML source into a file.
$file is a filename to create.
$tree is a referecen to a hash tree.

=head1 AUTHOR

Yusuke Kawasaki, http://www.kawa.net/

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2007 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut

package XML::TreePP;
use strict;
use Carp;
use Symbol;

use vars qw( $VERSION );
$VERSION = '0.21';

my $XML_ENCODING      = 'UTF-8';
my $INTERNAL_ENCODING = 'UTF-8';
my $USER_AGENT        = 'XML-TreePP/'.$VERSION.' ';
my $ATTR_PREFIX       = '-';
my $TEXT_NODE_KEY     = '#text';

sub new {
    my $package = shift;
    my $self    = {@_};
    bless $self, $package;
    $self;
}

sub die {
    my $self = shift;
    my $mess = shift;
    return if $self->{ignore_error};
    Carp::croak $mess;
}

sub warn {
    my $self = shift;
    my $mess = shift;
    return if $self->{ignore_error};
    Carp::carp $mess;
}

sub set {
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    if ( defined $val ) {
        $self->{$key} = $val;
    }
    else {
        delete $self->{$key};
    }
}

sub get {
    my $self = shift;
    my $key  = shift;
    $self->{$key} if exists $self->{$key};
}

sub writefile {
    my $self   = shift;
    my $file   = shift;
    my $tree   = shift or return $self->die( 'Invalid tree' );
    my $encode = shift;
    return $self->die( 'Invalid filename' ) unless defined $file;
    my $text = $self->write( $tree, $encode );
    $self->write_raw_xml( $file, $text );
}

sub write {
    my $self = shift;
    my $tree = shift or return $self->die( 'Invalid tree' );
    my $from = $self->{internal_encoding} || $INTERNAL_ENCODING;
    my $to   = shift || $self->{output_encoding} || $XML_ENCODING;
    my $decl = $self->{xml_decl};
    $decl = '<?xml version="1.0" encoding="' . $to . '" ?>' unless defined $decl;

    local $self->{__first_out};
    if ( exists $self->{first_out} ) {
        my $keys = $self->{first_out};
        $keys = [$keys] unless ref $keys;
        $self->{__first_out} = { map { $keys->[$_] => $_ } 0 .. $#$keys };
    }

    local $self->{__last_out};
    if ( exists $self->{last_out} ) {
        my $keys = $self->{last_out};
        $keys = [$keys] unless ref $keys;
        $self->{__last_out} = { map { $keys->[$_] => $_ } 0 .. $#$keys };
    }

    my $tnk = $self->{text_node_key};
    local $self->{text_node_key} = $TEXT_NODE_KEY;
    $self->{text_node_key} = $tnk if defined  $tnk;

    my $apre = $self->{attr_prefix};
    $apre = $ATTR_PREFIX unless defined  $apre;
    local $self->{__attr_prefix_len} = length($apre);
    local $self->{__attr_prefix_rex} = defined $apre ? qr/^\Q$apre\E/s : undef;

    my $text = $self->hash_to_xml( undef, $tree );
    if ( $from && $to ) {
        my $stat = $self->encode_from_to( \$text, $from, $to );
        return $self->die( "Unsupported encoding: $to" ) unless $stat;
    }
    return $text if ( $decl eq '' );
    join( "\n", $decl, $text );
}

sub parsehttp {
    my $self = shift;

    local $self->{__user_agent};
    if ( exists $self->{user_agent} ) {
        my $agent = $self->{user_agent};
        $agent .= $USER_AGENT if ( $agent =~ /\s$/s );
        $self->{__user_agent} = $agent if ( $agent ne '' );
    } else {
        $self->{__user_agent} = $USER_AGENT;
    }

    my $http = $self->{__http_module};
    unless ( $http ) {
        $http = $self->find_http_module(@_);
        $self->{__http_module} = $http;
    }
    if ( $http eq 'LWP::UserAgent' ) {
        return $self->parsehttp_lwp(@_);
    }
    elsif ( $http eq 'HTTP::Lite' ) {
        return $self->parsehttp_lite(@_);
    }
    else {
        return $self->die( "LWP::UserAgent or HTTP::Lite is required: $_[1]" );
    }
}

sub find_http_module {
    my $self = shift || {};

    if ( exists $self->{lwp_useragent} && ref $self->{lwp_useragent} ) {
        return 'LWP::UserAgent' if defined $LWP::UserAgent::VERSION;
        return 'LWP::UserAgent' if &load_lwp_useragent();
        return $self->die( "LWP::UserAgent is required: $_[1]" );
    }

    if ( exists $self->{http_lite} && ref $self->{http_lite} ) {
        return 'HTTP::Lite' if defined $HTTP::Lite::VERSION;
        return 'HTTP::Lite' if &load_http_lite();
        return $self->die( "HTTP::Lite is required: $_[1]" );
    }

    return 'LWP::UserAgent' if defined $LWP::UserAgent::VERSION;
    return 'HTTP::Lite'     if defined $HTTP::Lite::VERSION;
    return 'LWP::UserAgent' if &load_lwp_useragent();
    return 'HTTP::Lite'     if &load_http_lite();
    return $self->die( "LWP::UserAgent or HTTP::Lite is required: $_[1]" );
}

sub load_lwp_useragent {
    return $LWP::UserAgent::VERSION if defined $LWP::UserAgent::VERSION;
    local $@;
    eval { require LWP::UserAgent; };
    $LWP::UserAgent::VERSION;
}

sub load_http_lite {
    return $HTTP::Lite::VERSION if defined $HTTP::Lite::VERSION;
    local $@;
    eval { require HTTP::Lite; };
    $HTTP::Lite::VERSION;
}

sub load_tie_ixhash {
    return $Tie::IxHash::VERSION if defined $Tie::IxHash::VERSION;
    local $@;
    eval { require Tie::IxHash; };
    $Tie::IxHash::VERSION;
}

sub parsehttp_lwp {
    my $self   = shift;
    my $method = shift or return $self->die( 'Invalid HTTP method' );
    my $url    = shift or return $self->die( 'Invalid URL' );
    my $body   = shift;
    my $header = shift;

    my $ua = $self->{lwp_useragent} if exists $self->{lwp_useragent};
    if ( ! ref $ua ) {
        $ua = LWP::UserAgent->new();
        $ua->timeout(10);
        $ua->env_proxy();
        $ua->agent( $self->{__user_agent} ) if defined $self->{__user_agent};
    } else {
        $ua->agent( $self->{__user_agent} ) if exists $self->{user_agent};
    }

    my $req = HTTP::Request->new( $method, $url );
    my $ct = 0;
    if ( ref $header ) {
        foreach my $field ( sort keys %$header ) {
            my $value = $header->{$field};
            $req->header( $field => $value );
            $ct ++ if ( $field =~ /^Content-Type$/i );
        }
    }
    if ( defined $body && ! $ct ) {
        $req->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
    }
    $req->content($body) if defined $body;
    my $res = $ua->request($req);
    return unless $res->is_success();
    my $text = $res->content();
    $self->parse( \$text );
}

sub parsehttp_lite {
    my $self   = shift;
    my $method = shift or return $self->die( 'Invalid HTTP method' );
    my $url    = shift or return $self->die( 'Invalid URL' );
    my $body   = shift;
    my $header = shift;

    my $http = HTTP::Lite->new();
    $http->method($method);
    my $ua = 0;
    if ( ref $header ) {
        foreach my $field ( sort keys %$header ) {
            my $value = $header->{$field};
            $http->add_req_header( $field, $value );
            $ua ++ if ( $field =~ /^User-Agent$/i );
        }
    }
    if ( defined $self->{__user_agent} && ! $ua ) {
        $http->add_req_header( 'User-Agent', $self->{__user_agent} );
    }
    $http->{content} = $body if defined $body;
    $http->request($url) or return;
    my $text = $http->body();
    $self->parse( \$text );
}

sub parsefile {
    my $self = shift;
    my $file = shift;
    return $self->die( 'Invalid filename' ) unless defined $file;
    my $text = $self->read_raw_xml($file);
    $self->parse( \$text );
}

sub parse {
    my $self = shift;
    my $textref = ref $_[0] ? $_[0] : \$_[0];
    return $self->die( 'Invalid XML source' ) if ( ref($textref) ne 'SCALAR' );
    return $self->die( 'Null XML source' ) unless defined $$textref;

    my $to = $self->{internal_encoding} || $INTERNAL_ENCODING;
    if ($to) {
        my $from = &xml_decl_encoding($textref);
        if ($from) {
            my $stat = $self->encode_from_to( $textref, $from, $to );
            return $self->die( "Unsupported encoding: $from" ) unless $stat;
        }
    }

    local $self->{__force_array};
    if ( exists $self->{force_array} ) {
        my $force = $self->{force_array};
        $force = [$force] unless ref $force;
        $self->{__force_array} = { map { $_ => 1 } @$force };
    }

    my $tnk = $self->{text_node_key};
    local $self->{text_node_key} = $TEXT_NODE_KEY;
    $self->{text_node_key} = $tnk if defined  $tnk;

    my $apre = $self->{attr_prefix};
    local $self->{attr_prefix} = $ATTR_PREFIX;
    $self->{attr_prefix} = $apre if defined  $apre;

    if ( exists $self->{use_ixhash} && $self->{use_ixhash} ) {
        return $self->die( "Tie::IxHash is required." ) unless &load_tie_ixhash();
    }

    my $flat = $self->xml_to_flat($textref);
    my $tree = $self->flat_to_tree( $flat, '' );
    wantarray ? ( $tree, $$textref ) : $tree;
}

sub xml_to_flat {
    my $self    = shift;
    my $textref = shift;    # reference
    my $flat    = [];
    my $prefix = $self->{attr_prefix};
    my $ixhash = ( exists $self->{use_ixhash} && $self->{use_ixhash} );

    while ( $$textref =~ m{
        ([^<]*) <
        ((
            \? ([^<>]*) \?
        )|(
            \!\[CDATA\[(.*?)\]\]
        )|(
            \!DOCTYPE\s+([^\[\]<>]*(?:\[.*?\]\s*)?)
        )|(
            \!--(.*?)--
        )|(
            ([^\!\?\s<>](?:"[^"]*"|'[^']*'|[^"'<>])*)
        ))
        > ([^<]*)
    }sxg ) {
        my (
            $ahead,     $match,    $typePI,   $contPI,   $typeCDATA,
            $contCDATA, $typeDocT, $contDocT, $typeCmnt, $contCmnt,
            $typeElem,  $contElem, $follow
          )
          = ( $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13 );
        if ( defined $ahead && $ahead =~ /\S/ ) {
            $self->warn( "Invalid string: [$ahead] before <$match>" );
        }

        if ($typeElem) {                        # Element
            my $node = {};
            if ( $contElem =~ s#^/## ) {
                $node->{endTag}++;
            }
            elsif ( $contElem =~ s#/$## ) {
                # one line
            }
            else {
                $node->{startTag}++;
            }
            $node->{tagName} = $1 if ( $contElem =~ s#^(\S+)\s*## );
            unless ( $node->{endTag} ) {
                my $attr;
                while ( $contElem =~ m{
                    ([^\s\=\"\']+)=(?:(")(.*?)"|'(.*?)')
                }sxg ) {
                    my $key = $1;
                    my $val = &xml_unescape( $2 ? $3 : $4 );
                    if ( ! ref $attr ) {
                        $attr = {};
                        tie( %$attr, 'Tie::IxHash' ) if $ixhash;
                    }
                    $attr->{$prefix.$key} = $val;
                }
                $node->{attributes} = $attr if ref $attr;
            }
            push( @$flat, $node );
        }
        elsif ($typeCDATA) {    ## CDATASection
            if ( exists $self->{cdata_scalar_ref} && $self->{cdata_scalar_ref} ) {
                push( @$flat, \$contCDATA );    # as reference for scalar
            }
            else {
                push( @$flat, $contCDATA );     # as scalar like text node
            }
        }
        elsif ($typeCmnt) {                     # Comment (ignore)
        }
        elsif ($typeDocT) {                     # DocumentType (ignore)
        }
        elsif ($typePI) {                       # ProcessingInstruction (ignore)
        }
        else {
            $self->warn( "Invalid Tag: <$match>" );
        }
        if ( $follow =~ /\S/ ) {                # text node
            my $val = &xml_unescape($follow);
            push( @$flat, $val );
        }
    }
    $flat;
}

sub flat_to_tree {
    my $self   = shift;
    my $source = shift;
    my $parent = shift;
    my $tree   = {};
    my $text   = [];

    if ( exists $self->{use_ixhash} && $self->{use_ixhash} ) {
        tie( %$tree, 'Tie::IxHash' );
    }

    while ( scalar @$source ) {
        my $node = shift @$source;
        if ( !ref $node || UNIVERSAL::isa( $node, "SCALAR" ) ) {
            push( @$text, $node );              # cdata or text node
            next;
        }
        my $name = $node->{tagName};
        if ( $node->{endTag} ) {
            last if ( $parent eq $name );
            return $self->die( "Invalid tag sequence: <$parent></$name>" );
        }
        my $elem = $node->{attributes};
        if ( $node->{startTag} ) {              # recursive call
            my $child = $self->flat_to_tree( $source, $name );
            if ( ref $elem && scalar keys %$elem ) {
                if ( UNIVERSAL::isa( $child, "HASH" ) ) {
                    # some attributes and some child nodes
                    foreach my $key ( keys %$child ) {
                        $elem->{$key} = $child->{$key};
                    }
                }
                elsif ( defined $child ) {
                    # some attributes and text node
                    $elem->{$self->{text_node_key}} = $child;
                }
            }
            else {
                # no attributes and text node or nothing
                $elem = $child;
            }
        }
        # next unless defined $elem;
        $tree->{$name} ||= [];
        push( @{ $tree->{$name} }, $elem );
    }
    foreach my $key ( keys %$tree ) {
        next if $self->{__force_array}->{$key};
        next if ( 1 < scalar @{ $tree->{$key} } );
        $tree->{$key} = shift @{ $tree->{$key} };
    }
    if ( scalar @$text ) {
        if ( scalar @$text == 1 ) {
            $text = shift @$text;
        }
        elsif ( ! scalar grep {ref $_} @$text ) {
            $text = join( '', @$text );
        }
        else {
            my $join = join( '', map {ref $_ ? $$_ : $_} @$text );
            $text = \$join;
        }
        if ( scalar keys %$tree ) {
            # some child nodes and also text node
            $tree->{$self->{text_node_key}} = $text;
        }
        else {
            # only text node without child nodes
            $tree = $text;
        }
    }
    $tree;
}

sub hash_to_xml {
    my $self      = shift;
    my $name      = shift;
    my $hash      = shift;
    my $out       = [];
    my $attr      = [];
    my $allkeys   = [ keys %$hash ];
    my $fo = $self->{__first_out} if ref $self->{__first_out};
    my $lo = $self->{__last_out}  if ref $self->{__last_out};
    my $firstkeys = [ sort { $fo->{$a} <=> $fo->{$b} } grep { exists $fo->{$_} } @$allkeys ] if ref $fo;
    my $lastkeys  = [ sort { $lo->{$a} <=> $lo->{$b} } grep { exists $lo->{$_} } @$allkeys ] if ref $lo;
    $allkeys = [ grep { ! exists $fo->{$_} } @$allkeys ] if ref $fo;
    $allkeys = [ grep { ! exists $lo->{$_} } @$allkeys ] if ref $lo;
    unless ( exists $self->{use_ixhash} && $self->{use_ixhash} ) {
        $allkeys = [ sort @$allkeys ];
    }
    my $prelen = $self->{__attr_prefix_len};
    my $pregex = $self->{__attr_prefix_rex};

    foreach my $loopkey ( $firstkeys, $allkeys, $lastkeys ) {
        next unless ref $loopkey;
        foreach my $key ( grep { ! $prelen || $_ !~ $pregex } @$loopkey ) {
            my $val = $hash->{$key};
            if ( !defined $val ) {
                push( @$out, "<$key />" );
            }
            elsif ( UNIVERSAL::isa( $val, 'ARRAY' ) ) {
                my $child = $self->array_to_xml( $key, $val );
                push( @$out, $child );
            }
            elsif ( UNIVERSAL::isa( $val, 'SCALAR' ) ) {
                my $child = $self->scalaref_to_cdata( $key, $val );
                push( @$out, $child );
            }
            elsif ( ref $val ) {
                my $child = $self->hash_to_xml( $key, $val );
                push( @$out, $child );
            }
            else {
                my $child = $self->scalar_to_xml( $key, $val );
                push( @$out, $child );
            }
        }
    
        foreach my $key ( grep { $prelen && $_ =~ $pregex } @$loopkey ) {
            my $name = substr( $key, $prelen );
            my $val = &xml_escape( $hash->{$key} );
            push( @$attr, ' ' . $name . '="' . $val . '"' );
        }
    }
    my $jattr = join( '', @$attr );

    # s/^(\s*<)/  $1/mg foreach @$out;              # indent
    my $text = join( '', @$out );
    if ( defined $name ) {
        if ( scalar @$out ) {
            $text = "<$name$jattr>$text</$name>\n";
        }
        else {
            $text = "<$name$jattr />\n";
        }
    }
    $text;
}

sub array_to_xml {
    my $self  = shift;
    my $name  = shift;
    my $array = shift;
    my $out   = [];
    foreach my $val (@$array) {
        if ( !defined $val ) {
            push( @$out, "<$name />\n" );
        }
        elsif ( UNIVERSAL::isa( $val, 'ARRAY' ) ) {
            my $child = $self->array_to_xml( $name, $val );
            push( @$out, $child );
        }
        elsif ( UNIVERSAL::isa( $val, 'SCALAR' ) ) {
            my $child = $self->scalaref_to_cdata( $name, $val );
            push( @$out, $child );
        }
        elsif ( ref $val ) {
            my $child = $self->hash_to_xml( $name, $val );
            push( @$out, $child );
        }
        else {
            my $child = $self->scalar_to_xml( $name, $val );
            push( @$out, $child );
        }
    }

    # s/^(\s*<)/  $1/mg foreach @$out;              # indent
    my $text = join( '', @$out );
    $text;
}

sub scalaref_to_cdata {
    my $self = shift;
    my $name = shift;
    my $ref  = shift;
    my $text = '<![CDATA[' . $$ref . ']]>';
    $text = "<$name>$text</$name>\n" if ( $name ne $self->{text_node_key} );
    $text;
}

sub scalar_to_xml {
    my $self   = shift;
    my $name   = shift;
    my $scalar = shift;
    my $copy   = $scalar;
    my $text   = &xml_escape($copy);
    $text = "<$name>$text</$name>\n" if ( $name ne $self->{text_node_key} );
    $text;
}

sub write_raw_xml {
    my $self = shift;
    my $file = shift;
    my $fh   = Symbol::gensym();
    open( $fh, ">$file" ) or return $self->die( "$! - $file" );
    print $fh @_;
    close($fh);
}

sub read_raw_xml {
    my $self = shift;
    my $file = shift;
    my $fh   = Symbol::gensym();
    open( $fh, $file ) or return $self->die( "$! - $file" );
    local $/ = undef;
    my $text = <$fh>;
    close($fh);
    $text;
}

sub xml_decl_encoding {
    my $textref = shift;
    return unless defined $$textref;
    my $args    = ( $$textref =~ /^\s*<\?xml(\s+\S.*)\?>/s )[0] or return;
    my $getcode = ( $args =~ /\s+encoding="(.*?)"/ )[0] or return;
    $getcode;
}

sub encode_from_to {
    my $self   = shift;
    my $txtref = shift or return;
    my $from   = shift or return;
    my $to     = shift or return;
    return $to if ( uc($from) eq uc($to) );
    &load_encode() if ( $] > 5.008 );

    unless ( defined $Encode::EUCJPMS::VERSION ) {
        $from = 'EUC-JP' if ( $from =~ /\beuc-?jp-?(win|ms)$/i );
        $to   = 'EUC-JP' if ( $to   =~ /\beuc-?jp-?(win|ms)$/i );
    }

    if ( defined $Encode::VERSION ) {
        my $check = ( $Encode::VERSION < 2.13 ) ? 0x400 : Encode::FB_XMLCREF();
        Encode::from_to( $$txtref, $from, $to, $check );
    }
    elsif ( (  uc($from) eq 'ISO-8859-1'
            || uc($from) eq 'US-ASCII'
            || uc($from) eq 'LATIN-1' ) && uc($to) eq 'UTF-8' ) {
        &latin1_to_utf8($txtref);
    }
    else {
        my $jfrom = &get_jcode_name($from);
        my $jto   = &get_jcode_name($to);
        return $to if ( uc($jfrom) eq uc($jto) );
        if ( $jfrom && $jto ) {
            &load_jcode();
            if ( defined $Jcode::VERSION ) {
                Jcode::convert( $txtref, $jto, $jfrom );
            }
            else {
                return $self->die( "Jcode.pm is required: $from to $to" );
            }
        }
        else {
            return $self->die( "Encode.pm is required: $from to $to" );
        }
    }
    $to;
}

sub load_jcode {
    return if defined $Jcode::VERSION;
    local $@;
    eval { require Jcode; };
}

sub load_encode {
    return if defined $Encode::VERSION;
    local $@;
    eval { require Encode; };
}

sub latin1_to_utf8 {
    my $strref = shift;
    $$strref =~ s{
        ([\x80-\xFF])
    }{
        pack( 'C2' => 0xC0|(ord($1)>>6),0x80|(ord($1)&0x3F) )
    }exg;
}

sub get_jcode_name {
    my $src = shift;
    my $dst;
    if ( $src =~ /^utf-?8$/i ) {
        $dst = 'utf8';
    }
    elsif ( $src =~ /^euc.*jp(-?(win|ms))?$/i ) {
        $dst = 'euc';
    }
    elsif ( $src =~ /^(shift.*jis|cp932|windows-31j)$/i ) {
        $dst = 'sjis';
    }
    elsif ( $src =~ /^iso-2022-jp/ ) {
        $dst = 'jis';
    }
    $dst;
}

sub xml_escape {
    my $str = shift;
    # except for TAB(\x09),CR(\x0D),LF(\x0A)
    $str =~ s{
        ([\x00-\x08\x0B\x0C\x0E-\x1F\x7F])
    }{
        sprintf( '&#%d;', ord($1) );
    }gex;
    $str =~ s/&(?!#(\d+;|x[\dA-Fa-f]+;))/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/'/&apos;/g;
    $str =~ s/"/&quot;/g;
    $str;
}

sub xml_unescape {
    my $str = shift;
    my $map = {qw( quot " lt < gt > apos ' amp & )};
    $str =~ s{
        (&(?:\#(\d+)|\#x([0-9a-fA-F]+)|(quot|lt|gt|apos|amp));)
    }{
        $4 ? $map->{$4} : &char_deref($1,$2,$3);
    }gex;
    $str;
}

sub char_deref {
    my( $str, $dec, $hex ) = @_;
    if ( defined $dec ) {
        return &code_to_utf8( $dec ) if ( $dec < 256 );
    }
    elsif ( defined $hex ) {
        my $num = hex($hex);
        return &code_to_utf8( $num ) if ( $num < 256 );
    }
    return $str;
}

sub code_to_utf8 {
    my $code = shift;
    if ( $code < 128 ) {
        return pack( C => $code );
    }
    elsif ( $code < 256 ) {
        return pack( C2 => 0xC0|($code>>6), 0x80|($code&0x3F));
    }
    elsif ( $code < 65536 ) {
        return pack( C3 => 0xC0|($code>>12), 0x80|(($code>>6)&0x3F), 0x80|($code&0x3F));
    }
    return shift if scalar @_;      # default value
    sprintf( '&#x%04X;', $code );
}

1;
