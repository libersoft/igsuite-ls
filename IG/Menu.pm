## IGSuite 4.0.0
## Procedure: Menu.pm
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
use     IG;
use     IG::Utils;
use	strict;

##############################################################################
##############################################################################
sub MkMenu
 {
  my $html;
  my ($wi, $he);
 
  if ($IG::screen_size eq 'noframe2')
   { 
    $html .= "<div".
             " onclick=\"goOver(0,'menu')\"".
             " name=\"menu1\"".
             " id=\"menu1\"".
             " style=\"cursor:pointer; color:$IG::clr{font_barra}; ".
                      "font-size:$menufontsize; width:95px; height:14; ".
                      "background:$IG::clr{bg_menu}; z-index:100; ".
                      "overflow:visible; position:absolute; ".
                      "left:0px; top:0px; visibility:visible; ".
                      "padding:0px\">[ Menu ]</div>\n".

	     "<div".
	     " onclick=\"goOver(1,'menu')\"".
	     " name=\"menu0\"".
	     " id=\"menu0\"".
	     " style=\"border:1px solid #FFFFFF; width:95px; ".
	              "background-color:$IG::clr{bg_menu}; z-index:100; ".
	              "overflow:visible; position:absolute; left:0px; top:0px; ".
	              "visibility:hidden; padding:2px;\">";
   }

  if ( $auth_user ne 'guest' )
   {
    ## draw star logo
    $html .= _mk_star_logo();

    $html .= "<div id=\"menu_content\">";

    $html .= _mk_menu(	'services', 1,
      [ 'IGFile',
	$IG::screen_size eq 'large'
	? 'filemanager?action=mkframes'
	: 'filemanager',
	"mainf" ],
      [ 'IGMsg',
	'isms?action=isms_arrived&amp;recheck=1',
	'mainf' ],
      [ 'IGWebMail',
	'webmail?recheck=1&amp;action=displayheaders',
	'mainf' ],

      ( IG::ConfigParam('igchats.window_target') eq 'same'
        ? [ 'IGChats',
            'igchats',
            'mainf' ]
        : [ 'IGChats',
            "javascript:winPopUp('igchats?a=1',650,400,'igchatspanel')",
            'new' ] ),

      [ 'IGCalendar',
	'calendar',
	'mainf' ],
      [ 'IGToDo',
	'todo',
	'mainf' ],
      [ 'IGFax',
	'igfax',
	'mainf' ],
      [ 'IGPostIt',
	'postit',
	'mainf' ],
      [ 'IGWiki',
	'igwiki?action=summary&amp;ig=1',
	'mainf' ],

	   );

    $html .= _mk_menu(	'management', 1,
	  	[ $lang{staff},		'users',	'mainf'],
		[ $lang{contacts},	'contacts',	'mainf'],
		[ $lang{opportunities},	'opportunities','mainf'],
		[ $lang{products},	'products',	'mainf'],
		[ $lang{services},	'services',	'mainf'],
		[ $lang{equipments},	'equipments',	'mainf'],
		[ $lang{documentation}, 'documentation','mainf']
	    );

    $html .= _mk_menu(	'protocols', 1,
		[ $lang{contracts},	'contracts',	'mainf'],
		[ $lang{offers},	'offers',	'mainf'],
		[ $lang{nc_int},	'nc_int',	'mainf'],
		[ $lang{nc_ext},	'nc_ext',	'mainf'],
		[ $lang{letters},	'letters',	'mainf'],
		[ $lang{fax_sent},	'fax_sent',	'mainf'],
		[ $lang{fax_received},	'fax_received',	'mainf'],
		[ $lang{archive},	'archive',	'mainf'],
		[ $lang{orders},	'orders',	'mainf'],
		[ $lang{binders},       'binders',      'mainf'],
	    );

    $html .= _mk_menu(  'controls', 1,
      [ $lang{summary},
        'igsuite?action=summary',
        'mainf' ],
      [ $lang{settings},
	'preferences',
	'mainf' ],
      [ $lang{logout},
        'igsuite?action=logout" onclick="'.
          IG::JsConfirm($IG::lang{are_you_sure}),
        '_top' ] );

    ## Add personal menu items
    if (%IG::menu_item)
     {
      my @items;
      foreach (keys %IG::menu_item)
       { push @items, ([$_, $IG::menu_item{$_}[0], $IG::menu_item{$_}[1] ]); }
      $html .= _mk_menu( $lang{personals}, 0, @items ) if $items[0][0];
     }
     
    ## close class menu_content
    $html .= "\n<!-- Close Menu Content -->\n</div>\n";
   }

  if ( $IG::screen_size eq 'noframe2' )
   {
    $html .= '</div>';
   }
  elsif ( $auth_user ne 'guest' && $IG::screen_size ne 'noframe' )
   {
    $html .= Img( style      => "position:absolute; left:0px; bottom:0px; ".
                                "visibility:visible; width:7px; height:19px;",
                  href       => "javascript: parent.resizeFrame('5,*')",
                  src        => "$IG::img_url/hide.gif",
                  title      => "Close Frame" );
   }

  defined wantarray ? return $html : PrOut $html;
 }

##############################################################################
##############################################################################
sub _mk_star_logo
 {
  ##XXX2TRANSLATE
  my $username = IG::TextElide( string => $auth_user, length => 12 );

  return "<table cellspacing=0 cellpadding=0 width=80>
          <tr><td width=\"100%\" align=\"center\">
	  <table cellspacing=0 cellpadding=0>
	   <tr>
  	    <td></td>
	    <td align=\"center\">
		<a href=\"igsuite?action=summary\" target=\"mainf\">
		<img src=\"$IG::img_url/${tema}su.gif\" border=0 alt=\"$lang{summary}\" title=\"$lang{summary}\"></a>
	    </td>
	    <td></td>
	   </tr><tr>
	    <td align=\"right\" valign=\"middle\">
		<a href=\"javascript:history.go(-1)\" target=\"mainf\">
		<img src=\"$IG::img_url/${tema}sinistra.gif\" border=0 alt=\"$lang{previous_page}\" title=\"$lang{previous_page}\"></a>
	    </td>
	    <td style=\"background-color:$IG::clr{bg_menu_title}\">
		<a href=\"igsuite?action=setsessionyear\"
		   target=\"leftf\"
		   title=\"Usa le punte della stella per navigare\"
		   style=\"color:$IG::clr{font_menu_title}; line-height:1.1em; text-align:center; font-size:10px; display:block\">$tv{session_year}<br>$username</a>
	    </td>
	    <td align=\"left\" valign=\"middle\">
		<a href=\"javascript:history.go(+1)\" target=\"mainf\">
		<img src=\"$IG::img_url/${tema}destra.gif\" border=0 alt=\"$lang{next_page}\" title=\"$lang{next_page}\"></a>
	    </td>
	   </tr><tr>
	    <td></td>
 	    <td align=\"center\">
		<a href=\"igsuite?action=summary\" target=\"mainf\" onclick=\"javascript:winPopUp('igsuite?',(window.screen.availWidth-10),(window.screen.availHeight-10),'OverTop');\">
		<img src=\"$IG::img_url/${tema}giu.gif\" border=0  alt=\"Full Screen\" title=\"Full Screen\"></a>
	    </td>
	    <td></td>
	   </tr>
	  </table>
	 </td></tr></table>\n";
 }

##############################################################################
##############################################################################
sub _mk_menu
 {
  my ($title, $check_script, @data) = @_;
  my $html;

  $lang{$title} ||= ucfirst($title);
  $lang{$title} = IG::MkEntities($lang{$title});

  ## set image bullet
  my $img_src = -e "$htdocs_dir${S}images${S}${tema}bullet.png"
              ? "$IG::img_url/${tema}bullet.png"
              : "$IG::img_url/bullet.gif";

  foreach my $k ( 0 .. $#data )
   {
    my $scr_url = $data[$k][1];
       $scr_url =~ s/javascript\:winPopUp\(\'([^\']+)\'.+/$1/;
    my ($script) = $scr_url =~ /^([^\?\/]+)[\?\/]*/;

    next if    ( $check_script && ! -e "$IG::cgi_dir${S}$script")
            || ( $IG::privileges{"${script}_view"}
	         && !CheckPrivilege("${script}_view") );

    $html .= ( $data[$k][1] =~ s/^javascript\://
                            ?  "<a href=\"javascript:void(0)\" onclick=\"$data[$k][1]\" "
                            :  "<a href=\"$data[$k][1]\" target=\"$data[$k][2]\" " ).
	      "class=\"item\">".

          
             ( $tema ne 'microview_'
               ? "<img src=\"$img_src\"".
                 " align=\"absmiddle\"".
                 " style=\"background-color:transparent; margin-right:3px; width:9px; height:9px;\">"
               : '' ).

	     IG::MkEntities($data[$k][0]).
	     '</a>';
   }

  if ( $html )
   {
    ## Insert title
    $html = ( $title
	      ? "\n<div class=\"menu_title\">$lang{$title}</div>\n"
	      : '' ).

	    "<div class=\"menu_title_content\">\n$html</div>\n";
   }

  return $html;
 }

1;
