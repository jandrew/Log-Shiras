#!perl
use lib 'lib', '../lib',;
use Log::Shiras::Switchboard;
use Log::Shiras::TapWarn;
$| = 1;
### <where> - lets get ready to rumble...
my	$fail_over = 0;
re_route_warn(#re-route warn statements
	level		=> 'warn',
	fail_over	=> $fail_over,
); 
warn "Watch Out World 0";
### <where> - No warning here (the switchboard is not set up) ...
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
					TapWarn =>{
						UNBLOCK =>{
							# UNBLOCKing the log_file report
							# 	at Log::Shiras::Tapwarn and deeper
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
				Warn::Excited->new,
			],
			quiet =>[
				Warn::Wisper->new,
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
warn "Watch Out World 1";
### <where> - message went to the log_file - didnt warn ...
re_route_warn(#re-route warn statements
	report 		=> 'quiet',
	fail_over	=> $fail_over,
); 
warn "Watch Out World 2";
### <where> - message went to the buffer - turning off buffering for the 'quiet' destination ...
my	$other_operator = Log::Shiras::Switchboard->get_operator(
		buffering =>{ quiet => 0, }, 
	);
### <where> - should have warned what was in the buffer ...
re_route_warn(# level too low
	report	=> 'quiet',
	level	=> 'debug',
	fail_over	=> $fail_over,
);
warn "Watch Out World 3";
re_route_warn(# level OK
	report	=> 'loud',
	level	=> 'info',
	fail_over	=> $fail_over,
);
warn "Watch Out World 4";
### <where> - should have warned here too...
re_route_warn(# level OK , report wrong
	report		=> 'run',
	level		=> 'warn',
	fail_over	=> $fail_over,
);
warn "Watch Out World 5";


package Warn::Excited;
sub new{
	bless {}, shift;
}
sub add_line{
	shift;
	my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ? @{$_[0]->{message}} : $_[0]->{message};
	my @new_list;
	map{ push @new_list, $_ if $_ } @input;
	chomp @new_list;
	print '!!!' . uc(join( ' ', @new_list)) . "!!!\n";
}


package Warn::Wisper;
sub new{
	bless {}, shift;
}
sub add_line{
	shift;
	my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ? @{$_[0]->{message}} : $_[0]->{message};
	my @new_list;
	map{ push @new_list, $_ if $_ } @input;
	chomp @new_list;
	print '--->' . lc(join( ' ', @new_list )) . "<---\n";
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
	printf ( "subroutine - %-28s | line - %04d |\n\t:(\t%-31s ):\n", $_[0]->{up_sub}, $_[0]->{line}, join( "\n\t\t", @new_list ) );
}
1;