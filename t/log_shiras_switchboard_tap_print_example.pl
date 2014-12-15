#!perl
use lib 'lib', '../lib',;
use Log::Shiras::Switchboard;
use Log::Shiras::TapPrint;
$| = 1;
### <where> - lets get ready to rumble...
my	$fail_over = 0;
re_route_print(#re-route print statements
	level		=> 'warn',
	fail_over	=> $fail_over,
); 
print "Hello World 0\n";
### <where> - No printing here (the switchboard is not set up) ...
my $operator = Log::Shiras::Switchboard->get_operator(
		self_report => 1,# required to UNBLOCK log_file reporting in Log::Shiras 
		name_space_bounds =>{
			main =>{# UNBLOCKing actual ->talk messages
				UNBLOCK =>{
					quiet	=> 'warn',
					loud	=> 'info',
					run		=> 'trace',
				},
			},
			Log =>{
				Shiras =>{
					TapPrint =>{
						UNBLOCK =>{
							# UNBLOCKing the log_file report
							# 	at Log::Shiras::TapPrint and deeper
							#	(self reporting)
							log_file => 'info',
						},
					},
					Switchboard =>{
						get_operator =>{
							UNBLOCK =>{
								# UNBLOCKing log_file
								# 	at Log::Shiras::Switchboard::get_operator
								#	(self reporting)
								log_file => 'info',
							},
						},
						_flush_buffer =>{
							UNBLOCK =>{
								# UNBLOCKing log_file
								# 	at Log::Shiras::Switchboard::_flush_buffer
								#	(self reporting)
								log_file => 'info',
							},
						},
					},
				},
			},
		},
		reports =>{
			loud =>[
				Print::Excited->new,
			],
			quiet =>[
				Print::Wisper->new,
			],
			log_file =>[
				Print::Log->new,
			],
		},
		buffering =>{
			quiet => 1, 
		},
	);
### <where> - sending a message ...
print "Hello World 1\n";
### <where> - message went to the log_file - didnt print ...
re_route_print(#re-route print statements
	report 		=> 'quiet',
	fail_over	=> $fail_over,
); 
print "Hello World 2\n";
### <where> - message went to the buffer - turning off buffering for the 'quiet' destination ...
my	$other_operator = Log::Shiras::Switchboard->get_operator(
		buffering =>{ quiet => 0, }, 
	);
### <where> - should have printed what was in the buffer ...
re_route_print(# level too low
	report	=> 'quiet',
	level	=> 'debug',
	fail_over	=> $fail_over,
);
print "Hello World 3\n";
re_route_print(# level OK
	report	=> 'loud',
	level	=> 'info',
	fail_over	=> $fail_over,
);
print "Hello World 4\n";
### <where> - should have printed here too...
re_route_print(# level OK , report wrong
	report		=> 'run',
	level		=> 'warn',
	fail_over	=> $fail_over,
);
print "Hello World 5\n";


package Print::Excited;
sub new{
	bless {}, shift;
}
sub add_line{
	shift;
	my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ? @{$_[0]->{message}} : $_[0]->{message};
	my @new_list;
	map{ push @new_list, $_ if $_ } @input;
	chomp @new_list;
	print STDOUT '!!!' . uc(join( ' ', @new_list)) . "!!!\n";
}


package Print::Wisper;
sub new{
	bless {}, shift;
}
sub add_line{
	shift;
	my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ? @{$_[0]->{message}} : $_[0]->{message};
	my @new_list;
	map{ push @new_list, $_ if $_ } @input;
	chomp @new_list;
	print STDOUT '--->' . lc(join( ' ', @new_list )) . "<---\n";
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