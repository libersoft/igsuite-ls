## IGSuite 4.0.0
## Procedure: Utils.pm
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

package IG;

use strict;
use IG;

##############################################################################
##############################################################################

=head3 CleanWhiteSpaces()

Clean white spaces from a multi-lines string

=cut

sub CleanWhiteSpaces
 {
  my %data = @_;

  return if ! $data{text};
  my @arr = split /\n/, $data{text};

  ## Leading/Trailing space cleanup
  @arr = _leadtrailclean(@arr) if $data{leadclean} || $data{clean_all};
  @arr = reverse _leadtrailclean(reverse @arr) if $data{trailclean} || $data{clean_all};

  ## Indentation cleanup
  @arr = _indentclean(@arr) if $data{indentclean} || $data{clean_all};

  ## EOL Space cleanup
  @arr = _eolclean(@arr) if $data{eolclean} || $data{clean_all};

  return join "\n", @arr;
 }

## Internal functions
sub _leadtrailclean
 {
  my $first = 1;
  my @ret = ();
  foreach (@_)
   {
    if ( $first )
     {
      if (! /^\s*$/)
       {
       	$first = 0;
	push @ret, $_;
       }
     }
    else
     {
      $first = 0;
      push @ret, $_;
     }
   }
  return @ret;
 }

sub _indentclean
 {
  my @ret = ();
  foreach (@_)
   {
    1 while s/^[ \t]//g;
    push @ret, $_;
   }
  return @ret;
 }

sub _eolclean
 {
  my @ret = ();
  foreach (@_)
   {
    $_ =~ s/[ \t]*(\r*)$/$1/g;
    push @ret, $_;
   }
  return @ret;
 }

##############################################################################
##############################################################################

=head3 TextElide()

Inspired by Text::Elide

=cut

sub TextElide
 {
  my %data = @_;

  defined( my $string = $data{string} )       || die "no string argument\n";
  defined( my $length = $data{length} || 80 ) || die "no length argument\n";
  die "length must be a positive integer\n" if $length < 1;
  my $elipsis = $data{elipsis} || '...';

  die "elipsis string ($elipsis) is longer than length ($length)\n"
    if length( $elipsis ) > $length;

  $length = $length - length($elipsis);

  ## trivial case where string is already less than length
  return $string if length( $string ) <= $length;

  ## to check if we have broken in the middle of a word ...
  my $broken_word =    substr( $string, $length-1, 1 ) =~ /\S/
                    && substr( $string, $length, 1 )   =~ /\S/;

  ## crudely truncate ...
  $string = substr( $string, 0, $length );

  ## strip trailing whitespace
  $string =~ s/\s*$//;

  ## return truncated string if only one word / part of word (no whitespace) -
  ## ( ... but possibly with leading whitespace)
  return $string . $elipsis if $string =~ s/^(\s*\S+)\s*$/$1/;

  ## require: length( $elipsis ) <= $length
  if ( $broken_word )
   {
    ## remove partial word if crude truncation split mid-word
    $string =~ s/\s+\S+$//;
   }

  ## if there is only one word ...
  return $string . $elipsis unless $string =~ /\S\s+\S/;

  ## recursively remove "words" until there is room for the elipsis string
  $string =~ s/\s+\S+$// while length( $string ) > $length;

  return $string . $elipsis;
 }

##############################################################################
##############################################################################

=head3 Debug()

Get debug information

=cut

sub Debug
 {
  return if $IG::executed{debug}++;
  my %data = @_;
  die("No Debug ID specified!") if !$data{id};
   
  my %ig_env = (   '$client_browser' => $IG::client_browser,
                   '$client_os'      => $IG::client_os,
                   '$OS'             => $IG::OS,
                   'PID'             => $$,
                   'Server Date'     => "$tv{time} $tv{today} $tv{time_offset}",
                   'Path separator'  => $S,
                   '$cgi_url'        => $IG::cgi_url,
                   '$htdocs_dir'     => $IG::htdocs_dir,
                   '$webpath'        => $IG::webpath,
                   '$cgi_dir'        => $IG::cgi_dir,
                   '$cgi_name'       => $IG::cgi_name,
                   '$cgi_path'       => $IG::cgi_path,
                   '$auth_user'      => $IG::auth_user,
                   '$user_dir'       => $IG::user_dir,
                   '$logs_dir'       => $IG::logs_dir,
                   'Perl path'       => join(',',@INC),
                   '$remote_host'    => $IG::remote_host,
                   '$img_url'	     => $IG::img_url,
                   '$db_name'	     => $IG::db_name,
                   '$db_driver'      => $IG::db_driver,
                   '$db_host'        => $IG::db_host,
                   '$db_port'        => $IG::db_port,
                   '$conf_dir'       => $IG::conf_dir );

  my @info;
  push @info, [( Br().Blush('IGSuite Environment'),'' )];
  push @info, [( $_, _debug_value($ig_env{$_}) )] foreach sort keys %ig_env;
  push @info, [( Br().Blush('Parameters'),'' )];
  push @info, [( $_, _debug_value($on{$_}) )] foreach sort keys %on;
  push @info, [( Br().Blush('Files included'),'' )];

  foreach my $module ( sort keys %INC )
   {
    no strict 'refs';
    if ($module !~ /^(\/|\\)/)
     {
      $module =~ s/\//\:\:/g;
      $module =~ s/\.pm$//;
     }
    push @info, [( $module, ${$module.'::VERSION'})] 
   }

  my $dprof1 = "getdprof(['NO_CACHE',".
                         "'igdebugid__$data{id}',".
                         "'options__-t'],['layer_content1'])";
  my $dprof2 = "getdprof(['NO_CACHE',".
                         "'igdebugid__$data{id}',".
                         "'options__'],['layer_content2'])";

  my $label = "<div style=\"background-color:$IG::clr{bg_evidence};".
              " border: 1px solid #999999; z-index:1000; opacity: .5;".
              " filter: alpha(opacity=50);".
              " position:absolute; top:10px; left:10px; padding:5px;\">".
              '[Show Debug Info]</div>';

  ## IGSuite Env              
  my $pan1 = MkTable( style=>"width: 660px;".
                             "background:$IG::clr{bg_low_evidence};",
                      style_c1_r=>'font-weight:bold;'.
                                  'vertical-align:top;',
                      values=>\@info );

  ## Db Dump
  my $pan2 = "<div>";
  my $cnt;
  for my $queries ( @{$IG::debug_info{db_queries}} )
   {  
    $pan2 .= "N.:". ++$cnt.
             " ID:<span style=\"color:green; font-weight:bold;\">".
              ($$queries[0] || 'default') ."</span>".
             " QRY:" .
              ( $$queries[1] eq 'New connection'
                ? Blush($$queries[1])
                : IG::MkEntities($$queries[1]) ).
             "<br><br>\n";
   }
  $pan2 .= "</div>";

  ## Symbols table
  require IG::DevelSymdump;
  my $obj = Devel::Symdump->new(qw(IG));
  my $pan3 = $obj->as_HTML;

  ## CGI Env
  @info = ();
  push @info, [( Br().Blush('CGI Environment'),'' )];
  push @info, [( $_, _debug_value($ENV{$_}))] foreach sort keys %ENV;
  my $pan4 = MkTable( style=>"width: 660px;".
                             "background:$IG::clr{bg_low_evidence};",
                      style_c1_r=>'font-weight:bold;'.
                                  'vertical-align:top;',
                      values=>\@info );

  ## Draw TabPane        
  my $html = ToolTip( width    => '700px',
                      id       => 'debugtask',
                      show     => $label,
                      title    => "IGSuite $IG::VERSION Debug Info -".
                                  " ID:$data{id}",
                      body=> IG::TabPane( data=>[( [ 'IG Env',
                                                     $pan1 ],
                                                   [ 'DProf (Tree)',
                                                     '&nbsp;',
                                                     $dprof1 ],
                                                   [ 'DProf (Times)',
                                                     '&nbsp;',
                                                     $dprof2 ],
                                                   [ 'DB Dump',
                                                     $pan2 ],
                                                   [ 'Symbols Table',
                                                     $pan3 ],
                                                   [ 'CGI ENV',
                                                     $pan4 ] )],
                                          height=>300,
                                          width=>690 ) );

  defined wantarray ? return $html : PrOut $html;
 }

sub _debug_value
 {
  my $value = shift;
  $value = MkEntities($value);
  $value =~ s/\,/<br>/g;
  $value ||= 'none';
  return $value;
 }
 
##############################################################################
##############################################################################

=head3 GetAvailableResource()

Get available tema or language

=cut

sub GetAvailableResource
 {
  my $resource = shift;
  my @available_resource;
  
  if ($resource eq 'tema')
   {
    opendir (DIR, "$IG::cgi_dir${S}tema${S}")
      or die("Can't open directory $IG::cgi_dir${S}tema${S}");
    for (sort grep /\w+\_tema$/, readdir DIR)
     {
      /(.+)(\_)tema/;
      next if $1 eq 'printable';
      push @available_resource, [($1.$2, $1)];
     }
    close (DIR);
   }
  elsif ($resource eq 'languages')
   {
    push @available_resource, [('auto','Auto')];
    foreach (sort { $languages{$a} cmp $languages{$b} } keys %IG::languages)
     {
      push @available_resource,
           [($_, $IG::languages{$_})] if -d "$IG::cgi_dir${S}lang${S}$_";
     }
   }
  elsif ($resource eq 'timezones')
   {
    foreach ( sort { $IG::timezones{$a} cmp $IG::timezones{$b} }
              keys %IG::timezones )
     {
      push @available_resource, [( $_, "$IG::timezones{$_} $_" )];
     }
   }
  else
   {
    die("Unknown resource requested!\n");
   }
   
  return \@available_resource;                               
 }
 
##############################################################################
##############################################################################

=head3 MkGraph()

Draw an istogram with numeric values passed.

=cut

sub MkGraph
 {
  my %data = @_;
  my $nseries;	## The series we have
  my $values;	## How many values have each serie
  my $val;	## Used to remember some number
  my $cnt;	## Used to count
  my $maxvalue;	## The Max value in all series
  my $step;	## The step for the stair
  my @series;	## All series
  my @variables;## The variables for description
  my @dat;
  my $width;
  my $html;

  ## Read passed values and set defaults
  $data{rows}=~ s/\(//g;
  @series = split /\)/, $data{rows};
  $nseries = $#series;
  @variables = split /\,/, $data{vars};

  $data{bgcolor} ||= 'white';
  $data{width}   ||= 300;
  $data{height}  ||= 200;  
  $data{series_margin} ||= 0;

  for my $i (0..$nseries)
   {
    $cnt = -1;
    $dat[$i][++$cnt] = $_ foreach split /\,/, $series[$i];
    if ($cnt > $values) { $values = $cnt }

    for my $k (0..$cnt)
     {
      if ($dat[$i][$k] > $maxvalue)
       { $maxvalue = $dat[$i][$k] }
     }
   }

  ## Check scale
  if (!$data{scale} || $data{scale}>$maxvalue)
   { $data{scale} = int($maxvalue/10)+1 }

  $step = int( ($data{height}*$data{scale})/$maxvalue );
  $width = int(($data{width}/(($#variables+1)*(1)))/($nseries+1));

  $html="<table bgcolor=\"black\" cellspacing=1 cellpadding=0>
          <tr><td>
	   <table bgcolor=\"white\" cellspacing=4>
	    <tr><td>
	        <span style=\"background: $IG::clr{bg_link}; font-weight: bold;\">
		$data{title}
	        </span>
	    </td></tr><tr><td>
	     <table cellspacing=0 cellpadding=0>
	      <tr><td>
               <table cellspacing=0 cellpadding=0 style=\"font-size:10px;\">";

  ## Draw graduate scale
  if ($data{draw_scale} eq 'false')
   {
    $html .= "<tr><td></td></tr>";
   }
  else
   {
    for my $i (reverse 0..(int($maxvalue/$data{scale})))
     {
      $val = $i*$data{scale};
      $val = IG::MkByte($val) if $data{values_as} eq 'byte';
      $html .= "<tr>
                 <td style=\"font-size:10px\" valign=\"bottom\" align=\"right\" height=$step nowrap>$val</td>
  	       <td valign=\"bottom\">
  	        <img src=\"$IG::img_url/black.gif\" alt=\"graduate\" width=10 height=1></td>
  	      </tr>\n";
     }
   }
  $html .= "</table></td><td bgcolor=\"black\" width=1></td>";

  ## Draw histogram bars
  $val = $data{height}+$step;
  $val = IG::MkByte($val) if $data{values_as} eq 'byte';
  $html .= "<td valign=bottom>
             <table style=\"height:${val}px; background:$data{bgcolor};\" cellspacing=1 cellpadding=0>
              <tr>";

  for my $i (0..$values)
   {
    $html .= "<td valign=\"bottom\" style=\"padding-right:$data{series_margin}px\">";
    for my $k (0..$nseries)
     {
      $val = int(($data{height}*$dat[$k][$i])/$maxvalue)-1;

      $html .= Img( src    => "$IG::img_url/$k.gif",
                    title  => $data{values_as} eq 'byte'
                           ?  IG::MkByte($dat[$k][$i])
                           :  $dat[$k][$i],
                    width  => $width,
                    height => $val );
     }
    $html .= "</td>\n";
   }
  ++$values;
  $html .= "</tr></table>
            </td></tr>
            <tr><td></td><td></td><td bgcolor=\"black\" height=2></td></tr>
            <tr><td></td><td></td><td align=\"right\">
            <table border=0 cellspacing=0 cellpadding=0><tr>";

  foreach(@variables)
   {
    $html .= "<td align=center width=".
	     (($width*($nseries+1))+1+$data{series_margin}).
	     " style=\"font-size: 10px; white-space: normal; font-family: $tasksfontname;\">$_</td>";
   }
  $html .= "</tr></table>
            </td></tr></table>
            </td></tr></table>
            </td></tr></table>";

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 MkChart()

Draw an istogram by XML/SWF Chart.

=cut

sub MkChart
 {
  my %data = @_;
  $data{width}  ||= 400;
  $data{height} ||= 250;
  $data{id}     ||= 'charts';
  $data{align}  ||= 'center';
  $data{bgcolor}||= '#666666';
  $data{source} ||= "$img_url/sample.xml";
  $data{quality}||= 'high';

  my $html = <<FINE;
<OBJECT classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
        codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0" 
        WIDTH="$data{width}" 
        HEIGHT="$data{height}" 
        id="$data{id}" 
        ALIGN="$data{align}">
<PARAM NAME="movie" VALUE="$img_url/charts.swf?library_path=$img_url/&amp;xml_source=$data{source}">
<PARAM NAME="quality" VALUE="$data{quality}">
<PARAM NAME="bgcolor" VALUE="$data{bgcolor}">

<EMBED src="$img_url/charts.swf?library_path=$img_url/&amp;xml_source=$data{source}"
       quality="$data{quality}"
       bgcolor="$data{bgcolor}"
       WIDTH="$data{width}" 
       HEIGHT="$data{height}" 
       NAME="$data{id}" 
       ALIGN="$data{align}" 
       swLiveConnect="true" 
       TYPE="application/x-shockwave-flash" 
       PLUGINSPAGE="http://www.macromedia.com/go/getflashplayer">
</EMBED>
</OBJECT>
<SCRIPT LANGUAGE="JavaScript"> 
<!-- 
function $data{id}_DoFSCommand(command, args) {  }
//--> 
</SCRIPT>
FINE
  defined wantarray ? return $html : PrOut $html;
 }
 
##############################################################################
##############################################################################

=head3 CleanSessions()

For security reason we can't permit to use a session for more than 8 hours (a
working day) so we have to remove old and died sessions. In that way every
day users has to login again.

=cut

sub CleanSessions
 {
  ## Remove old sessions
  my $sid;
  opendir (DIRE, $logs_dir)
    or die( "Can't read from log directory '$logs_dir'. ".
            "Check directory permissions ".
            "or try to execute 'mkstruct.pl' script as user root.\n" );

  while ( defined( $sid = readdir(DIRE) ) )
   {
    ## guest sessions ( 15 minutes )
    Logout( undef, $sid ) if    $sid =~ /^guest\-session\-\d+\-\w+/
                             && -M "$logs_dir${S}$sid" > 0.0104;

    ## system users session as defined in $session_timeout
    Logout( undef, $sid ) if    $sid =~ /^([A-Za-z\_][A-Za-z0-9\_\.\-]{1,31})
                                         \-session\-\d+\-\w+/x
                             && -M "$logs_dir${S}$sid" > $session_timeout;
   }

  closedir (DIRE);

  ## Disable expired user accounts and eventually clean relative session
  if ( $on{action} eq 'login' )
   {
    ## change account status if expired
    DbQuery( type  => 'UNNESTED',
             query => "update users set status = '2' ".
                      "where".
                      " status='1' and".
                      " statusdate is not null and".
                      " statusdate <= current_date" );
   }

  ## clean old (2 days) elements viewed
  DbQuery( query => "delete from last_elements_log ".
                    "where issuedate+2 < current_date",
           type  => 'UNNESTED' ) if $auth_user ne 'guest';
 }

##############################################################################
##############################################################################

=head3 MkComments()

Insert specific comment related to commentid value.

=cut

sub MkComments
 {
  my %data = @_;
  my @_row;
  my @comments;
  my $comments_cnt;
  return  if !$data{comments};

  $data{commentid}      ||= $on{id};
  $data{commentbackurl} ||= $query_string;
  $data{background}     ||= $IG::clr{bg_task};

  my $moreStyles = $data{commentwidth} ? " width:$data{commentwidth};" : '';

  my $html = ## Comments box
             "<div style=\"clear:both;".
			" padding:0px;".
			" margin:10px 0px 0px 0px;".
			" display:block;".
			" border:1px $IG::clr{border_low} solid;".
                        " $moreStyles".
			" background:$data{background}\">\n".
             ## all Comments
	     "<div style=\"padding:0px 10px 10px 10px;\">";

  $on{notifyowner} = 0; ## we will use the last user selection 

  ## preload all comments to avoid nested database queries
  my $cid = DbQuery( query => "select * from comments ".
                              "where referenceproc='$cgi_name'".
		              " and referenceid='".DbQuote($data{commentid})."' ".
		              "order by date desc, time desc",
                     type  => 'UNNESTED');

  push @comments, [@_row] while @_row = FetchRow($cid);
  
  for my $comment_ref ( @comments )
   { 
    my @row = @$comment_ref;
    $comments_cnt++;

    $html .= HTitle( title => $lang{comments},
                     style => 'margin: 10px 5px 0px 5px; padding:0px;',
                     level => 4 ) if $comments_cnt==1;

    ## Each comment in a div
    $html .= "<div style=\"width:auto; margin:10px 0px 10px 0px; padding:5px; text-align:left; border:1px #999999 dotted;\">\n".
	     "$lang{insert_from} <a href=\"".
             ( $auth_user ne 'guest'
	       ? "javascript:winPopUp('webmail?action=composemessage&amp;onsend=close&amp;to=$row[6]',700,560,'compose')"
	       : "mailto:$row[6]" ).
	     "\">$row[5]</a>  $row[3] $row[4]";

    $on{notifyowner} = $row[10] eq 'S' ## default = last user selection
                 if $row[9] ne 'guest' && $row[9] eq $auth_user;

    if (   ($row[9] ne 'guest' && $row[9] eq $auth_user)
        || $auth_user eq $data{commentowner}
        || CheckPrivilege('sys_delete_comments')
       )
     {
      $html .= 	FormHead(	formaction=>"$cgi_url/igsuite",
				cgiaction=>'deletecomments').

		Input( type     => 'hiddens',
		       override => 1,
		       data     => { commentid      => $row[0],
		                     commentproc    => $cgi_name,
		                     commentowner   => $data{commentowner},
		                     commentbackurl => $data{commentbackurl} }
		      ).

		Input( type     => 'submit',
		       show     => $lang{delete},
		       float    => 'right' ).

		FormFoot();
     }

    $html .=	Br() . MkLink($row[8]) . "\n</div>\n";
   }
 
  $html .=	FormHead( formaction => "$cgi_url/igsuite",
                          autofocus  => 'false',
                          name       => 'newcomment',
                          float      => 'none',
                          labelstyle => 'width: 15%', 
                          cgiaction  => 'writecomments' ).
 
                "<div id=\"comments_add\" style=\"padding:5px 5px 0px 5px\">".
		"<a onclick=\"new Effect.SwitchOff('comments_add');".
		             "new Effect.BlindDown('comments_form');".
		             "setTimeout('\$(\\'commenttext\\').focus()',1500);".
		             "setTimeout('window.location.hash=\\'add_comment_anchor\\'',1000);\"".
                  " style=\"cursor:pointer;\">".
                Img( src => "$IG::img_url/add.gif", title => 'Add' ).
		" $lang{new_comment}</a>".
                "</div>".

		Input( type     => 'hiddens',
		       override => 1,
		       data     => { commentid      => $data{commentid},
		                     commentproc    => $cgi_name,
		                     commentowner   => $data{commentowner},
		                     commentbackurl => $data{commentbackurl} }
		      );

  ## New comment form
  $html .= "<div".
           " id=\"comments_form\"".
           " style=\"border:1px solid #999999;".
                    "padding:10px;".
                    "margin:5px;".
                    "display:none\">";

  if ($auth_user eq 'guest')
   {
    $html .=	Input (	type=>'text',
			size=>50,
			name=>'commentauthorname',
			show=>$lang{name}).

		Input (	type=>'text',
			size=>50,
			name=>'commentauthoremail',
			show=>"E-Mail").

		Input (	type=>'text',
			size=>50,
			name=>'commentauthorurl',
			show=>'Url');
   }
  else
   {
    $html .= Input (	type=>'label',
			show=>$lang{user},
			data=>IG::UsrInf('name') );
   }

  $html .= Input (	type=>'textarea',
			name=>'commenttext',
			fieldstyle=>'width: 70%',
			style=>'width: 100%',
			rows=>4,
			cols=>55,
			onchange=>"newcomment.captcha.value='1';",
			show=>$lang{comments});

  $html .= Input (	type=>'checkbox',
                        name=>'notifyowner',
	      		show=>$lang{comment_notify})
	 if $auth_user ne 'guest'              ## no notification for guests
	 && $auth_user ne $data{commentowner}; ## onwer user is notified anyway
  
  $html .= Input (	type=>'submit',
			fieldstyle=>'float:none',
			show=>$lang{send} ).
			
           Input (	type=>'hidden',
                        name=>'captcha',
                        value=>0,
                        override=>1,
                        method=>'html').

	   FormFoot().
	   "</div></div></div>\n".
	   "<a name=\"add_comment_anchor\"></a>\n";

  ## Check external plugins
  $html = CkExtPlugins( 'MkComments', \$html, \%data ) if %IG::plugins;

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 Currency($number)

Show a money value

=cut

sub Currency
 {
  my $value = shift;
  $value =~ s/[^\-\d$decimal_separator]//g;
  my ($integer,$decimal) = split /$decimal_separator/, $value;
  if (!$decimal && $decimal ne '0')
   { ($integer,$decimal) = $value =~ /(.*)(\d\d)$/; } 
  $decimal = substr('00'.$decimal, -2,2);
  $integer ||= '0';
  $integer = reverse join($thousands_separator,
			  grep {$_ ne ''} split /(...)/, reverse $integer);
  $value = "$currency $integer$decimal_separator$decimal";
  $value =~ s/\-\Q$thousands_separator/\-/;
  defined wantarray ? return $value : PrOut $value;
 }

##############################################################################
##############################################################################

=head3 MkMapLink()

Link passed address to a map service on internet (www.mapporama.com).

=cut

sub MkMapLink
 {
  my %data = @_;

  return if    !$data{address}
            || !$data{zip}
            || !$data{city}
            || !$soc_address
            || !$soc_zip
            || !$soc_city;

  $data{country} ||= $soc_country;

  my $link = "http://maps.google.com/maps?".
	"f=q&amp;".
	"saddr=".MkUrl($soc_address).
	"%2C".MkUrl($soc_city).
	"%2C".$soc_zip.
	"%2C".MkUrl($IG::countries{uc($soc_country)}).
	"&amp;hl=$IG::default_lang".
	"&amp;daddr=".MkUrl($data{address}).
	"%2C".$data{zip}.
	"%2C".MkUrl($data{city}).
	"%2C". ( MkUrl($IG::countries{uc($data{country})}) ||
		 MkUrl($IG::countries{uc($soc_country)}) );

  return $link;
 }

##############################################################################
##############################################################################

=head3 TabPane

Creates a tab pane as in a window manager. You can define labels.

=cut

sub TabPane
 {
  my %data = @_;
  my $html; 
  my $labels = @{$data{data}} - 1;

  $data{width}         ||= '100%';
  $data{padding}       ||= 10;
  $data{default}       ||= '0';
  $data{height}        ||= 200;
  $data{name}          ||= 'layer';
  $data{margin_top}    ||= 8;
  $data{margin_bottom} ||= 5;
  $data{label_type}    ||= 2; # 1= 1 line label; 2 = 2 or more lines label

  if ( $tema eq 'printable_' || $IG::screen_size =~ /^noframe/ )
   {
    ## Print version
    for my $i (0 .. $labels)
     { 
      next if    !$data{data}[$i][1]
              || $data{data}[$i][1] eq '&nbsp;'
              || $data{data}[$i][1] =~ /^<iframe/;

      $html .=  "<div style=\"width:$data{width}; float:left; clear:both; margin:20px 5px 10px 5\">".
		HTitle( style => 'clear:both; margin: 0 0 10px 0',
			title => $data{data}[$i][0],
			level => 3 ).
		$data{data}[$i][1].
		'</div>';
     }
   }
  else
   {
    ## Start a Pane version
    $html = "\n<!-- Start TabPane  -->\n".
            "<div style=\"height:$data{margin_top}px; clear:both;\"></div>\n";
               
    for my $y ( 0..$labels  )
     {
      $data{data}[$y][2] = '' if !$data{data}[$y][1];

      if ($data{label_type} == 2)
       {
        ## Label have to wrap first white space
        $data{data}[$y][0] = '<br>' . $data{data}[$y][0]
                             if $data{data}[$y][0] !~ s/ /<br>/;
       }
     }

    for my $i ( 0 .. $labels  )
     {
      ## this is contenitor div
      $html .= "<div".
	       " id=\"$data{name}$i\"".
	       " class=\"tabpane\">\n";
      
      ## this div contain labels
      $html .= "<div style=\"float:left; clear:both;".
               " width:$data{width}; background:$IG::clr{bg_task};\">\n".
               "<div style=\"float:left; width:10px\">&nbsp;</div>";

      for my $k ( 0..$labels )
       {
        ## Create labels
        $html .= "<div class=\"".
                  ( !$data{data}[$k][1]
 	 	    ? 'navdisabled"'
		    : ( ($k == $i ? 'navon' : 'navoff').
		        "\" onclick=\"goOver('$k','$data{name}');".
		        "$data{data}[$k][2]\""
		      )
                  ).
                 ( $data{label_type} == 1 ? ' style="height:auto"' : '').
                 '>'.
		 $data{data}[$k][0].
		 "</div>\n";
       }

      ## Close labels content
      $html .= "</div>\n";
      
      ## Body contenitor
      $html .= "<div style=\"clear:both; float:left; margin:0; padding:0;".
               " width:$data{width}; border:1px solid #666666;\">";

      ## Body div
      $html .= "<div".
               " id=\"$data{name}_content$i\"".
               " style=\"padding:0px; height:$data{height}; overflow:auto;".
               " vertical-align:top; margin:$data{padding}px;\">\n";

      $html .= $data{data}[$i][1] . "</div></div></div>\n";
     }

    ## set default pane opened
    $html .= "<script defer type=\"text/javascript\">\n".
	     "\tgoOver($data{default},'$data{name}');\n".
	     "\t$data{data}[$data{default}][2];\n".
	     "</script>\n";

    $html .= "<div style=\"height:$data{margin_bottom}px; clear:both;\">".
             "</div>\n".
             "<!-- End TabPane  -->\n";
   } 

  ## Check external plugins
  $html = CkExtPlugins( 'TabPane', \$html, \%data ) if %IG::plugins;

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 ParseDoc($document_type, $template_name, $document_id)

Parse an html or odt document.

=cut

sub ParseDoc
 {
  my ($document_type, $template_name, $document_id ) = @_;
  my ($parsed_doc, @unresolved );

  die("Not enought arguments for ParseDoc!") if !$document_type ||
                                                !$template_name ||
                                                !$document_id;

  ## Values needed by ParseText
  my %var;
     $var{docid} = IG::UsrInf('acronym')."/$document_id"; 

  ## discover template format
  my $template_format   = $template_name =~ /\.odt$/ ? 'odt' : 'htm';


  my ($docyear)         = $document_id =~ /\.(\d\d)$/;

  my $document_file     = $IG::htdocs_dir . ${S} .
                          $IG::default_lang{$document_type} . ${S} .
                          $docyear . ${S} . 
                          IG::Crypt($document_id) . '.' . $template_format;

  my $template_file     = $IG::htdocs_dir . ${S} .
                          $IG::default_lang{$document_type} . ${S} .
                          $IG::default_lang{templates} . ${S} .
                          $template_name;

  ## Check document protocol directory
  CkProtocolDir($document_type, $docyear);

  ## start parsing
  if ( $template_format ne 'odt' )
   {
    ## load template file
    my $unparsed_document;

    open (DAT, '<', $template_file)
      or die("Can't read from '$template_file'.\n");
    $unparsed_document = do { local $/; <DAT> };
    close(DAT);

    ## parse text (pass %var as additional values to parse)
    ($parsed_doc, @unresolved) = ParseText( $unparsed_document, %var );

    ## Trash an eventually old document
    IG::TrashDoc($document_id);

    ## Write new document
    open (DIT, '>', $document_file)
      or die("Can't write to '$document_file'.\n");
    print DIT $parsed_doc;
    close(DIT);
   }
  else
   {
    ## Parse ODT files
    no strict 'subs';
    eval( "require Archive::Zip;" );
    die("You have to install Archive::Zip module to parse ODT files!\n") if $@;

    my $zip = new Archive::Zip;
    die "Cannot open $template_file\n"
      if $zip->read($template_file) != Archive::Zip::AZ_OK;

    ## parse xml text content
    my $member   = $zip->removeMember('content.xml');
    my $xml_text = $member->contents();
    ($parsed_doc, @unresolved) = ParseText( $xml_text, %var );
    $zip->addString($parsed_doc, 'content.xml');

    unless ( $zip->writeToFileNamed($document_file) == Archive::Zip::AZ_OK )
     { die "Can't write on $document_file"; }
   }

  ## Adjust permissions
  chmod( 0664, $document_file )
    or die("Can't change permissions to $document_file");

  LogD( 'Parsed and created a document from template',
	'update',
	$document_type,
	$document_id );

  ## need to be reparsed ? /in circular we can't reparse template
  if ($cgi_name ne 'circular' && @unresolved )
   {
    IG::Redirect( "docmaker?".
                  "action=reparse&amp;".
                  "docid=$document_id&amp;".
                  "backto=$document_type" );
    return 0;
   }
  return 1;
 }

##############################################################################
##############################################################################

=head3 ParseText($document, \%values)

Parse an html document abd return $document and @unresolved.

=cut

sub ParseText
 {
  my ($document, %values) = @_;
  my @unresolved;
  
  my $doc_type = IG::CkHtml($document) ? 'html' : 'odt';

  ## set values to parse
  %values = ( %values, %on );

  $values{sendmode} = $doc_type eq 'odt'
                    ? $lang{$on{sendmode}}
                    : "<span style=\"font-size: 11px\; font-weight: bold\">".
                      "<u>$lang{$on{sendmode}}</u></span>";

  if ($on{sendmode} eq 'byfax')
   {
    $values{sendmode} .= "<br>$lang{from}: $IG::soc_fax<br>".
                         "$lang{to}: $on{fax}";
   }
  elsif ($on{sendmode} eq 'byemail')
   {
    $values{sendmode} .= "<br>$lang{from}: " . IG::UsrInf('email') .
                         "<br>$lang{to}: $on{email}";
   }
  elsif ($on{sendmode} ne 'byhand')
   {
    $values{sendmode} = ' ';
   }

  ## Set variables to substitute
  $values{owner}          = $on{owner} || $auth_user;
  $values{logo}           = $IG::soc_logo;
  $values{today}          = $tv{today};
  $values{year}	          = $tv{year};
  $values{endyear}        = $tv{end_year};
  $values{startyear}      = $tv{start_year};
  $values{pricesvtable}   = $on{pricesvtable};
  $values{pricesotable}   = $on{priceshtable};
  $values{function}       = IG::UsrInf('function', $values{owner} );
  $values{docissue}       = $on{issue} || $tv{today};
  $values{docexpire}      = $on{expire} || $on{todate};
  $values{docowner}       = IG::UsrInf('name', $values{owner} );

  $values{document_title} = $values{docid};

  while ( $document =~ /\%\%([^\% ]{1,30})\%\%/ )
   {
    my $key = lc($1);
    my $value = $values{$key} || $values{'igsuite_' . $key};

    if ( $doc_type eq 'html' )
     {
      $value &&= $key =~ /^(sendmode|logo|priceshtable|pricesvtable)$/
                      ? $value
                      : MkEntities( $value );
     }
    else
     {
      $value &&= XmlEscape( $value );
     }

    $value ||= "%<%$key%>%";

    ## in odt document set a right line break
    $value =~ s/\n|\&lt\;br\&gt\;/<text\:line\-break\/>/g
      if $doc_type eq 'odt';

    $document =~ s/\%\%([^\% ]{1,30})\%\%/$value/;
   }

  ## restore and find unresolved keys
  push @unresolved, $1
    while $document =~ s/\%\<\%([^\%]{1,30})\%\>\%/\%\%$1\%\%/;

  ## clean duplicate keys but keep keys order
  my %temp_keys;
  @unresolved = grep { !$temp_keys{$_}++ } @unresolved;

  return ($document, @unresolved);
 }

##############################################################################
##############################################################################

=head3 XmlEscape

Escape xml content

=cut

sub XmlEscape
 {
  ## try to load module to convert latin to utf8 XXX2DEVELOPE use IG::TextConvert
  eval("require Unicode::String;");
  my $unicode_module = $@ ? 0 : 1;

  push @errmsg, "Attention! you have to install Perl module Unicode::String ".
                "to convert your latin1 string in utf8!" if !$unicode_module;

  my @strings = @_;
  for ( @strings )
   {
    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;
    s/\"/&quot;/g;
    s/\'/&apos;/g;
    s/\s+$//;

    $_ = Unicode::String::latin1($_)->Unicode::String::utf8()
         if $unicode_module;
    ## dirty convert from utf8
    #s/([\xC2\xC3])([\x80-\xBF])/chr(ord($1)<<6&0xC0|ord($2)&0x3F)/eg;
   }

  return (wantarray ? @strings : $strings[0]);
 }
 
##############################################################################
##############################################################################

=head3 MkCalendar

Draw a calendar with different color to show events

=cut

sub MkCalendar
 {
  my %data = @_;
  my $rows;
  my $html;
  my %calendar_day_event;

  $data{cellheight}	||= 20;
  $data{day}		||= $tv{day};
  $data{month}		||= $tv{month};
  $data{year}		||= $tv{year};
  $data{width}		||= '100%';

  my ($last_day, $calendar_week_event, $calendar_day_event, $day_of_the_week);

  $html = "<table style=\"width:$data{width}; ".
                         "border-bottom:2px solid $IG::clr{bg_barra}; ".
                         "background-color:$IG::clr{bg_barra};\"".
                " cellspacing=0 cellpadding=1>
	   <tr><td align=\"left\">";
 
  if ($data{prevmonth})
   {
    $html .= Img( href=>$data{prevmonth},
                  alt=>"Previous Month",
                  src=>"$IG::img_url/left-grey.gif",
                  align=>'absmiddle');
   }

  $html .= "<span style=\"color: $IG::clr{font_menu_title};\">".
           "$IG::months{$data{month}}[0]</span>";

  if ($data{nextmonth})
   {
    $html .= Img( href=>$data{nextmonth},
                  alt=>"Next Month",
                  src=>"$IG::img_url/right-grey.gif",
                  align=>'absmiddle');
   }
  $html .= "</td><td align=\"right\">";

  if ($data{prevyear})
   {
    $html .= Img( href=>$data{prevyear},
                  src=>"$IG::img_url/left-grey.gif",
                  alt=>"Previuos Year",
                  align=>'absmiddle' );
   }
  $html .= "<span style=\"color:$IG::clr{font_menu_title};\">$data{year}</span>";

  if ($data{nextyear})
   {
    $html .= Img( href=>$data{nextyear},
                  src=>"$IG::img_url/right-grey.gif",
                  alt=>"Next Year",
                  align=>'absmiddle');
   }

  $html .= "</td></tr><tr><td colspan=2 bgcolor=\"$IG::clr{bg_barra}\">
	    <table width=\"100%\" cellspacing=0 cellpadding=1 bgcolor=\"$IG::clr{bg_task}\">
	    <tr><td bgcolor=\"$IG::clr{bg_task}\">
	    <table width=\"100%\" cellspacing=1 cellpadding=0><tr>";

  ## Draw name of the days
  $html .= "<td class=\"menu\" style=\"font-size:11px;\">".
	   substr($IG::days[$_],0,2).
	   "</td>\n" for 0..6;
  $html .= "</tr>\n<tr>";

  if ($data{showevent} eq 'colorize')
   {
    ## We have to exclude previous events so we need last day of the month
    ## accordind to $date_format
    $last_day = GetDateByFormat( IG::GetDaysInMonth($data{month},$data{year}),
                                 $data{month},
                                 $data{year} );

    my $first_day = GetDateByFormat(    1,
                                        $data{month},
                                        $data{year} );

    ## Looking for events to show
    my $cid = DbQuery
               ( query => "SELECT day, weekday, startdate, repeatend ".
                          "FROM calendar ".
	                  "WHERE startdate<='$last_day' and".
	                  ( $data{category}
	                    ? " category='".DbQuote($data{category})."' and"
	                    : '').
	                  " (repeatend >= '$first_day' or repeatend is null) and".
	                  " (touser='".DbQuote($data{user})."' or touser='all') and".
	                  " (month=".DbQuote($data{month})." or month=0) and".
	                  " (year=".DbQuote($data{year})." or year=0)",
                 type  => 'UNNESTED' );

    while ( my ( $day, $weekday, $startdate, $repeatend ) = FetchRow($cid) )
     {
      if ( $day == 0 )
       { 
        for my $i ('01' .. IG::GetDaysInMonth( $data{month}, $data{year}) )
         {
          my $date = IG::GetDateByFormat( $i, 
                                          $data{month}, 
                                          $data{year} );

          my $wd   = IG::GetDayByDate(    $i, 
                                          $data{month}, 
                                          $data{year} );

          if (    IG::CompareDate( $date, $startdate ) >= 0 
               && (!$repeatend || IG::CompareDate( $date, $repeatend ) <= 0)
               && ($weekday == 8 || $wd == $weekday) ) 
           {
            $calendar_day_event{$i} = 1;
           }
         }
       }
      else
       {
        $calendar_day_event{$day} = 1;
       }
     }
   }

  ## Check days preselected
  $calendar_day_event{$_} = 1 for @{$data{selected}};
  $day_of_the_week = 0;

  ## Draw calendar
  for my $i ( 1 .. IG::GetDaysInMonth( $data{month}, $data{year} ) )
   {
    while (1)
     {
      my $day = GetDayByDate($i, $data{month}, $data{year});
      if ($day == $day_of_the_week)
       {
        my $style = "style=\"font-size: 100%; height: $data{cellheight}px; ";

        ## Check if this is today date
        if ($i == $tv{day} && $data{month} == $tv{month} && $data{year} == $tv{year})
         { $style .= "border: 2px solid $IG::clr{font_link}; padding: 1px; " } 
        else
         { $style .= "padding: 2px; " }

        ## Change background color if we have an event on this day
        if ($calendar_week_event=~ /$day/gi || $calendar_day_event{$i})
         { $style .= "background: $IG::clr{bg_low_evidence}; font-weight: bold\"" }
        else
	 { $style .= "background: $IG::clr{bg_link}\"" }

        ## The link to day event
        my $daylink = $data{daylink};
        my $calendar_date = MkUrl(GetDateByFormat($i,$data{month},$data{year}));

        $daylink =~ s/CALENDARDAY/$i/g;
        $daylink =~ s/DAYOFTHEWEEK/$IG::days[$day_of_the_week]/g;
        $daylink =~ s/CALENDARDATE/$calendar_date/g;
        $html .= "<td $style><a href=\"$daylink\" target=\"$data{target}\">$i</a></td>";
        $day_of_the_week++;
        last; 
       }
      else
       {
        $html .= "<td bgcolor=\"$IG::clr{bg_link}\">&nbsp;</td>";
        $day_of_the_week++;
       }
     }
    if ($day_of_the_week>6)
     {
      $rows++;
      $html .= "</tr>\n<tr>";
      $day_of_the_week=0;
     }
   }

  ## Draw empty blocks
  for my $i (0..6-$day_of_the_week)
   { $html .= "<td style=\"height: $data{cellheight}px; background: $IG::clr{bg_link}\">&nbsp</td>" }

  $html .= "</tr>".( $rows==4 ? "<tr>".("<td style=\"height: $data{cellheight}px; background: $IG::clr{bg_link}\">&nbsp</td>" x 7)."</tr>" : "");

  $html .= "</table></td></tr></table></td></tr></table>\n";

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 CalendarEventsToConfirm

Find Events to be confirmed (by self and by others)

=cut

sub CalendarEventsToConfirm
 {
  my $user = shift;
  my $onquestion_events = shift; ## hash ref
  my $toconfirm_events = shift;  ## hash ref

  my $cid
  = DbQuery( type  => 'UNNESTED',
             query =>
              "select calendar.eventid ".
              "from calendar ".
              "left join calendar childev on childev.parent=calendar.eventid ".
              "left join calendar parentev on calendar.parent<>''".
              "          and parentev.eventid=calendar.parent ".
              "left join calendar brotherev on calendar.parent<> ''".
              "          and brotherev.parent = calendar.parent ".
              "where calendar.touser = '$user'".
              " and (calendar.parent<>'' or childev.eventid<>'')".
              " and (calendar.startdate >= '$tv{today}'".
              "      or (calendar.year=0 and calendar.repeatend>='$tv{today}'))".
              " and (calendar.confirmation in (0,2) or".
              "      childev.confirmation in (0,2) or".
              "      parentev.confirmation in (0,2) or".
              "      brotherev.confirmation in (0,2))".
              " and (calendar.reserved=0 or".
              "      calendar.fromuser='$user' or".
              "      calendar.touser='$user') " );

  while( my $eventid = FetchRow($cid) )
   {
    $$onquestion_events{$eventid} = 1;
   }
  
  return if $user ne $auth_user;
  
  $cid
  = DbQuery( type  => 'UNNESTED',
             query =>
              "select calendar.eventid ".
              "from calendar ".
              "left join calendar childev ".
              "on childev.parent = calendar.eventid ".
              "where calendar.touser='$auth_user' and".
              " calendar.confirmation=0 and".
              " (calendar.parent<>'' or childev.eventid<>'') ".
              " and (calendar.startdate >= '$tv{today}'".
              "     or (calendar.year=0 and calendar.repeatend>='$tv{today}'))" );

  while( my $eventid = FetchRow($cid) )
   {
    $$toconfirm_events{$eventid} = 1;
   }
 }

##############################################################################
##############################################################################

=head3 BookingNotes()

Usage:
$description=IG::BookingNotes( description   => event description,
                               touser        => event owner,
			       equipmentlist => comma saparated list of equipment descriptions,
			       claimed       => comma separator list of claimed times,
			       approvedby    => comma separator list of users that have approved bookings );

=cut

sub BookingNotes
 {
  my %data = @_;
  my $desc = $data{description};
  
  $desc = "<strong>".
          MkEntities( IG::UsrInf( 'name', $data{touser} ) ).
          "</strong>: $desc"
          if $on{equipmentid};

  if( $data{equipmentlist} && !$on{equipmentid} )
   {
    my @equip_list = split( /, /, $data{equipmentlist} );
    my @claim_list = split( /, /, $data{claimed} );
    my @approve_list = split( /, /, $data{approvedby} );
    $desc .= " (";
    for (0 .. $#equip_list)
     {
      $desc .= ", " if $_ > 0;
      $desc .= '<i style="font-size:10px; font-weight:bold;">'.
               MkEntities( $equip_list[$_] ).
	       "</i>";
      $desc .= '<span style="font-size:10px; font-weight:bold; color:#ff0000;">'.
               " $lang{booking_claimed}</span>"
            if $claim_list[$_];
      $desc .= '?' if !$approve_list[$_] && !$claim_list[$_];
     }
    $desc .= ")";
   }

  if( $on{equipmentid} )
   {
    if( $data{claimed} )
     {
      my ($s,$m,$h,$g,$me,$ye,$wday,$y,$k) = localtime($data{claimed});
      my $claimed_from = sprintf( "%s %d:%02d", 
                                  IG::GetDateFromTime( $data{claimed} ),
				  $h, $m );
      $desc .= " <i style=\"font-size:10px; font-weight:bold; color:#ff0000\">".
               $lang{booking_claimed}.
	       " $claimed_from</i>";
     }
   }

  return $desc;
 }

##############################################################################
##############################################################################

=head3 HtPasswd()

Set an Apache htaccess account

=cut

sub HtPasswd
 {
  my %data = @_;
  $data{action} ||= 'set';

  if ( -x $IG::ext_app{htpasswd} )
   {
    ## execute original apache utility 'htpasswd'
    if ( $data{action} eq 'set' )
     {
      ## insert/set an user account
      IG::SysExec( command   => $IG::ext_app{htpasswd},
                   arguments => [( '-b',
	                           $data{htaccess_file},
	                           $data{login},
	                           $data{password} )]
	         ) or return 0;
     }
    else
     {
      ## delete an user
      IG::SysExec( command   => $IG::ext_app{htpasswd},
	           arguments => [( '-D',
	                           $data{htaccess_file},
	                           $data{login} )]
	         ) or return 0;
     }
   }
  else
   {
    ## try to use a perl module
    eval("require Apache::Htpasswd");
    die("Any available method to change htaccess account to file ".
        "$data{htaccess_file}. Please set a right htpasswd application ".
        "path inside igsuite.conf configuration file\n") if $@;
    my $foo = new Apache::Htpasswd( $data{htaccess_file} );

    if ($data{action} eq 'set')
     { $foo->htpasswd($data{login}, $data{password}, {'overwrite' => 1}); }
    else
     { $foo->htDelete($data{login}); }
   }
  return 1;
 }

##############################################################################
##############################################################################

=head3 StatusBar()

Draw a status bar

=cut

sub StatusBar
 {
  my %data = @_;
  $data{width}      ||= 35;
  $data{height}     ||= 8;
  $data{background} ||= '#FFFFFF';
  $data{color}      ||= $data{perc} == 100 ? '#00cc33' : '#FF0000';
  my $barwidth        = (($data{width}-2) * $data{perc} / 100) . 'px';

  my $html = "<div style=\"border: 1px solid black;".
			  " background:$data{background};".
			  " width:$data{width}px;".
			  " height:$data{height}px;".
			  " padding:0px;margin:2px 1px 2px 1px;".
	     "\" title=\"$data{perc}%\" alt=\"$data{perc}%\">".
	     "<div style=\"background:$data{color};".
			  " border:0px;padding:0px;margin:1px;".
			  " float:left;".
			  " width:$barwidth;".
			  " height:". ($data{height}-2) . 'px;'.
	     "\"></div></div>\n";

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################

=head3 HtmlUntag()

Untag Html content

=cut

sub HtmlUntag
 {
  my $html = shift;

  ## Try to use expert modules
  eval('require HTML::FormatText::WithLinks');
  if ( 0 && !$@ )#XXX2TEST
   {
    my $f = HTML::FormatText::WithLinks->new();
    return $f->parse($html);
   }

  eval('require HTML::TreeBuilder');
  if ( 0 && !$@ )#XXX2TEST
   {
    ## The HTML::FormatText is a formatter that outputs plain latin1 text
    eval('require HTML::FormatText');
    if ( !$@ )
     {
      my $obj = HTML::TreeBuilder->new();
         $obj->parse($html);
      my $formatter = HTML::FormatText->new(leftmargin=>0, rightmargin=>50);
      return $formatter->format($obj);
     }
   }
    
  ## From: http://www.perlmonks.org/index.pl?node_id=161281
  $html =~ s{
    <               # open tag
    (?:             # open group (A)
      (!--) |       #   comment (1) or
      (\?) |        #   another comment (2) or
      (?i:          #   open group (B) for /i
        ( TITLE  |  #     one of start tags
          SCRIPT |  #     for which
          APPLET |  #     must be skipped
          OBJECT |  #     all content
          STYLE     #     to correspond
        )           #     end tag (3)
      ) |           #   close group (B), or
      ([!/A-Za-z])  #   one of these chars, remember in (4)
    )               # close group (A)
    (?(4)           # if previous case is (4)
      (?:           #   open group (C)
        (?!         #     and next is not : (D)
          [\s=]     #       \s or "="
          ["`']     #       with open quotes
        )           #     close (D)
        [^>] |      #     and not close tag or
        [\s=]       #     \s or "=" with
        `[^`]*` |   #     something in quotes ` or
        [\s=]       #     \s or "=" with
        '[^']*' |   #     something in quotes ' or
        [\s=]       #     \s or "=" with
        "[^"]*"     #     something in quotes "
      )*            #   repeat (C) 0 or more times
    |               # else (if previous case is not (4))
      .*?           #   minimum of any chars
    )               # end if previous char is (4)
    (?(1)           # if comment (1)
      (?<=--)       #   wait for "--"
    )               # end if comment (1)
    (?(2)           # if another comment (2)
      (?<=\?)       #   wait for "?"
    )               # end if another comment (2)
    (?(3)           # if one of tags-containers (3)
      </            #   wait for end
      (?i:\3)       #   of this tag
      (?:\s[^>]*)?  #   skip junk to ">"
    )               # end if (3)
    >               # tag closed
   }{ }gsx;         # STRIP THIS TAG

  1 while  $html =~ s/ {2,}/ /g;

  ## Decode Entities
  my $html_ori = $html;
  eval {
        local $SIG{'__DIE__'};
        local $SIG{'__WARN__'};
        require IG::HTMLEntities;
        $html = HTML::Entities->can( 'decode_entities' )   
              ? HTML::Entities::decode_entities( $html )   
              : HTML::Entities::decode_entities_old( $html );
       };
  $html = $html_ori if $@;

  return $html || '';
 }
 
1;
