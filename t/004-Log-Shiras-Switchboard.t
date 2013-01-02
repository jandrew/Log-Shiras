#!perl
#######  Initial Test File for Log::Shiras::Switchboard  #######
BEGIN{
	#~ $ENV{ Smart_Comments } = '### ####'; #####
}
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;
}

use Test::Most;
use Test::Moose;
use Capture::Tiny 0.12 qw(
	capture_stderr
	capture_stdout
);
use YAML::Any;
$| = 1;
use lib
		'../lib', 'lib', 
		'../../Data-Walk-Extracted/lib',
		'../Data-Walk-Extracted/lib';# 
use Log::Shiras::Switchboard v0.013;

sub caller_test{
	get_telephone;
}

my(
			$wait, 
			$ella_peterson, 
			$mary_printz, 
			$name_space_ref,
			$report_placeholder_1,
			$report_placeholder_2,
			$report_ref, 
			$add_ref_source, 
			$add_ref_report ,
			$error_message,
			$print_message,
			$connection,
			$second_call,
			$printed_data,
			$main_phone,
);# $deputyandy, $firstinst, $testinst, $secondinst, $newclass, $newmeta, $capturefilename

my  		@exported_methods = qw(
				get_operator
				get_telephone
			);


my  		@attributes = qw(
				name_space_bounds
				reports
				logging_levels
				will_cluck
				ignored_callers
				buffering
			);

my  		@switchboard_methods = qw(
				get_name_space
				has_no_name_space
				get_reports
				has_no_reports
				get_report
				remove_reports
				has_log_level
				add_log_levels
				get_log_levels
				remove_log_levels
				set_all_log_levels
				get_all_log_levels
				will_cluck
				set_will_cluck
				ignored_callers
				set_ignored_callers
				add_ignored_callers
				get_all_buffering
				has_no_buffering
				has_buffering
				set_buffering
				get_buffering
				remove_buffering
				add_name_space_bounds
				add_reports
				remove_name_space
				set_stdout_level
				set_warn_level
				clear_stdout_level
				clear_warn_level
				clear_buffer
				send_buffer_to_output
			);

my  		@telephone_methods = qw(
				talk
			);

### Log-Shiras easy questions
map{
can_ok		'main', $_,
}			@exported_methods;
ok			$name_space_ref = {
				main =>{
					UNBLOCK =>{
						report1	=> 'ELEVEN',
						run		=> 'warn',
						STDOUT	=> 'warn',
						WARN	=> 'debug',
					},
					caller_test =>{
						UNBLOCK =>{
							report1	=> 'debug',
							run		=> 'fatal',
						}
					},
				},
				Check =>{
					Print =>{
						add_line =>{
							UNBLOCK =>{
								STDOUT => 'eleven',
							},
						},
					},
				},
			},							"Build initial sources for testing";
ok			$report_placeholder_1 = Check::Print->new, 		
										"Build a report stub";
ok			$report_placeholder_2 = Check::Cluck->new,
										"Build a second report stub";
ok 			$report_ref = {
				report1 =>[],
				run		=>[ $report_placeholder_1 ],
			},							"Build initial reports for testing";
lives_ok{
			$ella_peterson = get_operator(
				name_space_bounds => $name_space_ref,
				reports	=> 	$report_ref,
			);
}										"Get a switchboard operator (using setup)";
### <where> - Ella Peterson: $ella_peterson
map{
has_attribute_ok
			$ella_peterson, $_,			"Check that the new instance has the -$_- attribute",
}			@attributes;
map{									#Check that the new instance can use all methods
can_ok		$ella_peterson, $_,
}			@switchboard_methods;
map{									#Check that all exported methods are available
can_ok		'main', $_,
}			@exported_methods;

### Log-Shiras-Switchboard harder questions
is_deeply	$ella_peterson->get_name_space, $name_space_ref,			
										"Check that the sources were loaded to this instance";
is_deeply	$ella_peterson->get_reports, $report_ref,			
										"Check that the reports were loaded to this instance";
lives_ok{ 	$mary_printz = get_operator }
										"Start a concurrent instance of Log::Shiras with no input";
is			$mary_printz->set_will_cluck( 1 ), 1,
										"Turn on clucking for the singleton to see what happens";
#~ ### <where> - Mary Printz: $mary_printz
is_deeply	$mary_printz->get_name_space, $name_space_ref,			
										"Check that the sources are available to the copy of the instance";
is_deeply	$mary_printz->get_reports, $report_ref,			
										"Check that the reports are available to the copy of the instance";
ok  		$add_ref_source = { 
				second_life =>{
					dancer=>{
						UNBLOCK =>{
							run => 'info',
						},
					}
				}
			},							"Build an add_ref for testing source changes";
ok  		$name_space_ref->{second_life} = {
				dancer=>{
					UNBLOCK =>{
						run => 'info',
					},
				},
			},							"Update the master source variable for testing";
lives_ok{ 	$ella_peterson->add_name_space_bounds( $add_ref_source ) }
										"Add a source to the second instance";
is_deeply 	$mary_printz->get_name_space, $name_space_ref,	
										"Check that the new source is combined with the old source";
ok			$add_ref_report = {
				report1 =>[], 
				run => [ $report_placeholder_1, $report_placeholder_2 ],
			},							"Build an add_ref for testing report changes";
lives_ok{ 	$mary_printz->add_reports( run => [ $report_placeholder_2 ], ) }#$add_ref_report
										"Add a report to the second instance";
is_deeply 	$ella_peterson->get_reports(), $add_ref_report,
										"Check that the new report element is available (along with the old one) in the other instance";
ok  		delete $name_space_ref->{second_life},	
										"Update the master source variable (by removing a section) for testing";
lives_ok{	$ella_peterson->remove_name_space( {	second_life =>{} }  ) }
										"Try to remove the second instance source through the first instance";
is_deeply 	$mary_printz->get_name_space, $name_space_ref,
										"Check that the second instance source was affected";
lives_ok{ 	$ella_peterson->remove_reports( 'run', ) }
										"Try to remove the shared report instance source through the first instance";
ok			delete $report_ref->{run},	"Update (remove an element) the report ref for testing";
is_deeply 	$mary_printz->get_reports, $report_ref,
																	"Check that the second instance sources were not affected in the global variable";
ok			!($mary_printz = undef),	"Clear the Mary Printz handle on the singleton to test re-setup";
lives_ok{
			$mary_printz = get_operator(
				name_space_bounds =>{ 
					test_sub =>{ 
						UNBLOCK =>{
							run => 'debug',
						},
					},
				},
				reports	=> 	{
					report1 => [$report_placeholder_1],
					run	=> [ $report_placeholder_2 ],
				},
			);
}										"Set Mary Printz back up with some data to ensure that it works";
lives_ok{
			$mary_printz->add_log_levels(
				report1 => [ qw( special all  ) ],
			);
}										"Test adding log levels to another report name";
is_deeply	$ella_peterson->get_log_levels( 'report1' ), [ 'special', 'all' ],
										"... and test that the data loaded correctly";
lives_ok{
			$mary_printz->remove_log_levels( 'report1' );
}										"Test removing the same level";
is_deeply	$ella_peterson->get_log_levels( 'report1' ), undef,
										"... and test that the data loaded correctly";
lives_ok{
			$mary_printz->add_reports( STDOUT => [ $report_placeholder_1 ], );
}										"Add an STDOUT report";
ok			$error_message = capture_stderr { $ella_peterson->set_stdout_level( 'debug' ) },
										"Set STDOUT output to the debug level for namespace testing";
like		$error_message, qr/You are currently attempting to Hijack some STDOUT output.  BEWARE,/,
										"... and check that the correct warning was displayed";
is			$ella_peterson->set_will_cluck( 0 ), 0,
										"Turn clucking back off for future processing";
lives_ok{
			$print_message = capture_stdout{ $report_placeholder_1->add_line( { message => "Hello World 1" } ) };
}										"Send a print statement that should be processed as inside the name space and level";
like		$print_message, qr/^--\|Hello World 1\|--$/,		
										"... and check that the output includes the expected reporting add ons";
lives_ok{
			$print_message = capture_stdout{ print "Hello World 2\n" };
}										"Send a print statement that should NOT be processed as inside the name space and level";
like		$print_message,  qr/^Hello World 2$/,		
										"... and check that the output does NOT includes the expected reporting add ons";
			my $expected = ( $ENV{ Smart_Comments } ) ? qr/re-pointing standard output to the new coderef \.\.\./ : qr/^$/ ; 
like		capture_stderr { $mary_printz->set_stdout_level( 'warn' ) }, $expected,
										"Change STDOUT output to report at the 'warn' level (with no warnings)";
lives_ok{
			$print_message = capture_stdout{ print "Hello World 2\n" };
}										"Now send the same print statement that didn't get processed before";
like		$print_message,  qr/^--\|Hello World 2\|--$/,		
										"... and check that the output now includes the expected reporting add-ons since the level is now inside the namespace";
ok			$ella_peterson->clear_stdout_level,
										"Clear the STDOUT level definition so the Switchboard operator will quit testing it";
lives_ok{
			$mary_printz->add_reports( WARN => [ $report_placeholder_2 ], );
}										"Add a WARN report";
lives_ok{
			$ella_peterson->set_warn_level( 'debug' );
}										"Set __WARN__ trap at the 'debug' level for namespace testing.";
lives_ok{
			$error_message = capture_stderr{ warn "Watch Out World!" };
}										"Send a warning that is in the namespace and is at an approved level";
like		$error_message,  qr/\|\|Watch Out World! at (t\\)?004-Log-Shiras-Switchboard.t line \d{3}.\|\| at (t\\)?004-Log-Shiras-Switchboard.t line \d{3}/,		
										"... and check that the output now includes the expected reporting add-ons since the level is inside the namespace";
lives_ok{
			$error_message = capture_stdout{ 
				Check::Cluck->add_line( {message => "Watch Out World!"} );
			};
}										"Send a warning that is OUT of the namespace";
like		$error_message,  qr/\|\|Watch Out World!\|\| at (t\\)?004-Log-Shiras-Switchboard.t line \d{3}.\n.*Check::Cluck::add_line\(\)/,		
										"... and check that the output is different since the 'warn' capture was triggered in a different place";
lives_ok{
			$ella_peterson->add_name_space_bounds( { Check =>{ Cluck =>{ add_line =>{ UNBLOCK =>{ WARN => 'debug', } } } } } );
}										"Change the WARN report level for the Check::Cluck module";
lives_ok{
			$error_message = capture_stderr{ 
				Check::Cluck->add_line( {message => "Watch Out World!"} );
			};
}										"Send a warning that is IN the namespace";
like		$error_message,  qr/\|\|\|\|Watch Out World!\|\| at (t\\)?004-Log-Shiras-Switchboard.t line \d{3}/,		
										"... and check that the test didn't go into deep recursion";
lives_ok{
			$ella_peterson->set_warn_level( 'trace' );
}										"Change __WARN__ trap rerouting to the 'eleven' level (loudest) for namespace testing.";
lives_ok{
			$error_message = capture_stdout{ warn "Watch Out World!" };
}										"Send a warning that is in the namespace but is at too low a level";
like		$error_message,  qr/^\s*Watch Out World! at (t\\)?004-Log-Shiras-Switchboard.t line \d{3}/,		
										"... and check that the warning was sent to stdout as planned";
lives_ok{
			$ella_peterson->clear_warn_level;
}										"Clear warn capture for reporting";
ok 			$main_phone = get_telephone(),
										"Test getting a telephone";
map{									#Check that all exported methods are available
can_ok		$main_phone, $_,
}			@telephone_methods;
			$print_message = capture_stdout{
lives_ok{
			$main_phone->talk( report => 'report1', level => 'eleven', message =>[ 'Hello World' ], );
}										"Test making a call";
			};
is			$print_message, "--|Hello World|--\n",
										"... and check the output";
			$print_message = capture_stdout{
lives_ok{
			$main_phone->talk( report => 'run', level => 'debug', message =>[ 'Hello World' ], );
}										"Test making a call with too low of a level";
			};
is			$print_message, '',			"... and check the output";
			$error_message = capture_stderr{
dies_ok{
			$main_phone->talk( report => 'run', level => 'fatal',  );
}										"Test calling fatal when it is in the namespace to ensure it dies";
			};
like		$@, qr/fatal phone call successfully placed at /,
										"... and check the obituary";
like		$error_message, qr/\|\|Fail with no descriptive message provided\|\| at (t\\)?004-Log-Shiras-Switchboard.t line \d{3}/,
										"... then check the error out";
ok 			$main_phone = get_telephone( 'main::report1' ),
										"Test getting a telephone that falls inside and UNBLOCKed name space";
is 			$main_phone->{works}, 1,	"And check that it is turned on";
is			$main_phone->talk( report => 'report 1', level => 'fatal', dont_report => 1, ), 0,
										"Test calling fatal when it is OUT of the namespace to ensure it lives";
ok 			$main_phone = get_telephone( 'Not::In::Bounds' ),
										"Test getting a telephone that is out of bounds";
is 			$main_phone->{works}, 0,	"And check that it is turned off";
ok			$mary_printz->set_buffering( report1 => 1, ),
										"Turn on buffering for 'report1'";
ok 			$main_phone = get_telephone(),
										"Test getting another telephone";
			$print_message = capture_stdout{
lives_ok{
			$main_phone->talk( report => 'report1', level => 'eleven', message =>[ 'Hello World 11' ], );
}										"Test making a call";
			};
is			$print_message, "",			"... and check that the output was buffered";
is			capture_stdout{ $mary_printz->send_buffer_to_output( 'report1' ) }, 
			"--|Hello World 11|--\n",	"... then check sending the buffer to output";
			$print_message = capture_stdout{
lives_ok{
			$main_phone->talk( report => 'report1', level => 'eleven', message =>[ 'Hello World 10' ], );
}										"Test making another call";
			};
is			$print_message, "",			"... and check that the output was buffered";
ok			$mary_printz->clear_buffer( 'report1' ),
										'Clear the buffer';
is			capture_stdout{ $mary_printz->send_buffer_to_output( 'report1' ) }, '',
										"... then check there is nothing left in the buffer";
is 			$Test::Log::Shiras::last_buffer_position, undef,
										"Check that the Test::Log::Shiras buffer is not active";
ok 			require Test::Log::Shiras, "Load Test::Log::Shiras";
is 			$Test::Log::Shiras::last_buffer_position, 11,
										"Check that the Test::Log::Shiras buffer is NOW active";
explain									"... Test Done";
done_testing;

package Check::Cluck;
use Carp qw( cluck );
use YAML::Any;
sub new{
	bless {}, __PACKAGE__;
}
sub add_line{
	my $class = shift;
	my @messages = @_;
	#~ print Dump( @messages );
	chomp @messages;
	my 	$message = ( @messages  == 1 ) ?
			( ( ref $messages[0] eq 'HASH' ) ?
				( ( ref $messages[0]->{message} eq 'ARRAY' ) ?
					join ' ', @{$messages[0]->{message}} : $messages[0]->{message} ) :
					$messages[0] ) :
			join ' ', @messages ;
	$message //= 'Fail with no descriptive message provided';
	chomp $message;
	cluck "||$message||";
}

package Check::Print;
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;
}
sub new{
	bless {}, __PACKAGE__;
}
sub add_line{
	my ( $self, $ref ) = @_;
	### <where> - passed: $ref
	my @input = ( ref $ref->{message} eq 'ARRAY' ) ? @{$ref->{message}} : ($ref->{message} );
	chomp @input;
	print STDOUT "--|" . join( ' ', @input ) . "|--\n";
}

1;