## IGSuite 4.0.0
## Procedure: Hylafax.pm
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

package Hylafax;

use Net::FTP;
use strict;

#XXXIG2DEVELOPE we need to standardize sendq/recvq/status queues
#               set by hfaxd.conf

#XXX No mod_perl compliant
use vars qw (	$port		$host		$login		$pwd
		$timeout	$debug		$passive        $VERSION
		$ftp		$errmsg		@ISA		@EXPORT);

$VERSION = '4.0.0';
require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(	ConnectFax	DeleteFaxJob	PrintFaxStat
        	FaxOutGoing	FaxDone 	GetRecvq
        	InfoFaxJob	SendFax		FaxInfo );

## Set default parameters
$port	||= 4559;
$host	||= '127.0.0.1';
$login	||= 'root';
$pwd	||= '';
$timeout||= 15;
$debug	||= '0';
$passive||= '0';


#############################################################################
#############################################################################
sub ParseLogRow
 {
  my $text = shift;
  ##
  ## date SEND commid modem jobid  jobtag sender 'dest-number'  'CSI' params #pages jobtime conntime 'reason' 
  ## date RECV commid modem <null> <null> fax    'local-number' 'TSI' params #pages jobtime conntime 'reason'
  ##
  ## date     : The date and time of the transaction in the format MM/DD/YY
  ##            HH:MM, where MM is the numeric month, DD the numeric day,
  ##            YY the last two digits of the year, and HH:MM is the time
  ##            in 24-hour format. 
  ## commid   : The communication identifier for the call. 
  ## modem    : The device identifier for the modem that was used to do the
  ##            send or receive. 
  ## jobid    : The job number for outbound calls. 
  ## jobtag   : The client-specified job tag for outbound calls. 
  ## sender   : The sender/receiver's electronic mailing address
  ##            (facsimile receptions are always attributed to the `fax'' user). 
  ## dest-number : The phone number dialed for outgoing calls. 
  ## TSI      : The Transmitter Subscriber Identification string (as received)
  ##            for incoming calls. 
  ## CSI      : The Caller Subscriber Identification string of the remote
  ##             machine (as reported) for outgoing calls. 
  ## local-number : The local phone number on which the data was received. 
  ## params   : The negotiatated facsimile session parameters used for
  ##            transferring data encoded as described below. 
  ## pages    : The total number of pages transferred. 
  ## jobtime  : The duration of the session; in the format HH:MM:SS.
  ##            This time includes setup overhead and any time spent
  ##            cleaning up after a call. 
  ## conntime : The time spent on the phone; in the format HH:MM:SS.
  ##            This should be the time used by the PTT to calculate
  ##            usage charges. 
  ## reason   : A string that indicates if any problem occured during
  ##            the session.
  ##

  $text =~ qr{^
    (\d\d).(\d\d).(\d\d)  #1 date of transaction in the format MM/DD/YY

    \s
    (\d\d\:\d\d)          #2 time of transaction in the format HH:MM

    \t
    (SEND|RECV|CALL)      #3 direction

    \t
    (\d+)                 #4 commid: The communication identifier for the call

    \t
    ([^\t]+)              #5 modem: The device identifier for the modem
                          #  that was used to do the send or receive. 
    \t
    (\d*)                 #6 jobid: The job number for outbound calls. 

    \t
    \"([^\"]*)\"          #7 jobtag: The client-specified job tag for outbound calls. 

    \t
    ([^\t]+)              #8 sender: The sender/receiver's electronic mailing
                          #  address (facsimile receptions are always attributed
                          #  to the fax user).
    \t
    \"([^\"]*)\"          #9 dest-number: The phone number for outgoing calls

    \t
    \"([^\"]*)\"          #10 TSI: The Transmitter Subscriber Identification
                          #   string (as received) for incoming calls. 
                          #   CSI: The Caller Subscriber Identification string
                          #   of the remote machine (as reported) for outgoing calls. 
                          #   local-number: The local phone number on which the data was received. 
    \t
    (\d+)                 #11 params: The negotiatated facsimile session
                          #   parameters used for transferring data encoded
                          #   as described below. 
    \t
    (\d+)                 #12 pages: The total number of pages transferred. 

    \t
    (\d+\:\d+)            #13 jobtime: The duration of the session; in the
                          #   format HH:MM:SS. This time includes setup overhead
                          #   and any time spent cleaning up after a call. 
    \t
    (\d+:\d+)             #14 conntime: The time spent on the phone; in the
                          #   format HH:MM:SS. This should be the time used by
                          #   the PTT to calculate usage charges. 
    \t
    \"([^\"]*)\"          #15 reason: A string that indicates if any problem
                          #   occured during the session.

    \t
    \"([^\"]*)\"          #16 unknown

    \t
    \"([^\"]*)\"          #17 unknown

    \t
    \"([^\"]*)\"          #18 username

          }xs;

  return {} if !$1;

  return { date_m    => $1,
           date_d    => $2,
           date_y    => $3,
           time      => $4,
           direction => $5,
           commid    => $6,
           modem     => $7,
           jobid     => $8,
           jobtag    => $9,
           sender    => $10,
           dest_numb => $11,
           dest_id   => $12,
           params    => $13,
           pages     => $14,
           jobtime   => $15,
           conntime  => $16,
           reason    => $17,
           user      => $20 };
 }

#############################################################################
#############################################################################
sub ConnectFax
 {
  $errmsg = '';
  
  $ftp = Net::FTP->new("$host",
			Port	=> $port,
                        Timeout => $timeout,
                        Debug   => $debug,
			Passive => $passive)
	 or ( ($errmsg = "Can't connect to Hylafax Server") && return 0 );

  $ftp->login($login, $pwd) or ( ($errmsg = "Can't login") && return 0 );
  $ftp->type("I");
  return 1;
 }

#############################################################################
#############################################################################
sub DeleteFaxJob
 {
  my $job = shift;
  ConnectFax() or return 0;
  my @ris = $ftp->quot("jsusp $job");
     @ris = $ftp->quot("jkill $job");
     @ris = $ftp->quot("jdele $job");
  $ftp->quit();
  return 1;
 }

#############################################################################
#############################################################################
sub PrintFaxStat
 {
  my %modem;
  ConnectFax() or return "$errmsg";
  my $msg = "Hylafax Server: $host $IG::lang{user}: $login<br>";

  #my $cx = $ftp->retr("status/any.info");
  #$msg .= $_ while <$cx>;

  for ($ftp->dir("status")) 
   {
    if ($_=~ /Modem/)
     {
      $modem{$1}="$2 ($1)" if $_=~ s/Modem (\w+) \((.+)\)/Fax in $1 \($2\)/g;
 
      if ($IG::lang eq "it")
       {
        $_=~ s/Initializing server/Reinizializzo il modem/g;
        $_=~ s/Receiving from/Sto ricevendo da/g;
        $_=~ s/Listening to rings from modem/Attendo gli squilli del modem/g;
        $_=~ s/Sending job/Sto inviando il lavoro n\./g;
        $_=~ s/Receiving facsimile/Sto ricevendo un Fax sconosciuto/g;
        $_=~ s/Running and idle/Pronto ed in ascolto/g;
        $_=~ s/Answering the phone/Sto rispondendo al telefono/g;
        $_=~ s/Waiting for modem to come ready/Attendo che il modem sia pronto/g;
        $_=~ s/Waiting for modem to come free/Attendo che il modem si liberi/g;
       }
      $msg.="$_<br>";
     }
   }
  $msg ||= "Attention! Check your Hylafax configuration";
  $ftp->quit();
  return $msg;
 }

#############################################################################
#############################################################################
sub FaxOutGoing
 {
  ConnectFax() or return 0;
  my @queue = $ftp->dir('sendq');
  @queue = sort ( @queue );
  $ftp->quit();
  return @queue; 
 }

#############################################################################
#############################################################################
sub FaxDone
 {
  ConnectFax() or return 0;
  my @queue = $ftp->dir('doneq');
  @queue = sort ( @queue );
  $ftp->quit();
  return @queue;
 }

#############################################################################
#############################################################################
sub GetRecvq
 {
  ## Get hylafax received fax
  my $target_path = shift;

  ## try to connect
  ConnectFax() or return 0;

  my $year = substr((localtime(time))[5],-2,2);
  my @fax  = $ftp->dir('recvq')
               or ( $errmsg = "Can't access to recvq dir" && return 0 );  
  my $ris  = $ftp->cwd('recvq')
               or ( $errmsg = "Can't access to recvq dir" && return 0 );

  foreach ( @fax )
   {
    if ( /(fax)(\d+)(\.tif)/ )
     {
      my $faxin   = $1.$2.$3;
      my $faxout  = '7' . substr('00000'.$2, -5, 5) . "_${year}.tif"; 
      my $faxfile = "$target_path$IG::S$faxout";
      my $cx      = $ftp->retr($faxin) || next;

      ## write fax file on local server
      open (FH , '>', $faxfile) or die("Can't write to '$faxfile'.\n");
      binmode(FH);
      print FH $_ while (<$cx>);
      close (FH);

      $cx  = $ftp->abort();
      if ( -e $faxfile )
       {
        my $faxsize = (stat($faxfile))[7];
        next if $faxsize < 500;
        $ris = $ftp->delete($faxin) ;
       }
     }
   }

  $ftp->quit();
  return 1;
 }

#############################################################################
#############################################################################
sub InfoFaxJob
 {
  my ($job, $queue) = @_;
  die("You have to specify a job and a Queue") if !$job || !$queue;
  my %fx;

  ConnectFax() or return 0;
  my $cx = $ftp->retr("$queue/q$job");
  $errmsg = "Can't retrieve $queue/q$job" && return 0 if !$cx;

  while (<$cx>)
   {
    /postscript\:0\:\:docq\/(.+)/g && ( $fx{faxjob} = $1)	||
    /(\w+)\:(.*)/g		   && ( $fx{$1} = $2);
   }
  $ftp->quit();

  return %fx;
 }

#############################################################################
#############################################################################
sub SendFax
 {
  my %fx  = @_;
  my $remote_cover;
  my $remote_document;
  my $unique = time . $$ . int(rand 10000);
  my %ris  = {
		JOB_ID	=> '',
		TRACE	=> '',
		SUCCESS	=> '',
	};

  ##  Set defaults
  $fx{fromuser}		||= $login;
  $fx{touser}		||= 'unknow';
  $fx{tocompany}	||= 'unknow';
  $fx{tolocation}	||= 'unknow';
  $fx{lasttime}		||= '000259';
  $fx{maxdials}		||= '12';
  $fx{maxtries}		||= '3';
  $fx{pagewidth}	||= '209';
  $fx{pagelength}	||= '296';
  $fx{vres}		||= '196';
  $fx{schedpri}		||= '127';
  $fx{chopthreshold}	||= '3';
  $fx{notify}		||= 'none';
  $fx{notifyaddr}	||= $login;
  $fx{sendtime}		||= 'now';
  $fx{jobinfo}		||= '';
  $fx{modem}		||= 'any';
  $fx{pagechop}		||= 'default';

  ##  Basic error checking
  $ris{TRACE} = "*dialstring* parameter is missing" unless $fx{dialstring};
  $ris{TRACE} .= "What I have to send?" if (! -e $fx{docfile} && ! -e $fx{coverfile});
  if ($ris{TRACE}) { return %ris;}

  ##  Try to connect
  if (!ConnectFax())
   {
    $ris{TRACE} = $errmsg;
    return %ris
   };


  if (-e $fx{coverfile})
   {
    $remote_cover = "/tmp/$unique.cover";
    $ris{TRACE} .= "PUT: put $fx{coverfile} in $remote_cover\n";
    $ftp->put($fx{coverfile}, $remote_cover);
    $ris{TRACE} .= $ftp->message;
   }

  if (-e $fx{docfile})
   {
    $remote_document = "/tmp/$unique";
    $ris{TRACE} .= "PUT: put $fx{docfile} in $remote_document\n";
    $ftp->put($fx{docfile}, $remote_document);
    $ris{TRACE} .= $ftp->message;
   }

  $ris{TRACE} .= "JNEW: Make a new job\n";
  $ftp->quot("jnew");
  $ris{TRACE} .= $ftp->message;
  $ftp->message =~ /jobid: (\d+)/i;
  $ris{JOB_ID} = $1 if $1;

  #XXX 'JPARM SENDTIME 23:00': Syntax error,
  # bad time specification (expecting 12 digits).

  foreach ( 	'fromuser',
		'lasttime',
		'maxdials',
		'maxtries',
		'schedpri',
		'dialstring',
		'sendtime',
		'notifyaddr',
		'vres',
		'pagewidth',
		'pagelength',
		'notify',
		'jobinfo',
		'touser',
		'tocompany',
		'tolocation',
		'modem',
		'pagechop',
		'chopthreshold')
   {
    $ris{TRACE} .= "JPARAM: Set $_ = $fx{$_}\n";
    $ftp->quot("jparm $_", $fx{$_});
    $ris{TRACE} .= $ftp->message;
   }

  if (-e $fx{coverfile})
   {
    $ris{TRACE} .= "JPARAM: Set cover = $remote_cover\n";
    $ftp->quot("jparm cover", $remote_cover);
    $ris{TRACE} .= $ftp->message;
   }

  if (-e $fx{docfile})
   {
    $ris{TRACE} .= "JPARAM: Set document = $remote_document\n";
    $ftp->quot("jparm document", $remote_document);
    $ris{TRACE} .= $ftp->message;
   }

  $ris{TRACE} .= "JDUBM: Send the job\n";
  $ftp->quot("jsubm");
  $ris{TRACE} .= $ftp->message;
  $ris{SUCCESS} = $ftp->message =~ /failed/i || $ftp->message =~ /failed/i? 0 : 1;

  ## Delete Cover and fax document
  if (-e $fx{docfile})
   {
    $ris{TRACE} .= "DELETE: Delete $remote_document\n";
    $ftp->delete($remote_document);
    $ris{TRACE} .= $ftp->message;
   }

  if (-e $fx{coverfile})
   {
    $ris{TRACE} .= "DELETE: Delete $remote_cover\n";
    $ftp->delete($remote_cover);
    $ris{TRACE} .= $ftp->message;
   }

  ##  Disconnect
  $ftp->quit;
  $ris{TRACE} .= $ftp->message;

  return %ris;
 }

#############################################################################
#############################################################################
sub FaxInfo
 {
  my $tiff_file = shift;
  my $row;
  my $pages;
  my $received_date;
  my $received_time;
  my $faxnumber;

  if ( $IG::ext_app{faxinfo} && -x $IG::ext_app{faxinfo} )
   {
    ## This is a faxinfo output sample
    ## Sender: 069100643
    ## Pages: 1
    ## Quality: Fine
    ## Page: ISO A4
    ## Received: 2007:08:27 11:32:20
    ## TimeToRecv: 0:27
    ## SignalRate: 14400 bit/s
    ## DataFormat: 2-D MMR
    ## ErrCorrect: Yes

    my $faxinfo = `$IG::ext_app{faxinfo} $tiff_file`;
       $faxinfo =~ /Sender\:\s([^\n\r]+).+
                    Pages\:\s([^\n\r]+).+
                    Received\:\s(\d\d\d\d)(\:|\/)(\d\d)(\:|\/)(\d\d)\s([^\n\r]+)/smx;

    $faxnumber     = $1;
    $pages         = $2;
    $received_date = IG::GetDateByFormat($7,$5,$3);;
    $received_time = $8;
   }

  if ( !$faxnumber )
   {
    ## try to discover faxnumber from a PP hack
    
    open (FH, '<', $tiff_file) or return 0;
    binmode(FH); ##XXX2TEST

    while (<FH>)
     {
      $row = $_;
      $pages++ if /\000\136\210\004\000\001\000\000\000/;
      
      if ($row=~ /\000\136\210\004\000\001\000\000\000.{8}([^\000]+)\000/)
       {
        $faxnumber = $1;
        if ( $faxnumber !~ /\d/)
         {
          ## Neended by Hylafax 4.3.0
          $row =~ /\000\136\210\004\000\001\000\000\000.{14}([^\012]+)\012/;
          $faxnumber = $1;
         }
       }
     }
    close(FH);

    $row =~ /(\d\d\d\d)(\:|\/)(\d\d)(\:|\/)(\d\d).(\d\d)\:(\d\d)\:(\d\d)/;
    $received_date = IG::GetDateByFormat($5,$3,$1);
    $received_time = "$6:$7:$8";
   }

  $faxnumber =~ s/[^\d]//g;
  $pages ||= 1;

  return ($pages, $faxnumber, $received_date, $received_time);
 }

1;
