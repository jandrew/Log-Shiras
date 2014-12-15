#!perl
use lib
		'../lib', 'lib', 
		'../../Data-Walk-Extracted/lib',
		'../Data-Walk-Extracted/lib';# 
use Log::Shiras::Switchboard;
use Log::Shiras::Telephone;
my	$operator = Log::Shiras::Switchboard->get_operator(
	{# Can be replaced with a config file
		reports => {
			log_file => [
				{
					roles => [
					   "Log::Shiras::Report::ShirasFormat",
					   "Log::Shiras::Report::TieFile"
					],
					format_string => "%{date_time}P(m=>'ymd')s," .
						"%{filename}Ps,%{inside_sub}Ps,%{line}Ps,%s,%s,%s",
					filename => "test.csv",
					superclasses => [
					   "Log::Shiras::Report"
					],
					header => "Date,File,Subroutine,Line,Data1,Data2,Data3",
					package => "Log::File::Shiras"
				}
			],
			phone_book => [
				{
					roles => [
					   "Log::Shiras::Report::ShirasFormat",
					   "Log::Shiras::Report::TieFile"
					],
					format_string => "%s,%s,%s",
					filename => "phone.csv",
					superclasses => [
					   "Log::Shiras::Report"
					],
					header => "Name,Area_Code,Number",
					package => "Phone::Report"
				},
				{
					roles => [
					   "Log::Shiras::Report::ShirasFormat",
					],
					format_string => "Loading -%3\$s- in the phone book for -%1\$s-",
					superclasses => [
					   "Log::Shiras::Report"
					],
					package => "Phone::Log",
					to_stdout => 1
				}
			]
		},
		name_space_bounds => {
			main => {
				UNBLOCK => {
					log_file => "warn"
				},
				test_sub => {
					UNBLOCK => {
						log_file => "debug"
					}
				}
			},
			Special =>{
				Name =>{
					Space =>{
						UNBLOCK => {
							killer => "warn"
						}
					}
				}
			},
			Activity => {
				call_someone => {
					UNBLOCK => {
						log_file => "trace",
						phone_book => "eleven"
					}
				}
			}
		},
		buffering => {
			log_file => 1
		},
		#~ will_cluck => 1,
	}
);
my	$telephone = Log::Shiras::Telephone->new;
	$telephone->talk( 
		level => 'debug', report => 'log_file', 
		message =>[ qw( humpty dumpty sat on a wall ) ] 
	);
	$telephone->talk( 
		level => 'warn', report => 'log_file', 
		message =>[ qw( humpty dumpty had a great fall ) ] 
	);
	$operator->send_buffer_to_output( 'log_file' );
	$telephone->talk( message =>['Dont', 'Save', 'This'] );
	$operator->clear_buffer( 'log_file' );
	test_sub( 'Scooby', 'Dooby', 'Do' );
	$telephone->talk( message =>['and', 'Scrappy', 'too!'] );
	Activity->call_someone( 'Jenny', '', '867-5309' );
	$operator->send_buffer_to_output( 'log_file' );
my	$phone = Log::Shiras::Telephone->new( 'Special::Name::Space' );
	$phone->talk( message => "Not done yet!", level => 'debug', report => 'killer' );
	$phone->talk( message => "Not done yet!", level => 'warn', report => 'killer' );#No actual report!
	$phone->talk( message => "The code is done!", level => 'fatal', report => 'killer' );
	
sub test_sub{
	my @message = @_;
	my $phone = Log::Shiras::Telephone->new;
	$phone->talk( level => 'debug', report => 'log_file', message =>[ @message ] );
}

package Activity;
use Log::Shiras::Switchboard;

sub call_someone{
	shift;
	my $phone = Log::Shiras::Telephone->new;
	my $output;
	$output .= $phone->talk( report => 'phone_book', message => [ @_ ], );
	$output .= $phone->talk( 'calling', @_[0, 2] );
	return $output;
}
1;