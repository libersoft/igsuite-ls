## IGSuite 4.0.0
## Procedure: SmsGateway.pm
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

package SmsGateway;

use strict;
use LWP::UserAgent;

use vars qw ($VERSION);
$VERSION = '4.0.0';

sub new
 {
  my $type = shift;
  my ($username, $password, $url) = @_;
  my $self = {};

  $self->{username} = $username;
  $self->{password} = $password;
  $self->{agent} = LWP::UserAgent->new;
  $self->{agent}->agent("IGSuite $IG::VERSION");

  $url =~ /(\w+)\:(\w+)\@(\w+)/
       ? ($self->{authlogin}, $self->{authpwd}, $self->{url}) = ($1,$2,$3)
       : $self->{url} = $url;

  $self->{url} ||= 'http://www.subitosms.it/gateway.php';

  $self->{agent}->authorization_basic($self->{authlogin}, $self->{authpwd})
    if $self->{authlogin};

  return bless $self, $type;
 }

#############################################################################
#############################################################################
sub sendmsg
 {
  my $self = shift;
  my %data = @_;
  my $id = 0;

  ## We can easily add '+39' because www.subitosms.it is for Italian sms only
  $data{receiver}   = '+39' . $data{receiver} if $data{receiver} !~ /^\+/;
  $data{sender}     = '+39' . $data{sender}
                      if $data{sender} !~ /^\+/ && $data{sender} !~ /[a-z]/;

  ## Subito Sms limit
  $data{sender}     =~ s/\s//g;
  $data{sender}     = substr( $data{sender}, 0, 11 );

  $self->{dest}     = $data{receiver};
  $self->{mitt}     = $data{sender};
  $self->{testo}    = $data{text};
  $self->{content}  = '';

  my $req = HTTP::Request->new( POST => $self->{url} );
  $req->content_type('application/x-www-form-urlencoded');

  for (qw ( username password mitt dest testo ) )
   {
    $self->{content} .= "$_=" .
                        IG::MkUrl($data{$_} || $self->{$_}) .
                        '&'; ## only '&' and not '&amp;'
   }

  ## debug requests
  $self->{content} .= "test=1" if $data{debug} == 1 || $data{debug} eq 'true';

  $req->content($self->{content});

  # send request
  my $res = $self->{agent}->request($req);
  if ($res->is_success)
   {
    ($id) = $res->as_string =~ /.+id\:(\d+).+$/sm;
   }

  # check the outcome
  $self->{status} = $res->status_line . "\n";
  return $id;
 }

#############################################################################
#############################################################################
sub getcredit
 {
  my $self = shift;
  my %data = @_;
  my $credit = 0;

  my $req = HTTP::Request->new(POST => $self->{url});
  $req->content_type('application/x-www-form-urlencoded');

  $self->{content} = '';
  for (qw ( username	password ))
   { $self->{content} .= "$_=" . IG::MkUrl($data{$_} || $self->{$_}) . '&'; }
  $req->content($self->{content});

  # send request
  my $res = $self->{agent}->request($req);
  if ($res->is_success)
   {
    $credit = $res->as_string; 
    $credit =~ s/.+credito\:(\d+).+$/$1/sm;
   }

  # check the outcome
  $self->{status} = $res->status_line . "\n";
  return $self->{credit} = $credit;
 }

#############################################################################
#############################################################################
sub getstatus
 {
  my $self = shift;
  my %data = @_;
  die("No message id") if !$data{id};

  my $req = HTTP::Request->new(POST => $self->{url});
  $req->content_type('application/x-www-form-urlencoded');

  $self->{content} = '';
  for (qw ( username password id ))
   { $self->{content} .= "$_=" . IG::MkUrl($data{$_} || $self->{$_}) . '&'; }
  $req->content($self->{content});

  # send request
  my $res = $self->{agent}->request($req);
  my ($header, $status) = split /\n\r*\n/, $res->as_string, 2;
  $status =~ s/\r|\n//g;

  # check the outcome
  $self->{status} = $res->status_line . "\n";
  return $status;
 }


1;
