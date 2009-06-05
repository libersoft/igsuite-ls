INSTALLING IGSUITE 4.0.0
------------------------------------------------------------------------------

Index
	        1. Introduction
	        2. Installation Requirements
	        3. Configuration
	        4. Quick Start
	        5. On-Line Update
	        6. Upgrade from previous versions
	        7. Manifest
	        8. Copyright
	        9. Trademarks



1. Introduction

IGSuite is a powerful business applications "suite" with a web-based
interface making it easy to use and deploy. It includes a package of
applications which provide a customizable multiuser e-workplace covering such
business requirements such as customer relationship, document management,
resource and planning management.

To access these powerful business applications, the user simply needs use a
new generation browser (with Java script CSS2 and Cookies support). As an
organisation actively involved in the open source community we support the
use of the open source browsers such as Safari, Mozilla, Firefox and Opera
and will also work on Microsoft's Internet Explorer. IGSuite has not been
tested on any beta version of any browser currently released.

Thanks to the user management and authentication system, when you connect to
your server a personalized session will be opened and an environment where it
is possible to manage and personalize your "virtual" workplace is presented.
All with the preferred look and feel (preferred skin), the chosen language,
numerous personal preferences and the possibility to set user privileges per
procedure.


2. Installation Requirements

IGSuite is a group of cgi written in Perl that take advantage exclusively
from an external module support (N.B you have to install if it is not present
in your system yet) in order to connect to a RDBMS (PostgreSQl, MySQL or
SQLite).

Requirements are:


2.1. Perl

There is nothing to special about Perl; IGSuite uses some Perl standard
modules, the so-called "Core", and others not are not standard.
Non standard modules are only used to connect to the Database like
DBD::Pg (for PostgreSQL) ; DBD::mysql for MySQL or DBD::sqlite for SQLite
for which we ask you to read the relative documentation. 


2.2. PostgreSQL or MySQL

These are two of the most manageable Database currently available. During our
job we have tested the performances of both and sure MySQL offers greater
speed performances, but the entire project of IGSuite is native for
PostgreSQL and it is on this database that IGSuite has been mainly tested.


2.3. SQLite

This incredible database is extremely powerful and useful but only and
exclusively when you want to test the Suite or you want to use it for
unimportant amounts of data. The implementation of SQLite is very recent and
not recommended for use in production server environment.


2.3.1 RDBMS Configuration

As far as the RDBMS configuration it will need to have or to create a user
who has the permissions to create tables and database. If you have problems
please read HowTo or FAQ section in the official documentation. You can also
sign to the mailing list or choose some commercial support available.

N.B. THE GREATER NUMBER OF THE PROBLEMS DURING IGSUITE INSTALLATION ARE DUE
TO THE INCORRECT SETTING OF USERS RIGHTS FOR THE DATABASE AND TABLE CREATION
WITHIN THE RDBMS.



2.4. DBI with DBD::Pg or DBD::mysql or DBD::SQLite

These are modules that allow Perl to interact with the database. It is
important to ensure that the one installed is compatible with the version of
the database that is being used.

If you use Linux we refer you back to the documentation of the respective
distribution in use. In fact for some distributions the modules installation
happens thanks to an inner packages manager (E.g. for Suse it is Yast) for
other distributions will be necessary to leverage the packages offered by
http://www.cpan.org 

If you use Windows, you can download Perl from ActivePerl
http://www.activeperl.com a distribution of Active State. Inside of
ActivePerl distribution you can find documentation relative to PPM (Perl
Package Manager) in order to install the cited modules on. On the IGSuite
site in the Howto section there is available a mini-howto that explains how
to install modules under Windows.



2.5. Linux (Any Distribution) - Windows (from 98 to Vista)

We choose to write IGSuite applications so that they are portable and can be
run on almost every platform. This allows the customer the freedom to run the
platform of their choice.

Make you sure that requirements list is compatible with the platform you want
to use for the installation of IGSuite and all should work without any
problems.

Currently we have tested IGSuite on following systems: Ubuntu, Suse, RedHat,
Mandriva, Gentoo, Debian, Slackware, Win98, Win2000 Server, Win XP, Vista.

For futher information, you can consult these documents: [Installing IGSuite
under Windows] 


2.6. [Apache]

This web server is distributed for all currently tested platforms and only
requires a small amount of customisation inside of the configuration file
(httpd.conf).

Be sure that all folders and of particular note: DocumentRoot and cgi-bin
(or practically the system directory that contains the data files and cgi
scripts of IGSuite) they have the read, write and execute permissions (for
cgi-bin directory) for the system user who executes Apache.

We recommend that you configure Apache a in Virtual Host configuration for
IGSuite so as not to interfere with other Web Sites managed by the Apache
web server. 


2.7. [HylaFax (optional)]

Without a doubt this is one of the better open source Fax servers that
exists. It does not need any particular attention from within the IGSuite
framework. Once it is installed (IGSuite can also be installed without it)
you will have to configure a user who has sufficient privileges to access the
received fax using the FTP protocol (Please read official documentation of
Hylafax for more details).

In order to use all the Hylafax features in IGSuite (on Linux only), it will
be necessary to install also the LIBTIFF package on the server where IGSuite
is installed.

N.B. At moment there is no version of Hylafax available for Windows,
therefore the Hylafax feature is not usable when IGSuite is installed on a
Windows platform 


2.8. [Samba (optional)]

On samba we will simply share the Apache "DocumentRoot" directory, where
every user of IGSuite on the client side has privileges to read and write, by
mapping the share to a local drive unit letter. (e.g. L:  ).

The share will also have to allow reading and writing to the user who
executes Apache. This in order to allow IGSuite to create documents and
standard templates.

You can consult HowTo section on the IGSuite official site project. 


3. Configuration

If, before installing IGSuite all the installation requirements have not been
met then numerous anomalies can be expected which will compromise the
execution of the functionalities in the suite.

However as user root/Administrator of the system, you can type "perl
install.pl", and answer all the questions that appear and this will assist you
in ensuring you meet all the requirements for a successful installation.

At the moment, in order to configure IGWebMail you will need to manually edit
the configuration file "cgi_directory/conf/igsuite.conf" and to follow the 
explanations contained in it. For more information, please read this document
on [How to configure IGSuite]. 

IGWebMail can receive email messages by taking advantage of a number of
mechamisms from the use of the POP3 protocol to the direct reading of the
mail spool directory. On Windows systems it will be necessary to use the SMTP
and POP3 protocols for the sending and receiving of the email. 


4. Quick Start

When the installation has been successfully completed, you simply have to use
a  browser (that support HTML 4; CCS; JavaScript; and that is cookies
enabled) and point it to the web server address.

You can open the index.html file made by installation script or call
"igsuite" script by an address like this:

 Example: http://my_server_domain/cgi-bin/igsuite

A form will ask you a Login name and a Password. You have to insert that ones
you set up for "administrator of IGSuite" during the installation. Once you
have logged in, click on Staff item and add others system users or follow
the information provided.


5. On-Line Update

To update IGSuite, you have two possibilities: manual update or automatic
update.

Manual Update: Execute from the command line the follow script:
 root@server# /directory/of/cgi/igsuited --update-igsuite

Automatic Update: "igsuited" is a daemon, which will take care of numerous
operations. One of these is the one to always keeps the system up to date, by
the updating of the scripts and also the updating of the tables and the
databases needed by IGSuite. 

In order to execute it after each system reboot, please refer to the system
documentation of your server.


6. Upgrade from previous versions

	* To update from release 3.2.x execute simply "install.pl" The
script of new release will update all the scripts and the databases
structure.


7. Manifest

In order to see the latest release of the Manifest, follow this address
http://www.igsuite.org/cgi-bin/igwiki?action=findexec&keytofind=manifest


8. Copyright

Copyright (c) 1998-2009. This is free software; see the source for copying
conditions. There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE.

SEE ALSO
perl(1), DBI(3), Mysql(3), Postgres, SQLite, and sure http://www.igsuite.org


9. Trademarks

Microsft and Internet Explorer are trademarks of Microsoft Corporation. All
trademarks are acknowledged as belonging to their rightful owner/s.
