package Log::Shiras::TapPrint;
use version; our $VERSION = version->declare("v0.018.002");
use Moose::Exporter;
Moose::Exporter->setup_import_methods(
    as_is => [ qw( re_route_print restore_print ) ],
);
use MooseX::Types::Moose qw(
		ArrayRef
    );
use IO::Callback;
use lib '../../../lib',;
use Log::Shiras::Switchboard;
our	$switchboard = Log::Shiras::Switchboard->instance;
#~ use Smart::Comments '###';

#########1 Exported Methods   3#########4#########5#########6#########7#########8#########9

sub re_route_print{
	### <where> - made it ...
	my ( @passed ) = @_;
	my 	$data_ref =
		(	exists $passed[0] and
			ref $passed[0] eq 'HASH' and
			( 	exists $passed[0]->{report} or
				exists $passed[0]->{level} or
				exists $passed[0]->{fail_over}	)  ) ?
			$passed[0] :
		( 	@passed % 2 == 0 and
			( 	exists {@passed}->{report} or
				exists {@passed}->{level} or
				exists {@passed}->{fail_over}	) ) ?
			{@passed} :
			{ level => $_[0] };
	$switchboard->_internal_talk( { report => 'log_file', level => 0,######### Logging
		name_space => 'Log::Shiras::TapPrint::re_route_print',
		message =>	"Arrived Log::Shiras::TapPrint::re_route_print to settings: " .
			$switchboard->print_data( $data_ref ), } );
	if(	!$data_ref->{report} ){
		$data_ref->{report}	= 'log_file';
		$switchboard->_internal_talk( { report => 'log_file', level => 3,######### Logging
			name_space => 'Log::Shiras::TapPrint::report',
			message =>	"No report was passed to 're_route_print' so the target report for print is set to: 'log_file'", } );
	}#default report is log_file
	if(	!$data_ref->{level} ){
		$data_ref->{level} = 11;			
		$switchboard->_internal_talk( { report => 'log_file', level => 3,######### Logging
			name_space => 'Log::Shiras::TapPrint::level',
			message =>	"No urgency level was defined in the 're_route_print' method call so future 'print' messages will be sent at: 11 (These go to 11)", } );
	}#default urgency is the maximum (11)
	$switchboard->_internal_talk( { report => 'log_file', level => 2,###### Logging
		name_space => 'Log::Shiras::TapPrint::re_route_print',
		message =>[
			"You are currently attempting to Hijack the default 'print' output destination.",
			"BEWARE, this will slow all printing down!!!! ",
			"Going foward, all print statements, without the explicit syntax 'print STDOUT',",
			"\twill be routed through the switchboard to the -$data_ref->{report}- ",
			"\treport with an urgency level of -$data_ref->{level}-." ], 					} );
	$switchboard->_internal_talk( { report => 'log_file', level => 1,######### Logging
		name_space => 'Log::Shiras::TapPrint::re_route_print',
		message =>	"Final setting for print calls: " . $switchboard->print_data( $data_ref ), } );
	my	$code_ref = sub{
			### <where> - running coderef with: $_[0]
			$data_ref->{message} = [ @_ ];
			chomp @{$data_ref->{message}};
			my $go_back = 0;
			my $message;
			$data_ref->{name_space} = $switchboard->get_caller( 3 )->{up_sub};
			my	$arrived = is_ArrayRef( $data_ref->{message} ) ? $data_ref->{message} : [ $data_ref->{message} ];
			$switchboard->_internal_talk( { report => 'log_file', level => 2,######### Logging
				name_space => 'Log::Shiras::TapPrint::print',
				message => [ "captured print message:", @$arrived ], } );
			$switchboard->_internal_talk( { report => 'log_file', level => 0,######### Logging
				name_space => 'Log::Shiras::TapPrint::print',
				message => [ "raw message ref:", $switchboard->print_data( $data_ref ) ], } );
			if(	$switchboard->_can_communicate( 
					$data_ref->{report}, $data_ref->{level}, $data_ref->{name_space} ) ){
				$switchboard->_internal_talk( {
					report => 'log_file', level	=> 0,
					name_space 	=> 'Log::Shiras::TapPrint::print',
					message	=>	"Message approved",	} );
				### <where> - message approved ...
				$switchboard->_internal_talk( { report => 'log_file', level => 0,######### Logging
					name_space => 'Log::Shiras::TapPrint::print',
					message => 'print message cleared - sending it to the switchboard', } );
				my $x = $switchboard->_attempt_to_report( $data_ref );
				if( $x ){
					$switchboard->_internal_talk( { report => 'log_file', level => 2,######### Logging
						name_space => 'Log::Shiras::TapPrint::print',
						message => [ "The print message was sent to -$x- destination(s)", ], } );
				}else{
					$switchboard->_internal_talk( {
						report => 'log_file', level	=> 3,
						name_space 	=> 'Log::Shiras::TapPrint::print',
						message	=>[	"Message approved by the switchboard but it found no outlet!" ], }, );
					$go_back = 1;
				}
			}else{
				### <where> - message blocked ...
				$switchboard->_internal_talk( {
					report => 'log_file', level	=> 3,
					name_space 	=> 'Log::Shiras::TapPrint::print',
					message	=>[ 
						"Message blocked by the switchboard!",
						$switchboard->_last_error, ],			} );
				$go_back = 1;
			}
			if( $go_back ){
				if( $data_ref->{fail_over} ){
					### <where> - failover back to STDOUT ...
					print STDOUT @_;
				}else{
					### <where> - sending warning for unprinted message ...
					$data_ref->{message}->[0] = "-->" . $data_ref->{message}->[0];
					$data_ref->{message}->[-1] .= "<--";
					$switchboard->_internal_talk( {
						report => 'log_file', level	=> 3,
						name_space 	=> 'Log::Shiras::TapPrint::print',
						message	=>	["Failover is blocked - no printing of:",
							@{$data_ref->{message}} ],	} );
				}
			}
		};
	select( IO::Callback->new('>', $code_ref)) or die "Couldn't redirect STDOUT: $!";
	$switchboard->_internal_talk( { report => 'log_file', level => 0,######### Logging
		name_space => 'Log::Shiras::TapPrint::re_route_print',
		message =>	"Finished re_routing print statements", } );
	return 1;
}

sub restore_print{
	select( STDOUT ) or 
			die "Couldn't reset print: $!";
	$switchboard->_internal_talk( { report => 'log_file', level => 0,######### Logging
		name_space => 'Log::Shiras::TapPrint::restore_print',
		message =>	"Log::Shiras is no longer tapping into 'print' statements!", } );
	return 1;
}

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

1;

#########1 Phinish            3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::TapPrint - Reroute print to Log::Shiras::Switchboard

=head1 DESCRIPTION

L<Shiras|http://en.wikipedia.org/wiki/Moose#Subspecies> - A small subspecies of 
Moose found in the western United States (of America).
    
This module is only meant to be used as an accessory to L<Log::Shiras::Switchboard
|https://metacpan.org/module/Log::Shiras::Switchboard>. It's function is to capture, 
prepare, and re-route L<print|http://perldoc.perl.org/functions/print.html> messages 
to the switchboard. Once the messages are wrapped and re-routed to the switchboard 
they can be managed just like any other L<Log::Shiras
|https://metacpan.org/module/Log::Shiras> message.

Unlike most of the other classes in this package this class uses a functional 
interface NOT an object oriented interface.  There is no instance creation method 
provided or intended.  The L<re_route|/re_route_print( %args )> method builds an 
L<anonymous subroutine|http://perldoc.perl.org/perlfaq7.html#What's-a-closure%3f> 
(closure) for processing print input when received.  This subroutine is passed to 
L<IO::Callback|https://metacpan.org/module/IO::Callback> so it can be seen by perl 
as a filehandle.  It then uses that filehandle in the L<select( $fh )
|http://perldoc.perl.org/functions/select.html> command to redirect generic print 
through the anonymous subroutine.  The anonymous subroutine packages the print 
statement, checks for permissions, and sends the statements to 
L<Log::Shiras::Switchboard|https://metacpan.org/module/Log::Shiras::Switchboard>.  
Traffic permissions and handling are all managed by calls to the 'Switchboard' 
class.

=head2 Functions

These functions are used to change the routing of general print statements.

=head2 re_route_print( %args )

This is the function used to re_route generic print statements to 
L<Log::Shiras::Switchboard|https://metacpan.org/module/Log::Shiras::Switchboard> for 
processing.  There are several settings adjustments that affect the routing of these 
statements.  Since print statments are intended to be captured in-place, with no 
modification, all these settings must be fixed when the re-routing is implemented.  
This function accepts all of the possible settings, minimally scrubs the data as 
needed, builds the needed anonymous subroutine, and then redirects generic print 
statements to that subroutine.  Each set of content from generic print statements 
will then be packaged by the anonymous subroutine and sends it to the switchboard.  
In L<Log::Shiras::Telephone|https://metacpan.org/module/Log::Shiras::Telephone> you 
can also set the name-space for the message.  Since print statements are generally 
scattered throughout pre-existing code the name-space is always the L<(caller(1))[3]
|http://perldoc.perl.org/functions/caller.html> 'subroutine' string of the print 
statement location.

=head3 Accepts

The following keys in a hash or hashref

=head4 report

This is the name of the destination report for the print statement.

=head4 level

This is a string indicating the urgency level of all subsequent print statements.  It 
should match one of the L<defined
|https://metacpan.org/module/Log::Shiras::Switchboard#get_log_levels-report_name> levels 
for that report.  It also accepts integers 0 - 11.  Any level strings that do not match 
will be treated as being sent at level 0.  If the level matches fatal (=~/fatal/i) then 
the code will die after sending the message to the report.  However, if the level is sent 
as an integer equivalent to fatal then it will not die.

=head4 fail_over

This is a boolean value that acts as a switch to turn off or on an outlet to messages 
sent via print that are not succesfully sent to at least one L<report|/report> instance.  
If the outlet is on then the message sent by 'print' is sent to STDOUT.  This is a helpful 
feature when writing code containing TapPrint but you are not ready to set up a 
switchboard to see what is going on.  You can managage settings in the whole script by 
having a $fail_over variable at the top that is used to set each of the fail_over elements 
for re_route_print.  That way you can turn this on or off for the whole script at once if 
you want. 

=head4 ask

This can be ommitted but if it is set to 1 then the Switchboard will ask for STDIN (command 
prompt) input after subsequent print statments prior to proceding and then append the input 
to any message sent by 'print'.

=head3 Returns

1

=head2 restore_print

This sends all print statements to STDOUT

=head3 Accepts

Nothing

=head3 Returns

1

=head1 Self Reporting

This logging package will L<self report
|https://metacpan.org/module/Log::Shiras::Switchboard#self_report>.  It is possible to 
turn on different levels of logging to trace the internal actions of the report.  All 
internal reporting is directed at the 'log_file' report.  In order to receive internal 
messages B<including warnings>, you need to set the Switchboard 'self_report' attribute to 
1 and then UNBLOCK the correct L<name_space
|https://metacpan.org/module/Log::Shiras::Switchboard#name_space_bounds> for the targeted 
messages.  I determined at which urgency level each message should be sent and set them with 
integer equivalent urgencies to allow for possible renameing of log_file levels without 
causing this to break.  If you are concerned with availability of messages or dispatched 
urgency level please let L<me|/AUTHOR> know.

=head2 Listing of Internal Name Spaces

=over

=item Log

=over

=item Shiras

=over

=item TapPrint

=over

=item re_route_print

=item report

=item level

=item print

=item restore_print

=back

=back

=back

=back

=head1 SYNOPSIS

This is pretty long so I put it at the end
    
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
			#~ self_report => 1,# required to UNBLOCK log_file reporting in Log::Shiras 
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
        
	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is -don't care- (off for speed)
	# 	the Log::Shiras::TapPrint self reporting is BLOCKED
	# 	the Log::Shiras::Switchboard::get_operator self reporting is BLOCKED
	# 	the Log::Shiras::Switchboard::_flush_buffer self reporting is BLOCKED
	#	the fail_over attribute is NOT activated
	# 01: --->hello world 2<---
	# 02: !!!HELLO WORLD 4!!!
	#######################################################################################
			
	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is -don't care- (off for speed)
	# 	the Log::Shiras::TapPrint self reporting is BLOCKED
	# 	the Log::Shiras::Switchboard::get_operator self reporting is BLOCKED
	# 	the Log::Shiras::Switchboard::_flush_buffer self reporting is BLOCKED
	#	the fail_over attribute is activated
	# 01: Hello World 0
	# 02: Hello World 1
	# 03: --->hello world 2<---
	# 04: Hello World 3
	# 05: !!!HELLO WORLD 4!!!
	# 06: Hello World 5
	#######################################################################################
			
	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is activated
	# 	the Log::Shiras::TapPrint self reporting is UNBLOCKED to warn
	# 	the Log::Shiras::Switchboard::get_operator self reporting is UNBLOCKED to info
	# 	the Log::Shiras::Switchboard::_flush_buffer self reporting is UNBLOCKED to info
	#	the fail_over attribute is activated
	# 01: Hello World 0
	# 02: subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 03: 	:(	Switchboard finished updating the following arguments: 
	# 04: 		self_report
	# 05: 		buffering
	# 06: 		reports
	# 07: 		name_space_bounds ):
	# 08: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0069 |
	# 09:	:(	captured print message:
	# 10:		Hello World 1 ):
	# 11: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0099 |
	# 12: 	:(	Message blocked by the switchboard!
	# 13: 		Report -log_file- is NOT UNBLOCKed for the name-space: main ):
	# 14: Hello World 1
	# 15: subroutine - Log::Shiras::TapPrint::re_route_print | line - 0046 |
	# 16: 	:(	No urgency level was defined in the 're_route_print' method call so future 'print' messages will be sent at: 11 (These go to 11) ):
	# 17: subroutine - Log::Shiras::TapPrint::re_route_print | line - 0050 |
	# 18: 	:(	You are currently attempting to Hijack the default output destination.
	# 19: 		BEWARE, this will slow all printing down!!!! 
	# 20: 		Going foward, all print statements without the explicit syntax 'print STDOUT'
	# 21: 			will be routed through the switchboard to the -quiet- 
	# 22: 			report with an urgency level of -11-. ):
	# 23: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0069 |
	# 24: 	:(	captured print message:
	# 25: 		Hello World 2 ):
	# 26: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0087 |
	# 27: 	:(	The print message was sent to -buffer- destination(s) ):
	# 30: subroutine - Log::Shiras::Switchboard::get_operator | line - 0074 |
	# 21: 	:(	Starting get operator
	# 22: 		With updates to:
	# 23: 		buffering ):
	# 24: subroutine - Log::Shiras::Switchboard::_flush_buffer | line - 0771 |
	# 25: 	:(	There are messages to be flushed for: quiet ):
	# 26: --->hello world 2<---
	# 27: subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 28:	:(	Switchboard finished updating the following arguments: 
	# 29:		buffering ):
	# 30: subroutine - Log::Shiras::TapPrint::re_route_print | line - 0050 |
	# 31:	:(	You are currently attempting to Hijack the default output destination.
	# 32:		BEWARE, this will slow all printing down!!!! 
	# 33:		Going foward, all print statements without the explicit syntax 'print STDOUT'
	# 34:			will be routed through the switchboard to the -quiet- 
	# 35:			report with an urgency level of -debug-. ):
	# 36: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0069 |
	# 37: 	:(	captured print message:
	# 38: 		Hello World 3 ):
	# 39: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0099 |
	# 40: 	:(	Message blocked by the switchboard!
	# 41: 		The destination -quiet- is UNBLOCKed but not to the -debug- level at the name space: main ):
	# 42: Hello World 3
	# 43: subroutine - Log::Shiras::TapPrint::re_route_print | line - 0050 |
	# 44: 	:(	You are currently attempting to Hijack the default output destination.
	# 45: 		BEWARE, this will slow all printing down!!!! 
	# 46: 		Going foward, all print statements without the explicit syntax 'print STDOUT'
	# 47: 			will be routed through the switchboard to the -loud- 
	# 48: 			report with an urgency level of -info-. ):
	# 49: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0069 |
	# 50: 	:(	captured print message:
	# 51: 		Hello World 4 ):
	# 52: !!!HELLO WORLD 4!!!
	# 53: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0087 |
	# 54: 	:(	The message was sent to -1- destination(s) ):
	# 55: subroutine - Log::Shiras::TapPrint::re_route_print | line - 0050 |
	# 56: 	:(	You are currently attempting to Hijack the default output destination.
	# 57: 		BEWARE, this will slow all printing down!!!! 
	# 58: 		Going foward, all print statements without the explicit syntax 'print STDOUT'
	# 59: 			will be routed through the switchboard to the -run- 
	# 60: 			report with an urgency level of -warn-. ):
	# 61: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0069 |
	# 62: 	:(	captured print message:
	# 63: 		Hello World 5 ):
	# 64: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0091 |
	# 65: 	:(	Message approved by the switchboard but it found no outlet! ):
	# 66: Hello World 5
	#######################################################################################

	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is activated
	# 	the Log::Shiras::TapPrint self reporting is UNBLOCKED to info
	# 	the Log::Shiras::Switchboard::get_operator self reporting is UNBLOCKED to info
	# 	the Log::Shiras::Switchboard::_flush_buffer self reporting is UNBLOCKED to info
	#	the fail_over attribute is NOT activated
	# 01: subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 02: 	:(	Switchboard finished updating the following arguments: 
	# 03: 		self_report
	# 04: 		buffering
	# 05: 		reports
	# 06: 		name_space_bounds ):
	# 07: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0069 |
	# 08:	:(	captured print message:
	# 09:		Hello World 1 ):
	# 10: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0099 |
	# 11: 	:(	Message blocked by the switchboard!
	# 12: 		Report -log_file- is NOT UNBLOCKed for the name-space: main ):
	# 13: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0119 |
	# 14: 	:(	Failover is blocked - no printing of:
	# 15: 		-->Hello World 1<-- ):
	# 16: subroutine - Log::Shiras::TapPrint::re_route_print | line - 0046 |
	# 17: 	:(	No urgency level was defined in the 're_route_print' method call so future 'print' messages will be sent at: 11 (These go to 11) ):
	# 18: subroutine - Log::Shiras::TapPrint::re_route_print | line - 0050 |
	# 19: 	:(	You are currently attempting to Hijack the default output destination.
	# 20: 		BEWARE, this will slow all printing down!!!! 
	# 21: 		Going foward, all print statements without the explicit syntax 'print STDOUT'
	# 22: 			will be routed through the switchboard to the -quiet- 
	# 23: 			report with an urgency level of -11-. ):
	# 24: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0069 |
	# 25: 	:(	captured print message:
	# 26: 		Hello World 2 ):
	# 27: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0087 |
	# 28: 	:(	The print message was sent to -buffer- destination(s) ):
	# 29: subroutine - Log::Shiras::Switchboard::get_operator | line - 0074 |
	# 30: 	:(	Starting get operator
	# 31: 		With updates to:
	# 32: 		buffering ):
	# 33: subroutine - Log::Shiras::Switchboard::_flush_buffer | line - 0771 |
	# 34: 	:(	There are messages to be flushed for: quiet ):
	# 35: --->hello world 2<---
	# 36: subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 37:	:(	Switchboard finished updating the following arguments: 
	# 38:		buffering ):
	# 39: subroutine - Log::Shiras::TapPrint::re_route_print | line - 0050 |
	# 40:	:(	You are currently attempting to Hijack the default output destination.
	# 41:		BEWARE, this will slow all printing down!!!! 
	# 42:		Going foward, all print statements without the explicit syntax 'print STDOUT'
	# 43:			will be routed through the switchboard to the -quiet- 
	# 44:			report with an urgency level of -debug-. ):
	# 45: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0069 |
	# 46: 	:(	captured print message:
	# 47: 		Hello World 3 ):
	# 48: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0099 |
	# 49: 	:(	Message blocked by the switchboard!
	# 50: 		The destination -quiet- is UNBLOCKed but not to the -debug- level at the name space: main ):
	# 51: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 01119 |
	# 52: 	:(	Failover is blocked - no printing of:
	# 53: 		-->Hello World 3<-- ):
	# 54: subroutine - Log::Shiras::TapPrint::re_route_print | line - 0050 |
	# 55: 	:(	You are currently attempting to Hijack the default output destination.
	# 56: 		BEWARE, this will slow all printing down!!!! 
	# 57: 		Going foward, all print statements without the explicit syntax 'print STDOUT'
	# 58: 			will be routed through the switchboard to the -loud- 
	# 59: 			report with an urgency level of -info-. ):
	# 60: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0069 |
	# 61: 	:(	captured print message:
	# 62: 		Hello World 4 ):
	# 63: !!!HELLO WORLD 4!!!
	# 64: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0087 |
	# 65: 	:(	The message was sent to -1- destination(s) ):
	# 66: subroutine - Log::Shiras::TapPrint::re_route_print | line - 0050 |
	# 67: 	:(	You are currently attempting to Hijack the default output destination.
	# 68: 		BEWARE, this will slow all printing down!!!! 
	# 69: 		Going foward, all print statements without the explicit syntax 'print STDOUT'
	# 70: 			will be routed through the switchboard to the -run- 
	# 71: 			report with an urgency level of -warn-. ):
	# 72: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0069 |
	# 73: 	:(	captured print message:
	# 74: 		Hello World 5 ):
	# 75: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0091 |
	# 76: 	:(	Message approved by the switchboard but it found no outlet! ):
	# 77: subroutine - Log::Shiras::TapPrint::__ANON__ | line - 0119 |
	# 78:	:(	Failover is blocked - no printing of:
	# 79:		-->Hello World 5<-- ):
	#######################################################################################

=head2 SYNOPSIS EXPLANATION

=head3 re_route_print( level => 'warn', fail_over => $fail_over )

This generates an L<anonymous subroutine
|http://perldoc.perl.org/perlfaq7.html#What's-a-closure%3f> (closure) with the passed 
arguments for processing print input when received.  This subroutine is passed to 
L<IO::Callback|https://metacpan.org/module/IO::Callback> so it can be seen by perl as a 
filehandle.  It then uses that filehandle in the L<select( $fh )
|http://perldoc.perl.org/functions/select.html> command to re-route standard print 
statements.

=head3 print "Hello World 0\n"

This is a first opportunity to capture print messages.  Since the switchboard is not setup 
yet all reports (switchboard destinations) are blocked.  The only time something happens 
here is if the fail_over setting is on.  (from the previous step).  If fail_over => 1 
then 'Hello World' goes to STDOUT.  If failover is not active even the warning messages 
will not be collected/reported.

=head3 my $operator = Log::Shiras::Switchboard->get_operator( %args )

This uses an exported method to get an instance of the L<Log::Shiras::Switchboard
|https://metacpan.org/module/Log::Shiras::Switchboard> class and set the initial 
switchboard settings.

=head4 self_report => Bool

To access the self reporting features of this package you must turn this on!  As this 
attribute implies, the whole package has built-in logging messages to follow the action 
behind the scenes!.  These messages can be captured by UNBLOCKing the name-spaces of 
interest to the level of detail that you wish.  All internal messages are sent to the 
'log_file' report name.

=head4 name_space_bounds =>{ %args }

This is where the name-space bounds are defined.  Each UNBLOCK section can unblock many 
reports to a given urgency level.  Different levels of urgency for each report can be 
definied for each name-space level.

=head4 reports =>{ %args }

This is where the reports are defined for the switchboard.  Each 'report' key is a 
L<report|https://metacpan.org/module/Log::Shiras::Switchboard#reports> name addressable 
by a phone message.  For a pre-built class that only needs role modification review the 
documentation for L<Log::Shiras::Report|https://metacpan.org/module/Log::Shiras::Report>

=head4 buffering =>{ %args }

This sets the buffering state by report name.

=head3 print "Hello World 1\n"

The switchboard is on at this point so warning messages can be generated but the message 
won't print because it is directed at the 'log_file' report which is not UNBLOCKed for 
main.

=head3 print "Hello World 2\n"

This is a third attempt to print a message (after the destination and urgency of print 
messages was changed).  This time the message is approved but it is buffered since the 
message was sent to a report name with buffering turned on.

=head3 my $other_operator = Log::Shiras::Switchboard->get_operator( buffering =>{ quiet => 0, }, )

This opens another operator instance and sets the 'quiet' buffering to off.  I<This 
overwrites the original operators setting of on.>  As a consequence the existing buffer 
contents are flushed to the report instance(s). (And the message prints!)

=head3 package Print::Log

This is an example of a simple report class that includes formatting of the output.  
This package includes a default report class and a formatting role that should simplify 
building these classes.  see L<Log::Shiras::Report
|https://metacpan.org/module/Log::Shiras::Report>

=head1 SUPPORT

=over

L<github Log-Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 TODO

=over

=item Add self_report messages to the test file

=back

=head1 AUTHOR

=over

=item Jed Lund

=item jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

This software is copyrighted (c) 2012 and 2013 by Jed Lund.

=head1 DEPENDANCIES

=over

L<Moose::Exporter|https://metacpan.org/module/Moose::Exporter>

L<MooseX::Types::Moose|https://metacpan.org/module/MooseX::Types::Moose>

L<version|https://metacpan.org/module/version>

L<IO::Callback|https://metacpan.org/module/IO::Callback>

L<Log::Shiras::Switchboard|https://metacpan.org/module/Log::Shiras::Switchboard>

=back

=head1 SEE ALSO

=over

L<Capture::Tiny|https://metacpan.org/module/Capture::Tiny>

=cut

#########1#########2 <where> - main pod documentation end  6#########7#########8#########9