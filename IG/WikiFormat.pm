## IGSuite 4.0.0
## Procedure: WikiFormat.pm
## Last update: 25/05/2009
#############################################################################
# IGSuite 4.0.0 - Provides an Office Suite by  simple web interface         #
# Copyright (C) 2002 Dante Ortolani  [LucaS]                                #
# 'chromatic chromatic@wgz.org has shamelessly adapted this job from        #
# Jellybean project; I have shamelessly adapted it from his project :)      #
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

package WikiFormat;

use strict;
use Carp;

use vars qw( %tags @levels $VERSION );
$VERSION = '4.0.0';

%tags   = (
indent		=> qr/^\t+/,
newline		=> '<br />',
link		=> \&make_html_link,
strong		=> sub { "<strong>$_[0]</strong>" },
strong_tag	=> qr/'''(.+?)'''/,
exponent	=> sub { "<span style=\"vertical-align:super\">$_[0]</span>" },
exponent_tag	=> qr/\^(.+?)\^/,
strike		=> sub { "<strike>$_[0]</strike>" },
strike_tag	=> qr/---(.+?)---/,
evidence	=> sub { "<span style=\"background: $IG::clr{bg_evidence}\">$_[0]</span>" },
evidence_tag	=> qr/\,\,\,(.+?)\,\,\,/,
colored		=> sub { "<span style=\"color: $_[0]\">$_[1]</span>" },
colored_tag	=> qr/\%(red|blue|green|white|black)\%(.+?)\%\1\%/,
emphasized	=> sub { "<em>$_[0]</em>" },
emphasized_tag	=> qr/''(.+?)''/,
underline	=> sub { "<u>$_[0]</u>" },
underline_tag	=> qr/\,\,(.+?)\,\,/,
center		=> sub { "<center>$_[0]</center>" },
center_tag	=> qr/\(\(\((.+?)\)\)\)/,
right           => sub { "<div style=\"width:100%; text-align:right\">$_[0]</div>" },
right_tag       => qr/\)\)\)(.+?)\)\)\)/,
 
code	 => [ "<pre>\n",	"</pre>\n",		'',	"\n" ],
line	 => [ '',		"\n",			'<hr />',"\n" ],
table	 => [ '',		"\n",			sub { return $_[2] },	"\n" ],
paragraph=> [ '<p>',		"</p>\n",		'',	"<br />\n", 1 ],
unordered=> [ "<ul>\n",		"</ul>\n",		'<li>', "</li>\n" ],
ordered  => [ "<ol>\n",		"</ol>\n",		sub { qq|<li value="$_[2]">|, $_[0], "</li>\n" } ],
defs	 => [ "<dl>\n",		"</dl>\n",		sub {	$_[0] =~ /([^\:]+)\:(.+)/;
								return "<dt><strong>",
									$1,
									"</strong>\n<dd>$2\n"
							    } ],
header	 => [ '',		"\n",			sub {   my $name;
								my $level = length $_[2];
								$levels[$level]++;
								$levels[$_] = 0 for ($level+1)..5;
								$name .= $levels[$_] ? "$levels[$_]." : "" for 1..$level;
								my $name2 = $_[3];
								$name2 =~ s/[^A-Za-z0-9_\-\.]/_/g;
								return "<h$level><a name=\"$name\"></a><a name=\"$name2\">",
									format_line($_[3],@_[-2, -1]),
									"</a></h$level>\n"
							    } ],
blocks		=> {
			table		=> qr/^(<\/*(?:td|tr|th|table)[^>]*>)/,
			ordered		=> qr/^([\dA-Za-z]{1,3}\.)\s/,
			unordered	=> qr/^\*\s*/,
			defs		=> qr/^\;/,
			code		=> qr/  /,
			header		=> qr/^(=+) (.+) \1/,
			paragraph	=> qr/^/,
			line		=> qr/^-{4,}/,
	   	   },
indented	=> { map { $_ => 1 } qw( defs ordered unordered code)},
nests		=> { map { $_ => 1 } qw( ordered unordered ) },

blockorder		 => [qw( table header line defs ordered unordered code paragraph )],
extended_link_delimiters => [qw( [ ] )],
);
 
sub process_args
 {
  my $self = shift;
  my $name = @_ == 1 ? shift : 'wikiformat';
  return ( as => $name, @_ );
 }

sub default_opts
 {
  my ($class, $args) = @_;
  my %defopts = ( implicit_links => 1, map { $_ => delete $args->{ $_ } }
		  qw( prefix extended implicit_links) );
  return %defopts;
 }


sub merge_hash
 {
  my ($from, $to) = @_;
  while (my ($key, $value) = each %$from)
   {
    if (UNIVERSAL::isa( $value, 'HASH' ))
     {
	$to->{$key} = {} unless defined $to->{$key};
	merge_hash( $value, $to->{$key} );
     }
    else
     {	$to->{$key} = $value;	}
   }
 }


sub import
 {
  my $class = shift;
  return unless @_;

  my %args    = $class->process_args( @_ );
  my %defopts = $class->default_opts( \%args );

  my $caller = caller();
  my $name   = delete $args{as};

  no strict 'refs';
  *{ $caller."::$name" } = sub {
				my ($text, $tags, $opts) = @_;
				$tags ||= {};
				$opts ||= {};
				my %tags = %args;
				merge_hash( $tags, \%tags );
				my %opts = %defopts;
				merge_hash( $opts, \%opts );
				WikiFormat::format( $text, \%tags, \%opts);
			       }
 }


sub format
 {
  my ($text, $newtags, $opts) = @_;
  $opts    ||= { prefix => '', extended => 0, implicit_links => 1 };
  my %tags   = %tags;
  @levels = ();

  ## Delete comments
  $text =~ s/(\&lt;|<)\!\-\-\s.*?\s\-\-(\&gt;|>)\n?//smg;

  ## Pharse Table
  while ($text=~ s/(\{\|.+\|\})/\%\%TABLE\%\%/ms)
   {
	my $table = $1;
	$table =~ s/\{\|(.*)$/<table$1>\n<tr>/mg;		 ## <TABLE>
	$table =~ s/\|\}.*$/<\/tr>\n<\/table>/mg;		 ## </TABLE>
	$table =~ s/^\|\-(.*)$/<\/tr>\n<tr$1>/mg;		 ## <TR>
 
	$table =~ s/\|\|/\n\|/g;				 ## ||
	$table =~ s/^\|([^\|]+)$/<td>\n$1/mg;                    ## <TD>
	$table =~ s/^\|([^\|]+)\|([^\|]+)$/<td $1>\n$2/mg;       ## <TD p>

	$table =~ s/\!\!/\n\!/g;				 ## !!
	$table =~ s/^\!([^\!]+)$/<th>\n$1/mg;                    ## <TR>
	$table =~ s/^\!([^\|]+)\|([^\|]+)$/<th $1>\n$2/mg;       ## <TR p>
        
	$table =~ s/<(td|th)(.*?)(?=<\/*(td|th|tr))/<$1$2<\/$1>\n/gms;

	$text =~ s/\%\%TABLE\%\%/$table/;
   }

  merge_hash( $newtags, \%tags ) if defined $newtags and UNIVERSAL::isa( $newtags, 'HASH' );
  check_blocks( \%tags ) if exists $newtags->{blockorder} or exists $newtags->{blocks};

  my @blocks =  find_blocks( $text,     \%tags, $opts );
  @blocks    = merge_blocks( \@blocks,  \%tags, $opts );
  @blocks    =  nest_blocks( \@blocks,  \%tags, $opts );
  return     process_blocks( \@blocks,  \%tags, $opts );
 }


sub check_blocks
 {
  my $tags   = shift;
  my %blocks = %{ $tags->{blocks} };
  delete @blocks{ @{ $tags->{blockorder} } };
  Carp::carp("No order specified for blocks '" . join(', ', keys %blocks ) . "'\n") if keys %blocks;
 }


sub find_blocks
 {
  my ($text, $tags, $opts) = @_;
  my @blocks;

  for my $line ( split(/\n/, $text) )
   {
    my $block = start_block( $line, $tags, $opts );
    push @blocks, $block if $block;
   }
  return @blocks;
 }


sub start_block
 {
  ## Crea un blocco
  my ($text, $tags, $opts) = @_;
  return { type => 'end', level => 0 } unless $text;

  ## sfoglia uno a uno i blocchi che conosce per vedere se li puo'
  ## applicare al testo. Procede quindi per esclusione
  for my $block (@{ $tags->{blockorder} })
   {
    my ($line, $level, $indentation)  = ( $text, 0, '' );

    ## Se e' un tipo di blocco indentato ne controlla il livello di indentazione
    ## se vede che non è indentato va oltre
    if ($tags->{indented}{$block})
     {
	($level, $line, $indentation) = get_indentation( $tags, $line );
	next unless $level;
     }

    ## Se la definizione del blocco ha effetto sulla riga $marker_removed
    ## prende il valore di 1
    my $marker_removed = length ($line =~ s/$tags->{blocks}{$block}//);

    if ($block eq 'code')
     {
	$level          = 0;
	$marker_removed = 1;

	# don't remove the indent, but do remove the code indent
	#XXXIG (indentazione del code)($line = $text) =~ s/$tags->{blocks}{code}//;
     }

    next unless $marker_removed;

    return {
	    args => [ grep { defined } $1, $2, $3, $4, $5, $6, $7, $8, $9 ],
	    type => $block,
	    text => ($block eq 'code' || $block eq 'table') ? $line : format_line($line, $tags, $opts),
	    level=> $level || 0,
           };
   }
 }


sub merge_blocks
 {
  ## Unisce blocchi contigui dello stesso tipo e livello

  my ($blocks, $tags, $opts) = @_;
  my @merged;

  for my $block (@$blocks)
   {
    if (@merged and $block->{type} eq $merged[-1]{type}	and $block->{level} == $merged[-1]{level})
     {
	push @{ $merged[-1]{text} }, $block->{text};
	push @{ $merged[-1]{args} }, $block->{args};
	next;
     }

    push @merged, {	text  => [ $block->{text} ],
			type  => $block->{type},
			level => $block->{level},
			args  => [ $block->{args} ],
		  };
   }
  return @merged;
 }


sub nest_blocks
 {
  ## Unisce i blocchi innestati facenti parte dello stesso tipo e livello
  my ($blocks, $tags, $opts) = @_;
  my @merged;

  for my $block (@$blocks)
   {
    if ( @merged and $tags->{nests}{ $block->{type} }
		 and $tags->{nests}{ $merged[-1]{type} }
		 and $block->{level} > $merged[-1]{level} )
     {
	push @{ $merged[-1]{text} }, $block;
	next;
     }
    push @merged, $block;
   }
  return @merged;
 }


sub process_blocks
 {
  my ($blocks, $tags, $opts) = @_;
  my @open;

  for my $block (@$blocks)
   {
    push @open, process_block( $block,$tags,$opts )
	unless $block->{type} eq 'end';
   }
  return join('', @open);
 }


sub process_block
 {
  my ($block, $tags, $opts) = @_;
  my ($start, $end, $start_line, $end_line, $between) = @{ $tags->{ $block->{type} } };
  my @text;

  for my $line (@{ $block->{text} })
   {
    if (UNIVERSAL::isa( $line, 'HASH' ))
     {
	my $prev_end = pop @text || ();
	push @text, process_block( $line, $tags, $opts ), $prev_end;
	next;
     }

    if (UNIVERSAL::isa( $start_line, 'CODE' ))
     {
      (my $start_line, $line, $end_line) = 
				$start_line->( $line, $block->{level}, 
				@{ shift @{ $block->{args} } }, $tags, $opts);
      push @text, $start_line, $line, $end_line;
     }
    else
     {
      push @text, $start_line, $line, $end_line;
     }
   }

  pop @text if $between;
  return join('', $start, @text, $end);
 }


sub get_indentation
 {
  my ($tags, $text) = @_;

  return 0, $text unless $text =~ s/($tags->{indent})//;
  return( length( $1 ) + 1, $text, $1 );
 }


sub format_line
 {
  my ($text, $tags, $opts) = @_;
  $opts ||= {};

  $text =~ s!$tags->{strong_tag}!$tags->{strong}->($1, $opts)!eg;
  $text =~ s!$tags->{exponent_tag}!$tags->{exponent}->($1, $opts)!eg;
  $text =~ s!$tags->{strike_tag}!$tags->{strike}->($1, $opts)!eg;
  $text =~ s!$tags->{emphasized_tag}!$tags->{emphasized}->($1, $opts)!eg;
  $text =~ s!$tags->{center_tag}!$tags->{center}->($1, $opts)!eg;
  $text =~ s!$tags->{right_tag}!$tags->{right}->($1, $opts)!eg; 
  $text =~ s!$tags->{evidence_tag}!$tags->{evidence}->($1, $opts)!eg;
  $text =~ s!$tags->{underline_tag}!$tags->{underline}->($1, $opts)!eg;
  $text =~ s!$tags->{colored_tag}!$tags->{colored}->($1, $2, $opts)!eg;

  ## Font size
  ##
  foreach (
	['\+{4}',	"<span style=\"font-size: 200%;\">","</span>"],
	['\+{3}',	"<span style=\"font-size: 170%;\">","</span>"],
	['\+{2}',	"<span style=\"font-size: 140%;\">","</span>"],
	['\*{4}',	"<span style=\"font-size: 40%;\">","</span>"],
	['\*{3}',	"<span style=\"font-size: 70%;\">","</span>"],
	['\*{2}',	"<span style=\"font-size: 90%;\">","</span>"],
		  )
   { while ($text=~ s/(@$_[0])([^\1]*@$_[0])/@$_[1]$2/) { $text=~ s/@$_[0]/@$_[2]/; } }

  $text = find_extended_links( $text, $tags, $opts ) if $opts->{extended};

  $text =~ s|(?<!["/>=])\b([A-Za-z]+(?:[A-Z]\w+)+)|
			$tags->{link}->($1, $opts)|egx
			if !defined $opts->{implicit_links} or $opts->{implicit_links};

  return $text;
 }


sub find_extended_links
 {
  my ($text, $tags, $opts) = @_;
  my ($start, $end) = @{ $tags->{extended_link_delimiters} };
  my $position = 0;

  while (1)
   {
	my $open       = index $text, $start, $position;
	last if $open  == -1;
	my $close      = index $text, $end, $open;
	last if $close == -1;

	my $text_start = $open + length $start;
	my $extended   = substr $text, $text_start, $close - $text_start;

	$extended  = $tags->{link}->( $extended, $opts );
	substr $text, $open, $close - $open + length $end, $extended;
	$position += length $extended;
   }
  return $text;
 }


sub make_html_link
 {
  my ($link, $opts)        = @_;
  $opts                  ||= {};

  ($link, my $title)       = find_link_title( $link, $opts );
  ($link, my $is_relative) = escape_link( $link, $opts );

  my $prefix=( defined $opts->{prefix} && $is_relative ) ? $opts->{prefix} : '';
  return qq|<a href="$prefix$link">$title</a>|;
 }


sub escape_link
 {
  my ($link, $opts) = @_;
  #  my $u = URI->new( $link );

  #  return $link if $u->scheme();

  # it's a relative link
  # return( uri_escape( $link ), 1 );
 }


sub find_link_title
 {
  my ($link, $opts)    = @_;
  my $title;
  ($link, $title)      = split(/\|/, $link, 2) if $opts->{extended};
  $title             ||= $link;

  return $link, $title;
 }

