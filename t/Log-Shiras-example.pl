#!perl
use Modern::Perl;
use lib
		'../lib', 'lib', 
		'../../Data-Walk-Extracted/lib',
		'../Data-Walk-Extracted/lib';# 
use Log::Shiras::Switchboard 0.013;
my	$operator = get_operator(
	{
		reports => {# Can be replaced with a config file
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
		}
	}
);
my	$telephone = get_telephone;
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
	my $output;
	$output .= $phone->talk( report => 'phone_book', message => [ @_ ], );
	$output .= $phone->talk( 'calling', @_[0, 2] );
	return $output;
}
1;