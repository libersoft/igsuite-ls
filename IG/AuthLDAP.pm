## IGSuite 4.0.0
## Procedure: AuthLDAP.pm
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

package IG::AuthLDAP;

use strict;
use vars qw ($VERSION);
$VERSION = '3.2.6';


#############################################################################
#############################################################################
sub new
 {
  my $type = shift;
  my %opt  = @_;
  my $self = {};

  $self->{hostname}    = $opt{hostname}    || 'localhost';
  $self->{port}        = $opt{port}        || ( $opt{usessl} ? 1389 : 389 );
  $self->{version}     = $opt{version}     || 3;
  $self->{usessl}      = $opt{usessl}      || 0;
  $self->{admin_dn}    = $opt{admin_dn};
  $self->{admin_pwd}   = $opt{admin_pwd};
  $self->{search_base} = $opt{search_base};
  $self->{user_dn}     = $opt{user_dn}     || 'uid';

  ## load LDAP Perl module
  if ( $self->{usessl} )
   {
    eval("require Net::LDAPS");
    die("You have to install Perl module 'Net::LDAPS' if you want ".
        "to authenticate your users by LDAP over an SSL connection.\n"
       ) if $@;
   }
  else
   {
    eval("require Net::LDAP");
    die("You have to install Perl module 'Net::LDAP' if you want ".
        "to authenticate your users by an LDAP server.\n"
       ) if $@;
   }

  return bless $self, $type;
 }

#############################################################################
#############################################################################
sub login
 {
  my $self = shift;
  my $ldap;
  my ( $user_login, $user_pwd ) = @_;

  my ($userDn, %user_info) = $self->getUserInfo( $user_login );

  ## first case: user unknown
  return undef unless $userDn;

  ## try to use user dn to connect    
  if ( $self->{usessl} )
   {
    ## Use LDAPS (SSL)
    $ldap = Net::LDAPS->new( "$self->{hostname}:$self->{port}",
                             verify => 'none' ) or die "$@";
   }
  else
   {
    ## Use LDAP
    $ldap = Net::LDAP->new( "$self->{hostname}:$self->{port}",
                            verify => 'none' ) or die "$@";
   }

  my $mesg = $ldap->bind( $userDn, password => $user_pwd );
    
  if ( $mesg->code )
   {
    ## Bad Bind
    return undef;
   }
    
  $ldap->unbind;

  ## add login and pwd to %user_info
  $user_info{login}  = $user_login;
  $user_info{passwd} = $user_pwd;

  return (1, %user_info);
 }

#############################################################################
#############################################################################
sub getUserInfo
 {
  my $self = shift;
  my $guid = shift;
  my $dn;
  my $ldap;
  my %user_info;

  ## connect to ldap server
  if ( $self->{usessl} )
   {
    ## Use LDAPS (SSL)
    $ldap = Net::LDAPS->new( "$self->{hostname}:$self->{port}",
                             verify => 'none' ) or die "$@";
   }
  else
   {
    ## Use LDAP
    $ldap = Net::LDAP->new( "$self->{hostname}:$self->{port}",
                            verify => 'none' ) or die "$@";
   }

  ## bind to ldap server by admin dn
  my $mesg = $ldap->bind( $self->{admin_dn},
                          password => $self->{admin_pwd} );
  die "Error can't bind Admin DN: ",ldap_error_name($mesg) if $mesg->code;

  $mesg = $ldap->search( base   => $self->{search_base},
                         filter => "$self->{user_dn}=$guid",
                         scope  => 'sub' );

  $mesg->code && return undef;
  my $entry = $mesg->shift_entry;
     
  if ( $entry )
   {
    ## User exists, let's retrieve info
    $dn        = $entry->dn;
    %user_info = ( name        => ( $entry->get_value( 'sn' ).
                                    ' '.
                                    $entry->get_value( 'givenname' ) ),
                   jobphone    => $entry->get_value( 'telephonenumber' ) || '',
                   mobilephone => $entry->get_value( 'mobile' )          || '',
                   address     => (   $entry->get_value( 'street' )
                                   || $entry->get_value( 'streetaddress' )
                                   || '' ),
                   zip         => $entry->get_value( 'postalcode' )      || '',
                   city        => $entry->get_value( 'l' )               || '',
                   note        => $entry->get_value( 'description' )     || '',
                   email       => $entry->get_value( 'mail' )            || ''
                 );

    $user_info{initial} = $user_info{name};
    $user_info{initial} =~ s/^(\w)[^ ]+/$1/g;
    $user_info{initial} =~ s/ (\w)[^ ]+/$1/g;
    $user_info{initial} =~ s/[^a-zA-Z]//g;
    $user_info{initial} = substr( uc($user_info{initial}), 0, 5 );
   }
    
  ## unbind ldap server    
  $ldap->unbind;
    
  return ( $dn, %user_info );
 }

1;