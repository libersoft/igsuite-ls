## IGSuite 4.0.0
## Procedure: Thumbnails.pm
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

package Thumbnails;

use strict;

use vars qw ($VERSION);
$VERSION = '4.0.0';

#############################################################################
#############################################################################
sub new
 {
  my $type = shift;
  my %opt  = @_;
  my $self = {};

  ## In Pdf case "convert" uses "gs" so try to give it a right path
  my $gs_path = $IG::ext_app{gs};
     $gs_path =~ s/[\/\\][^\/\\]+$//;
  $ENV{PATH} .= ":$1" if -d $gs_path;

  $self->{dir}       = $opt{dir};
  $self->{thumb_dir} = $opt{thumb_dir} || '.thumbnails';
  $opt{width}      ||= 48;
  $self->{size}      = "$opt{width}x$opt{height}";
  $self->{overwrite} = $opt{overwrite};

  ## check if there is thumb_dir
  if ( ! -e "$self->{dir}${IG::S}$self->{thumb_dir}" )
   {
    mkdir( IG::CkPath("$self->{dir}${IG::S}$self->{thumb_dir}"), 0755 )
      or die( "Can't make thumbail directory ".
              "in '$self->{dir}${IG::S}$self->{thumb_dir}'\n" );
   }

  return bless $self, $type;
 }

#############################################################################
#############################################################################
sub get_thumb_name
 {
  my $self = shift;
  $self->{imagename} = shift;
  $self->{imagesize} = (stat("$self->{dir}${IG::S}$self->{imagename}"))[7];
  return undef if $self->{imagesize} == 0;
  return IG::Md5Digest( "$self->{imagename} . $self->{imagesize}" );
 }

#############################################################################
#############################################################################
sub can_convert
 {
  my $self = shift;
  return -x $IG::ext_app{convert} ? 1 : 0;
 }

#############################################################################
#############################################################################
sub convert
 {
  my $self = shift;

  my %opt = @_;
     $opt{imagepage} ||= '0';

  my $source_file = $self->{dir} . $IG::S . $opt{imagefilename};

  return 0 if    ! $opt{imagefilename}
              || ! -e $source_file
              || ! can_convert();

  $opt{thumbname}     ||= $self->get_thumb_name( $opt{imagefilename} );
  $opt{thumbfilename} ||= $opt{thumbname} . '.png';

  my $target_file = $self->{dir}       . $IG::S .
                    $self->{thumb_dir} . $IG::S . 
                    $opt{thumbfilename};

  ## check if already we have the thumb
  return $opt{thumbname} if      -e $target_file
                            && ! -z $target_file
                            && ! $self->{overwrite};

  ## Mk the thumbnails
  IG::SysExec( command   => $IG::ext_app{convert},
               stdout    => $IG::_IS_MOD_PERL ? 'active' : '',
               arguments => [(
                '-resize',           "$self->{size}>",
		"$source_file\[$opt{imagepage}\]",
		'-bordercolor',      'white',
		'-border',           6,
		'-bordercolor',      'grey60',
		'-border',           1,
		'-background',       'none',
		'(', '+clone',
		     '-shadow',
		     '60x4+4+4', ')',
		'+swap',
		'-background',       'none',
		'-flatten',
		'-depth',            8,
		'-quality',          95,
		$target_file
		             )]
	     );

  return 0 if ! -e $target_file;
  chmod 0664, $target_file;

  return $opt{thumbname};
 }

#############################################################################
#############################################################################
sub delete_orphan_thumbnails
 {
  my $self = shift;
  my %images;

  ## have we got a thumbnails dir?
  return if ! -d "$self->{dir}${IG::S}$self->{thumb_dir}";

  ## first read image dir
  opendir( IMAGEDIR, $self->{dir} )
   or die( "Can't open directory '$self->{dir}': $!\n" );

  foreach ( grep /\.(tiff|tif|png|jpg|jpeg|gif|bmp|pdf|thm)$/i,
            readdir IMAGEDIR )
   {
    my $thumb_name = $self->get_thumb_name($_) || '';
    next if ! $thumb_name; ## zero file
    $images{$thumb_name}++;
   }
  closedir (IMAGEDIR);

  ## now read thumbnails dir
  opendir( THUMBDIR, "$self->{dir}${IG::S}$self->{thumb_dir}" )
    or die("Can't open directory '$self->{dir}${IG::S}$self->{thumb_dir}': $!\n");

  foreach ( grep /^.{32}\.png$/, readdir THUMBDIR )
   {
    my $thumb_name = substr( $_, 0, 32 );
    if ( ! $images{$thumb_name} )
     {
      IG::FileUnlink ("$self->{dir}${IG::S}$self->{thumb_dir}${IG::S}$_")
        or die("Can't delete thumbnails file '$_'.\n");
     }
   }
  closedir (THUMBDIR);
 }

1;
