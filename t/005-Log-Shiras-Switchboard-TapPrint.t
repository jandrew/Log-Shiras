#!perl
#######  Initial Test File for Log::Shiras::TapPrint  #######
#~ use Smart::Comments '###';
use Test::Most;
use Test::Moose;
use Capture::Tiny 0.12 qw(
	capture_stdout
);
use YAML::Any;
$| = 1;
use lib
		'../lib', 'lib', '../../Data-Walk-Extracted/lib';# 
use Log::Shiras::Switchboard 0.018;
use Log::Shiras::TapPrint 0.018;

my(
			$ella_peterson, 
			$name_space_ref,
			$report_placeholder,
			$report_ref, 
			$print_message,
);

my  		@tap_print_methods = qw(
				re_route_print
				restore_print
			);
### TapPrint easy questions ...
map{									#Check that all exported methods are available
can_ok		'Log::Shiras::TapPrint', $_,
}			@tap_print_methods;

### confirm print works as expected prior to changes ...
lives_ok{
			$print_message = capture_stdout{
				print "Hello World 0\n";
			};							
}										"Send a print statement that should be processed normally with no re-routing";
like		$print_message, qr/^Hello World 0$/,		
										"... and check that the output is not massaged or appended";

### Turn on the switchboard ...
ok			$name_space_ref = {
				main =>{
					UNBLOCK =>{# UNBLOCKing self reporting error messages
						run => 'info',
					},
					yellow_submarine =>{
						UNBLOCK =>{# UNBLOCKing self reporting error messages
							run => 'warn',
						},
					}
				},
				Log =>{
					Shiras =>{
						TapPrint =>{
							UNBLOCK =>{# UNBLOCKing self reporting error messages
								log_file => 'info',
							},
						},
					},
				},
			},							"Build initial name-space for testing";
ok			$report_placeholder = Check::Print->new, 		
										"Build a report stub";
ok 			$report_ref = {
				run		=>[ $report_placeholder ],
				log_file =>[
					Print::Log->new,
				],
			},							"Build initial report definitions for testing";
lives_ok{
			$ella_peterson = Log::Shiras::Switchboard->get_operator(
				name_space_bounds	=> $name_space_ref,
				reports				=> 	$report_ref,
				#~ self_report			=> 1,
			);
}										"Get a switchboard operator and set up the switchboard";
### <where> - turn on print statement capture ...
ok(			re_route_print(
				fail_over => 0,
				level => 'debug',
				report => 'run', 
			),							"Initiating print re-routing");
lives_ok{	$print_message = capture_stdout{ print "Hello World 0\n" } }
										"Send a basic print statement that should be captured rather than print";
unlike		$print_message, qr/Hello World 0/,		
										"... and check that it did NOT print";
ok(			re_route_print(
				fail_over => 1,
				level => 'debug',
				report => 'run', 
			),							"Re-route print with fail_over on");
lives_ok{ 	$print_message = capture_stdout{ print "Hello World 1\n" } }
										"Send another print statement that should make it to STDOUT through the fail_over";
like		$print_message, qr/^Hello World 1$/,		
										"... and check that it did print (as written)";
ok(			re_route_print(
				fail_over => 1,
				level => 'info',
				report => 'run',
			),							"Re-route print with fail_over on");
lives_ok{ 	$print_message = capture_stdout{ print "Hello World 2\n" } }
										"Send a print statement that should be sent to the 'run' report";
like		$print_message, qr/^--\|Hello World 2\|--$/,		
										"... and check that the output includes the expected reporting add ons";
lives_ok{ 	$print_message = capture_stdout{ yellow_submarine( "Hello World 3\n" ) } }
										"Send another print statement deeper in the main:: name-space that should be sent to fail_over";
like		$print_message, qr/^Hello World 3$/,		
										"... and check that it did print (as written)";
ok(			re_route_print(
				fail_over => 1,
				level => 'warn',
				report => 'run',
			),							"Re-route print with a higher level of urgency");
lives_ok{ 	$print_message = capture_stdout{ print "Hello World 4\n" } }
										"Send a print statement that should be sent to the 'run' report";
like		$print_message, qr/^--\|Hello World 4\|--$/,		
										"... and check that the output includes the expected reporting add ons";
ok(			$ella_peterson->set_self_report( 1 ),
										"Turn on self reporting");
lives_ok{ 	$print_message = capture_stdout{ print "Hello World 5\n" } }
										"Send a print statement that should trigger self reporting";
like		$print_message, qr/^subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0073 |\n\t:(	captured print message:\n\t\tHello World 5 ):/,		
										"... and check that a self_report statement was generated";
explain									"... Test Done";
done_testing;

sub yellow_submarine{
	print shift;
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
	#### <where> - passed: $ref
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
	printf STDOUT ( "subroutine - %-28s | line - %04d |\n\t:(\t%-31s ):\n", $_[0]->{up_sub}, $_[0]->{line}, join( "\n\t\t", @new_list ) );
}

1;