## IGSuite 4.0.0
## Procedure: Digestbase.pm
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

package Digest::base;

use strict;
use vars qw($VERSION);
$VERSION = "1.00";

# subclass is supposed to implement at least these
sub new;
sub clone;
sub add;
sub digest;

sub reset {
    my $self = shift;
    $self->new(@_);  # ugly
}

sub addfile {
    my ($self, $handle) = @_;

    my $n;
    my $buf = "";

    while (($n = read($handle, $buf, 4*1024))) {
        $self->add($buf);
    }
    unless (defined $n) {
	require Carp;
	Carp::croak("Read failed: $!");
    }

    $self;
}

sub add_bits {
    my $self = shift;
    my $bits;
    my $nbits;
    if (@_ == 1) {
	my $arg = shift;
	$bits = pack("B*", $arg);
	$nbits = length($arg);
    }
    else {
	($bits, $nbits) = @_;
    }
    if (($nbits % 8) != 0) {
	require Carp;
	Carp::croak("Number of bits must be multiple of 8 for this algorithm");
    }
    return $self->add(substr($bits, 0, $nbits/8));
}

sub hexdigest {
    my $self = shift;
    return unpack("H*", $self->digest(@_));
}

sub b64digest {
    my $self = shift;
    require IG::MIMEBase64;#XXXIG
    my $b64 = IG::MIMEBase64::encode($self->digest(@_), "");#XXXIG
    $b64 =~ s/=+$//;
    return $b64;
}

1;

__END__

=head1 NAME

Digest::base - Digest base class

=head1 SYNOPSIS

  package Digest::Foo;
  use base 'Digest::base';

=head1 DESCRIPTION

The C<Digest::base> class provide implementations of the methods
C<addfile> and C<add_bits> in terms of C<add>, and of the methods
C<hexdigest> and C<b64digest> in terms of C<digest>.

Digest implementations might want to inherit from this class to get
this implementations of the alternative I<add> and I<digest> methods.
A minimal subclass needs to implement the following methods by itself:

    new
    clone
    add
    digest

The arguments and expected behaviour of these methods are described in
L<Digest>.

=head1 SEE ALSO

L<Digest>
