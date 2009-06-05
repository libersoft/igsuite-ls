## IGSuite 4.0.0
## Procedure: System.pm
## Last update: 25/05/2009
#############################################################################
# IGSuite 4.0.0 - Provides an Office Suite by  simple web interface         #
# Copyright (C) 2002 Dante Ortolani  [LucaS]                                #
#                                                                           #
# Copied and inspired from IPC::System::Simple                              #
# Copyright (C) 2006 by Paul Fenwick <pjf@cpan.org>                         #
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

package IG::System;

use strict;
use Config;
use POSIX qw(WIFEXITED WEXITSTATUS WIFSIGNALED WTERMSIG);

use vars qw ($VERSION);
$VERSION = '4.0.0';

## give a name to exit signals
my @Signal_from_number = split(' ', $Config{sig_name});

# Not all systems implment the WIFEXITED calls, but POSIX
# will always export them (even if they're just stubs that
# die with an error).  Test for the presence of a working
# WIFEXITED and friends, or define our own.

eval { local $SIG{'__DIE__'}; WIFEXITED(0); };
if ($@ =~ /not defined POSIX macro/)
 {
  *WIFEXITED   = sub { $_[0] != 1 and not $_[0] & 127 };
  *WEXITSTATUS = sub { $_[0] >> 8  };
  *WIFSIGNALED = sub { $_[0] & 127 };
  *WTERMSIG    = sub { $_[0] & 127 };
 }

############################################################################
############################################################################
sub run
 {
  my %data = @_;
  ## Valid parameters  are:
  ## command       : command to execute
  ## arguments     : an array of arguments
  ## stdout        : active (>STDOUT) | none (>STDERR)
  ## valid_signals : an array of valid exit signals

  my %valid_signals = map { $_, 1 } ( $data{valid_signals}
                                      ? @{$data{valid_signals}}
                                      : ( 0..255 ) );
  my $command       = $data{command};
  my @args          = $data{arguments} ? @{$data{arguments}} : ();
  $data{stdout}   ||= 'none';

  ## reset CHLD signal to default (Needed by mod_perl)
  $SIG{CHLD} = 'DEFAULT';
  
  ## Check values
  if ( !$command )
   {
    push @IG::errmsg, 'No command to execute';
    return 0;
   }

  eval( 'require IPC::Run3' );
  if ( 0 && !$@ )
   {
    #  ^^^^
    #XXX2DEVELOPE
   }
  else
   {
    ## Use an IG solution
    if ( $data{stdout} ne 'active' )
     {
      ## redirect STDOUT to STDERR
      open my $oldout, ">&STDOUT" or die "Can't dup STDOUT: $!";

      close STDOUT;
      open ( STDOUT, '>&', \*STDERR ) or die "Can't dup STDOUT: $!";

      select STDERR; $| = 1;	# make unbuffered
      select STDOUT; $| = 1;	# make unbuffered

      ## Call system()
      system($command, @args);

      ## restore original STDOUT
      close STDOUT;
      open ( STDOUT, '>&', $oldout )
        or die "Can't reopen original stdout: $!";
     }
    else
     {
      ## Call system() without stdout redirection
      system($command, @args);
     }
   }


  ## ANALYZE OUTPUT SIGNALS
  ##

  ## Flush STDOUT needed by Perl<5.6.0
  $| = 1;

  ## failed to start
  if ($? == -1)
   {
    push @IG::errmsg, qq{"$command" failed to start: "$!"};
    return 0;
   }

  ## exit with a signal
  elsif ( WIFEXITED( $? ) )
   {
    my $exit_value = WEXITSTATUS( $? );

    if ( not defined $valid_signals{$exit_value} )
     {
      push @IG::errmsg,
           qq{"$command" unexpectedly returned exit value $exit_value"};
      return 0;
     }
    ## ok it's a valid signal
    return 1;
   }

  ## stopped by a signal
  elsif ( WIFSIGNALED( $? ) )
   {
    my $signal_no   = WTERMSIG( $? );
    my $signal_name = $Signal_from_number[$signal_no] || 'UNKNOWN';
      
    push @IG::errmsg,
         qq{"$command" died to signal "$signal_name" ($signal_no)};
    return 0;
   }

  ## any signal!
  push @IG::errmsg,
       qq{Internal error - "$command" ran without exit value or signal"};
  return 0;
 }

1;
