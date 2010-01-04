## IGSuite 4.0.0
## Procedure: HTTPBrowserDetect.pm
## Last update: 25/11/2009
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

package HTTP::BrowserDetect;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @ALL_TESTS);
require Exporter;

@ISA       = qw(Exporter);
@EXPORT    = qw();
@EXPORT_OK = qw();
$VERSION   = '1.05';

# Operating Systems
push @ALL_TESTS, qw(
    win16   win3x       win31
    win95   win98       winnt
    windows win32       win2k
    winxp   win2k3      winvista
    winme   dotnet      mac
    macosx  mac68k      macppc
    os2     unix        sun
    sun4    sun5        suni86
    irix    irix5       irix6
    hpux    hpux9       hpux10
    aix     aix1        aix2
    aix3    aix4        linux
    sco     unixware    mpras
    reliant dec         sinix
    freebsd bsd         vms
    x11     amiga       android
);

# Devices
push @ALL_TESTS, qw(
    palm    audrey      iopener
    wap     blackberry  iphone
    ipod
);

# Browsers
push @ALL_TESTS, qw(
    mosaic      netscape    nav2
    nav3        nav4        nav4up
    nav45       nav45up     nav6
    nav6up      navgold     firefox
    chrome      safari      ie
    ie3         ie4         ie4up
    ie5         ie5up       ie55
    ie55up      ie6         ie7
    ie8         opera       opera3
    opera4      opera5      opera6
    opera7      lynx        links
    aol         aol3        aol4
    aol5        aol6        neoplanet
    neoplanet2  avantgo     emacs
    mozilla     gecko
);

# Robots
push @ALL_TESTS, qw(
    puf         curl        wget
    getright    robot       yahoo
    altavista   lycos       infoseek
    lwp         webcrawler  linkexchange
    slurp       webtv       staroffice
    lotusnotes  konqueror   icab
    google      java
);

# Properties
push @ALL_TESTS, 'mobile';

#######################################################################################################
# BROWSER OBJECT

my $default = undef;

sub new {
    my ( $class, $user_agent ) = @_;

    my $self = {};
    bless $self, $class;

    unless ( defined $user_agent ) {
        $user_agent = $ENV{'HTTP_USER_AGENT'};
    }

    $self->user_agent($user_agent);
    return $self;
}

foreach my $test (@ALL_TESTS) {
    no strict 'refs';
    my $key = uc $test;
    *{$test} = sub {
        my ($self) = _self_or_default(@_);
        return $self->{tests}->{$key};
    };
}

sub _self_or_default {
    my ($self) = $_[0];
    return @_
        if ( defined $self
        && ref $self
        && ( ref $self eq 'HTTP::BrowserDetect' )
        || UNIVERSAL::isa( $self, 'HTTP::BrowserDetect' ) );
    $default ||= HTTP::BrowserDetect->new();
    unshift( @_, $default );
    return @_;
}

sub user_agent {
    my ( $self, $user_agent ) = _self_or_default(@_);
    if ( defined $user_agent ) {
        $self->{user_agent} = $user_agent;
        $self->_test();
    }
    return $self->{user_agent};
}

# Private method -- test the UA string
sub _test {
    my ($self) = @_;

    my @ff = qw( firefox firebird iceweasel phoenix );
    my $ff = join "|", @ff;

    my $ua = lc $self->{user_agent};

    # Browser version
    my ( $major, $minor, $beta ) = (
        $ua =~ m{
            \/                      # Version starts with a slash
            [A-Za-z]*               # Eat any letters before the major version
            ( [^.]* )               # Major version number is everything before the first dot
            \.                      # The first dot
            ( [\d]* )               # Minor version number is every digit after the first dot
            [\d.]*                  # Throw away remaining numbers and dots
            ( [^\s]* )              # Beta version string is up to next space
        }x
    );

    # Firefox version
    if ( $ua =~ m{
                ($ff)
                \/
                ( [^.]* )           # Major version number is everything before first dot
                \.                  # The first dot
                ( [\d]* )           # Minor version nnumber is digits after first dot
            }x
        ) {
        $major = $2;
        $minor = $3;
    }

    # IE version
    if (
        $ua =~ m{
                compatible;
                \s*
                \w*                 # Browser name
                [\s|\/]
                [A-Za-z]*           # Eat any letters before the major version
                ( [^.]* )           # Major version number is everything before first dot
                \.                  # The first dot
                ( [\d]* )           # Minor version nnumber is digits after first dot
                [\d.]*              # Throw away remaining dots and digits
                ( [^;]* )           # Beta version is up to the ;
                ;
        }x
    ) {
        $major  = $1;
        $minor  = $2;
        $beta   = $3;
    }

    $major = 0 if !$major;
    $minor = 0 + ( '.' . ( $minor || 0 ) );

    $self->{tests} = {};
    my $tests = $self->{tests};

    # Mozilla browsers

    $tests->{GECKO} = ( index( $ua, "gecko" ) != -1 )
        && ( index( $ua, "khtml, like gecko" ) == -1 );

    foreach my $ff ( @ff ) {
        $tests->{FIREFOX} = ( index( $ua, $ff ) != -1 );
        last if $tests->{FIREFOX};
    }

    $tests->{CHROME} = ( index( $ua, "chrome/" ) != -1 );
    $tests->{SAFARI}
        = (    ( index( $ua, "safari" ) != -1 )
            || ( index( $ua, "applewebkit" ) != -1 ) )
        && ( index( $ua, "chrome" ) == -1 );

    # Chome Version
    if ( $tests->{CHROME} ) {
        ( $major, $minor ) = (
            $ua =~ m{
                chrome
                \/
                ( [^.]* )           # Major version number is everything before first dot
                \.                  # The first dot
                ( [^.]* )           # Minor version number is digits after first dot
            }x
        );

        #print "major=$major minor=$minor beta=$beta\n";
    }

    # Safari Version
    elsif ( $tests->{SAFARI} ) {
        if ( index( $ua, "version/" ) != -1 ) {
            ( $major, $minor ) = (
                $ua =~ m{
                    version/
                    ( [^.]* )       # Major version number is everything before first dot
                    \.              # The first dot
                    ( [^.]* )       # Minor version number is digits after first dot
                }x
            );
        }
        else {
            my ( $safari_build, $safari_minor );
            ( $safari_build, $safari_minor ) = (
                $ua =~ m{
                    safari
                    \/
                    ( [^.]* )       # Major version number is everything before first dot
                    (?:             # The first dot
                    ( \d* ))?       # Minor version number is digits after first dot
                }x
            );

            # in some obscure cases, extra characters are captured by the regex
            # like: Mozilla/5.0 (SymbianOS/9.1; U; en-us) AppleWebKit/413 (KHTML, like Gecko) Safari/413 UP.Link/6.3.1.15.0
            $safari_build =~ s{ [^\d] }{}gxms;

            $major = int( $safari_build / 100 );
            $minor = int( $safari_build % 100 ) / 100;
            $beta  = $safari_minor;

            #print "major=$major minor=$minor beta=$beta\n";
        }

    }

    # Gecko-powered Netscape (i.e. Mozilla) versions
    $tests->{NETSCAPE}
        = (    !$tests->{FIREFOX}
            && !$tests->{SAFARI}
            && index( $ua, "mozilla" ) != -1
            && index( $ua, "spoofer" ) == -1
            && index( $ua, "compatible" ) == -1
            && index( $ua, "opera" ) == -1
            && index( $ua, "webtv" ) == -1
            && index( $ua, "hotjava" ) == -1 );

    if (   $tests->{GECKO}
        && $tests->{NETSCAPE}
        && index( $ua, "netscape" ) != -1 )
    {
        ( $major, $minor, $beta ) = (
            $ua =~ m{
                netscape6?\/
                ( [^.]* )           # Major version number is everything before first dot
                \.                  # The first dot
                ( [\d]* )           # Minor version nnumber is digits after first dot
                ( [^\s]* )
            }x
        );
        $minor = 0 + ".$minor";

        #print "major=$major minor=$minor beta=$beta\n";
    }

    # Netscape browsers
    $tests->{NAV2}    = ( $tests->{NETSCAPE} && $major == 2 );
    $tests->{NAV3}    = ( $tests->{NETSCAPE} && $major == 3 );
    $tests->{NAV4}    = ( $tests->{NETSCAPE} && $major == 4 );
    $tests->{NAV4UP}  = ( $tests->{NETSCAPE} && $major >= 4 );
    $tests->{NAV45}   = ( $tests->{NETSCAPE} && $major == 4 && $minor == .5 );
    $tests->{NAV45UP} = ( $tests->{NAV4}     && $minor >= .5 )
        || ( $tests->{NETSCAPE} && $major >= 5 );
    $tests->{NAVGOLD} = ( defined($beta) && index( $beta, "gold" ) != -1 );    
    $tests->{NAV6}   = ( $tests->{NETSCAPE} && ( $major == 5 || $major == 6 ) );    # go figure
    $tests->{NAV6UP} = ( $tests->{NETSCAPE} && $major >= 5 );

    $tests->{MOZILLA} = ( $tests->{NETSCAPE} && $tests->{GECKO} );

    # Internet Explorer browsers

    $tests->{IE} = ( index( $ua, "msie" ) != -1
            || index( $ua, 'microsoft internet explorer' ) != -1 );
    $tests->{IE3}    = ( $tests->{IE}  && $major == 3 );
    $tests->{IE4}    = ( $tests->{IE}  && $major == 4 );
    $tests->{IE4UP}  = ( $tests->{IE}  && $major >= 4 );
    $tests->{IE5}    = ( $tests->{IE}  && $major == 5 );
    $tests->{IE5UP}  = ( $tests->{IE}  && $major >= 5 );
    $tests->{IE55}   = ( $tests->{IE}  && $major == 5 && $minor >= .5 );
    $tests->{IE55UP} = ( $tests->{IE5} && $minor >= .5 )
        || ( $tests->{IE} && $major >= 6 );
    $tests->{IE6} = ( $tests->{IE} && $major == 6 );
    $tests->{IE7} = ( $tests->{IE} && $major == 7 );
    $tests->{IE8} = ( $tests->{IE} && $major == 8 );

    # Neoplanet browsers

    $tests->{NEOPLANET} = ( index( $ua, "neoplanet" ) != -1 );
    $tests->{NEOPLANET2}
        = ( $tests->{NEOPLANET} && index( $ua, "2." ) != -1 );

    # AOL Browsers

    $tests->{AOL}  = ( index( $ua, "aol" ) != -1 );
    $tests->{AOL3} = ( index( $ua, "aol 3.0" ) != -1 )
        || ( $tests->{AOL} && $tests->{IE3} );
    $tests->{AOL4} = ( index( $ua, "aol 4.0" ) != -1 )
        || ( $tests->{AOL} && $tests->{IE4} );
    $tests->{AOL5}  = ( index( $ua, "aol 5.0" ) != -1 );
    $tests->{AOL6}  = ( index( $ua, "aol 6.0" ) != -1 );
    $tests->{AOLTV} = ( index( $ua, "navio" ) != -1 )
        || ( index( $ua, "navio_aoltv" ) != -1 );

    # Opera browsers

    $tests->{OPERA}  = ( index( $ua, "opera" ) != -1 );
    $tests->{OPERA3} = ( index( $ua, "opera 3" ) != -1 )
        || ( index( $ua, "opera/3" ) != -1 );
    $tests->{OPERA4} = ( index( $ua, "opera 4" ) != -1 )
        || ( index( $ua, "opera/4" ) != -1 );
    $tests->{OPERA5} = ( index( $ua, "opera 5" ) != -1 )
        || ( index( $ua, "opera/5" ) != -1 );
    $tests->{OPERA6} = ( index( $ua, "opera 6" ) != -1 )
        || ( index( $ua, "opera/6" ) != -1 );
    $tests->{OPERA7} = ( index( $ua, "opera 7" ) != -1 )
        || ( index( $ua, "opera/7" ) != -1 );

    # Other browsers

    $tests->{CURL}       = ( index( $ua, "libcurl" ) != -1 );
    $tests->{STAROFFICE} = ( index( $ua, "staroffice" ) != -1 );
    $tests->{ICAB}       = ( index( $ua, "icab" ) != -1 );
    $tests->{LOTUSNOTES} = ( index( $ua, "lotus-notes" ) != -1 );
    $tests->{KONQUEROR}  = ( index( $ua, "konqueror" ) != -1 );
    $tests->{LYNX}       = ( index( $ua, "lynx" ) != -1 );
    $tests->{LINKS}      = ( index( $ua, "links" ) != -1 );
    $tests->{WEBTV}      = ( index( $ua, "webtv" ) != -1 );
    $tests->{MOSAIC}     = ( index( $ua, "mosaic" ) != -1 );
    $tests->{PUF}        = ( index( $ua, "puf" ) != -1 );
    $tests->{WGET}       = ( index( $ua, "wget" ) != -1 );
    $tests->{GETRIGHT}   = ( index( $ua, "getright" ) != -1 );
    $tests->{LWP}
        = ( index( $ua, "libwww-perl" ) != -1 || index( $ua, "lwp-" ) != -1 );
    $tests->{YAHOO}  = ( index( $ua, "yahoo" ) != -1 );
    $tests->{GOOGLE} = ( index( $ua, "google" ) != -1 );
    $tests->{JAVA}
        = ( index( $ua, "java" ) != -1 || index( $ua, "jdk" ) != -1 );
    $tests->{ALTAVISTA}    = ( index( $ua, "altavista" ) != -1 );
    $tests->{SCOOTER}      = ( index( $ua, "scooter" ) != -1 );
    $tests->{LYCOS}        = ( index( $ua, "lycos" ) != -1 );
    $tests->{INFOSEEK}     = ( index( $ua, "infoseek" ) != -1 );
    $tests->{WEBCRAWLER}   = ( index( $ua, "webcrawler" ) != -1 );
    $tests->{LINKEXCHANGE} = ( index( $ua, "lecodechecker" ) != -1 );
    $tests->{SLURP}        = ( index( $ua, "slurp" ) != -1 );
    $tests->{ROBOT}        = (
        (          $tests->{WGET}
                || $tests->{PUF}
                || $tests->{GETRIGHT}
                || $tests->{LWP}
                || $tests->{YAHOO}
                || $tests->{ALTAVISTA}
                || $tests->{LYCOS}
                || $tests->{INFOSEEK}
                || $tests->{WEBCRAWLER}
                || $tests->{LINKEXCHANGE}
                || $tests->{SLURP}
                || $tests->{GOOGLE}
        )
            || index( $ua, "bot" ) != -1
            || index( $ua, "spider" ) != -1
            || index( $ua, "crawl" ) != -1
            || index( $ua, "agent" ) != -1
            || index( $ua, "seek" ) != -1
            || index( $ua, "search" ) != -1
            || index( $ua, "reap" ) != -1
            || index( $ua, "worm" ) != -1
            || index( $ua, "find" ) != -1
            || index( $ua, "index" ) != -1
            || index( $ua, "copy" ) != -1
            || index( $ua, "fetch" ) != -1
            || index( $ua, "ia_archive" ) != -1
            || index( $ua, "zyborg" ) != -1
    );

    # Devices

    $tests->{BLACKBERRY} = ( index( $ua, "blackberry" ) != -1 );
    $tests->{IPHONE}     = ( index( $ua, "iphone" ) != -1 );
    $tests->{IPOD}       = ( index( $ua, "ipod" ) != -1 );
    $tests->{AUDREY}     = ( index( $ua, "audrey" ) != -1 );
    $tests->{IOPENER}    = ( index( $ua, "i-opener" ) != -1 );
    $tests->{AVANTGO}    = ( index( $ua, "avantgo" ) != -1 );
    $tests->{PALM}
        = ( $tests->{AVANTGO} || index( $ua, "palmos" ) != -1 );
    $tests->{WAP}
        = (    index( $ua, "up.browser" ) != -1
            || index( $ua, "nokia" ) != -1
            || index( $ua, "alcatel" ) != -1
            || index( $ua, "ericsson" ) != -1
            || index( $ua, "sie-" ) == 0
            || index( $ua, "wmlib" ) != -1
            || index( $ua, " wap" ) != -1
            || index( $ua, "wap " ) != -1
            || index( $ua, "wap/" ) != -1
            || index( $ua, "-wap" ) != -1
            || index( $ua, "wap-" ) != -1
            || index( $ua, "wap" ) == 0
            || index( $ua, "wapper" ) != -1
            || index( $ua, "zetor" ) != -1 );

    $tests->{MOBILE} = (
               index( $ua, "up.browser" ) != -1
            || index( $ua, "nokia" ) != -1
            || index( $ua, "alcatel" ) != -1
            || index( $ua, "ericsson" ) != -1
            || index( $ua, "sie-" ) == 0
            || index( $ua, "wmlib" ) != -1
            || index( $ua, " wap" ) != -1
            || index( $ua, "wap " ) != -1
            || index( $ua, "wap/" ) != -1
            || index( $ua, "-wap" ) != -1
            || index( $ua, "wap-" ) != -1
            || index( $ua, "wap" ) == 0
            || index( $ua, "wapper" ) != -1
            || index( $ua, "blackberry" ) != -1
            || index( $ua, "iemobile" ) != -1
            || index( $ua, "palm" ) != -1
            || index( $ua, "smartphone" ) != -1
            || index( $ua, "windows ce" ) != -1
            || index( $ua, "palmsource" ) != -1
            || index( $ua, "iphone" ) != -1
            || index( $ua, "ipod" ) != -1
            || index( $ua, "opera mini" ) != -1
            || index( $ua, "android" ) != -1
            || index( $ua, "htc_" ) != -1
            || index( $ua, "symbian" ) != -1
            || index( $ua, "webos" ) != -1
            ||

            #               index($ua," ppc") != -1 ||
            index( $ua, "samsung" ) != -1
            || index( $ua, "samsung" ) != -1
            || index( $ua, "zetor" ) != -1
            || index( $ua, "android" ) != -1
    );

    # Operating System

    $tests->{WIN16}
        = (    index( $ua, "win16" ) != -1
            || index( $ua, "16bit" ) != -1
            || index( $ua, "windows 3" ) != -1
            || index( $ua, "windows 16-bit" ) != -1 );
    $tests->{WIN3X}
        = (    index( $ua, "win16" ) != -1
            || index( $ua, "windows 3" ) != -1
            || index( $ua, "windows 16-bit" ) != -1 );
    $tests->{WIN31}
        = (    index( $ua, "win16" ) != -1
            || index( $ua, "windows 3.1" ) != -1
            || index( $ua, "windows 16-bit" ) != -1 );
    $tests->{WIN95}
        = ( index( $ua, "win95" ) != -1 || index( $ua, "windows 95" ) != -1 );
    $tests->{WIN98}
        = ( index( $ua, "win98" ) != -1 || index( $ua, "windows 98" ) != -1 );
    $tests->{WINNT}
        = (    index( $ua, "winnt" ) != -1
            || index( $ua, "windows nt" ) != -1
            || index( $ua, "nt4" ) != -1
            || index( $ua, "nt3" ) != -1 );
    $tests->{WIN2K}
        = ( index( $ua, "nt 5.0" ) != -1 || index( $ua, "nt5" ) != -1 );
    $tests->{WINXP}    = ( index( $ua, "nt 5.1" ) != -1 );
    $tests->{WIN2K3}   = ( index( $ua, "nt 5.2" ) != -1 );
    $tests->{WINVISTA} = ( index( $ua, "nt 6.0" ) != -1 );
    $tests->{DOTNET}   = ( index( $ua, ".net clr" ) != -1 );

    $tests->{WINME} = ( index( $ua, "win 9x 4.90" ) != -1 );    # whatever
    $tests->{WIN32} = (
        (          $tests->{WIN95}
                || $tests->{WIN98}
                || $tests->{WINME}
                || $tests->{WINNT}
                || $tests->{WIN2K}
        )
            || $tests->{WINXP}
            || $tests->{WIN2K3}
            || $tests->{WINVISTA}
            || index( $ua, "win32" ) != -1
    );
    $tests->{WINDOWS} = (
        (          $tests->{WIN16}
                || $tests->{WIN31}
                || $tests->{WIN95}
                || $tests->{WIN98}
                || $tests->{WINNT}
                || $tests->{WIN32}
                || $tests->{WIN2K}
                || $tests->{WINXP}
                || $tests->{WIN2K3}
                || $tests->{WINVISTA}
                || $tests->{WINME}
        )
            || index( $ua, "win" ) != -1
    );

    # Mac operating systems

    $tests->{MAC}
        = ( index( $ua, "macintosh" ) != -1 || index( $ua, "mac_" ) != -1 );
    $tests->{MACOSX} = ( index( $ua, "macintosh" ) != -1
            && index( $ua, "mac os x" ) != -1 );
    $tests->{MAC68K} = ( ( $tests->{MAC} )
            && ( index( $ua, "68k" ) != -1 || index( $ua, "68000" ) != -1 ) );
    $tests->{MACPPC}
        = (    ( $tests->{MAC} )
            && ( index( $ua, "ppc" ) != -1 || index( $ua, "powerpc" ) != -1 )
        );

    # Others

    $tests->{AMIGA} = ( index( $ua, 'amiga' ) != -1 );

    $tests->{EMACS} = ( index( $ua, 'emacs' ) != -1 );
    $tests->{OS2}   = ( index( $ua, 'os/2' ) != -1 );

    $tests->{SUN}  = ( index( $ua, "sun" ) != -1 );
    $tests->{SUN4} = ( index( $ua, "sunos 4" ) != -1 );
    $tests->{SUN5} = ( index( $ua, "sunos 5" ) != -1 );
    $tests->{SUNI86} = ( ( $tests->{SUN} ) && index( $ua, "i86" ) != -1 );

    $tests->{IRIX}  = ( index( $ua, "irix" ) != -1 );
    $tests->{IRIX5} = ( index( $ua, "irix5" ) != -1 );
    $tests->{IRIX6} = ( index( $ua, "irix6" ) != -1 );

    $tests->{HPUX} = ( index( $ua, "hp-ux" ) != -1 );
    $tests->{HPUX9}  = ( ( $tests->{HPUX} ) && index( $ua, "09." ) != -1 );
    $tests->{HPUX10} = ( ( $tests->{HPUX} ) && index( $ua, "10." ) != -1 );

    $tests->{AIX}  = ( index( $ua, "aix" ) != -1 );
    $tests->{AIX1} = ( index( $ua, "aix 1" ) != -1 );
    $tests->{AIX2} = ( index( $ua, "aix 2" ) != -1 );
    $tests->{AIX3} = ( index( $ua, "aix 3" ) != -1 );
    $tests->{AIX4} = ( index( $ua, "aix 4" ) != -1 );

    $tests->{LINUX} = ( index( $ua, "inux" ) != -1 );
    $tests->{SCO} = $ua =~ m{(?:SCO|unix_sv)};
    $tests->{UNIXWARE} = ( index( $ua, "unix_system_v" ) != -1 );
    $tests->{MPRAS}    = ( index( $ua, "ncr" ) != -1 );
    $tests->{RELIANT}  = ( index( $ua, "reliantunix" ) != -1 );

    $tests->{DEC}
        = (    index( $ua, "dec" ) != -1
            || index( $ua, "osf1" ) != -1
            || index( $ua, "declpha" ) != -1
            || index( $ua, "alphaserver" ) != -1
            || index( $ua, "ultrix" ) != -1
            || index( $ua, "alphastation" ) != -1 );

    $tests->{SINIX}   = ( index( $ua, "sinix" ) != -1 );
    $tests->{FREEBSD} = ( index( $ua, "freebsd" ) != -1 );
    $tests->{BSD}     = ( index( $ua, "bsd" ) != -1 );
    $tests->{X11}     = ( index( $ua, "x11" ) != -1 );
    $tests->{UNIX}
        = (    $tests->{X11}
            || $tests->{SUN}
            || $tests->{IRIX}
            || $tests->{HPUX}
            || $tests->{SCO}
            || $tests->{UNIXWARE}
            || $tests->{MPRAS}
            || $tests->{RELIANT}
            || $tests->{DEC}
            || $tests->{LINUX}
            || $tests->{BSD} );

    $tests->{VMS}
        = ( index( $ua, "vax" ) != -1 || index( $ua, "openvms" ) != -1 );

    $tests->{ANDROID} = ( index( $ua, "android") != -1 );

    # A final try at browser version, if we haven't gotten it so far
    if ( !defined($major) || $major eq '' ) {
        if ( $ua =~ /[A-Za-z]+\/(\d+)\;/ ) {
            $major = $1;
            $minor = 0;
        }

    }

    # Gecko version
    $self->{gecko_version} = undef;
    if ( $tests->{GECKO} ) {
        if ( $ua =~ /\([^)]*rv:([\w.\d]*)/ ) {
            $self->{gecko_version} = $1;
        }
    }

    $self->{major} = $major;
    $self->{minor} = $minor;
    $self->{beta}  = $beta;
}

sub browser_string {
    my ($self)         = _self_or_default(@_);
    my $browser_string = undef;
    my $user_agent     = $self->user_agent;
    if ( defined $user_agent ) {
        $browser_string = 'Netscape'    if $self->netscape;
        $browser_string = 'Konqueror' if $self->konqueror; #XXXIG
        $browser_string = 'Firefox'     if $self->firefox;
        $browser_string = 'Safari'      if $self->safari;
        $browser_string = 'Chrome'      if $self->chrome;
        $browser_string = 'MSIE'        if $self->ie;
        $browser_string = 'WebTV'       if $self->webtv;
        $browser_string = 'AOLBrowser' if $self->aol; #XXXIG
        $browser_string = 'Opera'       if $self->opera;
        $browser_string = 'Mosaic'      if $self->mosaic;
        $browser_string = 'Lynx'        if $self->lynx;
    }
    return $browser_string;
}

sub os_string {
    my ($self)     = _self_or_default(@_);
    my $os_string  = undef;
    my $user_agent = $self->user_agent;
    if ( defined $user_agent ) {
        $os_string = 'Win95'    if $self->win95;
        $os_string = 'Win98'    if $self->win98;
        $os_string = 'WinNT'    if $self->winnt;
        $os_string = 'Win2k'    if $self->win2k;
        $os_string = 'WinXP'    if $self->winxp;
        $os_string = 'Win2k3'   if $self->win2k3;
        $os_string = 'WinVista' if $self->winvista;
        $os_string = 'Mac'      if $self->mac;
        $os_string = 'Mac OS X' if $self->macosx;
        $os_string = 'Win3x'    if $self->win3x;
        $os_string = 'OS2'      if $self->os2;
        $os_string = 'Unix'     if $self->unix && !$self->linux;
        $os_string = 'Linux'    if $self->linux;
    }
    return $os_string;
}

sub gecko_version {
    my ( $self, $check ) = _self_or_default(@_);
    my $version;
    $version = $self->{gecko_version};
    if ( defined $check ) {
        return $check == $version;
    }
    else {
        return $version;
    }
}

sub version {
    my ( $self, $check ) = _self_or_default(@_);
    my $version;
    $version = $self->{major} + $self->{minor};
    if ( defined $check ) {
        return $check == $version;
    }
    else {
        return $version;
    }
}

sub major {
    my ( $self, $check ) = _self_or_default(@_);
    my ($version) = $self->{major};
    if ( defined $check ) {
        return $check == $version;
    }
    else {
        return $version;
    }
}

sub minor {
    my ( $self, $check ) = _self_or_default(@_);
    my ($version) = $self->{minor};
    if ( defined $check ) {
        return ( $check == $self->{minor} );
    }
    else {
        return $version;
    }
}

sub beta {
    my ( $self, $check ) = _self_or_default(@_);
    my ($version) = $self->{beta};
    if ($check) {
        return $check eq $version;
    }
    else {
        return $version;
    }
}

sub language {
    
    my ( $self, $check ) = _self_or_default(@_);
    my $parsed = $self->_language_country();
    return $parsed->{'language'};
    
}

sub country {
    
    my ( $self, $check ) = _self_or_default(@_);
    my $parsed = $self->_language_country();
    return $parsed->{'country'};
    
}


sub _language_country {

    my ( $self, $check ) = _self_or_default(@_);

    if ( $self->safari ) {
        if ( $self->major == 1 && $self->user_agent =~ m/\s ( [a-z]{2,} ) \)/xms ) {
            return { language => uc $1 };
        }
        if ( $self->user_agent =~ m/([a-z]{2,})-([a-z]{2,})/xms ) {
            return { language => uc $1, country => uc $2 };
        }
    }

    if ( $self->user_agent =~ m/([a-z]{2,})-([A-Z]{2,})/xms ) {
        return { language => uc $1, country => uc $2 };
    }
    
    return { language => undef, country => undef };
}

1;

__END__

=head1 NAME

HTTP::BrowserDetect - Determine the Web browser, version, and platform from an HTTP user agent string

=head1 VERSION

Version 1.05

=head1 SYNOPSIS

    use HTTP::BrowserDetect;

    my $browser = new HTTP::BrowserDetect($user_agent_string);

    # Detect operating system
    if ($browser->windows) {
      if ($browser->winnt) ...
      if ($brorwser->win95) ...
    }
    print $browser->mac;

    # Detect browser vendor and version
    print $browser->netscape;
    print $browser->ie;
    if (browser->major(4)) {
    if ($browser->minor() > .5) {
        ...
    }
    }
    if ($browser->version() > 4) {
      ...;
    }

    # Process a different user agent string
    $browser->user_agent($another_user_agent_string);



=head1 DESCRIPTION

The HTTP::BrowserDetect object does a number of tests on an HTTP user
agent string.  The results of these tests are available via methods of
the object.

This module is based upon the JavaScript browser detection code
available at
B<http://www.mozilla.org/docs/web-developer/sniffer/browser_type.html>.

=head1 CONSTRUCTOR AND STARTUP

=head2 new()

    HTTP::BrowserDetect->new( $user_agent_string )

The constructor may be called with a user agent string specified.
Otherwise, it will use the value specified by $ENV{'HTTP_USER_AGENT'},
which is set by the web server when calling a CGI script.

You may also use a non-object-oriented interface.  For each method,
you may call HTTP::BrowserDetect::method_name().  You will then be
working with a default HTTP::BrowserDetect object that is created
behind the scenes.

=head1 SUBROUTINES/METHODS

=head2 user_agent($user_agent_string)

Returns the value of the user agent string.  When called with a
parameter, it resets the user agent and reperforms all tests on the
string.  This way you can process a series of user agent strings (from
a log file, perhaps) without creating a new HTTP::BrowserDetect object
each time.

=head2 language

Returns the language string as it is found in the user agent string.  This
will be in the form of an upper case 2 character code.  ie: EN, DE, etc

=head2 country

Returns the country string as it may be found in the user agent string.  This
will be in the form of an upper case 2 character code.  ie: US, DE, etc

=head1 Detecting Browser Version

=head2 major($major)

Returns the integer portion of the browser version.
If passed a parameter, returns true if it equals
the browser major version.

=head2 minor($minor)

Returns the decimal portion of the browser version as a B<floating-point number> less than 1.
For example, if the version is 4.05, this method returns .05; if the version is 4.5, this method returns .5.
B<This is a change in behavior from previous versions of this module, which returned a
string>.

If passed a parameter, returns true if equals the minor version.

On occasion a version may have more than one decimal point, such
as 'Wget/1.4.5'. The minor version does not include the second decimal point,
or any further digits or decimals.

=head2 version($version)

Returns the version as a floating-point number.  If passed a
parameter, returns true if it is equal to the version
specified by the user agent string.

=head2 beta($beta)

Returns any the beta version, consisting of any non-numeric characters
after the version number.  For instance, if the user agent string is
'Mozilla/4.0 (compatible; MSIE 5.0b2; Windows NT)', returns 'b2'.  If
passed a parameter, returns true if equal to the beta version.  If the beta
starts with a dot, it is thrown away.

=head1 Detecting OS Platform and Version

The following methods are available, each returning a true or false
value.  Some methods also test for the operating system version.
The indentations below show the hierarchy of tests (for example, win2k
is considered a type of winnt, which is a type of win32)

  windows
    win16 win3x win31
    win32
        winme win95 win98
        winnt
            win2k winxp win2k3 winvista
  dotnet

  mac
    mac68k macppc macosx

  os2

  unix
    sun sun4 sun5 suni86 irix irix5 irix6 hpux hpux9 hpux10
    aix aix1 aix2 aix3 aix4 linux sco unixware mpras reliant
    dec sinix freebsd bsd

  vms

  amiga

It may not be possibile to detect Win98 in Netscape 4.x and earlier.
On Opera 3.0, the userAgent string includes "Windows 95/NT4" on all Win32, so you can't distinguish between Win95 and WinNT.

=head2 os_string()

Returns one of the following strings, or undef.  This method exists solely for compatibility with the
B<HTTP::Headers::UserAgent> module.

  Win95, Win98, WinNT, Win2K, WinXP, Win2K3, WinVista, Mac, Mac OS X, Win3x, OS2, Unix, Linux

=head1 Detecting Browser Vendor

The following methods are available, each returning a true or false value.  Some methods also
test for the browser version, saving you from checking the version separately.

  netscape nav2 nav3 nav4 nav4up nav45 nav45up navgold nav6 nav6up
  gecko
  mozilla
  firefox
  safari
  chrome
  ie ie3 ie4 ie4up ie5 ie55 ie6 ie7 ie8
  neoplanet neoplanet2
  mosaic
  aol aol3 aol4 aol5 aol6
  webtv
  opera opera3 opera4 opera5 opera6 opera7
  lynx links
  emacs
  staroffice
  lotusnotes
  icab
  konqueror
  java
  curl

Netscape 6, even though its called six, in the userAgent string has version number 5.  The nav6 and nav6up methods correctly handle this quirk.
The firefox text correctly detects the older-named versions of the browser (Phoenix, Firebird)


=head2 browser_string()

Returns one of the following strings, or undef.

Netscape, MSIE, WebTV, AOL Browser, Opera, Mosaic, Lynx

=head2 gecko_version()

If a Gecko rendering engine is used (as in Mozilla or Firebird), returns the version of the renderer (e.g. 1.3a, 1.7, 1.8)
This might be more useful than the particular browser name or version when correcting for quirks in different versions of this rendering engine.
If no Gecko browser is being used, or the version number can't be detected, returns undef.

=head1 Detecting Other Devices

The following methods are available, each returning a true or false value.

  android
  audrey
  avantgo
  blackberry
  iopener
  iphone
  ipod
  palm
  wap

=head2 mobile()

Returns true if the browser appears to belong to a handheld device.

=head2 robot()

Returns true if the user agent appears to be a robot, spider,
crawler, or other automated Web client.

The following additional methods are available, each returning a true
or false value.  This is by no means a complete list of robots that
exist on the Web.

  wget
  getright
  yahoo
  altavista
  lycos
  infoseek
  lwp
  webcrawler
  linkexchange
  slurp
  google
  puf


=head1 AUTHOR

Lee Semel, lee@semel.net (Original Author)

Peter Walsham (co-maintainer)

Olaf Alders, C<olaf at wundercounter.com> (co-maintainer)

=head1 ACKNOWLEDGEMENTS

Thanks to the following for their contributions:

Leonardo Herrera

Denis F. Latypoff

merlynkline

Simon Waters

Toni Cebri�n

Florian Merges

david.hilton.p

Steve Purkis

Andrew McGregor

Robin Smidsrod

Richard Noble

Josh Ritter

Mike Clarke

=head1 SEE ALSO

"The Ultimate JavaScript Client Sniffer, Version 3.0", B<http://www.mozilla.org/docs/web-developer/sniffer/browser_type.html>.

"Browser ID (User-Agent) Strings" B<http://www.zytrax.com/tech/web/browser_ids.htm>

perl(1), L<HTTP::Headers>, L<HTTP::Headers::UserAgent>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::BrowserDetect


You can also look for information at:

=over 4

=item * GitHub Source Repository

L<http://github.com/oalders/http-browserdetect>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-BrowserDetect>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-BrowserDetect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-BrowserDetect>

=item * Search CPAN

L<http://search.cpan.org/dist/HTTP-BrowserDetect/>

=back

=head1 BUGS AND LIMITATIONS

The biggest limitation at this point is the test suite, which really needs to
have many more UserAgent strings to test against. It would also be much easier
to read if the UserAgents and their test conditions were broken out into some
sort of config file. Patches are certainly welcome, with many thanks to the
many contributions which have already been received. The preferred method of
patching would be to fork the GitHub repo and then send me a pull requests,
but plain old patch files are also welcome.

=head1 LICENSE AND COPYRIGHT

Copyright 1999-2009 Lee Semel.  All rights reserved.  This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
