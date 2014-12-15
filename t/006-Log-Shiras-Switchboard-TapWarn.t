#!perl
#######  Initial Test File for Log::Shiras::TapWarn  #######
BEGIN{
	#~ $ENV{ Smart_Comments } = '###'; #### #####
}
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;
}

use Test::Most;
use Test::Moose;
use Capture::Tiny 0.12 qw(
	capture_stderr
);
use YAML::Any;
$| = 1;
use lib
		'../lib', 'lib', '../../Data-Walk-Extracted/lib';# 
use Log::Shiras::Switchboard 0.018;
use Log::Shiras::TapWarn 0.018;

my(
			$ella_peterson, 
			$name_space_ref,
			$report_ref,
			$error_message,
);

my  		@tap_warn_functions = qw(
				re_route_warn
				restore_warn
			);

### Log-Shiras easy questions
map{
can_ok		'main', $_,
}			@tap_warn_functions;
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
						TapWarn =>{
							UNBLOCK =>{# UNBLOCKing self reporting error messages
								log_file => 'info',
							},
						},
						Switchboard =>{
							#~ get_caller =>{
								#~ UNBLOCK =>{# UNBLOCKing self reporting error messages
									#~ log_file => 'trace',
								#~ },
							#~ },
						},
					},
				},
			},							"Build initial name-space for testing";
#~ ok			$report_placeholder_1 = Check::Print->new, 		
										#~ "Build a report stub";
ok 			$report_ref = {
				run			=> [ Check::Cluck->new ],
				log_file	=> [ Print::Log->new ],
			},							"Build initial reports for testing";
lives_ok{
			$ella_peterson = Log::Shiras::Switchboard->get_operator(
				name_space_bounds => $name_space_ref,
				reports	=> 	$report_ref,
				#~ self_report => 1,
			);
}										"Get a switchboard operator (using setup)";
lives_ok{	$error_message = capture_stderr{ warn "Watch Out World 0" } }
										"Send a basic warning statement to establish a baseline";
like		$error_message, qr/^Watch Out World 0/,		
										"... and check that it did print";
### <where> - turn on warnings capture ...
ok(			re_route_warn(
				fail_over => 0,
				level => 'debug',
				report => 'run', 
			),							"Initiating print re-routing");
lives_ok{	$error_message = capture_stderr{ yellow_submarine( "Watch Out World 1" ) } }
										"Send a warning in the name_space_bounds but with an insufficient level of urgency";
like		$error_message, qr/^$/,		
										"... and check that it did NOT print";
ok(			re_route_warn(
				fail_over	=> 1,
				level		=> 'debug',
				report		=> 'run', 
			),							"Turn on fail_over at the same level and to the same report");
lives_ok{	$error_message = capture_stderr{ warn "Watch Out World 2" } }
										"Send a warning that should fail_over";
like		$error_message, qr/^Watch Out World 2/,		
										"... and check that it did print";
ok(			re_route_warn(
				fail_over	=> 1,
				level		=> 'info',
				report		=> 'run', 
			),							"Raise the urgency to clear the UNBLOCK state for the warning to go to the target report");
lives_ok{	$error_message = capture_stderr{ warn "Watch Out World 3" } }
										"Send a warning with a sufficient level of urgency to the 'run' report";
like		$error_message, qr/^||Watch Out World 3.+\n/,		
										"... and check that it did print with 'run' formatting";
lives_ok{	$error_message = capture_stderr{ yellow_submarine( "Watch Out World 4" ) } }
										"Send a warning in a different name-space (different urgency threshold)";
like		$error_message, qr/^Watch Out World 4/,		
										"... and check that it did NOT print with 'run' formatting";
ok(			re_route_warn(
				fail_over	=> 1,
				level		=> 'warn',
				report		=> 'run', 
			),							"Raise the urgency to clear the UNBLOCK state for the warning to go to the target report");
lives_ok{	$error_message = capture_stderr{ yellow_submarine( "Watch Out World 4" ) } }
										"Send a warning as before";
like		$error_message, qr/^||Watch Out World 4.+\n/,		
										"... and check that it did print with 'run' formatting";
ok(			restore_warn,				"Clear routing of warnings");
lives_ok{	$error_message = capture_stderr{ yellow_submarine( "Watch Out World 5" ) } }
										"Send a warning as before, before ...";
like		$error_message, qr/^Watch Out World 5/,		
										"... and check that it did NOT print with 'run' formatting";
explain									"... Test Done";
done_testing;

sub yellow_submarine{
	warn shift;
}

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