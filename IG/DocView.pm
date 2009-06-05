## IGSuite 4.0.0
## Procedure: DocView.pm
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

package DocView;

use IG;
use IG::FileMMagic;
use strict;

use vars qw ($VERSION);
$VERSION = '4.0.0';

sub extract
 {
  my %opt  = @_;

  #XXX2TEST ON WINDOWS
  die("Can't execute 'convert' application. Please set a right path value ".
      "inside igsuite configuration file for \$ext_app{convert} variable.\n")
    if ! -x $IG::ext_app{convert};

  die("You have to specify at least source file and protocol id to extract.\n")
    if !$opt{protocol} || !$opt{sourcefile};

  die("Source file doesn't exist: $opt{sourcefile}\n")
    if ! -e $opt{sourcefile};

  ## In Pdf case "convert" uses "gs" so we have give it the path
  my $gs_path = $IG::ext_app{gs};
  $gs_path    =~ /^(.+)\/[^\/]+$/;
  $ENV{PATH}  = "$ENV{PATH}:$1";

  ## Adjust options
  $opt{width}     ||= 800;
  $opt{height}    ||= 1200;
  $opt{imagepage} ||= '0';
  $opt{targetdir} ||= $IG::temp_dir;
  $opt{protocol}    =~ s/\./\_/;
  my $size = "$opt{width}x$opt{height}";

  ## set a page file path
  my $page_file_path = "$opt{targetdir}$IG::S".
                       "$opt{protocol}_".
                       "p$opt{imagepage}_".
                       "${size}".
                       ".jpg";

  ## check file type
  my $mm = new File::MMagic;
  my $res = $mm->checktype_filename( $opt{sourcefile} );
  return undef if $opt{sourcefile} !~ /\.(pdf|tiff*)$/i && $res !~ /(pdf|tif)/;

  ## Create the thumbnails in some cases
  if (   ! -e $page_file_path                            # no file in cache
      || $opt{rotate}                                    # rotate request
      || (-M $page_file_path) > (-M $opt{sourcefile}) )  # expired cache
   {
    IG::SysExec( command   => $IG::ext_app{convert},
                 arguments => [(
                                ## Source file
	                 	"$opt{sourcefile}\[$opt{imagepage}\]",

                                ## Quiet mode
                                #XXX '-quiet', problem with ImageMagick-6.2.0.3

                                ## Optimizing
	                        '-antialias',
	                        '-quality', 95,

                                ## New sizes
                                '-support', '1.0',
	                        '-resize', "$size!",

                                ## Rotate options
	                        ( $opt{rotate} > 1
	                     	  ? ('-rotate', $opt{rotate})
	                 	  : ''),

                                ## Document title
                                ( $opt{title}
                                  ? ('-gravity',    'NorthWest',
                                     '-background', '#EEEEEE',
                                     '-splice',     '0x20',
                                     '-font',       'helvetica',
                                     '-fill',       'black',
                                     '-pointsize',  '14',
                                     '-draw',       "text 0,0 \"$opt{title}\"")
                                  : ''),

                                ## Output file
	                  	$page_file_path
		               )]
               ) or die("Can't execute $IG::ext_app{convert}");
   }
  return $page_file_path;
 }

#############################################################################
#############################################################################
sub showdoc
 {
  my %opt  = @_;
  my $html;

  $opt{width}  ||= 800;
  $opt{height} ||= 1200;
  
  die("Any document ID specified") if !$opt{id};

  if (!$opt{sourcefile} || !$opt{doc_protocol})
   {
    my ( $doc_file_name,
         $doc_file_dir,
         $doc_protocol ) = IG::ProtocolToFile( $opt{id} );

    die("Any file relating to protocol $opt{id}") if !$doc_file_name;

    $opt{sourcefile}   = $doc_file_dir . $IG::S . $doc_file_name;
    $opt{doc_protocol} = $doc_protocol;
   }
          
  if ( $opt{sourcefile} !~ /\.(pdf|tiff*)$/i )
   {
    $html = TaskMsg("Only Pdf or Tiff files", 6);
   }
  elsif ( ! -x $IG::ext_app{convert} )
   {
    $html = TaskMsg("$lang{no_preview}<br><br>", 6);
   }
  else
   {
    $opt{pages} ||= DocView::getpages( sourcefile => $opt{sourcefile} );
    my $doc_image =   Img(   id      => 'documentpageview',
                             width   => $opt{width},
                             onclick => $opt{pages}>1 ? "setPage('next');" : '',
                             style   => $opt{pages}>1 ? 'cursor:pointer' : '',
	                     src     => "docview?".
	                                "action=page_view&amp;".
	                                "page=$opt{page}&amp;".
	                                "protocol=$opt{id}&amp;".
	                                "rotate=$opt{rotate}&amp;".
	                                "width=$opt{width}&amp;".
	                                "height=$opt{height}" );

    if ($on{print})
     {
      $html = $doc_image;
     }
    else
     {
      my @pages;
      for (0..($opt{pages}-1))
       {
        my $page = $_ + 1;
        $pages[$_][0] = $_;
        $pages[$_][1] = "$lang{pages} $page/$opt{pages}";
       }

      $html = IG::JsExec( position => 'inline',
                          code     => <<END );
  function setSrc()
   {
    var pgview = \$('documentpageviewnavi');

    document.images['documentpageview'].src
      = 'docview?action=page_view&amp;' +
        'width=$opt{width}&amp;' +
        'height=$opt{height}&amp;' +
        'protocol=$opt{id}&amp;' +
        'page=' + (pgview.value ? pgview.value : '0') + '&amp;' +
        'rotate=' + rotate.value;

    if ( ( parseInt(pgview.length) - 1 )> parseInt(pgview.value) )
     {
      var imgnext = parseInt(pgview.value) + 1;
      preLoad(imgnext);
     }
     
    // scroll on top of page
    document.body.scrollTop = 0;
   }

  function setPage(direction)
   {
    var pgview = \$('documentpageviewnavi');

    for (var i = pgview.length-1; i >= 0; i--)
     {
      if ( pgview.options[i].selected )
       {
        if (direction == "next")
         {
          if ( i > pgview.length-2 ) { i = -1; }
          pgview.selectedIndex = i + 1;
         }
        else
         {
          if ( i == 0 ) { i = pgview.length; }
          pgview.selectedIndex = i - 1;
         }
 
        setSrc();
        break;        
       }
     }
   }

  function preLoad(imgnext)
   {
    pic1 = new Image($opt{width},$opt{height}); 
    pic1.src = 'docview?action=page_view&amp;' +
               'width=$opt{width}&amp;' +
               'height=$opt{height}&amp;' +
               'protocol=$opt{id}&amp;' +
               'page=' + imgnext + '&amp;' +
               'rotate=' + rotate.value; 
   }
END

      IG::JsExec( position => 'footer',
                  code     => 'preLoad(1);' ) if $opt{pages} > 1;

      ## Get Direct Link to Document
      my $direct_link = IG::DirectLink($opt{id});
      $direct_link =~ s/.+href=\"([^\"]+)\".+/$1/;
                  
      $html
       .= TaskMsg
           ( HLayer
              (
               left_layers
                 => [( Img(  src        => "$IG::img_url/${IG::tema}left.gif",
                             style      => "cursor:pointer;", 
                             onclick    => "setPage('previous')" ),

                       Input( type      => 'select',
                              onchange  => 'setSrc();',
                              override  => 1,
                              value     => $opt{page} || '0',
  	                      name      => "documentpageviewnavi",
	                      data      => \@pages ),

                       Img (  src       => "$IG::img_url/${IG::tema}right.gif",
                              style     => "cursor:pointer;", 
                              onclick   => "setPage('next')" )
                     )],
               right_layers
                 => [( Input( type      => 'select',
                              name      => 'rotate',
                              zerovalue => 'true',
                              show      => $lang{turn},
                              labelstyle=> 'width:auto;',
                              onchange  => 'setSrc();',
                              value     => '0',
                              data      => [([  1, $lang{normal_view}],
 		                             [ 90, '90 gradi'],
 		                             [180, '180 gradi'],
 		                             [270, '270 gradi'])]),

                       Input( type      => 'button',
                              name      => 'viewdoc',
                              onclick   => "window.location = '$direct_link';",
                              show      => $lang{view_document} )
                     )] ).

             $doc_image
	     ,6 );
    }
   }

  defined wantarray ? return $html : PrOut $html;
 }

#############################################################################
#############################################################################
sub getpages
 {
  my %opt  = @_;
  my $pages = 0;

  ## in these cases doesn't work!
  return undef if ! -x $IG::ext_app{convert} || ! -e $opt{sourcefile};

  ## check file type
  my $mm = new File::MMagic;
  my $res = $mm->checktype_filename( $opt{sourcefile} );
  return undef if $opt{sourcefile} !~ /\.(pdf|tiff*)$/i && $res !~ /(pdf|tif)/;

  ## we try to use ImageMagick (identify) to discover page number
  ## next or a tiff parsing or PDF::Extract
  if ( $res =~ /pdf/)
   {
    ## Try to parse pdf file (to test!)
    open (DET, '<', $opt{sourcefile})
      or die("Can't open $opt{sourcefile}");
    binmode(DET);
    while (<DET>)
     { $pages++ while s/\/Type\s*\/Page[>\/\s]//; }
    close(DET);
   }
        
  if ( !$pages && -x $IG::ext_app{identify} && -x $IG::ext_app{gs} )
   {
    ## In Pdf case "identify" uses "gs" so we have give it the path
    my $gs_path = $IG::ext_app{gs};
       $gs_path    =~ /^(.+)\/[^\/]+$/;
    $ENV{PATH}  = "$ENV{PATH}:$1";     

    my $identified_pages;
    #XXX we could use SysExec
    open (IDENT, "$IG::ext_app{identify} -format \"-\" $opt{sourcefile}|")
      or die("Exec: $IG::ext_app{identify} -format \"-\" $opt{sourcefile}");
    $identified_pages .= $_ while <IDENT>;
    $pages = length($identified_pages) - 1;

    close(IDENT);
   }
  elsif ( $res =~ /tif/)
   {
    ## Try to parse tiff file (not safe!)
    open (DET, '<', $opt{sourcefile})
      or die("Can't open $opt{sourcefile}");
    binmode(DET);
    while (<DET>)
     {
      $pages++ if /\000\136\210\004\000\001\000\000\000/;
     }
    close(DET);
    $pages ||= 1;
   }     
  elsif ( !$pages && $res =~ /pdf/ )
   {
    ## Try to use PDF::Extract
    require IG::PDFExtract;
    my $pdf = new PDF::Extract( PDFDoc => $opt{sourcefile} );
    die("No pdf object") if !$pdf;

    while ( my $page = $pdf->getPDFExtract( PDFPages => ++$pages ) )
     { last if !$page; }
    $pages--;
              
    die("Any page from PDF file. " . $pdf->getVars("PDFError")) if !$pages;
   }

  return $pages;
 }

#############################################################################
#############################################################################
sub photo_view
 {
  my %opt  = @_;
  my $source_file_path;

  die("Wrong source file type. Photo type: '$opt{photo_type}'\n")
    if $opt{photo_type} !~ /^(users|equipments|filemanager)$/;

  my $size = "$opt{width}x$opt{height}";

  if ($opt{photo_type} eq 'filemanager')
   {
    $source_file_path = $opt{file_path};
    $size .= '>';
   }
  else
   {
    $source_file_path = $IG::data_dir    . $IG::S .
                        'photo'          . $IG::S .
                        $opt{photo_type} . $IG::S .
                        $opt{photo_name};
    $size .= ' !' if $opt{width} && $opt{height};
   }

  ## Adjust options
  $opt{targetdir} ||= $IG::temp_dir;

  ## set a target file path
  my $target_file_path = $opt{targetdir} . $IG::S .
                         IG::Crypt( ($opt{photo_name} || $opt{file}).
                                    $opt{photo_type}.
                                    $opt{width}.
                                    $opt{height} ) .
                         '.jpg';



  return if ! -e $source_file_path;

  if ( -x $IG::ext_app{convert} )
   {
    ## In Pdf case "convert" uses "gs" so we have give it the path
    my $gs_path = $IG::ext_app{gs};
    $gs_path    =~ /^(.+)\/[^\/]+$/;
    $ENV{PATH}  = "$ENV{PATH}:$1";

    ## Create the thumbnails in some cases
    if (   ! -e $target_file_path                           # no file in cache
        || $opt{rotate}                                     # rotate request
        || (-M $target_file_path) > (-M $opt{sourcefile}) ) # expired cache
     {
      IG::SysExec( command   => $IG::ext_app{convert},
                   arguments => [(
                                ## Source file
	                 	$source_file_path.'[0]',

                                ## Quiet mode
                                #XXX '-quiet', problem with ImageMagick-6.2.0.3

                                ## Optimizing
	                        '-antialias',
	                        '-quality', 95,

                                ## New sizes
                                '-support', '1.0',
	                        ( $opt{width} || $on{height}
	                          ? ('-resize', $size)
	                          : ''),

                                ## Rotate options
	                        ( $opt{rotate} > 1
	                     	  ? ('-rotate', $opt{rotate})
	                 	  : ''),

                                ## Output file
	                  	$target_file_path
		               )]
               ) or die( "Can't execute $IG::ext_app{convert} - ".
                         pop(@IG::errmsg) . '. ' );
     }
   }
  else
   {
    ## if we can't "convert" then simply copy the image file
    IG::FileCopy( $source_file_path,
                  $target_file_path);
   }

  return $target_file_path;
 }

#############################################################################
#############################################################################

1;
