#! C:/Perl/bin/perl
#######  High level Test File for Log::Shiras  #######

use Test::Most;
use Test::Moose;
use Capture::Tiny 0.12 qw(
	capture_stderr
	capture_stdout
);
use YAML::Any;
#~ use JSON::XS;
BEGIN{
	#~ $ENV{ Smart_Comments } = '### #### #####';
}
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;
}
$| = 1;
use lib
		'../lib', 'lib', 
		'../../Data-Walk-Extracted/lib',
		'../Data-Walk-Extracted/lib';# 
use Log::Shiras::Switchboard 0.013;
use Log::Shiras::Report 0.007;
use Log::Shiras::Report::ShirasFormat 0.007;
use Log::Shiras::Report::TieFile 0.007;
use MooseX::ShortCut::BuildInstance 0.003;

my(
			$wait, 
			$operator,
			$telephone,
			$report,
			$phone_book,
);# $deputyandy, $firstinst, $testinst, $secondinst, $newclass, $newmeta, $capturefilename
my  		@exported_methods = qw(
				get_operator
				get_telephone
			);


my  		@switchboard_attributes = qw(
				name_space_bounds
				reports
				logging_levels
				will_cluck
				ignored_caller_names
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
				ignored_caller_names
				set_ignored_caller_names
				add_ignored_caller_names
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

my  		@report_methods = qw(
				talk
			);

my  		@report_attributes = qw(
				talk
			);
#~ my	$header = 'Date,File,Line,Data1,Data2,Data3';
my	$log_file = 'test.csv';
my	$phone_file = 'phone.csv';
my	$config_file = 'test_files/config.json';
### Log-Shiras easy questions

map{
can_ok		'main', $_,
}			@exported_methods;
lives_ok{
			unlink  $log_file   if( -f $log_file );
}											'First Cleanup prep step';
lives_ok{
			unlink  $phone_file   if( -f $phone_file );
}											'Second Cleanup prep step';
ok			$operator = get_operator( $config_file ),
											"Load the switchboard";
ok			$report = $operator->get_report( 'log_file' )->[0],
											"Get the log_file report to investigate what is inside";
ok			$phone_book = $operator->get_report( 'phone_book' )->[0],
											"Get the phone_book report to investigate what is inside";
is			$report->count_file_lines, 1,	"Check that the header is the only line in the file";
ok			$telephone = get_telephone,		"Get a telephone";
ok			!$telephone->talk( 
				level => 'debug', report => 'log_file', 
				message =>[ qw( humpty dumpty sat on a wall ) ] 
			),								"Send a message that won't go through";
ok			$telephone->talk( 
				level => 'warn', report => 'log_file', 
				message =>[ qw( humpty dumpty sat on a wall ) ] 
			),								"... then send a message that will go through";
is			$report->count_file_lines, 1,	"... and check that the lines were not sent to the log_file";
is			$operator->send_buffer_to_output( 'log_file' ), 1,
											"...flush 1 message to 1 file from the buffer";
is			$report->count_file_lines, 2,	"... and confirm that there are now two lines in the file (including the header)";
is			$telephone->talk( message =>['Dont', 'Save', 'This'] ), 'buffer',
											"Test sending a message (to the buffer)";
ok			$operator->clear_buffer( 'log_file' ),
											"... and clear the buffer without loading the message to the file";
is			test_sub( 'Scooby', 'Dooby', 'Do' ), 'buffer',
											"Test sending a message from a subroutine with it's own phone";
is			$telephone->talk( message =>['and', 'Scrappy', 'too!'] ), 'buffer',#One report received a record
											"and sending a message from main with no level callout";
is			Activity->call_someone( 'Jenny', '', '867-5309' ), '1buffer',
											"Test sending something to a package with two output paths";
is			$operator->send_buffer_to_output( 'log_file' ), 3,
											"...flush 3 messages to 1 file from the buffer";
like		$report->get_file_line( 4 ), qr/\d{4}-\d{2}-\d{2}\Q,010-Log-Shiras-All.t,Activity::call_someone,\E\d{3}\Q,calling,Jenny,867-5309\E/sxm,
											"Check the contents of the file to see if the formatting worked as expected";
like		$phone_book->get_file_line( 1 ), qr/\QJenny,,867-5309\E/sxm,
											"Check the contents of the phone book to see if Jenny's number is there";
is			$report->disconnect_file, $log_file,
											"Remove the link to the log_file";
is			$phone_book->disconnect_file, $phone_file,
											"Remove the link to the phone_book";
is			-f $log_file, 1,				"Test that -$log_file- is found";
ok			unlink( $log_file ),			"Test that -$log_file- is deleted";
is			-f $phone_file, 1,				"Test that -$phone_file- is found";
ok			unlink( $phone_file ),			"Test that -$phone_file- is deleted";
explain										"... Test Done";
done_testing;
sub test_sub{
	my @message = @_;
	my $phone = get_telephone;
	$phone->talk( level => 'debug', report => 'log_file', message =>[ @message ] );
}

package Activity;
use Log::Shiras::Switchboard;

sub call_someone{
	shift;
	my $phone = get_telephone;
	#### <where> - calling someone: @_
	my $output;
	$output .= $phone->talk( report => 'phone_book', message => [ @_ ], );
	$output .= $phone->talk( 'calling', @_[0, 2] );
	return $output;
}
1;