## IGSuite 4.0.0
## Procedure: FileDirSync.pm
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

package File::DirSync;

use strict;
use Exporter;
use IG::FilePath qw(rmtree); #XXXIG
use IG::FileCopy qw(copy); #XXXIG
use Carp;

use vars qw( $VERSION @ISA );
$VERSION = '1.14';
@ISA = qw(Exporter);

use constant HAS_SYMLINKS => ($^O !~ /Win32/i) || 0;

sub new {
  my $class = shift;
  my $self = shift || {};
  $self->{only} ||= [];
  $| = 1 if $self->{verbose};
  bless $self, $class;
  return $self;
}

sub rebuild {
  my $self = shift;
  my $dir = shift || $self->{src};

  croak 'Source directory must be specified: $obj->rebuild($directory) or define $obj->src($directory)'
    unless defined $dir;

  # Remove trailing / if accidently supplied
  $dir =~ s%/$%%;
  -d $dir or
    croak 'Source must be a directory';

  if (@{ $self->{only} }) {
    foreach my $only (@{ $self->{only} }) {
      if ($only =~ /^$dir/) {
        $self->_rebuild( $only );
      } else {
        croak "$only is not a subdirectory of $dir";
      }
      local $self->{localmode} = 1;
      while ($only =~ s%/[^/]*$%% && $only =~ /^$dir/) {
        $self->_rebuild( $only );
      }
    }
  } else {
    $self->_rebuild( $dir );
  }
  print "Rebuild cache complete.\n" if $self->{verbose};
}

sub _rebuild {
  my $self = shift;
  my $dir = shift;

  # Hack to snab a scoped file handle.
  my $handle = do { local *FH; };
  $dir = $1 if $dir =~ m%^(.*)$%;
  return unless opendir($handle, $dir);
  my $current = (lstat $dir)[9];
  my $most_current = $current;
  my $node;
  my $skew = $self->{maxskew};
  if (defined $skew) {
    $skew += time;
    if ($current > $skew) {
      $most_current = $current = $skew;
    }
  }
  while (defined ($node = readdir($handle))) {
    next if $node =~ /^\.\.?$/;
    next if $self->{ignore}->{$node};
    my $path = "$dir/$node";
    # Recurse into directories to make sure they
    # are updated before comparing time stamps
    !$self->{localmode} && !-l $path && -d _ && $self->_rebuild( $path );
    my $this_stamp = (lstat $path)[9];
    if (defined $skew) {
      if ($this_stamp > $skew and !-l $path) {
        print "Clock skew detected [$path] ".($this_stamp-$skew)." seconds in the future? Repairing...\n" if $self->{verbose};
        utime($skew, $skew, $path);
        $this_stamp = $skew;
      }
    }
    if ($this_stamp > $most_current) {
      print "Found a newer node [$path]\n" if $self->{verbose};
      $most_current = $this_stamp;
    }
  }
  closedir($handle);
  if ($most_current > $current) {
    print "Adjusting [$dir]...\n" if $self->{verbose};
    $most_current = $1 if $most_current =~ /^(\d+)$/;
    utime($most_current, $most_current, $dir);
  }
  return;
}

sub dirsync {
  my $self = shift;
  my $src = shift || $self->{src};
  my $dst = shift || $self->{dst};
  croak 'Source and destination directories must be specified: $obj->dirsync($source_directory, $destination_directory) or specify $obj->to($source_directory) and $obj->src($destination_directory)'
    unless (defined $src) && (defined $dst);

  # Remove trailing / if accidently supplied
  $src =~ s%/$%%;
  -d $src or
    croak 'Source must be a directory';
  # Remove trailing / if accidently supplied
  $dst =~ s%/$%%;
  my $upper_dst = $dst;
  $upper_dst =~ s%/?[^/]+$%%;
  if ($upper_dst && !-d $upper_dst) {
    croak "Destination root [$upper_dst] must exist: Aborting dirsync";
  }
  $self->{_tracking} = {
    removed => [],
    updated => [],
    skipped => [],
    failed  => [],
  };
  return $self->_dirsync( $src, $dst );
}

sub _dirsync {
  my $self = shift;
  my $src = shift;
  my $dst = shift;

  my $when_dst = (lstat $dst)[9];
  my $size_dst = -s _;
  my $when_src = (lstat $src)[9];
  my $size_src = -s _;

  if (HAS_SYMLINKS) {
    # Symlink Check must be first because
    # I could not figure out how to preserve
    # timestamps (without root privileges).
    if (-l _) {
      # Source is a symlink
      my $point = readlink($src);
      if (-l $dst) {
        # Dest is a symlink, too
        if ($point eq (readlink $dst)) {
          # Symlinks match, nothing to do.
          return;
        }
        # Remove incorrect symlink
        print "$dst: Removing symlink\n" if $self->{verbose};
        unlink($dst) || warn "$dst: Failed to remove symlink: $!\n";
      }
      if (-d $dst) {
        # Wipe directory
        print "$dst: Removing tree\n" if $self->{verbose};
        rmtree($dst) || warn "$dst: Failed to rmtree: $!\n";
      } elsif (-e $dst) {
        # Regular file (or something else) needs to go
        print "$dst: Removing\n" if $self->{verbose};
        unlink($dst) || warn "$dst: Failed to purge: $!\n";
      }
      if (-l $dst || -e $dst) {
        warn "$dst: Still exists after wipe?!!!\n";
      }
      $point = $1 if $point =~ /^(.+)$/; # Taint
      # Point to the same place that $src points to
      print "$dst -> $point\n" if $self->{verbose};
      symlink($point, $dst) || warn "$dst: Failed to create symlink: $!\n";
      return;
    }
  }

  if ($self->{nocache} && -d _) {
    $size_dst = -1;
  }
  # Short circuit and kick out the common case:
  # Nothing to do if the timestamp and size match
  if ( defined
       ( $when_src && $when_dst && $size_src && $size_dst) &&
       $when_src == $when_dst && $size_src == $size_dst ) {
    push @{ $self->{_tracking}{skipped} }, $dst;
    return;
  }

  # Regular File Check
  if (-f _) {
    # Source is a plain file
    if (-l $dst) {
      # Dest is a symlink
      print "$dst: Removing symlink\n" if $self->{verbose};
      unlink($dst) || warn "$dst: Failed to remove symlink: $!\n";
    } elsif (-d _) {
      # Wipe directory
      print "$dst: Removing tree\n" if $self->{verbose};
      rmtree($dst) || warn "$dst: Failed to rmtree: $!\n";
    }
    my $temp_dst = $dst;
    $temp_dst =~ s%/([^/]+)$%/.\#$1.dirsync.tmp%;
    if (copy($src, $temp_dst)) {
      if (rename $temp_dst, $dst) {
        print "$dst: Updated\n" if $self->{verbose};
        push @{ $self->{_tracking}{updated} }, $dst;
      } else {
        warn "$dst: Failed to create: $!\n";
      }
    } else {
      warn "$temp_dst: Failed to copy: $!\n";
    }
    if (!-e $dst) {
      warn "$dst: Never created?!!!\n";
      push @{ $self->{_tracking}{failed} }, $dst;
      return;
    }
    # Force permissions to match the source
    chmod( (stat $src)[2] & 0777, $dst) || warn "$dst: Failed to chmod: $!\n";
    # Force user and group ownership to match the source
    chown ( (stat _)[4], (stat _)[5], $dst) || warn "$dst: Failed to chown: $!\n";
    # Force timestamp to match the source.
    utime($when_src, $when_src, $dst) || warn "$dst: Failed to utime: $!\n";
    return;
  }

  # Missing Check
  if (!-e _) {
    # The source does not exist
    # The destination must also not exist
    print "$dst: Removing\n" if $self->{verbose};
    if ( rmtree($dst) ) {
      push @{ $self->{_tracking}{removed} }, $dst;
    } else {
      push @{ $self->{_tracking}{failed} }, $dst;
      warn "$dst: Failed to rmtree: $!\n";
    }
    return;
  }

  # Finally, the recursive Directory Check
  if (-d _) {
    # Source is a directory
    if (-l $dst) {
      # Dest is a symlink
      print "$dst: Removing symlink\n" if $self->{verbose};
      unlink($dst) || warn "$dst: Failed to remove symlink: $!\n";
    }
    if (-f $dst) {
      # Dest is a plain file
      # It must be wiped
      print "$dst: Removing file\n" if $self->{verbose};
      if ( unlink($dst) ) {
        push @{ $self->{_tracking}{removed} }, $dst;
      } else {
        push @{ $self->{_tracking}{failed} }, $dst;
        warn "$dst: Failed to remove file: $!\n";
      }
    }
    if (!-d $dst) {
      if ( mkdir($dst, 0755) ) {
        push @{ $self->{_tracking}{updated} }, $dst;
      } else {
        push @{ $self->{_tracking}{failed} }, $dst;
        warn "$dst: Failed to create: $!\n";
      }
    }
    if (!-d $dst) {
      warn "$dst: Destination directory cannot exist?!!!\n";
    }
    # If nocache() was not specified, then it is okay
    # skip this directory if the timestamps match.
    if (!$self->{nocache}) {
      # (The directory sizes do not really matter.)
      # If the timestamps are the same, nothing to do
      # because rebuild() will ensure that the directory
      # timestamp is the most recent within its
      # entire descent.
      if ( defined ( $when_src && $when_dst) &&
           $when_src == $when_dst ) {
        push @{ $self->{_tracking}{skipped} }, $dst;
        return;
      }
    }

    print "$dst: Scanning...\n" if $self->{verbose};

    # I know the source is a directory.
    # I know the destination is also a directory
    # which has a different timestamp than the
    # source.  All nodes within both directories
    # must be scanned and updated accordingly.

    my ($handle, $node, %nodes);

    $handle = do { local *FH; };
    return unless opendir($handle, $src);
    while (defined ($node = readdir($handle))) {
      next if $node =~ /^\.\.?$/;
      next if $self->{ignore}->{$node};
      next if ($self->{localmode} &&
               !-l "$src/$node" &&
               -d _);
      $nodes{$node} = 1;
    }
    closedir($handle);

    $handle = do { local *FH; };
    return unless opendir($handle, $dst);
    while (defined ($node = readdir($handle))) {
      next if $node =~ /^\.\.?$/;
      next if $self->{ignore}->{$node};
      next if ($self->{localmode} &&
               !-l "$src/$node" &&
               -d _);
      $nodes{$node} = 1;
    }
    closedir($handle);

    # %nodes is now a union set of all nodes
    # in both the source and destination.
    # Recursively call myself for each node.
    foreach $node (keys %nodes) {
      $self->_dirsync("$src/$node", "$dst/$node");
    }
    # Force permissions to match the source
    chmod( (stat $src)[2] & 0777, $dst) || warn "$dst: Failed to chmod: $!\n";
    # Force user and group ownership to match the source
    chown ( (stat $src)[4], (stat _)[5], $dst) || warn "$dst: Failed to chown: $!\n";
    # Force timestamp to match the source.
    utime($when_src, $when_src, $dst) || warn "$dst: Failed to utime: $!\n";
    return;
  }

  print "$src: Unimplemented weird type of file! Skipping...\n" if $self->{verbose};
}

sub only {
  my $self = shift;
  push (@{ $self->{only} }, @_);
}

sub maxskew {
  my $self = shift;
  $self->{maxskew} = shift || 0;
}

sub dst {
  my $self = shift;
  $self->{dst} = shift;
}

sub src {
  my $self = shift;
  $self->{src} = shift;
}

sub ignore {
  my $self = shift;
  $self->{ignore} ||= {};
  # Load ignore into a hash
  foreach my $node (@_) {
    $self->{ignore}->{$node} = 1;
  }
}

sub lockfile {
  my $self = shift;
  my $lockfile = shift or return;
  open (LOCK, ">$lockfile") or return;
  if (!flock(LOCK, 6)) { # (LOCK_EX | LOCK_NB)
    print "Skipping due to concurrent process already running.\n" if $self->{verbose};
    exit;
  }
}

sub verbose {
  my $self = shift;
  if (@_) {
    $self->{verbose} = shift;
  }
  return $self->{verbose};
}

sub localmode {
  my $self = shift;
  if (@_) {
    $self->{localmode} = shift;
  }
  return $self->{localmode};
}

sub nocache {
  my $self = shift;
  if (@_) {
    $self->{nocache} = shift;
  }
  return $self->{nocache};
}


sub entries_updated {
  my $self = shift;
  return () unless ( ref $self->{_tracking} eq 'HASH' );
  return @{ $self->{_tracking}{updated} };
}

sub entries_removed {
  my $self = shift;
  return () unless ( ref $self->{_tracking} eq 'HASH' );
  return @{ $self->{_tracking}{removed} };
}

sub entries_skipped {
  my $self = shift;
  return () unless ( ref $self->{_tracking} eq 'HASH' );
  return @{ $self->{_tracking}{skipped} };
}

sub entries_failed {
  my $self = shift;
  return () unless ( ref $self->{_tracking} eq 'HASH' );
  return @{ $self->{_tracking}{failed} };
}

1;
__END__

=head1 NAME

File::DirSync - Syncronize two directories rapidly

$Id: DirSync.pm,v 1.27 2006/04/18 23:55:42 rob Exp $

=head1 SYNOPSIS

  use File::DirSync;

  my $dirsync = new File::DirSync {
    verbose => 1,
    nocache => 1,
    localmode => 1,
  };

  $dirsync->src("/remote/home/www");
  $dirsync->dst("/home/www");
  $dirsync->ignore("CVS");

  $dirsync->rebuild();

  #  and / or

  $dirsync->dirsync();

=head1 DESCRIPTION

File::DirSync will make two directories exactly the same. The goal
is to perform this syncronization process as quickly as possible
with as few stats and reads and writes as possible.  It usually
can perform the syncronization process within a few milliseconds -
even for gigabytes or more of information.

Much like File::Copy::copy, one is designated as the source and the
other as the destination, but this works for directories too.  It
will ensure the entire file structure within the descent of the
destination matches that of the source.  It will copy files, update
time stamps, adjust symlinks, and remove files and directories as
required to force consistency.

The algorithm used to keep the directory structures consistent is
a dirsync cache stored within the source structure.  This cache is
stored within the timestamp information of the directory nodes.
No additional checksum files or separate status configurations
are required nor created.  So it will not affect any files or
symlinks within the source_directory nor its descent.

=head1 METHODS

=head2 new( [ { properties... } ] )

Instantiate a new object to prepare for the rebuild and/or dirsync
mirroring process.

  $dirsync = new File::DirSync;

Key/value pairs in a property hash may optionally be specified
as well if desired as demonstrated in the SYNOPSIS above.  The
default property hash is as follows:

  $dirsync = new File::DirSync {
    verbose => 0,
    nocache => 0,
    localmode => 0,
    src => undef,
    dst => undef,
  };

=head2 src( <source_directory> )

Specify the source_directory to be used as the default for
the rebuild() method if none is specified.  This also sets
the default source_directory for the dirsync() method if
none is specified.

=head2 dst( <destination_directory> )

Specify the destination_directory to be used as the default
for the dirsync() method of none is specified.

=head2 rebuild( [ <source_directory> ] )

In order to run most efficiently, a source cache should be built
prior to the dirsync process.  That is what this method does.
If no <source_directory> is specified, you must have already
set the value through the src() method or by passing it as a
value to the "src" property to the new() method.  Unfortunately,
write access to <source_directory> is required for this method.

  $dirsync->rebuild( $from );

This may take from a few seconds to a few minutes depending on
the number of nodes within its directory descent.  For best
performance, it is recommended to execute this rebuild on the
computer actually storing the files on its local drive.  If it
must be across NFS or other remote protocol, try to avoid
rebuilding on a machine with much latency from the machine
with the actual files, or it may take an unusually long time.

=head2 dirsync( [ <source_directory> [ , <destination_directory> ] ] )

Copy everything from <source_directory> to <destination_directory>.
If no <source_directory> or <destination_directory> are specified,
you must have already set the values through the src() or dst()
methods or by passing it to the "src" or "dst" properties to new().
Files and directories within <destination_directory> that do not
exist in <source_directory> will be removed.  New nodes put within
<source_directory> since the last dirsync() will be mirrored to
<destination_directory> retaining permission modes and timestamps.
Write access to <destination_directory> is required.  Read-only
access to <source_directory> is sufficient since it will not be
modifed by this method.

  $dirsync->dirsync( $from, $to );

The rebuild() method should have been run on <source_directory>
prior to using dirsync() for maximum efficiency.  If not, then use
the nocache() setting to force dirsync() to mirror the entire
<source_directory> regardless of the dirsync source cache.

=head2 only( <source> [, <source> ...] )

If you are sure nothing has changed within source_directory
except for <source>, you can specify a file or directory
using this method.

  $dirsync->only( "$from/htdocs" );

However, the cache will still be built all the way up to the
source_directory.  This only() node must always be a subdirectory
or a file within source_directory.  This option only applies to
the rebuild() method and is ignored for the dirsync() method.
This method may be used multiple times to rebuild several nodes.
It may also be passed a list of nodes.  If this method is not
called before rebuild() is, then the entire directory structure
of source_directory and its descent will be rebuilt.

=head2 maxskew( [ future_seconds ] )

In order to avoid corrupting directory time stamps into the
future, you can specify a maximum future_seconds that you will
permit a node in the <source> directory to be modified.

  $dirsync->maxskew( 7200 );

If the maxskew method is not called, then no corrections to
the files or directories will be made.  If no argument is
passed, then future_seconds is assumed to be 0, meaning "now"
is considered to be the farthest into the future that a file
should be allowed to be modified.

=head2 ignore( <node> )

Avoid recursing into directories named <node> within
source_directory.  It may be called multiple times to ignore
several directory names.

  $dirsync->ignore("CVS");

This method applies to both the rebuild() process and the
dirsync() process.

=head2 lockfile( <lockfile> )

If this option is used, <lockfile> will be used to
ensure that only one dirsync process is running at
a time.  If another process is concurrently running,
this process will immediately abort without doing
anything.  If <lockfile> does not exist, it will be
created.  This might be useful say for a cron that
runs dirsync every minute, but just in case it takes
longer than a minute to finish the dirsync process.
It would be a waste of resources to have multiple
simultaneous dirsync processes all attempting to
dirsync the same files.  The default is to always
dirsync.

=head2 verbose( [ <0_or_1> ] )

  $dirsync->verbose( 1 );

Read verbose setting or turn verbose off or on.
Default is off.

=head2 localmode( [ <0_or_1> ] )

Read or set local directory only mode to avoid
recursing into the directory descent.

  $dirsync->localmode( 1 );

Default is to perform the action recursively
by descending into all subdirectories of
source_directory.

=head2 nocache( [ <0_or_1> ] )

When mirroring from source_directory to destination_directory,
do not assume the rebuild() method has been run on the source
already to rebuild the dirsync cache.  All files will be
mirrored.

  $dirsync->nocache( 1 );

If enabled, it will significantly degrade the performance
of the mirroring process.  The default is 0 - assume that
rebuild() has already rebuilt the source cache.

=head2 entries_updated()

Returns an array of all directories and files updated in the last
C<dirsync>, an empty list if it hasn't been run yet.

=head2 entries_removed()

Returns an array of all directories and files removed in the last
C<dirsync>, an empty list if it hasn't been run yet.

=head2 entries_skipped()

Returns an array of all directories and files that were skipped in the
last C<dirsync>, an empty list if it hasn't been run yet.

=head2 entries_failed()

Returns an array of all directories and files that failed in the last
C<dirsync>, an empty list if it hasn't been run yet.


=head1 TODO

Generalized file manipulation routines to allow for easier
integration with third-party file management systems.

Support for FTP dirsync (both source and destination).

Support for Samba style sharing dirsync.

Support for VFS, HTTP/DAV, and other more standard remote
third-party file management.

Support for skipping dirsync to avoid wiping the entire
destination directory when the source directory is empty.

Support for dereferencing symlinks instead of creating
matching symlinks in the destination.

=head1 BUGS

If the source or destination directory permission settings do not
provide write access, there may be problems trying to update nodes
within that directory.

If a source file is modified after, but within the same second, that
it is dirsynced to the destination and is exactly the same size, the
new version may not be updated to the destination.  The source will
need to be modified again or at least the timestamp changed after
the entire second has passed by.  A quick touch should do the trick.

It does not update timestamps on symlinks, because I couldn't
figure out how to do it without dinking with the system clock. :-/
If anyone knows a better way, just let the author know.

Only plain files, directories, and symlinks are supported at this
time.  Special files, (including mknod), pipe files, and socket files
will be ignored.

If a destination node is modified, added, or removed, it is not
guaranteed to revert to the source unless its corresponding node
within the source tree is also modified.  To ensure syncronization
to a destination that may have been modifed, a rebuild() will also
need to be performed on the destination tree as well as the source.
This bug does not apply when using { nocache => 1} however.

Win32 PLATFORM: Removing or renaming a node from the source tree
does NOT modify the timestamp of the directory containing that node
for some reason (see test case t/110_behave.t).  Thus, this change
cannot be detected and stored in the source rebuild() cache.  The
workaround for renaming a file is to modify the contents of the
new file in some way or make sure at least the modified timestamp
gets updated.  The workaround for removing a file, (which also
works for renaming a file), is to manually update the timestamp
of the directory where the node used to reside:

  perl -e "utime time,time,q{.}"

Then the rebuild() cache can detect and propagate the changes
to the destination.  The other workaround is to disable the
rebuild() cache (nocache => 1) although the dirsync() process
will generally take longer.

=head1 AUTHOR

Rob Brown, bbb@cpan.org

=head1 COPYRIGHT

Copyright (C) 2002-2003, Rob Brown, bbb@cpan.org

All rights reserved.

This may be copied, modified, and distributed under the same
terms as Perl itself.

=head1 SEE ALSO

L<dirsync(1)>,
L<File::Copy(3)>,
L<perl(1)>

=cut
