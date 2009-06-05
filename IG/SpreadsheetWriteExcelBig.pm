## IGSuite 4.0.0
## Procedure: SpreadsheetWriteExcelBig.pm
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

package Spreadsheet::WriteExcel::Big;

#############################################################################
#
# WriteExcel::Big
#
# Spreadsheet::WriteExcel - Write formatted text and numbers to a
# cross-platform Excel binary file.
#
# Copyright 2000-2008, John McNamara.
#
#

require Exporter;

use strict;
use IG::SpreadsheetWriteExcelWorkbookBig; ##XXXIG




use vars qw($VERSION @ISA);
@ISA = qw(Spreadsheet::WriteExcel::WorkbookBig Exporter);

$VERSION = '2.22';

###############################################################################
#
# new()
#
# Constructor. Wrapper for a Workbook object.
# uses: Spreadsheet::WriteExcel::BIFFwriter
#       Spreadsheet::WriteExcel::OLEwriter
#       Spreadsheet::WriteExcel::WorkbookBig
#       Spreadsheet::WriteExcel::Worksheet
#       Spreadsheet::WriteExcel::Format
#
sub new {

    my $class = shift;
    my $self  = Spreadsheet::WriteExcel::WorkbookBig->new($_[0]);

    bless  $self, $class;
    return $self;
}


1;


__END__



=head1 NAME


Big - A class for creating Excel files > 7MB.


=head1 SYNOPSIS

The direct use of this module is deprecated. See below.


=head1 DESCRIPTION

The module is a sub-class of Spreadsheet::WriteExcel used for creating Excel files greater than 7MB.

Direct use of this module is deprecated. As of version 2.17 Spreadsheet::WriteExcel can create files larger than 7MB if OLE::Storage_Lite is installed.

This module only exists for backwards compatibility.


    use Spreadsheet::WriteExcel::Big;

    my $workbook  = Spreadsheet::WriteExcel::Big->new("file.xls");
    my $worksheet = $workbook->add_worksheet();

    # Same as Spreadsheet::WriteExcel
    ...
    ...


=head1 REQUIREMENTS

OLE::Storage_Lite


=head1 AUTHOR


John McNamara jmcnamara@cpan.org


=head1 COPYRIGHT


© MM-MMVIII, John McNamara.


All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
