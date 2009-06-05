## IGSuite 4.0.0
## Procedure: WebMail.pm
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

package IG::WebMail;

use strict;
use IG;
use Carp qw(verbose croak);

use vars qw( $hitquota $folder $escapedfolder %folderinfo $VERSION $error );
$VERSION = '4.0.0';

#############################################################################
#############################################################################
sub SendMsg
 {
  ## Valid Header values
  ##  From		To			CC
  ##  Bcc		Reply-To		Subject
  ##  X-Mailer       	X-IPAddress		Message-Id
  ##  Date		MIME-Version		Disposition-Notification-To
  ##  Content-Type	In-Reply-To		References
  ##  X-Priority        			Content-Transfer-Encoding

  my %mail = @_;

  die ("No receiver email address specified!")
    if !$mail{To} && !$mail{CC} && !$mail{Bcc}; ##XXX2TEST

  ## Populate empty values
  $mail{'From'}         ||= IG::UsrInf('email') || "$auth_user\@localhost";
  $mail{'Reply-To'}     ||= $mail{'From'};
  $mail{'Subject'}      ||= 'No subject';
  $mail{'Content-Type'} ||= 'text/plain';
  $mail{'X-Mailer'}     ||= "IGWebMail $IG::VERSION";
  $mail{'Date'}         ||= IG::GetDateExtended();

  ## Check if caller wants a different smtp server
  my $smtp_server = delete $mail{'Smtp-Server'};
     $smtp_server =~ s/\:(\d+)$//;
  my $smtp_port   = $1;

  ## Encode body message to quoted printable if needed
  if (   !$mail{'Content-Transfer-Encoding'}
       && $mail{'Content-Type'} =~ /^text/i
     )
   {
    require IG::QuotedPrint;
    $mail{'Content-Transfer-Encoding'} = 'quoted-printable';
    $mail{'Message'} = QuotedPrint::encode_qp( $mail{'Message'} );
   }

  ## Try to use classic Unix Sendmail program if configured by user
  if ( !$smtp_server && $IG::ext_app{sendmail} && -e $IG::ext_app{sendmail} )
   {
    $mail{To} = $mail{From} if !$mail{To}; ##XXX2TEST

    my $sendmail_cmd = "$IG::ext_app{sendmail} ".
                       "-oem ".
                       "-oi ".
                       "-t 1>&2";

    open (SENDMAIL, "|$sendmail_cmd")
      or die("Can't execute '$sendmail_cmd'.\n");

    foreach ( keys %mail )
     {
      next if $_ eq 'Message';
      print SENDMAIL "$_: $mail{$_}\n";
     }

    print SENDMAIL "\n$mail{Message}";
    close(SENDMAIL) or die("Sendmail error! Retry and check your message.\n");

    return 1;
   }

  ## Try to use Net::SMTP
  eval("require Net::SMTP");
  if ( !$@ )
   {
    ## first we have to extract email addresses from: To, Cc, Bcc
    require IG::MailAddress;
    my (@addresses, %dejavue);
    for ( qw( To CC Bcc ) )
     {
      for ( Mail::Address->parse( $mail{$_} ) )
       {
        my $addr = $_->address;
        next if $dejavue{$addr}++;
        push @addresses, $addr;
       }
     }

    ## have we got valid receivers addresses
    unless( @addresses )
     {
      $IG::WebMail::error = 'No addresses found to send the message to';
      return 0;
     }

    $mail{To} ||= $mail{From}; ##XXX2TEST

    ## connect to smtp server
    my $smtp;
    my %_con_args = ( Host    => $smtp_server || $IG::smtp_conf{host},
                      Port    => $smtp_port   || $IG::smtp_conf{port},
                      Hello   => (IG::WebMail::ParseAddress( $mail{From} ))[2],
                      Timeout => $IG::smtp_conf{timeout} || 60,
                      Debug   => $IG::smtp_conf{debug}   || 0,
                      ExactAddresses => 1 );

    if ( $IG::smtp_conf{usessl} )
     {
      ## use ssl
      eval("require Net::SMTP::SSL");
      if ( $@ )
       {
        $IG::WebMail::error = "You have to install 'Net::SMTP::SSL' ".
                              "to use SSL on SMTP connection.";
        return 0;
       } 
      $smtp = Net::SMTP::SSL->new( %_con_args );
     }
    else
     {
      ## plain connection
      $smtp = Net::SMTP->new( %_con_args );
     }

    if ( !$smtp )
     {
      $IG::WebMail::error = "Can't connect to SMTP Server";
      return 0;
     }

    ## authenticate user
    if ( !$smtp_server && $IG::smtp_conf{login} ) 
     {
      eval("require Authen::SASL");
      if ( $@ )
       {
        $IG::WebMail::error = "You have to install 'Athen::SASL' perl module ".
                              "to use SMTP authentication.";
        return 0;
       }
      elsif ( !$smtp->auth( $IG::smtp_conf{login}, $IG::smtp_conf{pwd} ) )
       {
        $IG::WebMail::error = "SMTP Authentication failed or not needed";
        return 0;
       }
     }

    ## start mail message
    $smtp->mail( ( IG::UsrInf('email') || "$auth_user\@localhost" ) . "\n" );
    $smtp->recipient( @addresses, { SkipBad => 1 } );
    $smtp->data();

    ## send header part
    foreach ( keys %mail )
     {
      next if $_ eq 'Message';
      $smtp->datasend( "$_: $mail{$_}\n" );
     }

    ## send body part
    $smtp->datasend("\n$mail{Message}\n");
    $smtp->dataend();
    $smtp->quit;
    return 1;
   }

  ## As last chance use IG::MailSendmail
  else
   {
    require IG::MailSendmail;

    ## force an host and port for smtp server if requested
    unshift ( @{$Sendmail::mailcfg{'smtp'}} , $smtp_server )   if $smtp_server;
    $Sendmail::mailcfg{'port'} = $smtp_port                    if $smtp_port;

    ## send the message
    Sendmail::sendmail( %mail );

    ## restore original smtp config values
    shift @{$Sendmail::mailcfg{'smtp'}}                        if $smtp_server;
    $Sendmail::mailcfg{'port'} = ($IG::smtp_conf{port}  || 25) if $smtp_port;

    return 1 if ! $Sendmail::error;
    $IG::WebMail::error = $Sendmail::error;
    return 0;
   }
 }

#############################################################################
#############################################################################
sub SanitizeHtml
 {
  my $html = shift;

  #XXX2DEVELOPE
  #eval("require HTML::StripScripts::Parser");
  #if ( ! $@ )
  # {  
  #  my $hss = HTML::StripScripts::Parser->new
  #             (
  #              {
  #               Context        => 'Document',
  #               #BanList       => [qw( br img )],
  #               AllowSrc       => IG::ConfigParam('webmail.no_extsrc'),
  #               AllowHref      => 1,
  #               AllowRelURL    => 1,
  #               AllowMailto    => 0,
  #               EscapeFiltered => 0,
  #               Rules          => { img => { title     => 1,
  #                                            src       => qr{^(http\:\/\/|webmail)} },
  #                                 },
  #              },
  #              strict_comment => 1,             ## HTML::Parser options
  #              strict_names   => 1,
  #             );
  #                                                     
  #  return $hss->filter_html($html);
  # }

  require IG::MailHtmlFilter;
  return IG::MailHtmlFilter::sanitize( $html );
 }

#############################################################################
#############################################################################
sub CheckFolders
 {
  my @row;
  my $totalfoldersize;

  ## set/reset base folders
  %folderinfo = ( INBOX     => { name => $lang{INBOX} },
		  SENT      => { name => $lang{SENT}  },
		  TRASH     => { name => $lang{TRASH} },
		  DRAFTS    => { name => $lang{DRAFTS}},
		  PROTOCOLS => { name => $lang{PROTOCOLS}},
		);

  ## study user folders
  my $cid = DbQuery( query => "select folder, count(*), sum(size), status ".
                              "from email_msgs ".
                              "where owner='$auth_user' ".
                              "group by folder, status",
                     type  => 'UNNESTED' );
 
  while ( @row = FetchRow($cid) )
   {
    $folderinfo{$row[0]}{name}  ||= $lang{$row[0]} || $row[0];
    next if !$row[2];
    $folderinfo{$row[0]}{size}   += $row[2];
    $folderinfo{$row[0]}{unread} += $row[1] if $row[3] !~ /r/i;
    $folderinfo{$row[0]}{msgs}   += $row[1];
    $totalfoldersize += $row[2];
   }

  $hitquota = $IG::folderquota && $totalfoldersize >= ($IG::folderquota * 1024)
            ? 1
            : 0;
 
  ## set a valid current folder
  $folder        =    $folderinfo{$on{folder}}
                   || $on{folder} eq 'all'
		 ? $on{folder}
		 : 'INBOX';
  $escapedfolder = MkUrl($folder);

  ## mk mail spool dir
  IG::WebMail::MkSpoolDir("$IG::user_dir${S}MailBox${S}$folder");
 }

###############################################################################
###############################################################################
sub EmptyTrash
 {
  my $deleted_msg;
  my $cid = DbQuery( type  => 'AUTO',
                     query => "select id from email_msgs ".
                              "where owner='$IG::auth_user'".
                              " and folder='TRASH'" );

  while (my $id = FetchRow($cid))
   {
    ## Delete message on filesystem
    ++$deleted_msg;
    my $msg_to_delete = "$IG::user_dir${IG::S}MailBox${IG::S}TRASH${IG::S}$id";

    if (-e $msg_to_delete )
     {
      unlink( $msg_to_delete ) or die("Can't delete '$msg_to_delete'.\n");
     }

    ## Delete messages tags
    DbQuery( query => [("delete from email_msgtags ".
                        "where msgid='".DbQuote($id)."'",
			
                        "delete from comments ".
                        "where referenceproc='webmail'".
	                " and referenceid='".DbQuote($IG::auth_user."_".$id)."'"
		       )],
             type  => 'UNNESTED' );
   }

  DbQuery( query => "delete from email_msgs ".
                    "where owner='$IG::auth_user' and folder='TRASH'",
           type  => 'UNNESTED' );

  LogD('email trash emptied', 'delete', 'email_msgs');

  return $deleted_msg;
 }

###############################################################################
###############################################################################
sub TextMsgBeautify
 {
  my $text = shift;
     $text =~ s/^(\n|\r)+$//msg; ## remove leading and trailing spaces
     $text = IG::WebMail::MkLink( $text );
     $text =~ s/^((\&gt\;\s*)+)(.+)$/_quote_beautify($1,$3)/meg;

  ## smiles
  $text =~ s/\:[o\-\=]*[\)\]\>]+
            /<img src=\"$IG::img_url\/emoticon_smile.png\" align=\"top\">/xg;
  $text =~ s/\:[o\-\=][\(\[]+
            /<img src=\"$IG::img_url\/emoticon_unhappy.png\" align=\"top\">/xg;
  $text =~ s/\:[o\-\=][pP]
            /<img src=\"$IG::img_url\/emoticon_tongue.png\" align=\"top\">/xg;
  $text =~ s/[\;\,][o\-\=][\)\]\>]+
            /<img src=\"$IG::img_url\/emoticon_wink.png\" align=\"top\">/xg;
  return $text;
 }

{
 my $old_level = '';

sub _quote_beautify
 {
  my ($level, $text) = @_;
  return '' if !$text || $text =~ /^(\s|(\&nbsp\;\s*))*<br>$/i;
  my @colours = qw ( undef #009900 #ff6633 #9900cc #ff3333  );
  my $lv = $level =~ s/\&gt\;//g;
  my $html = "$level<span style=\"font-style:italic; margin-left:20px;".
             "color:". ($colours[$lv] || '#009900').
             ";\">". ('&gt;' x $lv). " $text<\/span>";
     $html = '<br style="line-height:7px">' . $html if $lv ne $old_level;
  $old_level = $lv;
  return $html;
 }
}

###############################################################################
###############################################################################
sub ApplyUserFilter
 {
  my $target_folder = shift || 'INBOX';
  my $when_apply    = ${{ INBOX => 1, SENT => 2 }}{$target_folder}; 
  my @ids;
  my $id;

  ## count how many messages we have before filtering
  DbQuery( "select count(*) ".
           "from email_msgs ".
           "where folder='$target_folder' and owner='$auth_user'");
  my $before_filter = FetchRow();

  ## load user filters
  my $conn = DbQuery( "select query, action, replymsg ".
                      "from email_filter ".
                      "where owner='$auth_user' and when_apply=$when_apply");

  while ( my @row = FetchRow($conn) )
   {
    ## Check if we have to send an automatic reply message
    if ( $row[2] && $when_apply == 1 )
     {
      ## inside $row[0] we already have a user limit set by mkfilter()
      my $subconn = DbQuery( "select id, status, sender, subject, contactid ".
                             "from email_msgs ".
                             "where $row[0]" );

      while ( my @msgrow = FetchRow($subconn) )
       {
        ## We don't want reply to message already replied
        next if $msgrow[1] =~ /e/i;

        ## Update messagge status to 'replied'
        $msgrow[1] = IG::WebMail::UpdateEmailMsgStatus
                      ( original_status => $msgrow[1],
                        status          => 'e',
                        message_id      => $msgrow[0] );

        ## Send reply message
        $on{to}	       = $msgrow[2];
        $on{subject}   = "Re: $msgrow[3]";
        $on{body}      = $row[2];
        $on{contactid} = $msgrow[4];
        sendmessage();
       }
     }

    ## Check if we have to move the message in a folder specified by filter
    if ( $row[1] )
     {
      ## Find message that we have to move and update the database
      DbQuery("select id from email_msgs where $row[0]");
      push @ids, $id while $id = FetchRow();
      DbQuery("$row[1] where $row[0]");

      ## Move also the messages files from the original to the new folder
      for my $i (@ids)
       {
        DbQuery( "select folder from email_msgs ".
                 "where id='$i' and owner='$auth_user' limit 1" );

        my $folder = FetchRow();

        IG::FileCopy( $IG::user_dir.${S}.'MailBox'.${S}.$target_folder.${S}.$i,
                      $IG::user_dir.${S}.'MailBox'.${S}.$folder       .${S}.$i,
                      1
                    ) if -e "$IG::user_dir${S}MailBox${S}$target_folder${S}$i";
       }
     }
   } 

  ## Count messages after filtering
  DbQuery( "select count(*) ".
           "from email_msgs ".
           "where folder='$target_folder' and owner='$auth_user'");
  my $after_filter = FetchRow();

  ## Count and return how many messages we have filtered and moved
  return $before_filter - $after_filter;
 }

###############################################################################
###############################################################################
sub MkLink
 {
  my $text = shift || return '&nbsp;';
  return $text if IG::CkHtml($text) && $IG::webmail_prefs =~ /html\_ok/;

  $text = MkEntities( $text );
  $text =~ s/\n/<br>\n/g;
  $text =~ s/ {2}/ &nbsp;/g;
  $text =~ s/\t/ &nbsp;&nbsp;&nbsp;&nbsp;/g;

  ## Net protocols. 
  $text=~ s/(\s|^)(https|http|ftp)(\:\/\/)([^\/\s]+)([^\s\"\'\r\n<>\(\)]*)(\s|$)/
            $1 . IG::BuildLink("$2$3$4$5") . $6/eg;

  ## Mailto
  $text =~ s/(>|\&lt\;|\s|^)([\w._%-]+@[\w._%-]+\.\w{2,4})(\,|<|\&gt\;|\s|$)/
	     "$1<a href=\"javascript:winPopUp('webmail?".
                                              "action=composemessage&amp;".
                                              "onsend=close&amp;".
                                              "to=$2',700,600,'compose')\">".
	     "$2<\/a>$3"/esmg;

  return $text;
 }


###############################################################################
###############################################################################
sub MkSpoolDir
 {
  ##XXX needed only by IG3.2
  my $dir = shift || "$IG::user_dir${IG::S}MailBox${IG::S}INBOX";

  if (! -d $dir && $folder ne 'all')
   {
    mkdir($dir, 0755) or croak("Can't create directory '$dir'.\n");
   }
 }

##############################################################################
##############################################################################
sub ParseAddress
 {
  require IG::MailAddress;
  my $address = shift;
  return if !$address;
  my @q = Mail::Address->parse( $address );
  my $q = shift @q;
  return ('unknown', 'unknown', 'unknown', 'unknown') if !$q;
  my $email	= $q->address;
  my $name	= $q->name || $email;
  my $host	= $q->host;
  my $format    = $q->format;

  return ($name, $email, $host, $format);
 }

##############################################################################
##############################################################################
sub _emailInLists
 {
  require IG::MailAddress;
  my ( $emailToSearch, @lists ) = @_;

  foreach my $list (@lists)
   {
    my @emails = Mail::Address->parse($list); #XXX2TEST
    foreach my $email (@emails)
     {
      return 1 if uc( $email->address ) eq uc( $emailToSearch );
     }
   }
  return 0;
 }

###############################################################################
###############################################################################
sub AddMimeHeader
 {
  ## Add a Mime Header to a contents and return it as a string
  ## argument (contents, name, type, encoding, content_id)
  my %data = @_;

  ## you can call this sub with a list of arguments too
  ( $data{contents},
    $data{name},
    $data{type},
    $data{encoding},
    $data{content_id} ) = @_ if !$data{contents};
    
  die("Any content! I can't add a mime header.\n") if !$data{contents};

  ## Trim an eventually path info from the filename
  $data{name} =~ s/^.*(\\|\/|\:)//;

  ## Find a valid content type
  $data{type} ||= (IG::FileStat($data{contents}, 'content'))[0];
  $data{type} ||= 'application/octet-stream';

  $data{name} = 'Email Message' if $data{type} eq 'message/rfc822';

  ## Encode contents
  if (!$data{encoding} || $data{encoding} eq 'base64')
   {
    ## Encode to Base64
    $data{encoding} = 'base64';
    $data{contents} = Mime::Base64::encode_base64( $data{contents} );
   }
  elsif ($data{encoding} eq 'quoted-printable')
   {
    ## Encode to Quoted Printable
    $data{contents} = QuotedPrint::encode_qp( $data{contents} );
    $data{contents} =~ s/^From/=46rom/gm;
   }
  elsif ($data{encoding} eq '7bit')
   {
    ## Used usually for message forward
    $data{contents} =~ s/^From .+(\n|\r)//m;
   }
  else
   {
    die("1423:Error no valid encoding value\n");
   }

  ## Add a mime header to the contents
  return "Content-Type: $data{type};\n".
	 "\tname=\"$data{name}\"\n".
	 "Content-Transfer-Encoding: $data{encoding}\n".
         "Content-disposition: attachment; filename=\"$data{name}\"\n".
	 ($data{content_id} ? "Content-ID: <$data{content_id}>\n" : '').
	 "\n".
	 $data{contents};
 }

###############################################################################
###############################################################################
sub GetAttList
 {
  my @attlist      = ();
  my $attach_cnt   = 0;
  my $savedattsize = 0;

  opendir (MAILDIR, $IG::user_dir)
    or die("Can't open user directory '$IG::user_dir'!\n");

  foreach ( sort grep /^(webmail-att-.+)$/, readdir MAILDIR )
   {
    $attach_cnt++;
    my $file_name = $_;
    my $file_path = $IG::user_dir . $IG::S . $file_name;

    my $attach_size = ( -s $file_path );
    $savedattsize += $attach_size;

    my ( $_type, $_name, $_encoding );
    open (ATTFILE, '<', $file_path )
      or die("Can't open attachment file '$file_path'.\n");
    my $line = <ATTFILE> . <ATTFILE> . <ATTFILE>;
    close (ATTFILE);

    $_type     = $1 if $line =~ /Content\-Type\: ([^\;]+)\;/i;
    $_name     = $1 if $line =~ /name\=\"([^\"]+)\"/i;
    $_encoding = $1 if $line =~ /Content\-Transfer\-Encoding\: (\w+)/i;

    push @attlist, [ IG::MkEntities( $_name || "Unnamed$attach_cnt"),
                     IG::MkByte($attach_size),
                     $file_name,
                     $_type,
                     $_encoding ];
   }

  closedir (MAILDIR);
  return $savedattsize, @attlist;
 }

###############################################################################
###############################################################################
sub AddAttachment
 {
  my %data = @_;
  #($data{attachment_path},
  # $data{content_type},
  # $data{encoding},
  # $data{attachment_name},
  # $data{content_id}

  die("I need an attachment_path.\n") if !$data{attachment_path};

  ## Adjust attach name
  $data{attachment_name} ||=  $data{attachment_path};
  $data{attachment_name}   =~ s/([E1-9]\d\d\d\d\d)\.(\d\d)/$1\_$2/;
  
  my ($savedattsize, @attlist) = IG::WebMail::GetAttList();
  my $target_file = "webmail-att-" . IG::MkId(15);
  my $contents;

  ## Read the file to attach
  open (RFH, '<', $data{attachment_path})
    or die("Can't open '$data{attachment_path}'.\n");
  binmode(RFH);
  $contents .= $_ while <RFH>;
  close(RFH);

  ## check storable space limit
  if (    $IG::attlimit
       && ($savedattsize + length($contents)) > ($IG::attlimit * 1048576)
     )
   {
    ##IG2DEVELOPE an IG::Warn() instead of die
    die("$lang{att_overlimit} $IG::attlimit MB!\n");
   }

  if ( defined wantarray )
   {
    ## Return an attachment file
    return IG::WebMail::AddMimeHeader( contents   => $contents,
                                       name       => $data{attachment_name},
                                       type       => $data{content_type},
                                       encoding   => $data{encoding},
                                       content_id => $data{content_id} );
   }
  else
   {
    ## Append the file with mimeheader to the attachments list
    open (WFH, '>', "$IG::user_dir${S}$target_file")
      or die("Can't write on '$IG::user_dir${S}$target_file'.\n");
    binmode(WFH);
    print WFH IG::WebMail::AddMimeHeader( contents   => $contents,
                                          name       => $data{attachment_name},
                                          type       => $data{content_type},
                                          encoding   => $data{encoding},
                                          content_id => $data{content_id} );
    close(WFH);
   }
 }

###############################################################################
###############################################################################
sub ParseHtmlBodyPart
 {
  ## Parse an Html body message and extract from it 
  ## and add as attachments all images.
  my ($contents) = @_;

  eval 'require LWP::Simple';
  return $contents if $@;

  my $img_cnt = 1;
  my %images;
  my $fake_html = $contents;
  my $urlbase;
  my $srvbase;

  ## find or set a base href XXX2TEST
  $contents  =~ /<base.*?href\s*\=\s*([\'\"\`])(.+?)\1/i;
  $urlbase   = $2 || "$IG::cgi_url/";
  $urlbase   =~ s!/[^/]+$!/!;
  ($srvbase) = $urlbase =~ /^([^\/]+\:\/\/[^\/]+)/;
  return $contents if !$urlbase || !$srvbase;
    
  ## Only absolute path can be transformed
  ## find image url to be attached
  while ( $fake_html =~ s/<img.*?src\s*\=\s*([\'\"\`])(.+?)\1//is )
   {
    my $img_url = $2;
    next if $img_url =~ /xid\=\%\%xid\%\%/;

    ## unique image
    $images{IG::Crypt($img_url)} = $img_url;
   }

  ## download images and build entities
  foreach my $img_name (keys %images)
   {
    my $img_file = $IG::temp_dir . $IG::S . $img_name;
    my ($ext) = $images{$img_name} =~ /(\.gif|\.jpg|\.png)$/i;
    my $img_url = $images{$img_name} =~ /^http\:\/\//
                ? $images{$img_name}
                : $images{$img_name} =~ /^\//
                  ? $srvbase . $images{$img_name}
                  : $urlbase . $images{$img_name};

    if ( LWP::Simple::is_success( LWP::Simple::getstore($img_url,$img_file) ) )
     {
      ## substitute image url with cid
      my $cid   = IG::MkId(20) . '@' . IG::MkId(20);
      $contents =~ s/(<img.*?src\s*\=\s*)([\'\"\`])(\Q$images{$img_name}\E)\2
                    /$1$2cid\:$cid$2/xisg;

      ## add image as attach
      IG::WebMail::AddAttachment( attachment_path => $img_file,
                                  attachment_name => 'Image_' .
                                                     $img_cnt++ .
                                                     $ext,
                                  content_id      => $cid );

      ## delete temporary image file
      IG::FileUnlink($img_file)
        or die("Can't delete this temporary file '$img_file'.\n");
     }
   }
  
  return $contents;
 }

###############################################################################
###############################################################################
sub UploadAttachment
 {
  my $param       = shift;
  my $target_file = "webmail-att-" . IG::MkId(15);
  my ($savedattsize, @attlist) = IG::WebMail::GetAttList();

  my $status = IG::FileUpload(	param_name  => $param,
		        	target_dir  => $IG::user_dir . $IG::S,
		        	target_file => $target_file,
		        	filter      => \&IG::WebMail::AddMimeHeader );

  ## check storable space limit
  $savedattsize += -s "$IG::user_dir$IG::S$target_file";
  if ( $IG::attlimit && $savedattsize > ($IG::attlimit * 1048576) )
   { die("$lang{att_overlimit} $IG::attlimit MB!\n") }
  
  return $status;
 }

###############################################################################
###############################################################################
sub DeleteAllAttachments
 {
  my $currentfile;

  opendir (MAILDIR, $IG::user_dir)
    or die("Can't open user directory '$IG::user_dir'!\n");

  while (defined( $currentfile = readdir(MAILDIR) ))
   {
    if ($currentfile =~ /^(webmail-att-.+)$/)
     {
      $currentfile = $1;
      IG::FileUnlink("$IG::user_dir${S}$currentfile")
        or die("Can't delete attachment '$IG::user_dir${S}$currentfile'.\n");
     }
   }
  closedir (MAILDIR);
 }

###############################################################################
###############################################################################
sub DeleteAttachments
 {
  my $attref   = shift;
  my @attfiles = ref( $attref ) eq 'ARRAY' ? @{$attref} : ($attref) ;

  for my $currentfile ( @attfiles )
   {
    if ( $currentfile =~ s/^(webmail-att-.+)$/$1/ )
     {
      IG::FileUnlink("$IG::user_dir${S}$currentfile")
        or die("Can't delete '$IG::user_dir${S}$currentfile'.\n");
     }
   }
 }

###############################################################################
###############################################################################
sub GetTags
 {
  my @email_tags = ();
  my $conn = DbQuery("select email_msgtags.name ".
                     "from email_msgtags ".
                     "left join email_msgs ".
                     "on email_msgtags.msgid = email_msgs.id ".
                     ($on{folder} ne 'PROTOCOLS'
                      ? "where email_msgs.owner='$auth_user' "
                      : '').
                     "group by email_msgtags.name ".
                     "order by email_msgtags.name");

  push @email_tags, $_ while $_ = FetchRow($conn);
  return \@email_tags;
 }

################################################################################
###############################################################################
sub AddVCard
 {
  my $cr = "\n\r";
  my $encoding = "CHARSET=iso-8859-1;ENCODING=QUOTED-PRINTABLE";
  my ($savedattsize, @attlist) = IG::WebMail::GetAttList();
  my $vcard;

  $vcard = "BEGIN:VCARD$cr".
           "EMAIL;$encoding:".
           QuotedPrint::encode_qp(IG::UsrInf('email')) . $cr.

           "FN;$encoding:".
           QuotedPrint::encode_qp(IG::UsrInf('name')) . $cr.

           "ORG;$encoding:".
           QuotedPrint::encode_qp($IG::soc_name) . $cr.

           "ROLE;$encoding:".
           QuotedPrint::encode_qp(IG::UsrInf('function')) . $cr.

           "TEL;TYPE=WORK;$encoding:".
           QuotedPrint::encode_qp($IG::soc_tel) . $cr.

           "TEL;TYPE=FAX;TYPE=WORK;$encoding:".
           QuotedPrint::encode_qp($IG::soc_fax) . $cr.

           "URL;$encoding:".
           QuotedPrint::encode_qp($IG::soc_site) . $cr.

           "VERSION:2.1$cr" . "END:VCARD$cr";

  ## Add mime header and encode vcard info
  $vcard = 'Content-Type: text/x-vcard; name="vcard.vcf"' . "\n".
           'Content-Disposition: attachment; filename="vcard.vcf"' . "\n".
           'Content-Transfer-Encoding: quoted-printable'. "\n\n".
           QuotedPrint::encode_qp($vcard);

  ## check storable space limit
  $savedattsize += length($vcard);
  if ( $IG::attlimit && $savedattsize > ($IG::attlimit * 1048576) )
   { die("$lang{att_overlimit} $IG::attlimit MB!\n") }

  my $target_file = "webmail-att-". MkId(15);
  open (OUT, '>', "$IG::user_dir${S}$target_file")
    or die("Can't write on '$IG::user_dir${S}$target_file'.\n");
  print OUT $vcard;
  close (OUT);
 }

###############################################################################
###############################################################################
sub UpdateEmailMsgStatus
 {
  ## STATUS FLAG
  ## r read
  ## v viewed
  ## e replied
  ## n received (we have a receipt)
  ## u ???
  ## o notified to sender
  ## f this is a folder (not an email message)
  
  my %data = @_;

  my $idField = 'id';
  if ( $data{original_id} )
   {
    $idField          = 'originalid';
    $data{message_id} = $data{original_id};
   }

  ## validate params
  die("I need a message_id value.\n") if !$data{message_id};
  die("I need a status to update.\n") if !$data{status};
  die("Unknown status flag.\n")       if $data{status} =~ /[^renuofv]/i;

  if ( !$data{original_status} )
   {
    ## read previous email status
    my $cid = DbQuery( query => "select status from email_msgs ".
                                "where $idField='".DbQuote($data{message_id})."' ".
                                "limit 1",
                       type  => 'UNNESTED' );
    $data{original_status} = FetchRow($cid);
   }

  if ( $data{action} eq 'delete' )
   {
    ## delete a status flag
    $data{original_status} =~ s/$data{status}//gi;
   }
  else
   {
    ## add a new status flag
    $data{original_status} = $data{original_status}.
                             $data{status}
                           if $data{original_status} !~ /$data{status}/i;
   }

  my $new_status = lc( $data{original_status} );
     $new_status =~ s/[^renuofv]//g;

  ## perform the status update
  my $cid = DbQuery( query => "update email_msgs ".
                              "set status='$new_status' ".
                              "where $idField='".DbQuote($data{message_id})."'".
                              ( $data{status} ne 'v'
                                ? " and owner='$auth_user'"
                                : '' ),
                     type  => 'UNNESTED' );
  return $new_status;
 }

###############################################################################
###############################################################################
sub PidToId
 {
  my %data = @_;
  
  my $pid = $data{pid};
  
  my $cid = DbQuery( query => "select id, owner, sharemode from email_msgs ".
                              "where pid='".DbQuote($on{pid})."'",
	             type  => 'UNNESTED' );
  ## search best message instance: user own message, fully shared, any other
  my ($_message_id, $_owner);
  while( my( $message_id, $owner, $sharemode ) = FetchRow($cid) ) 
   {
    if( $owner eq $auth_user ) ## user own message: best case
     {
      $_message_id = $message_id;
      $_owner = $owner;
      IG::DbFinish( $cid );
      last;
     }
    if( $sharemode == 1 || !$_message_id )
     {
      $_message_id = $message_id;
      $_owner = $owner;
      ## we continue searching, maybe we find user own message
     }
   }
  return ($_message_id, $_owner);
 }

###############################################################################
###############################################################################
1;
