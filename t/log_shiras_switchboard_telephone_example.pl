#!perl
use lib 'lib', '../lib',;
use Log::Shiras::Switchboard;
use Log::Shiras::Telephone;
$| = 1;
my $fail_over = 0;# Set fail_over here
### <where> - lets get ready to rumble...
my $telephone = Log::Shiras::Telephone->new( fail_over => $fail_over );
$telephone->talk( message => 'Hello World 0' );
### <where> - No printing here (the switchboard is not set up) ...
my 	$operator = Log::Shiras::Switchboard->get_operator(
		self_report => 1,# required to UNBLOCK log_file reporting in Log::Shiras 
		name_space_bounds =>{
			main =>{
				UNBLOCK =>{
					# UNBLOCKing the quiet, loud, and run reports 
					# 	at main and deeper
					#	for Log::Shiras::Telephone->talk actions
					quiet	=> 'warn',
					loud	=> 'info',
					run		=> 'trace',
				},
			},
			Log =>{
				Shiras =>{
					Telephone =>{
						UNBLOCK =>{
							# UNBLOCKing the log_file report
							# 	at Log::Shiras::Telephone and deeper
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
$telephone->talk( message => 'Hello World 1' );
### <where> - message went to the log_file - didnt print ...
$telephone->talk( report => 'quiet', message => 'Hello World 2' );
### <where> - message went to the buffer - turning off buffering for the 'quiet' destination ...
my 	$other_operator = Log::Shiras::Switchboard->get_operator(
		buffering =>{ quiet => 0, }, 
	);
### <where> - should have printed what was in the buffer ...
$telephone->talk(# level too low
	report  => 'quiet',
	level 	=> 'debug',
	message => 'Hello World 3',
);
$telephone->talk(# level OK
	report  => 'loud',
	level 	=> 'info',
	message => 'Hello World 4',
);
### <where> - should have printed here too...
$telephone->talk(# level OK , report wrong
	report 	=> 'run',
	level 	=> 'warn',
	message => 'Hello World 5',
);


package Print::Excited;
sub new{
	bless {}, shift;
}
sub add_line{
	shift;
	my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ?
					@{$_[0]->{message}} : $_[0]->{message};
	my @new_list;
	map{ push @new_list, $_ if $_ } @input;
	chomp @new_list;
	print '!!!' . uc(join( ' ', @new_list)) . "!!!\n";
}


package Print::Wisper;
sub new{
	bless {}, shift;
}
sub add_line{
	shift;
	my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ?
					@{$_[0]->{message}} : $_[0]->{message};
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
	my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ? 
					@{$_[0]->{message}} : $_[0]->{message};
	#### <where> - input: @input
	my @new_list;
	map{ push @new_list, $_ if $_ } @input;
	chomp @new_list;
	printf( "subroutine - %-28s | line - %04d |\n\t:(\t%-31s ):\n", 
				$_[0]->{up_sub}, $_[0]->{line}, 
				join( "\n\t\t", @new_list ) 						);
}
1;