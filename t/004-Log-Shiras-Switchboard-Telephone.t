#!perl
#######  Initial Test File for Log::Shiras::Switchboard/Telephone #######

use Test::Most;
use Test::Moose;
use Capture::Tiny 0.12 qw(
	capture_stdout
	capture_stderr
);
use YAML::Any;
$| = 1;
use lib
		'../lib', 'lib', '../../Data-Walk-Extracted/lib';# 
use Log::Shiras::Switchboard 0.018;
use Log::Shiras::Telephone 0.018;
sub caller_test{
	Log::Shiras::Telephone->new;
}

my(
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
);

my  		@attributes = qw(
				name_space_bounds
				reports
				logging_levels
				self_report
				buffering
			);

my  		@switchboard_methods = qw(
				get_operator
				get_caller
				get_all_skip_up_callers
				set_all_skip_up_callers
				add_skip_up_caller
				clear_all_skip_up_callers
				get_name_space
				get_reports
				get_report
				remove_reports
				has_log_level
				add_log_levels
				get_log_levels
				remove_log_levels
				set_all_log_levels
				get_all_log_levels
				self_report
				set_self_report
				get_all_buffering
				has_defined_buffering
				set_buffering
				get_buffering
				remove_buffering
				add_name_space_bounds
				add_reports
				remove_name_space_bounds
				send_buffer_to_output
			);

my  		@telephone_methods = qw(
				new
				talk
			);

### Log-Shiras easy questions
ok			$name_space_ref = {
				main =>{
					UNBLOCK =>{
						report1	=> 'ELEVEN',
						run		=> 'warn',
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
								log_file => 'eleven',
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
			$ella_peterson = Log::Shiras::Switchboard->get_operator(
				name_space_bounds => $name_space_ref,
				reports	=> 	$report_ref,
				self_report => 1,
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

### Log-Shiras-Switchboard harder questions
is_deeply	$ella_peterson->get_name_space, $name_space_ref,			
										"Check that the sources were loaded to this instance";
is_deeply	$ella_peterson->get_reports, $report_ref,			
										"Check that the reports were loaded to this instance";
lives_ok{ 	$mary_printz = Log::Shiras::Switchboard->get_operator }
										"Start a concurrent instance of Log::Shiras with no input";
is			$mary_printz->set_self_report( 1 ), 1,
										"Turn on self reporting for the singleton to see what happens";
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
lives_ok{	$ella_peterson->remove_name_space_bounds( {	second_life =>{} }  ) }
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
			$mary_printz = Log::Shiras::Switchboard->get_operator(
				name_space_bounds =>{ 
					test_sub =>{ 
						UNBLOCK =>{
							run => 'debug',
						},
					},
					#~ Log =>{
						#~ UNBLOCK =>{
							#~ log_file => 'warn',
						#~ },
					#~ },
					#~ Log =>{
						#~ Shiras =>{
							#~ Switchboard =>{
								#~ _attempt_to_report =>{
									#~ UNBLOCK =>{
										#~ log_file => 'trace',
									#~ },
								#~ },
							#~ },
							#~ Telephone =>{
								#~ talk =>{
									#~ UNBLOCK =>{
										#~ log_file => 'trace',
									#~ },
								#~ },
							#~ },
						#~ },
					#~ },
				},
				reports	=> 	{
					report1 => [$report_placeholder_1],
					run	=> [ $report_placeholder_2 ],
					log_file => [ Print::Log->new, ],
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
}										"Test removing the same custom levels";
is_deeply	$ella_peterson->get_log_levels( 'report1' ),
			[ 'trace', 'debug', 'info', 'warn', 'error', 'fatal', undef, undef, undef, undef, undef, 'eleven', ],
										"... and test that the levels are back to the default";
ok 			$main_phone = Log::Shiras::Telephone->new(),
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
like		$@, qr/Fatal call sent to the switchboard /,
										"... and check the obituary";
ok 			$main_phone = Log::Shiras::Telephone->new( name_space => 'main::report1' ),
										"Test getting a telephone that falls inside an UNBLOCKed name space";
is 			$main_phone->talk( report => 'report 1', level => 'fatal', ), 0,
										"Test calling fatal when it is OUT of the namespace to ensure it lives";
ok 			$mary_printz->set_buffering( report1 => 1, ),
										"Turn on buffering for 'report1'";
ok 			$main_phone = Log::Shiras::Telephone->new(),
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

package Print::Log;
sub new{
	bless {}, shift;
}
sub add_line{
	shift;
	my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ? @{$_[0]->{message}} : $_[0]->{message};
	#### <where> - input: @input
	my @new_list;
	map{ push @new_list, $_ if $_ } @input;
	chomp @new_list;
	printf( "subroutine - %-28s | line - %04d |\n\t:(\t%-31s ):\n", $_[0]->{subroutine}, $_[0]->{line}, join( "\n\t\t", @new_list ) );
}

1;