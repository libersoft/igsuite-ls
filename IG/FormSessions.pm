## IGSuite 4.0.0
## Procedure: FormSessions.pm
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

package FormSessions;

use strict;

use vars qw ($VERSION);
$VERSION = '4.0.0';

sub new
 {
  my $type = shift;
  my %opt  = @_;
  my $self = {};

  $self->{formid}      = $opt{formid};
  $self->{sessionid}   = $opt{sessionid} || $IG::cookie{igsuiteid};

  return bless $self, $type;
 }

sub insert
 {
  my $self = shift;
  my %opt = @_;
  my $param_name  = IG::DbQuote( $opt{param_name} );
  my $param_value = IG::DbQuote( $opt{param_value} );

  $self->{params}{$param_name} = $param_value;
 }

sub write
 { 
  my $self = shift;  
  my $query;
  my %params = %$self->{params};

  ## Clear previous session
  DbQuery( query => "delete from sessions_cache ".
                    "where formid='$self->{formid}'".
                    " or sessionid~*'$self->{sessionid}'".
                    " or keydate+2 < date'today'",
           type  => 'UNNESTED' );

  foreach my $pname ( keys %params )
   {
    DbQuery( query => "insert into sessions_cache values ".
                      "('$self->{sessionid}', '$self->{formid}',".
                      " '$pname', '$params{$pname}', '$IG::tv{today}')",
             type  => 'UNNESTED' );
   }
 }
 
sub update
 { 
  my $self = shift;  
  my %opt = @_;
  my $param_name  = IG::DbQuote( $opt{param_name} );
  my $param_value = IG::DbQuote( $opt{param_value} );

  $self->{params}{$param_name} = $param_value;

  DbQuery( query => [( "delete from sessions_cache ".
                       "where formid='$self->{formid}'".
                       " and sessionid='$self->{sessionid}'".
                       " and keyname='$param_name'",
                                
                       "insert into sessions_cache values ".
                       "('$self->{sessionid}', '$self->{formid}',".
                       " '$param_name',".
                       " '$param_value', '$IG::tv{today}')" )],
           type  => 'UNNESTED' );
   }

1;
