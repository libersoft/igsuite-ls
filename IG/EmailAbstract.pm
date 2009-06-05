## IGSuite 4.0.0
## Procedure: EmailAbstract.pm
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

package Email::Abstract;

use IG;
use IG::Utils;
use vars qw( %messages @messages $VERSION );

$VERSION = '4.0.0';

local $SIG{__WARN__} = sub {0};
local $SIG{__DIE__} = sub {0};

sub new
 {
  my $type = shift;
  my %opt  = @_;
  my $self = {};

  ## Initialize global
  %messages = ();
  @messages = ();
      
  %messages = _find_related( $opt{root_id} );
  return bless $self, $type;
 }

###############################################################################
###############################################################################
sub get_msgs
 {
  my $self = shift;
  return @messages;
 }

###############################################################################
###############################################################################
sub get_branch
 {
  my $self = shift;
  my ($msg_id) = @_;
  
  return (IG::WebMail::ParseAddress($messages{$msg_id}{sender}))[0] . ' - '.
         $messages{$msg_id}{issue} . ' '.
         substr( $messages{$msg_id}{timeissue},0,5 ) . ' - '.
         IG::TextElide( string => $messages{$msg_id}{subject}, length => 50);
 }

###############################################################################
###############################################################################
sub get_header
 {
  my $self = shift;
  my ($msg_id, $hdr) = @_;
  my $header = $hdr eq 'References' ? 'idsreferences'
             : $hdr eq 'In-Reply-To' ? 'inreplyto'
             : $hdr eq 'Message-ID' ? 'originalid'
             : $hdr eq 'subject' ? 'subject'
             : $hdr;
  my $head = $messages{$msg_id}{$header};
  return $head;
 }

###############################################################################
###############################################################################
sub _find_related
 {
  my $id = shift;
  my %unique_id;

  my $cid = DbQuery( query => "select id, originalid, subject, idsreferences,".
                              " sender, issue, timeissue, status ".
                              "from email_msgs ".
                              "where threadid='$id' and owner='$auth_user' ".
                              "order by issue desc, timeissue desc",
                     type  => 'UNNESTED' );
          
  while ( my @row = FetchRow($cid) )
   {  
    next if $unique_id{$row[1]};
    push @messages, $row[1];
    $unique_id{$row[1]}{id}            = $row[0];
    $unique_id{$row[1]}{originalid}    = $row[1];
    $unique_id{$row[1]}{subject}       = $row[2];
    $unique_id{$row[1]}{idsreferences} = $row[3];
    $row[4] =~ s/[\"\']//g;
    $unique_id{$row[1]}{sender}        = $row[4];
    $unique_id{$row[1]}{issue}         = $row[5];
    $unique_id{$row[1]}{timeissue}     = $row[6];
    $unique_id{$row[1]}{status}        = $row[7];
   }

  return %unique_id;
 }

1;
