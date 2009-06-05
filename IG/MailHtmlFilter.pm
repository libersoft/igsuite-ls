## IGSuite 4.0.0
## Procedure: MailHtmlFilter.pm
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

package IG::MailHtmlFilter;

use strict;

use vars qw ($VERSION);
$VERSION = '4.0.0';

my @jsevents=('onAbort', 'onBlur', 'onChange', 'onClick', 'onDblClick',
              'onDragDrop', 'onError', 'onFocus', 'onKeyDown', 'onKeyPress',
              'onKeyUp', 'onLoad', 'onMouseDown', 'onMouseMove', 'onMouseOut',
              'onMouseOver', 'onMouseUp', 'onMove', 'onReset', 'onResize',
              'onSelect', 'onSubmit', 'onUnload', 'window.open',
              '@import', 'window.location', 'location.href',
              'document.url', 'document.location', 'document.referrer');

sub sanitize
 {
  my $html = shift;
  $html =~ s/\&aps;?/\"/smg;
  $html = html4nobase($html);
  $html = _htmlclean($html);
  $html = html4disablejs($html);
  $html = html4disableembcode($html);
  $html = html4link($html);
  $html = html4disableemblink($html);
  return $html;
 }

# since this routine deals with base directive,
# it must be called first before other html...routines when converting html
sub html4nobase
 {
  my $html = shift;
  my $urlbase;

  if ( $html =~ /<base.*?href\s*\=\s*([\'\"\`])(.+?)\1/i )
   {
    $urlbase = $2;
    $urlbase =~ s!/[^/]+$!/!;
   }

  $html =~ s!\<base\s+([^\<\>]*?)\>!!gi;

  if ( $urlbase && $urlbase !~ /^file\:/ )
   {
    $html =~ s!(\<a\s+href|background|src|method|action)(=\s*"?)
	      !$1$2$urlbase!gix;

    # recover links that should not be changed by base directive
    $html =~ s!\Q$urlbase\E(http\:\/\/|https\:\/\/|ftp\:\/\/|mms\:\/\/|cid\:|mailto\:|\#)
	      !$1!gix;
   }

  return $html;
 }


# this routine is used to add target=_blank to links in a html message
# so clicking on it will open a new window
sub html4link
 {
  my $html = shift;
  $html =~ s/(<a\s+[^\<\>]*?>)/_link_target_blank($1)/igems;
  return $html;
 }

sub _link_target_blank
 {
  my $link = shift;

  if ($link =~ /(?:target=|javascript:|href="?#)/i )
   { return($link); }
  $link =~ s/<a\s+([^\<\>]*?)>/<a $1 target=\"_blank\">/is;
  return $link;
 }

# this routine is used to resolve frameset in html by
# converting <frame ...> into <iframe width="100%"..></iframe>
# so html with frameset can be displayed correctly inside the message body
#sub html4noframe
# {
#  my $html = shift;
#  $html =~ s/(<frame\s+[^\<\>]*?>)/_frame2iframe($1)/igems;
#  return($html);
# }


#sub _frame2iframe
# {
#  my $frame = shift;
#  return "" if ( $frame!~/src=/i );
#  $frame=~s/<frame /<iframe width="100%" height="250" /is;
#  $frame.=qq|</iframe>|;
#  return($frame);
# }


# this routine disables the javascript in a html message
# to avoid user being hijacked by some evil programs
sub html4disablejs
 {
  my $html = shift;
  foreach my $event (@jsevents)
   { $html=~s/$event/x_$event/isg; }

  $html =~ s/<script([^\<\>]*?)>/<disable_script$1>\n<!--\n/isg;
  $html =~ s/<!--\s*<!--/<!--/isg;
  $html =~ s/<\/script>/\n\/\/-->\n<\/disable_script>/isg;
  $html =~ s/\/\/-->\s*\/\/-->/\/\/-->/isg;
  $html =~ s/<([^\<\>]*?)javascript:([^\<\>]*?)>/<$1disable_javascript:$2>/isg;

  return $html;
 }


# this routine disables embed, applet, object tags in a html message
# to avoid user being hijacked by some evil programs
sub html4disableembcode
 {
  my $html = shift;

  foreach my $tag (qw(embed applet object))
   {
    $html =~ s!<\s*$tag([^\<\>]*?)>!<disable_$tag$1>!isg;
    $html =~ s!<\s*/$tag([^\<\>]*?)>!</disable_$tag$1>!isg;
   }

  $html =~ s!<\s*param ([^\<\>]*?)>!<disable_param $1>!isg;

  return $html;
 }


# this routine disables the embedded CGI in a html message
# to avoid user email addresses being confirmed by spammer through embedded CGIs
sub html4disableemblink
 {
  my $html = shift;
  $html=~s!(src|background)\s*=\s*(['"]?https?://[\w\.\-]+?/?[^\s<>]*)([\b|\n| ]*)
	  !_clean_emblink($1, $2, $3)
	  !egisx if $IG::webmail_prefs =~ /no\_extsrc/;
  return $html;
 }


sub _clean_emblink
 {
  my ($type, $url, $end) = @_;
  if ($url !~ /\Q$ENV{'HTTP_HOST'}\E/is)
   {
    $url =~ s/["']//g;
    return(qq|style="border:1px dotted black;background:#EEEEEE;" |.
           qq|$type="$IG::img_url/ftv2blank.gif" |.	# blank img url
           qq|alt="Embedded link removed by IGWebMail.\n$url" |.
           qq|onclick="window.open('$url', '_extobj');" |.
           $end);
   }
 
  return "$type=$url$end";
 }


sub _htmlclean
 {
  my $html = shift;

  $html =~ s#<body[^<>]*?>##gis;
  $html =~ s#</body>##gi;

  $html =~ s#<!doctype[^<>]*?>##gi;
  $html =~ s#<html[^<>]*?>##gi;
  $html =~ s#</html>##gi;

  $html =~ s#<head>.*?</head>##gis;
  $html =~ s#<head>##gi;
  $html =~ s#</head>##gi;

  $html =~ s#<meta[^<>]*?>##gi;
  $html =~ s#<!--.*?-->##gis;

  $html =~ s#<style[^<>]*?>#\n<!-- style begin\n#gi;
  $html =~ s#</style>#\nstyle end -->\n#gi;

  $html =~ s#<[^<>]*?stylesheet[^<>]*?>##gi;
  $html =~ s#(<div[^<>]*?)position\s*:\s*absolute\s*;([^<>]*?>)#$1$2#gi;

  return $html;
 }

1;
