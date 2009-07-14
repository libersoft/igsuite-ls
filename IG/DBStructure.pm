## IGSuite 4.0.0
## Procedure: DBStructure.pm
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

package IG::DBStructure;

use strict;

use vars qw( %db_tables_index %db_tables %db_views @ISA @EXPORT);

use vars qw ($VERSION);
$VERSION = '4.0.0';

require Exporter;
@ISA    = qw( Exporter );
@EXPORT = qw( %db_tables_index %db_tables %db_views);

####### Database table name ##### Field # Indexed Field # old table name ###
%db_tables_index = (
	archive			=> [ 11,'id;issue'],
	letters			=> [ 9,	'id;issue'],
	offers			=> [ 16,'id;issue'],
	orders			=> [ 10,'id;issue'],
	fax_sent		=> [ 10,'id;issue'],
	fax_received		=> [ 10,'id;issue'],
	nc_ext			=> [ 9,	'id'],
	nc_int			=> [ 9,	'id'],
	pages			=> [ 17,'id;name'],
	contracts		=> [ 17,'id;issue;phase'],
	contracts_phases	=> [ 14,'id'],
	email_msgs		=> [ 18,'id;owner,folder', 'email'],
	email_filter		=> [ 7,	''],
	email_msgtags		=> [ 2, 'msgid', 'email_tags'],
	email_imports		=> [ 9, ''],
	isms			=> [ 7,	''],
	contacts		=> [ 64,'contactid;contactname;nospace;master'],
	contacts_group		=> [ 2,	''],
	postit			=> [ 9,	''],
	prices			=> [ 16,''],
	articles		=> [ 1,	''],
	documentation		=> [ 9,	''],
	services		=> [ 18,'id;opendate,enddate'],
	services_stats		=> [ 4,	''],
	services_notes		=> [ 7,	''],
	users			=> [ 71,'login'],
	users_groups		=> [ 3, 'groupid'],
	users_groups_link	=> [ 2, 'groupid;userid'],
	users_privileges	=> [ 4, 'resource_id;who'],
	equipments		=> [ 45,''],
        equipments_maintenance  => [ 2, ''],
	calendar		=> [ 23,'eventid;parent'],
	todo			=> [ 15,''],
	basic_tables		=> [ 3,	''],
	polls			=> [ 46,''],
	opportunities		=> [ 13,''],
        comments                => [ 10, 'referenceproc,referenceid'],
	system_log		=> [ 8,	'targettable;targetid;level'],
	last_elements_log	=> [ 5,	''],
	sessions_cache		=> [ 4,	'formid'],
	signatures		=> [ 3, 'id'],
	reports			=> [ 9, ''],
        chats_msgs		=> [ 3, ''],
        chats_users		=> [ 8, ''],
	binders			=> [ 7, 'id'],
	bindeddocs		=> [ 3, 'binderid'],
	form_defs		=> [ 10, ''],
	form_records		=> [ 2, ''], 
        bookings                => [ 5, 'bookingid;eventid;equipmentid'],
	);

#XXX2DEVELOPE constraint=>'not null' in all table columns

%db_tables = (

signatures=>[
	{ name=>'id',
	  type=>'varchar(15)',},

	{ name=>'issue',
	  type=>'date',},

	{ name=>'md5key',
	  type=>'varchar(32)',},

	{ name=>'owner',
	  type=>'varchar(32)',},
	     ],
chats_msgs=>[
	{ name=>'issuetime',
	  type=>'int',},

	{ name=>'nick',
	  type=>'varchar(20)',},

	{ name=>'message',
	  type=>'text',},

	{ name=>'room',
	  type=>'varchar(100)',},
	     ],
chats_users=>[
	{ name=>'username',
	  type=>'varchar(32)',},

	{ name=>'userhost',
	  type=>'varchar(200)',},

	{ name=>'sessionstart',
	  type=>'int',},

	{ name=>'lastmsg',
	  type=>'int',},

	{ name=>'room',
	  type=>'varchar(100)',},

	{ name=>'nick',
	  type=>'varchar(20)',},

	{ name=>'sessionid',
	  type=>'varchar(20)',},

	{ name=>'status',
	  type=>'int',},

	{ name=>'topic',
	  type=>'varchar(200)',},
	     ],
form_defs=>[
	{ name=>'igformid',
	  type=>'varchar(20)',},

	{ name=>'fieldid',
	  type=>'varchar(20)',},

	{ name=>'fieldtype',
	  type=>'varchar(30)',},

	{ name=>'fieldlabel',
	  type=>'varchar(100)',},

	{ name=>'description',
	  type=>'text',},

	{ name=>'position',
	  type=>'int',},

	{ name=>'defaultvalues',
	  type=>'text',},

	{ name=>'status',
	  type=>'int',},

	{ name=>'fieldstyle',
	  type=>'text',},

	{ name=>'labelstyle',
	  type=>'text',},

	{ name=>'fieldfloat',
	  type=>'varchar(10)',},
	     ],
form_records=>[
	{ name=>'recordid',
	  type=>'varchar(50)',},

	{ name=>'fieldid',
	  type=>'varchar(20)',},

	{ name=>'value',
	  type=>'text',},
	     ],
binders=>[
	{ name=>'id',
	  type=>'varchar(15)',},

	{ name=>'owner',
	  label=>'owner',
	  itype=>'logins',
	  type=>'varchar(32)',},

	{ name=>'issue',
	  label=>'issue',
	  itype=>'date',
	  type=>'date',},

	{ name=>'name',
	  label=>'binder_name',
	  itype=>'text',
	  type=>'varchar(200)',},

	{ name=>'note',
	  label=>'note',
	  itype=>'text',
	  type=>'text',},

	{ name=>'category',
	  label=>'category',
	  itype=>'text',
	  type=>'varchar(200)',},

	{ name=>'contactname',
	  label=>'contact_name',
	  itype=>'text',
	  type=>'varchar(70)',},

	{ name=>'contactid',
	  type=>'varchar(15)',},
	     ],
bindeddocs=>[
	{ name=>'id',
	  type=>'varchar(15)',},

	{ name=>'binderid',
	  type=>'varchar(15)',},

	{ name=>'docid',
	  type=>'varchar(15)',},

	{ name=>'docissue',
	  type=>'date',},
	     ],
sessions_cache=>[
	{ name=>'sessionid',
	  type=>'varchar(65)',},

	{ name=>'formid',
	  type=>'varchar(15)',},

	{ name=>'keyname',
	  type=>'varchar(30)',},

	{ name=>'keyvalue',
	  type=>'text',},

	{ name=>'keydate',
	  type=>'date',},
	     ],
system_log=>[
	{ name=>'id',
	  type=>'varchar(15)',},

	{ name=>'level',
	  type=>'varchar(20)',},

	{ name=>'targettable',
	  type=>'varchar(20)',},

	{ name=>'targetid',
	  type=>'varchar(32)',},

	{ name=>'date',
	  type=>'date',},

	{ name=>'time',
	  type=>'varchar(8)',},

	{ name=>'authuser',
	  type=>'varchar(32)',},

	{ name=>'remotehost',
	  type=>'varchar(100)',},

	{ name=>'text',
	  type=>'text',},
	     ],
last_elements_log=>[
	{ name=>'id',
	  type=>'varchar(15)',},

	{ name=>'description',
	  type=>'text',},

	{ name=>'type',
	  type=>'varchar(20)',},

	{ name=>'owner',
	  type=>'varchar(32)',},

	{ name=>'issuedate',
	  type=>'date',},

	{ name=>'issuetime',
	  type=>'varchar(8)',},
	     ],
comments=>[
	{ name=>'id',
	  type=>'varchar(15)',},

	{ name=>'referenceid',
	  type=>'varchar(100)',},

	{ name=>'referenceproc',
	  type=>'varchar(15)',},

	{ name=>'date',
	  type=>'date',},

	{ name=>'time',
	  type=>'varchar(8)',},

	{ name=>'authorname',
	  type=>'varchar(70)',},

	{ name=>'authoremail',
	  type=>'varchar(100)',},

	{ name=>'authorurl',
	  type=>'varchar(100)',},

	{ name=>'comment',
	  type=>'text',},

	{ name=>'commentowner',
	  type=>'varchar(32)',},

        { name=>'notifyowner',
          type=>'varchar(1)',},
	     ],

opportunities=>[
	{ name=>'id',
	  type=>'varchar(15)',},

	{ name=>'name',
	  label=>'name',
	  itype=>'text',
	  type=>'text',},

	{ name=>'contactid',
	  type=>'varchar(15)',},

	{ name=>'type',
	  label=>'type',
	  itype=>'text',
	  type=>'varchar(5)',},

	{ name=>'source',
	  label=>'opportunity_source',
	  itype=>'basictable',
	  table=>'opportunities_source',
	  type=>'varchar(5)',},

	{ name=>'description',
	  label=>'description',
	  itype=>'text',
	  type=>'text',},

	{ name=>'amount',
	  label=>'amount',
	  itype=>'text',
	  type=>'int',},

	{ name=>'issue',
	  label=>'issue',
	  itype=>'date',
	  type=>'date',},

	{ name=>'enddate',
	  label=>'due_date',
	  itype=>'date',
	  type=>'date',},

	{ name=>'stage',
	  label=>'sales_stage',
	  itype=>'basictable',
	  table=>'opportunities_sales_stage',
	  type=>'varchar(5)',},

	{ name=>'probability',
	  label=>'probability',
	  itype=>'text',
	  type=>'varchar(5)',},

	{ name=>'owner',
	  label=>'owner',
	  itype=>'logins',
	  type=>'varchar(32)',},

	{ name=>'contactname',
	  label=>'contact_name',
	  itype=>'text',
	  type=>'varchar(70)',},

	{ name=>'status',
	  type=>'varchar(2)',},
	     ],

archive=>[
	{ name=>'id',
	  type=>'varchar(15)',},	#numero

	{ name=>'docref',
	  label=>'document_reference',
	  itype=>'text',
	  type=>'varchar(250)',},	#numrif

	{ name=>'issue',
	  label=>'issue',
	  itype=>'date',
	  type=>'date',},	#data

	{ name=>'contactname',
	  label=>'contact_name',
	  itype=>'text',
	  type=>'varchar(70)',},	#contact

	{ name=>'expire',
	  label=>'due_date',
	  itype=>'date',
	  type=>'date',},	     	#scadenza

	{ name=>'note',
	  label=>'note',
	  itype=>'text',
	  type=>'text',},		#note

	{ name=>'owner',
	  label=>'owner',
	  itype=>'logins',
	  type=>'varchar(32)',},#owner

	{ name=>'type',
	  label=>'document_type',
	  itype=>'documenttype',
	  type=>'varchar(5)',},		#tipo

	{ name=>'days',
	  type=>'int',},		#giorni

	{ name=>'contactid',
	  type=>'varchar(15)',},	#unidest

	{ name=>'docdate',
	  label=>'document_date',
	  itype=>'date',
	  type=>'date',},

	{ name=>'npa',
	  label=>'archive_position',
	  itype=>'text',
	  type=>'varchar(50)',},
	],

letters=>[
	{ name=>'id',
	  type=>'varchar(15)',},	#numero

	{ name=>'issue',
	  label=>'issue',
	  itype=>'date',
	  type=>'date',},		#data

	{ name=>'contactname',
	  label=>'contact_name',
	  itype=>'text',
	  type=>'varchar(70)',},	#contact

	{ name=>'owner',
	  label=>'owner',
	  itype=>'logins',
	  type=>'varchar(32)',},		#owner

	{ name=>'note',
	  label=>'note',
	  itype=>'text',
	  type=>'text',},		#note

	{ name=>'sharemode',
	  type=>'int',},		#sharemode

	{ name=>'free',
	  type=>'varchar(15)',},	#utente

	{ name=>'contactid',
	  type=>'varchar(15)',},	#unidest

	{ name=>'npa',
	  label=>'archive_position',
	  itype=>'text',
	  type=>'varchar(50)',},

	{ name=>'docref',
	  label=>'docref',
	  itype=>'text',
	  type=>'varchar(30)',},
	],

offers=>[
	{ name=>'id',
	  type=>'varchar(15)',},	#numero

	{ name=>'issue',
	  label=>'issue',
	  itype=>'date',
	  type=>'date',},		#data

	{ name=>'contactname',
	  label=>'contact_name',
	  itype=>'text',
	  type=>'varchar(70)',},	#contact

	{ name=>'note',
	  label=>'result',
	  itype=>'text',
	  type=>'text',},		#note

	{ name=>'owner',
	  label=>'owner',
	  itype=>'logins',
	  type=>'varchar(32)',},		#owner

	{ name=>'expire',
	  label=>'due_date',
	  itype=>'date',
	  type=>'date',},		#scadenza

	{ name=>'category',
	  itype=>'text',
	  label=>'category',
	  type=>'varchar(2)',},		#categoria

	{ name=>'days',
	  type=>'int',},	        #giorni

	{ name=>'flag',
	  type=>'varchar(2)',},		#flag

	{ name=>'pricesupdate',
	  type=>'date',},		#revisionep

	{ name=>'note1',
	  label=>'note',
	  itype=>'text',
	  type=>'text',},		#note1

	{ name=>'flag1',
	  type=>'varchar(1)',},		#flag1

	{ name=>'flag2',
	  type=>'varchar(1)',},		#flag2

	{ name=>'flag3',
	  type=>'varchar(1)',},		#flag3

	{ name=>'contactid',
	  type=>'varchar(15)',},	#unidest

	{ name=>'npa',
	  label=>'archive_position',
	  itype=>'text',
	  type=>'varchar(50)',},

	{ name=>'amount',
	  label=>'amount',
	  itype=>'text',
	  type=>'int',},
	],

orders=>[
	{ name=>'id',
	  type=>'varchar(15)',},	#numero

	{ name=>'issue',
	  label=>'issue',
	  itype=>'date',
	  type=>'date',},		#data

	{ name=>'docref',
	  label=>'document_reference',
	  itype=>'text',
	  type=>'varchar(30)',},	#ordine

	{ name=>'contactname',
	  label=>'contact_name',
	  itype=>'text',
	  type=>'varchar(70)',},	#contact

	{ name=>'note',
	  label=>'note',
	  itype=>'text',
	  type=>'text',},		#note

	{ name=>'owner',
	  label=>'owner',
	  itype=>'text',
	  type=>'varchar(32)',},		#owner

	{ name=>'expire',
	  label=>'due_date',
	  itype=>'date',
	  type=>'date',},		#scadenza

	{ name=>'flag',	
	  type=>'varchar(2)',},		#flag

	{ name=>'duedate',
	  label=>'delivery',
	  itype=>'date',
	  type=>'date',},		#consegna

	{ name=>'contactid',
	  type=>'varchar(15)',},	#unidest

	{ name=>'npa',
	  label=>'archive_position',
	  itype=>'text',
	  type=>'varchar(50)',},
	],

fax_sent=> [
	{ name=>'id',
	  type=>'varchar(15)',},	# numero

	{ name=>'issue',
	  label=>'issue',
	  itype=>'date',
	  type=>'date',},        	# data

	{ name=>'contactname',
	  label=>'contact_name',
	  itype=>'text',
	  type=>'varchar(70)',}, 	# contact

	{ name=>'owner',
	  label=>'owner',
	  itype=>'logins',
	  type=>'varchar(32)',},		# owner

	{ name=>'note',
	  label=>'note',
	  itype=>'text',
	  type=>'text',},        	# note

	{ name=>'faxnumber',
	  label=>'fax_number',
	  itype=>'text',
	  type=>'varchar(20)',}, 	# tel

	{ name=>'contactid',
	  type=>'varchar(15)',}, 	# unidest

	{ name=>'category',
	  label=>'document_type',
	  itype=>'documenttype',
	  type=>'varchar(5)',},  	# doctype

	{ name=>'timeissue',
	  label=>'invoice_time',
	  type=>'text',
	  type=>'varchar(8)',},  	#

	{ name=>'npa',
	  label=>'archive_position',
	  itype=>'text',
	  type=>'varchar(50)',},

	{ name=>'docref',
	  label=>'docref',
	  itype=>'text',
	  type=>'varchar(30)',},
	],

fax_received=>[
	{ name=>'id',
	  type=>'varchar(15)',},	# numero

	{ name=>'issue',
	  label=>'issue',
	  itype=>'date',
	  type=>'date',},		# data

	{ name=>'timeissue',
	  label=>'arrive_time',
	  ityme=>'text',
	  type=>'varchar(8)',},		# ora

	{ name=>'category',
	  label=>'document_type',
	  itype=>'documenttype',
	  type=>'varchar(5)',},		# tipo

	{ name=>'faxnumber',
	  label=>'fax_number',
	  itype=>'text',
	  type=>'varchar(20)',},	# telefono

	{ name=>'note',
	  label=>'note',
	  itype=>'text',
	  type=>'text',},		# note

	{ name=>'contactname',
	  label=>'contact_name',
	  itype=>'text',
	  type=>'varchar(70)',},	# contact

	{ name=>'owner',
	  label=>'owner',
	  itype=>'logins',
	  type=>'varchar(32)',},		# owner

	{ name=>'contactid',
	  type=>'varchar(15)',},	# unidest

	{ name=>'npa',
	  label=>'archive_position',
	  itype=>'text',
	  type=>'varchar(50)',},

	{ name=>'docref',
	  label=>'docref',
	  itype=>'text',
	  type=>'varchar(30)',},
	],

nc_ext=> [
	{ name=>'id',
	  type=>'varchar(15)',},	#numero

	{ name=>'issue',
	  label=>'issue',
	  itype=>'date',
	  type=>'date',},		#data

	{ name=>'contactname',
	  label=>'contact_name',
	  itype=>'text',
	  type=>'varchar(70)',},	#contact

	{ name=>'owner',
	  label=>'owner',
	  itype=>'logins',
	  type=>'varchar(32)',},		#owner

	{ name=>'note',
	  label=>'note',
	  itype=>'text',
	  type=>'text',},		#note

	{ name=>'priority',
	  label=>'priority',
	  itype=>'text',
	  type=>'varchar(3)',},		#priorita

	{ name=>'contactid',
	  type=>'varchar(15)',},	#unidest

	{ name=>'duedate',
	  label=>'due_date',
	  itype=>'date',
	  type=>'date',},		#chiusura

	{ name=>'npa',
	  label=>'archive_position',
	  itype=>'text',
	  type=>'varchar(50)',},

	{ name=>'docref',
	  label=>'docref',
	  itype=>'text',
	  type=>'varchar(30)',},
	],
nc_int=> [
	{ name=>'id',
	  type=>'varchar(15)',},	#numero

	{ name=>'issue',
	  label=>'issue',
	  itype=>'date',
	  type=>'date',},		#data

	{ name=>'contactname',
	  label=>'contact_name',
	  itype=>'text',
	  type=>'varchar(70)',},	#contact

	{ name=>'owner',
	  label=>'owner',
	  itype=>'logins',
	  type=>'varchar(32)',},		#owner

	{ name=>'note',
	  label=>'note',
	  itype=>'text',
	  type=>'text',},		#note

	{ name=>'priority',
	  type=>'varchar(3)',},		#priorita

	{ name=>'contactid',
	  type=>'varchar(15)',},	#unidest

	{ name=>'duedate',
	  label=>'due_date',
	  itype=>'date',
	  type=>'date',},		#chiusura

	{ name=>'npa',
	  label=>'archive_position',
	  itype=>'text',
	  type=>'varchar(50)',},

	{ name=>'docref',
	  label=>'docref',
	  itype=>'text',
	  type=>'varchar(30)',},
	],

pages=>[
	{ name=>'id',
	  type=>'varchar(15)',},

	{ name=>'name',
	  type=>'varchar(50)',},

	{ name=>'title',
	  type=>'varchar(200)',},

	{ name=>'category',
	  type=>'varchar(50)',},

	{ name=>'owner',
	  type=>'varchar(32)',},

	{ name=>'date',
	  type=>'date',},

	{ name=>'expire',
	  type=>'date',},

	{ name=>'lastedit',
	  type=>'date',},

	{ name=>'lasteditor',
	  type=>'varchar(32)',},

	{ name=>'showperm',
	  type=>'varchar(1)',},

	{ name=>'editperm',
	  type=>'varchar(1)',},

	{ name=>'status',
	  type=>'varchar(1)',},

	{ name=>'revision',
	  type=>'int',},

	{ name=>'text',
	  type=>'text',},

	{ name=>'approvedby',
	  type=>'varchar(32)',},

	{ name=>'template',
	  type=>'varchar(50)',},

	{ name=>'cryptstatus',
	  type=>'varchar(1)',},

	{ name=>'searchkeys',
	  type=>'text',},
	],

contracts=>[
	{ name=>'id',
	  type=>'varchar(15)',},

	{ name=>'issue',
	  label=>'issue',
	  itype=>'date',
	  type=>'date',},

	{ name=>'contactname',
	  label=>'contact_name',
	  itype=>'text',
	  type=>'varchar(70)',},	# contact

	{ name=>'owner',
	  label=>'owner',
	  itype=>'logins',
	  type=>'varchar(32)',},

	{ name=>'note',
	  label=>'note',
	  itype=>'text',
	  type=>'text',},

	{ name=>'expire',
	  label=>'due_date',
	  itype=>'date',
	  type=>'date',},		# duedate

	{ name=>'startdate',
	  label=>'start_from',
	  itype=>'date',
	  type=>'date',},

	{ name=>'phase',
	  type=>'varchar(15)',},

	{ name=>'type',
	  label=>'contract_type',
	  itype=>'basictable',
	  table=>'contracts_type',
	  type=>'int',},

	{ name=>'docref',
	  label=>'document_reference',
	  itype=>'text',
	  type=>'varchar(30)',},	# refnum

	{ name=>'duration',
	  type=>'int',},

	{ name=>'flag1',
	  type=>'varchar(1)',},

	{ name=>'flag2',
	  type=>'varchar(1)',},

	{ name=>'flag3',
	  type=>'varchar(1)',},

	{ name=>'contactid',
	  type=>'varchar(15)',},

	{ name=>'dayalert',             # NOT USED!
	  type=>'int',},

	{ name=>'npa',
	  label=>'archive_position',
	  itype=>'text',
	  type=>'varchar(50)',},

	{ name=>'amount',
	  label=>'amount',
	  itype=>'text',
	  type=>'int',},
	],

contracts_phases=>[
	{ name=>'id',
	  type=>'varchar(15)',},

	{ name=>'contracttype',
	  type=>'int',},

	{ name=>'name',
	  type=>'varchar(100)',},

	{ name=>'owner',
	  type=>'varchar(32)',},

	{ name=>'note',
	  type=>'text',},

	{ name=>'priority',
	  type=>'int',},

	{ name=>'bgcolor',
	  type=>'varchar(10)',},

	{ name=>'days',
	  type=>'int',},

	{ name=>'whenapply',
	  type=>'varchar(1)',},

	{ name=>'contractfield',
	  type=>'varchar(15)',},

	{ name=>'action1',
	  type=>'varchar(2)',},

	{ name=>'action1val',
	  type=>'varchar(15)',},

	{ name=>'action2',
	  type=>'varchar(2)',},

	{ name=>'contractstatus',
	  type=>'int',},

	{ name=>'owner1',
	  type=>'varchar(32)',},
	],
contacts_group=>[
	{ name=>'type',
	  type=>'varchar(15)',}, 	#tipo

	{ name=>'groupid',
	  type=>'varchar(15)',},	#cntgruppo

	{ name=>'contactid',
	  type=>'varchar(15)',},	#cntnumero
	],
reports=>[
	{ name=>'id',
	  type=>'varchar(15)',},

	{ name=>'owner',
	  type=>'varchar(32)',},

	{ name=>'name',
	  type=>'varchar(100)',},

	{ name=>'dbquery',
	  type=>'text',},

	{ name=>'dbcols',
	  type=>'text',},

	{ name=>'cgiquery',
	  type=>'text',},

	{ name=>'type',
	  type=>'varchar(30)',},

	{ name=>'orderby',
	  type=>'varchar(30)',},

	{ name=>'orderdirection',
	  type=>'varchar(4)',},

	{ name=>'lastchange',
	  type=>'date',},
	],
contacts=>[
	{ name=>'contactname',
	  type=>'varchar(70)',
	  label=>'contact_name'},	#nominativo

	{ name=>'address1',
	  label=>'operations_headquarters_address',
	  type=>'varchar(60)',},	#indirizzo

	{ name=>'city1',
	  label=>'operations_headquarters_city',
	  type=>'varchar(40)',},	#citta

	{ name=>'zip1',
	  label=>'operations_headquarters_zip_code',
	  type=>'varchar(15)',},	#cap

	{ name=>'prov1',
	  label=>'operations_headquarters_province',
	  type=>'varchar(10)',},	#prov

	{ name=>'piva',
	  label=>'vat_number',
	  type=>'varchar(20)',},	#piva

	{ name=>'taxidnumber',
          label=>'vat_code',
	  type=>'varchar(20)',},	#cfisc

	{ name=>'cciaa',
	  type=>'varchar(20)',},	#cciaa

	{ name=>'jobtitle',
	  type=>'varchar(60)',},	#contatto1

	{ name=>'confidence',
	  type=>'varchar(60)',},	#contatto2

	{ name=>'tel4',
	  type=>'varchar(20)',},	#telcon1

	{ name=>'tel5',
	  type=>'varchar(20)',},	#telcon2

	{ name=>'tel1',
	  label=>'telephone_exchange',
	  type=>'varchar(20)',},	#tel1

	{ name=>'tel2',
	  type=>'varchar(20)',},	#tel2

	{ name=>'tel3',
	  type=>'varchar(20)',},	#tel3

	{ name=>'fax',
	  label=>'fax_number',
	  type=>'varchar(20)',},	#fax

	{ name=>'qualification',
	  type=>'varchar(20)',},	#affidabile

	{ name=>'category',
	  type=>'varchar(20)',},	#categoria

	{ name=>'data1',
	  type=>'date',},		#data1

	{ name=>'data2',
	  type=>'date',},		#data2

	{ name=>'note',
	  label=>'notes',
	  type=>'text',},		#note

	{ name=>'contactid',
	  type=>'varchar(15)',},	#univoco

	{ name=>'pricelistflag',
	  type=>'varchar(2)',},		#prezzi

	{ name=>'pricelistupdate',
	  type=>'date',},		#revisionep

	{ name=>'free1',
	  type=>'varchar(5)',},		# Recuperato instant_msgs_type

	{ name=>'free2',
	  type=>'varchar(5)',},		#acquisto

	{ name=>'lastupdate',
	  label=>'last_change',
	  type=>'date',},		#agg

	{ name=>'activity',
	  type=>'text',},		#prodotti

	{ name=>'vendorslistflag',
	  type=>'varchar(2)',},		#qualita

	{ name=>'owner',
	  label=>'owner',
	  type=>'varchar(32)',},		#owner

	{ name=>'email',
	  label=>'email',
	  type=>'varchar(100)',},	#email

	{ name=>'url',
	  label=>'url',
	  type=>'varchar(100)',},	#url

	{ name=>'address2',
	  label=>'operating_center_address',
	  type=>'varchar(50)',},	#indirizzo2

	{ name=>'city2',
	  label=>'operating_center_city',
	  type=>'varchar(35)',},	#citta2

	{ name=>'zip2',
	  label=>'operating_center_zip_code',
	  type=>'varchar(15)',},	#cap2

	{ name=>'prov2',
	  label=>'operating_center_province',
	  type=>'varchar(10)',},	#prov2

	{ name=>'address3',
	  label=>'legal_situs_address',
	  type=>'varchar(50)',},	#indirizzo3

	{ name=>'city3',
	  label=>'legal_situs_city',
	  type=>'varchar(35)',},	#citta3

	{ name=>'zip3',
	  label=>'legal_situs_zip_code',
	  type=>'varchar(15)',},	#cap3

	{ name=>'prov3',
	  label=>'legal_situs_province',
	  type=>'varchar(10)',},	#prov3

	{ name=>'note1',
	  type=>'text',},		#note1

	{ name=>'qualifmethod',
 	  type=>'varchar(2)',},		#metodo

	{ name=>'contactvalue',
	  itype=>'basictable',
	  table=>'contactvalue',
	  label=>'class',
	  type=>'int',},		#qualifica

	{ name=>'passwd',
	  type=>'varchar(72)',},	#passwd

	{ name=>'nospace',
 	  type=>'varchar(70)',},	#nospace

	{ name=>'free3',
	  type=>'varchar(60)',},	#contatto3 Recuperato personal_doc

	{ name=>'free4',
	  type=>'varchar(20)',},	#telcon3 Recuperato instant_msgs_value

	{ name=>'master',
	  type=>'varchar(15)',},	#master

	{ name=>'lastfaxowner',
	  type=>'varchar(32)',},		#lastfaxowner

	{ name=>'rea',
	  type=>'varchar(20)',},	#rea

	{ name=>'istat',
	  type=>'varchar(20)',},	#istat

	{ name=>'economicsector',
	  itype=>'basictable',
	  table=>'economicsector',
	  label=>'economic_sector',
	  type=>'varchar(100)',},	#attivita

	{ name=>'employees',
	  label=>'employees',
	  type=>'int',},		#addetti

	{ name=>'billing',
	  itype=>'basictable',
	  table=>'billing',
	  label=>'billing',
	  type=>'int',},		#fatturato

	{ name=>'employername',
	  type=>'varchar(60)',}, 	#rappresentante

	{ name=>'sharemode',
	  type=>'int',},		#sharemode

	{ name=>'contactsource',
	  itype=>'basictable',
	  table=>'contactsource',
	  label=>'contact_origin',
	  type=>'int',},		#origine

	{ name=>'birthdate',
	  type=>'date',},		#nascita

	{ name=>'outfromlist',
	  type=>'int',},		#outfromlist

	{ name=>'contacttype',
	  label=>'contact_type',
	  type=>'int',},		#tipo

	{ name=>'economiczone',
          itype=>'basictable',
	  table=>'economiczone',
	  label=>'zone',
	  type=>'int',},		#zona

	{ name=>'country1',
	  label=>'operations_headquarters_country',
	  type=>'varchar(2)',},		#country

	{ name=>'country2',
	  label=>'operating_center_country',
	  type=>'varchar(2)',},		#country2

	{ name=>'country3',
	  label=>'legal_situs_country',
	  type=>'varchar(2)',},		#country3

	{ name=>'operativefunction',
	  type=>'int',},
	],
isms=>[
	{ name=>'id',
	  type=>'varchar(15)',}, 	#univoco

	{ name=>'date',
	  type=>'date',},        	#data

	{ name=>'sender',
	  type=>'varchar(32)',},		#mittente

	{ name=>'receiver',
	  type=>'varchar(32)',},  	#destinatario

	{ name=>'body',
	  type=>'text',},		#testo

	{ name=>'status',
	  type=>'varchar(2)',},		#esito

	{ name=>'time',
	  type=>'varchar(5)',},		#ora

	{ name=>'type',
	  type=>'varchar(2)',},		#tipo
	],
email_msgs=>[
	{ name=>'id',
	  type=>'varchar(200)',}, 	#univoco # era 32char

 	{ name=>'issue',
	  type=>'date',},        	#data

	{ name=>'timeissue',
	  type=>'varchar(20)',}, 	#time

	{ name=>'sender',
	  type=>'varchar(250)',},	#sender

	{ name=>'contactid',
	  type=>'varchar(15)',}, 	#unidest

	{ name=>'receiver',
	  type=>'text',},        	#receiver

	{ name=>'owner',
	  type=>'varchar(32)',},  	#owner

	{ name=>'subject',
	  type=>'text',},        	#subject

	{ name=>'folder',
	  type=>'varchar(200)',},	#folder

	{ name=>'content',
	  type=>'varchar(250)',},	#content

	{ name=>'status',
	  type=>'varchar(10)',}, 	#status

	{ name=>'size',
	  type=>'int',},         	#size

	{ name=>'sharemode',
	  type=>'int',},         	#sharemode

	{ name=>'category',
	  type=>'varchar(5)',},  	#category

	{ name=>'body',
	  type=>'text',},        	#body

	{ name=>'pid',
	  type=>'varchar(15)',}, 	#

	{ name=>'originalid',
	  type=>'varchar(250)',},	#

	{ name=>'idsreferences',
	  type=>'text',},        	#

	{ name=>'threadid',
	  type=>'varchar(100)',},	#
	],
email_filter=>[
	{ name=>'id',
	  type=>'varchar(15)',}, #univoco

	{ name=>'owner',
	  type=>'varchar(32)',}, #owner
	  
	{ name=>'name',
	  type=>'varchar(100)',},#name

	{ name=>'query',
	  type=>'text',},        #query

	{ name=>'form',
	  type=>'text',},        #form

	{ name=>'when_apply',
	  type=>'int',},         #when_apply

	{ name=>'action',
	  type=>'text',},        #

	{ name=>'replymsg',
	  type=>'text',},        #
	],

email_imports=>[
	{ name=>'id',		type=>'varchar(32)',},
	{ name=>'owner',	type=>'varchar(32)',},
	{ name=>'host',   	type=>'varchar(200)',},
	{ name=>'port',		type=>'varchar(10)',},
	{ name=>'login',	type=>'varchar(200)',},
	{ name=>'password',	type=>'varchar(72)',},
	{ name=>'authmode',	type=>'varchar(50)',},
	{ name=>'usessl',	type=>'varchar(2)',},
	{ name=>'keepmsgs',	type=>'varchar(2)',},	
	{ name=>'autodownload',	type=>'varchar(1)',
                 queries=> [( "update email_imports set autodownload='n'")] },
	],
email_msgtags=>[
	{ name=>'id',		type=>'varchar(32)',},
	{ name=>'msgid',	type=>'varchar(200)',},
	{ name=>'name',		type=>'varchar(100)',},
	],
postit=>[
	{ name=>'link',		type=>'text',},
	{ name=>'title',	type=>'text',},
	{ name=>'type',		type=>'varchar(50)',},
	{ name=>'owner',	type=>'varchar(32)',},
	{ name=>'id',		type=>'varchar(15)',},
	{ name=>'target',	type=>'varchar(10)',},
	{ name=>'category',	type=>'varchar(100)',},
	{ name=>'sharemode',	type=>'varchar(1)',},
	{ name=>'description',	type=>'text',},
	{ name=>'rating',	type=>'int',},
	],
prices=>[
	{ name=>'id',		type=>'varchar(15)',},
	{ name=>'description',	type=>'text',},
	{ name=>'price',	type=>'varchar(20)',},
	{ name=>'fromdate',	type=>'date',},
	{ name=>'todate',	type=>'date',},
	{ name=>'articleid',	type=>'varchar(15)',},
	{ name=>'rebate',	type=>'varchar(20)',},
	{ name=>'contactid',	type=>'varchar(15)',},
	{ name=>'docid',	type=>'varchar(10)',},
	{ name=>'docnotes', 	type=>'text',},
	{ name=>'measureunit',	type=>'varchar(20)',},
	{ name=>'note',		type=>'text',},
	{ name=>'minquantity',	type=>'varchar(20)',},
	{ name=>'maxquantity',	type=>'varchar(20)',},
	{ name=>'deliverymode',	type=>'varchar(5)',},
	{ name=>'deliverytime',	type=>'varchar(5)',},
	{ name=>'packing',	type=>'varchar(5)',},
	],
articles=>[
	{ name=>'id',		type=>'varchar(15)',},
	{ name=>'shortdescription',type=>'text',},
	],
users=>[
	{ name=>'name',		type=>'varchar(70)',},	# nominativo
	{ name=>'userid',	type=>'varchar(15)',},  # matricola
	{ name=>'hierarchycode',type=>'varchar(10)',},	# codice 
	{ name=>'address',	type=>'varchar(50)',},	# indirizzo
	{ name=>'city',		type=>'varchar(30)',},	# citta
	{ name=>'zip',		type=>'varchar(15)',},	# cap
	{ name=>'prov',		type=>'varchar(10)',},	# prov
	{ name=>'taxid',	type=>'varchar(20)',},	# codfisc
	{ name=>'company',	type=>'varchar(70)',},	# societa
	{ name=>'hierarchyref',	type=>'varchar(10)',},	# referente
	{ name=>'level',	type=>'varchar(5)',},	# livello
	{ name=>'assumption',	type=>'date',},		# dataass
	{ name=>'contracttype',	type=>'varchar(100)',},	# tipocontr
	{ name=>'function',	type=>'varchar(100)',},	# funzione
	{ name=>'jobtitles',	type=>'text',},		# titoli
	{ name=>'jobexperiences',type=>'text',},	# esperienze
	{ name=>'jobphone',	type=>'varchar(25)',},	# interno
	{ name=>'doc1id',	type=>'varchar(20)',},	# cartaid
	{ name=>'doc1expire',	type=>'date',},		# scadcart
	{ name=>'doc2id',	type=>'varchar(20)',},	# patente
	{ name=>'doc2type',	type=>'varchar(20)',},	# tipopat
	{ name=>'doc2expire',	type=>'date',},		# scadpat
	{ name=>'birthday',	type=>'date',},		# nascita
	{ name=>'personalphone',type=>'varchar(25)',},	# telefono
	{ name=>'mobilephone',	type=>'varchar(25)',},	# cellulare
	{ name=>'signature',	type=>'text',},		# note
	{ name=>'status',	type=>'varchar(30)',},	# stato
	{ name=>'statusdate',	type=>'date',},		# finoal
	{ name=>'fuelcardid',	type=>'varchar(10)',},	# carburante
	{ name=>'login',	type=>'varchar(32)',},	# login
	{ name=>'passwd',	type=>'varchar(72)',},	# passwd 
	{ name=>'initial',	type=>'varchar(5)',},	# iniziali
	{ name=>'acronym',	type=>'varchar(10)',},	# sigla
	{ name=>'igprivileges',	type=>'varchar(200)',},	# permessi
	{ name=>'email',	type=>'varchar(100)',},	# email
	{ name=>'doc3id',	type=>'varchar(20)',},	# patente2
	{ name=>'doc3type',	type=>'varchar(10)',},	# tipopat2
	{ name=>'doc3expire',	type=>'date',},		# scadpat2
	{ name=>'pop3login',	type=>'varchar(100)',},	# host
	{ name=>'pop3pwd',	type=>'varchar(72)',},	# tipohost
	{ name=>'healthopinion',type=>'text',},		# giudiziomedico
	{ name=>'lasthealthck',	type=>'date',},		# ultimavisita
	{ name=>'healthckfreq',	type=>'int',},		# intervallovisita
	{ name=>'jobformation',	type=>'text',},		# formazione
	{ name=>'isosyncpwd',	type=>'varchar(72)',},	# isosyncpwd
	{ name=>'lastsync',	type=>'date',},		# lastsync
	{ name=>'lastpwdchange',type=>'date',},# 
	{ name=>'note',		type=>'text',},#
	{ name=>'dismissal',	type=>'date',},#
	{ name=>'emailfrom',    type=>'text',},#
	{ name=>'hostsallow',   type=>'text',},#
	{ name=>'luogo_nascita',                    type=>'varchar(255)',},  
	{ name=>'sede_aziendale',                   type=>'varchar(1)',}, 
	{ name=>'operativita',                      type=>'varchar(1)',},
	{ name=>'reparto',                          type=>'varchar(255)',},
	{ name=>'mansione',                         type=>'varchar(255)',},
	{ name=>'scadenza_qualifica',               type=>'date',},
	{ name=>'titolo_studio',                    type=>'varchar(255)',},
	{ name=>'interno_telefonico',               type=>'varchar(255)',},
	{ name=>'email_aziendale',                  type=>'varchar(255)',},
	{ name=>'tipo_contratto',                   type=>'varchar(1)',},
	{ name=>'posizione_inps',                   type=>'varchar(255)',},
	{ name=>'posizione_inail',                  type=>'varchar(255)',},
	{ name=>'frequenza_visita_medica',          type=>'varchar(1)',},
	{ name=>'carta_credito',                    type=>'varchar(255)',},
	{ name=>'ordine_professionale',             type=>'varchar(255)',},
	{ name=>'ordine_professionale_rif',         type=>'varchar(255)',},
	{ name=>'ordine_professionale_iscr',        type=>'varchar(255)',},
	{ name=>'qualifica_prof',                   type=>'varchar(255)',},
	{ name=>'qualifica_prof_rif',               type=>'varchar(255)',},
	{ name=>'qualifica_prof_iscr',              type=>'varchar(255)',},
	{ name=>'qualifica_prof_scad',              type=>'varchar(255)',},
	],
users_groups=>[
	{ name=>'groupid',	type=>'varchar(15)',},
	{ name=>'name',		type=>'varchar(50)',},
	{ name=>'description',	type=>'text',},
	{ name=>'igprivileges',	type=>'varchar(200)',},
	],
users_groups_link=>[
	{ name=>'uid',		type=>'varchar(15)',},
	{ name=>'userid',	type=>'varchar(32)',},
	{ name=>'groupid',	type=>'varchar(15)',},
	],
users_privileges=>[
	{ name=>'resource_id',	type=>'varchar(250)',},
	{ name=>'resource_proc',type=>'varchar(20)',},
	{ name=>'who',		type=>'varchar(32)',},
	{ name=>'owner',	type=>'varchar(32)',},
	{ name=>'privilege_type',type=>'varchar(5)',},
	],
basic_tables=>[
	{ name=>'id',		type=>'int',},         #univoco 
	{ name=>'tablename',	type=>'varchar(50)',}, #tablename
	{ name=>'tablevalue',	type=>'varchar(200)',},#tablevalue
	{ name=>'status',	type=>'int',},         #status
	],
polls=>[
	{ name=>'id',		type=>'varchar(15)',},#univoco
	{ name=>'owner',	type=>'varchar(32)',}, #owner
	{ name=>'issue',	type=>'date',},       #data
	{ name=>'expire',	type=>'date',},       #expire
	{ name=>'question',	type=>'text',},       #question
	{ name=>'voters',	type=>'text',},       #voters
	{ name=>'a1',		type=>'varchar(250)',},
	{ name=>'a2',		type=>'varchar(250)',},
	{ name=>'a3',		type=>'varchar(250)',},
	{ name=>'a4',		type=>'varchar(250)',},
	{ name=>'a5',		type=>'varchar(250)',},
	{ name=>'a6',		type=>'varchar(250)',},
	{ name=>'a7',		type=>'varchar(250)',},
	{ name=>'a8',		type=>'varchar(250)',},
	{ name=>'a9',		type=>'varchar(250)',},
	{ name=>'a10',		type=>'varchar(250)',},
	{ name=>'a11',		type=>'varchar(250)',},
	{ name=>'a12',		type=>'varchar(250)',},
	{ name=>'a13',		type=>'varchar(250)',},
	{ name=>'a14',		type=>'varchar(250)',},
	{ name=>'a15',		type=>'varchar(250)',},
	{ name=>'a16',		type=>'varchar(250)',},
	{ name=>'a17',		type=>'varchar(250)',},
	{ name=>'a18',		type=>'varchar(250)',},
	{ name=>'a19',		type=>'varchar(250)',},
	{ name=>'a20',		type=>'varchar(250)',},
	{ name=>'n1',		type=>'int',},
	{ name=>'n2',		type=>'int',},
	{ name=>'n3',		type=>'int',},
	{ name=>'n4',		type=>'int',},
	{ name=>'n5',		type=>'int',},
	{ name=>'n6',		type=>'int',},
	{ name=>'n7',		type=>'int',},
	{ name=>'n8',		type=>'int',},
	{ name=>'n9',		type=>'int',},
	{ name=>'n10',		type=>'int',},
	{ name=>'n11',		type=>'int',},
	{ name=>'n12',		type=>'int',},
	{ name=>'n13',		type=>'int',},
	{ name=>'n14',		type=>'int',},
	{ name=>'n15',		type=>'int',},
	{ name=>'n16',		type=>'int',},
	{ name=>'n17',		type=>'int',},
	{ name=>'n18',		type=>'int',},
	{ name=>'n19',		type=>'int',},
	{ name=>'n20',		type=>'int',},
	{ name=>'groupid',	type=>'varchar(15)',},
	],
calendar=>[
	{ name=>'fromuser',
	  type=>'varchar(32)',},	# mittente

	{ name=>'touser',
	  type=>'varchar(32)',},	# destinatario

	{ name=>'day',
          type=>'int',},	# g

	{ name=>'month',
	  type=>'int',},	# m

	{ name=>'year',
	  type=>'int',},	# a

	{ name=>'weekday',
	  type=>'int',},	# giorno

	{ name=>'reserved',
	  type=>'int',},	# riserv

	{ name=>'starttime',
	  type=>'int',},	# ora

	{ name=>'endtime',
	  type=>'int',},	# ora1

	{ name=>'eventtext',
	  type=>'text',},	# testo

	{ name=>'startdate',
	  type=>'date',},	# data

	{ name=>'eventid',
	  type=>'varchar(15)',},# univoco

	{ name=>'showbyisms',
	  type=>'int',},	# byposta

	{ name=>'location',
	  type=>'int',},	# luogo

	{ name=>'activepopup',
	  type=>'int',},	# popup

	{ name=>'contactid',
	  type=>'varchar(15)',},# unidest

	{ name=>'category',
	  type=>'int',},

	{ name=>'repeatend',
	  type=>'date',},

        { name=>'notes',
          type=>'text',},

        { name=>'popupstatus',
          type=>'int' },

	{ name=>'eventtype',
	  type=>'int',
          queries=> [( "update calendar set eventtype=location",
		       "update calendar set location=0",
		       "update calendar set location=1 where eventtype=1",
		       "update calendar set eventtype=1 where eventtype=0",
		       "update calendar set eventtype=5 where starttime=2500"
                     )] },

        { name=>'parent',
          type=>'varchar(15)' },# id of parent event (for invitation)

        { name=>'confirmation', 
          type=>'int' },        # invitation: 0=to be confirmed, 1=confirmed, 2=rejected

        { name=>'invitation_note', # nota relativa all'invito
          type=>'text'},
	],

bookings=>[
	{ name=>'bookingid',	type=>'varchar(15)',}, # booking id (unique key)
	{ name=>'eventid',	type=>'varchar(15)',}, # calendar event id
	{ name=>'equipmentid',	type=>'varchar(15)',}, # booked equipment id
	{ name=>'approvedby',	type=>'varchar(32)',}, # user who has approved the booking
	{ name=>'note',	        type=>'text',},        # annotation about the booking
	{ name=>'claimed',      type=>'int',},         # time this booking is claimed from
	],

todo=>[
	{ name=>'login',	type=>'varchar(32)',}, #login
	{ name=>'todoid',	type=>'varchar(15)',},#univoco
	{ name=>'startdate',	type=>'date',},       #emissione
	{ name=>'enddate',	type=>'date',},       #risoluzione
	{ name=>'status',	type=>'int',},        #stato
	{ name=>'todotext',	type=>'text',},       #testo
	{ name=>'priority',	type=>'int',},        #priorita
	{ name=>'owner',	type=>'varchar(32)',}, #owner
	{ name=>'duedate',	type=>'date',},       #scadenza 
	{ name=>'description',	type=>'text',},       #descrizione
	{ name=>'sharemode',	type=>'int',},        #riservatezza
	{ name=>'master',	type=>'varchar(15)',},#master
	{ name=>'progress',	type=>'int',},        #avanzamento
	{ name=>'contactid',	type=>'varchar(15)',},#unidest
	{ name=>'category',	type=>'int',},
	{ name=>'duration',	type=>'varchar(15)',},
	],
services=>[
	{ name=>'opendate',	type=>'date',},	      #datar
	{ name=>'humantime',	type=>'varchar(10)',},#ora
	{ name=>'enddate',	type=>'date',},       #datae
	{ name=>'equipment',	type=>'varchar(15)',},#mezzo
	{ name=>'servicetype',	type=>'varchar(5)',}, #servizio
	{ name=>'materials',	type=>'varchar(5)',}, #materiale
	{ name=>'priority',	type=>'varchar(5)',}, #priorita
	{ name=>'docref',	type=>'varchar(30)',},#numero
	{ name=>'weight',	type=>'int',},        #kg 
	{ name=>'volume',	type=>'int',},        #mc
	{ name=>'contactname',	type=>'varchar(70)',},#contact
	{ name=>'owner',	type=>'varchar(32)',}, #owner
	{ name=>'contactid',	type=>'varchar(15)',},#unidest
	{ name=>'note',		type=>'text',},       #note
	{ name=>'opentime',	type=>'varchar(15)',},#oraric 
	{ name=>'endtime',	type=>'varchar(15)',},#oraeff
	{ name=>'contactvalue',	type=>'int',},        #qualifica
	{ name=>'checks',	type=>'text',},       #controlli
	{ name=>'id',		type=>'varchar(15)',},#univoco
	],
services_stats=>[
	{ name=>'statdate',	type=>'date',},     #data
	{ name=>'totalservices',type=>'int',},      #vgtot
	{ name=>'maxservices',	type=>'int',},      #vgmax
	{ name=>'minservices',	type=>'int',},      #vgmin
	{ name=>'averageservices',type=>'int',},    #vgmedia
	],
services_notes=>[
	{ name=>'contactid',	type=>'varchar(15)',}, #numero
	{ name=>'opendate',	type=>'date',},        #data
	{ name=>'opentime',	type=>'varchar(8)',},  #ora
	{ name=>'category',	type=>'varchar(5)',},  #tipo
	{ name=>'owner',	type=>'varchar(32)',},  #owner
	{ name=>'opentext',	type=>'text',},        #testo
	{ name=>'id',		type=>'varchar(15)',}, #soluzione
	{ name=>'closedate',	type=>'date',},        #risolutore
	],
equipments=>[
	{ name=>'id',
	  type=>'varchar(15)',},         #numero

	{ name=>'description',
	  type=>'text',},                #descrizione
	  
	{ name=>'builtcertificate',
	  type=>'varchar(50)',},         #certificato
	  
	{ name=>'brand',
	  type=>'varchar(50)',},         #marca
	  
	{ name=>'location',
	  type=>'varchar(200)',},        #locazione
	  
	{ name=>'type',
	  type=>'varchar(5)',},          #tipo
	  
	{ name=>'mntncinterval',
	  type=>'varchar(5)',},          #giorni
	  
	{ name=>'date0',
	  type=>'date',},                #data
	  
	{ name=>'date1',
	  type=>'date',},                #data1
	  
	{ name=>'date2',
	  type=>'date',},                #data2
	  
	{ name=>'date3',
	  type=>'date',},                #data3
	  
	{ name=>'mntnchoures',
	  type=>'varchar(3)',},          #ore
	  
	{ name=>'note',
	  type=>'text',},                #note
	  
	{ name=>'date4',
	  type=>'date',},                #data4
	  
	{ name=>'manual',
	  type=>'varchar(15)',},         #manuale
	  
	{ name=>'taxescost',
	  type=>'varchar(15)',},         #prezzobo
	  
	{ name=>'assurancecost',
	  type=>'varchar(15)',},         #prezzoas
	  
	{ name=>'gasolconsumption',
	  type=>'varchar(15)',},         #kmlt
	  
	{ name=>'electrconsumption',
	  type=>'varchar(15)',},         #forzamotrice
	  
	{ name=>'maintenance',
	  type=>'varchar(15)',},         #manutenzione
	  
	{ name=>'staffcost',
	  type=>'varchar(15)',},         #personale
	  
	{ name=>'date5',
	  type=>'date',},                #data5
	  
	{ name=>'date6',
	  type=>'date',},                #data6
	  
	{ name=>'date7',
	  type=>'date',},                #data7
	  
	{ name=>'date8',
	  type=>'date',},                #data8
	  
	{ name=>'services',
	  type=>'int',},
	  
	{ name=>'date9',
	  type=>'date',},
	  
	{ name=>'status',
	  type=>'int',
	  queries=> [( "update equipments set status=0 ",

                       "update equipments set status=1 ".
		       "where mntncinterval='2'",

                       "update equipments set status=2 ".
		       "where mntncinterval='0'"
	             )] },
	  
	{ name=>'contactid',
	  type=>'varchar(15)',},

	{ name=>'mntn_interventions',
	  type=>'text',},                #note

	{ name=>'owner',
	  label=>'owner',
	  itype=>'logins',
	  type=>'varchar(32)',},

	{ name=>'booking_group',
	  type=>'varchar(15)',},         # group whose users can book this equipment

	{ name=>'booking_admin_group',
	  type=>'varchar(15)',},         # group whose users can admin bookings

	{ name=>'booking_approve_group',
	  type=>'varchar(15)',},         # group whose users have to approve bookings

	{ name=>'matriculation',
	  type=>'varchar(255)',},

	{ name=>'property',
	  type=>'varchar(1)',},

	{ name=>'location',
	  type=>'varchar(255)',},

	{ name=>'classeses',
	  type=>'varchar(255)',},

	{ name=>'denomination',
	  type=>'text',},

	{ name=>'taration',
	  type=>'text',},

	{ name=>'taration_field',
	  type=>'text',},

	{ name=>'accreditation',
	  type=>'varchar(1)',},

	{ name=>'buydate',
	  type=>'date',},

	{ name=>'tarationdate',
	  type=>'date',},

	{ name=>'taration_reparts',
	  type=>'varchar(255)',},

	],
equipments_maintenance=>[
	{ name=>'id',
	  type=>'varchar(20)',},

	{ name=>'equipment_id',
	  type=>'varchar(15)',},
	  
	{ name=>'maintenance_date',
	  type=>'date',},
	],
documentation=>[
	{ name=>'id',		type=>'varchar(15)',}, #numero
	{ name=>'description',	type=>'varchar(100)',},#descrizione
	{ name=>'function',	type=>'varchar(32)',},  #ente
	{ name=>'pages',	type=>'int',},         #pagine 
	{ name=>'issueid',	type=>'int',},         #emissione
	{ name=>'revisionid',	type=>'int',},         #revisione
	{ name=>'issue',	type=>'date',},        #data
	{ name=>'publishstatus',type=>'varchar(5)',},  #pubblica
	{ name=>'approvalstatus',type=>'varchar(5)',}, #stato
	{ name=>'quality_system',type=>'varchar(25)',}, #sistema qualità
	]
  );

%db_views = (); #( last_docs => "create view last_docs".
		#	   " (id, description, type, owner) ".
		#	   "as select targetid, text, targettable, authuser ".
		#	   "from system_log ".
		#	   "where level='view' ".
		#	   "order by date desc, time desc ".
		#	   "limit 1000" );

1;
