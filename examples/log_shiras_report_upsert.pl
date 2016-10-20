use lib '../lib';
use Modern::Perl;
use Log::Shiras::Unhide qw( :InternalReporTUpserT :InternalReporT :InternalReportPostgreS :InternalPostgresTablE );#  
use MooseX::ShortCut::BuildInstance;
use Log::Shiras::Report::PostgreSQL;
use Log::Shiras::Report::PostgreSQL::Table;
use Log::Shiras::Report::Upsert;
use Log::Shiras::Report;
use Data::Dumper;
$ENV{hide_warn} = 0;
my $operator; #Unhide 
###InternalReporTUpserT	use Log::Shiras::Switchboard;
###InternalReporTUpserT	use Log::Shiras::Report::Stdout
###InternalReporTUpserT	$operator = Log::Shiras::Switchboard->get_operator( {
###InternalReporTUpserT 		name_space_bounds =>{ UNBLOCK =>{ log_file => 'trace' } },
###InternalReporTUpserT 		reports =>{ log_file =>[ Log::Shiras::Report::Stdout->new ]},
###InternalReporTUpserT 	} );
my 	$pg_connection = build_instance(
		package => 'TableLoader',
		superclasses =>[ 'Log::Shiras::Report::PostgreSQL' ],
		add_roles_in_sequence =>[
				'Log::Shiras::Report::PostgreSQL::Table',
				'Log::Shiras::Report::Upsert', # contains the add_line method
				'Log::Shiras::Report' # additional line and class checking
			],
		error_or_die => 'error',
		table_name => 'test_table',
		merge_rules => 'merge_rules.json',
		merge_modify => { value_2 => "use_old_except[6,9]" },
	);
	
	
	
	
#~ use Log::Shiras::Switchboard;
#~ use Log::Shiras::Telephone;
#~ use Log::Shiras::Report;
#~ use Log::Shiras::Report::PostgreSQL;
#~ use Log::Shiras::Report::Upsert;
#~ use Log::Shiras::Report::Stdout;
#~ $ENV{hide_warn} = 1;
#~ $| = 1;
#~ my	$operator = Log::Shiras::Switchboard->get_operator(
		#~ name_space_bounds =>{
			#~ UNBLOCK =>{
				#~ to_db => 'info',# for info and more urgent messages
#~ ###InternalReporTUpserT	log_file => 'trace',# for info and more urgent messages
			#~ },
		#~ },
		#~ reports =>{
#~ ###InternalReporTUpserT	log_file =>[{
#~ ###InternalReporTUpserT		superclasses =>[ 'Log::Shiras::Report::Stdout' ],
#~ ###InternalReporTUpserT		roles =>[ 'Log::Shiras::Report' ],
#~ ###InternalReporTUpserT	}],
		#~ }
	#~ );
	#~ $operator->add_reports(# Added later to ensure the switchboard is turned on
		#~ to_db =>[{
			#~ package => 'PostgreSQL::TableLoader',
			#~ superclasses =>[ 'Log::Shiras::Report::PostgreSQL' ],
			#~ add_roles_in_sequence =>[
				#~ 'Log::Shiras::Report::PostgreSQL::Table',
				#~ 'Log::Shiras::Report::Upsert', # contains the add_line method
				#~ 'Log::Shiras::Report' # additional line and class checking
			#~ ],
			#~ table_name => 'test_table',
			#~ # connection_file => '../../postgresql_db_settings.jsn',# Not included in the package
			#~ # for my PostgreSQL installation the file looks something like this (all must be one line)
			#~ # ["dbi:Pg:database=MyDataBase;host=localhost;port=5432","power_user","cool_password", .
			#~ # {"RaiseError":1,"AutoCommit":1,"PrintError":1,"LongReadLen":65000,"LongTruncOk":0}]
			#~ merge_rules => 'merge_rules.json',
			#~ merge_modify => { value_2 => "use_old_except[6,9]" },
		#~ }],
	#~ );
#~ my	$telephone = Log::Shiras::Telephone->new( report => 'to_db' );
	#~ $telephone->talk( level => 'info', message => 'A new line' );
	#~ $telephone->talk( level => 'trace', message => 'A second line' );
	#~ $telephone->talk( level => 'warn', message =>[ {
		#~ header_0 => 'A third line',
		#~ new_header => 'new header starts here' } ] );