package Log::Shiras::TapWarn;
use version; our $VERSION = version->declare("v0.018.002");
use Moose;
use Moose::Exporter;
Moose::Exporter->setup_import_methods(
    as_is => [ qw( re_route_warn restore_warn ) ],
);
use MooseX::Types::Moose qw(
		ArrayRef
    );
use lib '../../../lib';
use Log::Shiras::Switchboard;
our	$switchboard = Log::Shiras::Switchboard->instance;
#~ use Smart::Comments '###';

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub re_route_warn{
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
		name_space => 'Log::Shiras::TapWarn::re_route_warn',
		message =>	"Arrived Log::Shiras::TapWarn::re_route_warn to settings: " .
			$switchboard->print_data( $data_ref ), } );
	if(	!$data_ref->{report} ){
		$data_ref->{report}	= 'log_file';
		$switchboard->_internal_talk( { report => 'log_file', level => 3,######### Logging
			name_space => 'Log::Shiras::TapWarn::report',
			message =>	"No report was passed to 're_route_warn' so the target report for warnings is set to: 'log_file'", } );
	}#default report is log_file
	if(	!$data_ref->{level} ){
		$data_ref->{level} = 11;			
		$switchboard->_internal_talk( { report => 'log_file', level => 3,######### Logging
			name_space => 'Log::Shiras::TapWarn::level',
			message =>	"No urgency level was defined in the 're_route_warn' method call so future warnings will be sent at: 11 (These go to 11)", } );
	}#default urgency is the maximum (11)
	$switchboard->_internal_talk( { report => 'log_file', level => 2,###### Logging
		name_space => 'Log::Shiras::TapWarn::re_route_warn',
		message =>[
			"You are currently attempting to Hijack warnings.",
			"BEWARE, this will slow all warnings down!!!!",
			"Going foward, all warnings will be routed through the switchboard to\n",
			"\tthe -$data_ref->{report}- report with an urgency level of -$data_ref->{level}-." ], 					} );
	$switchboard->_internal_talk( { report => 'log_file', level => 1,######### Logging
		name_space => 'Log::Shiras::TapWarn::re_route_warn',
		message =>	"Final setting for warning statments: " . $switchboard->print_data( $data_ref ), } );
	$SIG{__WARN__} = sub{
			### <where> - running coderef with: @_
			$data_ref->{message} = [ @_ ];
			chomp @{$data_ref->{message}};
			my $go_back = 0;
			my $message;
			$data_ref->{name_space} = $switchboard->get_caller( 1 )->{up_sub};
			my	$arrived = is_ArrayRef( $data_ref->{message} ) ? $data_ref->{message} : [ $data_ref->{message} ];
			$switchboard->_internal_talk( { report => 'log_file', level => 2,######### Logging
				name_space => 'Log::Shiras::TapWarn::warn',
				message => [ "captured warning:", @$arrived ], } );
			$switchboard->_internal_talk( { report => 'log_file', level => 0,######### Logging
				name_space => 'Log::Shiras::TapWarn::warn',
				message => [ "raw message ref:", $switchboard->print_data( $data_ref ) ], } );
			if(	$switchboard->_can_communicate( 
					$data_ref->{report}, $data_ref->{level}, $data_ref->{name_space} ) ){
				$switchboard->_internal_talk( {
					report => 'log_file', level	=> 0,
					name_space 	=> 'Log::Shiras::TapWarn::warn',
					message	=>	"Message approved",	} );
				### <where> - message approved ...
				$switchboard->_internal_talk( { report => 'log_file', level => 0,######### Logging
					name_space => 'Log::Shiras::TapWarn::warn',
					message => 'Warning cleared - sending it to the switchboard', } );
				my $x = $switchboard->_attempt_to_report( $data_ref );
				if( $x ){
					$switchboard->_internal_talk( { report => 'log_file', level => 2,######### Logging
						name_space => 'Log::Shiras::TapWarn::warn',
						message => [ "The warning was sent to -$x- destination(s)", ], } );
				}else{
					$switchboard->_internal_talk( {
						report => 'log_file', level	=> 3,
						name_space 	=> 'Log::Shiras::TapWarn::warn',
						message	=>[	"Message approved by the switchboard but it found no outlet!" ], }, );
					$go_back = 1;
				}
			}else{
				### <where> - message blocked ...
				$switchboard->_internal_talk( {
					report => 'log_file', level	=> 3,
					name_space 	=> 'Log::Shiras::TapWarn::warn',
					message	=>[ 
						"Message blocked by the switchboard!",
						$switchboard->_last_error, ],			} );
				$go_back = 1;
			}
			if( $go_back ){
				if( $data_ref->{fail_over} ){
					### <where> - resend the warning ...
					warn @_;
				}else{
					### <where> - sending warning for unprinted message ...
					$data_ref->{message}->[0] = "-->" . $data_ref->{message}->[0];
					$data_ref->{message}->[-1] .= "<--";
					$switchboard->_internal_talk( {
						report => 'log_file', level	=> 3,
						name_space 	=> 'Log::Shiras::TapWarn::warn',
						message	=>	["Failover is blocked - no printing of:",
							@{$data_ref->{message}} ],	} );
				}
			}
		} or die "Couldn't redirect __WARN__: $!";
	$switchboard->_internal_talk( { report => 'log_file', level => 0,######### Logging
		name_space => 'Log::Shiras::TapWarn::re_route_warn',
		message =>	"Finished re_routing warnings", } );
	return 1;
}

sub restore_warn{
	my ( $self, )= @_;
	$SIG{__WARN__} = undef;
	$switchboard->_internal_talk( { report => 'log_file', level => 0,######### Logging
		name_space => 'Log::Shiras::Tapwarn::restore_warn',
		message =>	"Log::Shiras is no longer tapping into warnings!", } );
	return 1;
}

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9
	
no Moose;
__PACKAGE__->meta->make_immutable(
	inline_constructor => 0,
);


1;

#########1 Phinish            3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::Tapwarn - Rerout warnings to Log::Shiras::Switchboard

=head1 DESCRIPTION

L<Shiras|http://en.wikipedia.org/wiki/Moose#Subspecies> - A small subspecies of 
Moose found in the western United States (of America).
    
This module is only meant to be used as an accessory to L<Log::Shiras::Switchboard
|https://metacpan.org/module/Log::Shiras::Switchboard>. It's function is to capture, 
prepare, and re-route L<warnings|http://perldoc.perl.org/functions/warn.html>  
to the switchboard. Once the messages are wrapped and re-routed to the switchboard 
they can be managed just like any other L<Log::Shiras
|https://metacpan.org/module/Log::Shiras> message.

Unlike most of the other classes in this package this class uses a functional 
interface NOT an object oriented interface.  There is no instance creation method 
provided or intended.  The L<re_route|/re_route_warn( %args )> method builds an 
L<anonymous subroutine|http://perldoc.perl.org/perlfaq7.html#What's-a-closure%3f> 
(closure) for processing warnings when received.  This subroutine is used to set  
L<$SIG{__WARN__}|http://perldoc.perl.org/perlvar.html#%25SIG> to redirect warnings  
through the anonymous subroutine.  The anonymous subroutine packages the warnings, 
checks for permissions, and sends the statements to L<Log::Shiras::Switchboard
|https://metacpan.org/module/Log::Shiras::Switchboard>.  Traffic permissions and 
handling are all managed by calls to the 'Switchboard' class.

=head2 Functions

These functions are used to change the routing of warnings.

=head2 re_route_warn( %args )

This is the function used to re_route warnings to L<Log::Shiras::Switchboard
|https://metacpan.org/module/Log::Shiras::Switchboard> for processing.  There are 
several settings adjustments that affect the routing of warnings.  Since warnings 
are intended to be captured in-place, with no modification, all these settings must 
be fixed when the re-routing is implemented.  This function accepts all of the 
possible settings, minimally scrubs the data as needed, builds the needed anonymous 
subroutine, and then redirects warnings to that subroutine.  Each set of content 
from a warning statement will then be packaged by the anonymous subroutine and sent 
to the switchboard.  In L<Log::Shiras::Telephone
|https://metacpan.org/module/Log::Shiras::Telephone> you can also set the name-space 
for the message.  Since warnings are generally scattered throughout pre-existing code 
the name-space is always the L<(caller(1))[3]|http://perldoc.perl.org/functions/caller.html> 
'subroutine' string of the warning location.

=head3 Accepts

The following keys in a hash or hashref

=head4 report

This is the name of the destination report for the hijacked warning.

=head4 level

This is a string indicating the urgency level of all subsequent warnings.  It should 
match one of the L<defined
|https://metacpan.org/module/Log::Shiras::Switchboard#get_log_levels-report_name> levels 
for that report.  It also accepts integers 0 - 11.  Any level strings that do not match 
will be treated as being sent at level 0.  If the level matches fatal (=~/fatal/i) then 
the code will die after sending the message to the report.  However, if the level is sent 
as an integer equivalent to fatal then it will not die.

=head4 fail_over

This is a boolean value that acts as a switch to turn off or on an outlet to messages 
sent via warn that are not succesfully sent to at least one L<report|/report> instance.  
If the outlet is on then the message is re-sent to warn.  No recursion occurs thanks to 
perl!  This is a helpful feature when writing code containing TapPrint when you are not 
ready to set up a switchboard to see what is going on.  You can managage settings in the 
whole script by having a $fail_over variable at the top that is used to set each of the 
fail_over elements for re_route_warn.  That way you can turn this on or off for the whole 
script at once if you want. 

=head4 ask

This can be ommitted but if it is set to 1 then the Switchboard will ask for STDIN (command 
prompt) input after subsequent warnings and prior to proceding and then append the input 
to any warnings.

=head3 Returns

1

=head2 restore_warn

This unhooks the $SIG{__WARN__} handler and warnings go back to normal.

=head3 Accepts

Nothing

=head3 Returns

1

=head1 Self Reporting

This logging package will L<self report
|https://metacpan.org/module/Log::Shiras::Switchboard#self_report>.  It is possible to 
turn on different levels of logging to trace the internal actions of the report.  All 
internal reporting is directed at the 'log_file' report.  In order to receive internal 
messages B<including internal warnings>, you need to set the Switchboard 'self_report' attribute 
to 1 and then UNBLOCK the correct L<name_space
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

=item TapWarn

=over

=item re_route_warn

=item report

=item level

=item print

=item restore_warn

=back

=back

=back

=back

=head1 SYNOPSIS

	#!perl
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
	);position_index 
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
		printf ( "subroutine - %-28s | line - %04d |\n\t:(\t%-31s ):\n", $_[0]->{subroutine}, $_[0]->{line}, join( "\n\t\t", @new_list ) );
	}
	1;
	
	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is -don't care- (off for speed)
	# 	the Log::Shiras::TapWarn self reporting is BLOCKED
	# 	the Log::Shiras::Switchboard::get_operator self reporting is BLOCKED
	# 	the Log::Shiras::Switchboard::_flush_buffer self reporting is BLOCKED
	#	the fail_over attribute is NOT activated
	# 01:--->watch out world 2 at log-shiras-switchboard-tapwarn-example.pl line 77.<---
	# 02:!!!WATCH OUT WORLD 4 AT LOG-SHIRAS-SWITCHBOARD-TAPWARN-EXAMPLE.PL LINE 94.!!!
	#######################################################################################
			
	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is -don't care- (off for speed)
	# 	the Log::Shiras::TapWarn self reporting is BLOCKED
	# 	the Log::Shiras::Switchboard::get_operator self reporting is BLOCKED
	# 	the Log::Shiras::Switchboard::_flush_buffer self reporting is BLOCKED
	#	the fail_over attribute is activated
	# 01:Watch Out World 0 at Log-Shiras-Switchboard-TapWarn-example.pl line 12.
	# 02:Watch Out World 1 at Log-Shiras-Switchboard-TapWarn-example.pl line 71.
	# 03:--->watch out world 2 at log-shiras-switchboard-tapwarn-example.pl line 77.<---
	# 04:Watch Out World 3 at Log-Shiras-Switchboard-TapWarn-example.pl line 88.
	# 05:!!!WATCH OUT WORLD 4 AT LOG-SHIRAS-SWITCHBOARD-TAPWARN-EXAMPLE.PL LINE 94.!!!
	# 06:Watch Out World 5 at Log-Shiras-Switchboard-TapWarn-example.pl line 101.
	#######################################################################################
			
	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is activated
	# 	the Log::Shiras::TapWarn self reporting is UNBLOCKED to warn
	# 	the Log::Shiras::Switchboard::get_operator self reporting is UNBLOCKED to info
	# 	the Log::Shiras::Switchboard::_flush_buffer self reporting is UNBLOCKED to info
	#	the fail_over attribute is activated
	# 01:Watch Out World 0 at Log-Shiras-Switchboard-TapWarn-example.pl line 12.
	# 02:subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 03:	:(	Switchboard finished updating the following arguments: 
	# 04:		self_report
	# 05:		buffering
	# 06:		reports
	# 07:		name_space_bounds ):
	# 08:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0067 |
	# 09:	:(	captured warning:
	# 10:		Watch Out World 1 at Log-Shiras-Switchboard-TapWarn-example.pl line 71. ):
	# 11:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0097 |
	# 12:	:(	Message blocked by the switchboard!
	# 13:		Report -log_file- is NOT UNBLOCKed for the name-space: main ):
	# 14:Watch Out World 1 at Log-Shiras-Switchboard-TapWarn-example.pl line 71.
	# 15:subroutine - Log::Shiras::TapWarn::re_route_warn | line - 0045 |
	# 16:	:(	No urgency level was defined in the 're_route_warn' method call so future warnings will be sent at: 11 (These go to 11) ):
	# 17:subroutine - Log::Shiras::TapWarn::re_route_warn | line - 0049 |
	# 18:	:(	You are currently attempting to Hijack warnings.
	# 19:		BEWARE, this will slow all warnings down!!!!
	# 20:		Going foward, all warnings will be routed through the switchboard to
	# 21:			the -quiet- report with an urgency level of -11-. ):
	# 22:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0067 |
	# 23:	:(	captured warning:
	# 24:		Watch Out World 2 at Log-Shiras-Switchboard-TapWarn-example.pl line 77. ):
	# 25:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0085 |
	# 26:	:(	The warning was sent to -buffer- destination(s) ):
	# 27:subroutine - Log::Shiras::Switchboard::get_operator | line - 0074 |
	# 28:	:(	Starting get operator
	# 29:		With updates to:
	# 30:		buffering ):
	# 31:subroutine - Log::Shiras::Switchboard::_flush_buffer | line - 0771 |
	# 32:	:(	There are messages to be flushed for: quiet ):
	# 33:--->watch out world 2 at log-shiras-switchboard-tapwarn-example.pl line 77.<---
	# 34:subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 35:	:(	Switchboard finished updating the following arguments: 
	# 36:		buffering ):
	# 37:subroutine - Log::Shiras::TapWarn::re_route_warn | line - 0049 |
	# 38:	:(	You are currently attempting to Hijack warnings.
	# 39:		BEWARE, this will slow all warnings down!!!!
	# 40:		Going foward, all warnings will be routed through the switchboard to
	# 41:			the -quiet- report with an urgency level of -debug-. ):
	# 42:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0067 |
	# 43:	:(	captured warning:
	# 44:		Watch Out World 3 at Log-Shiras-Switchboard-TapWarn-example.pl line 88. ):
	# 45:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0097 |
	# 46:	:(	Message blocked by the switchboard!
	# 47:		The destination -quiet- is UNBLOCKed but not to the -debug- level at the name space: main ):
	# 48:Watch Out World 3 at Log-Shiras-Switchboard-TapWarn-example.pl line 88.
	# 49:subroutine - Log::Shiras::TapWarn::re_route_warn | line - 0049 |
	# 50:	:(	You are currently attempting to Hijack warnings.
	# 51:		BEWARE, this will slow all warnings down!!!!
	# 52:		Going foward, all warnings will be routed through the switchboard to
	# 53:			the -loud- report with an urgency level of -info-. ):
	# 54:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0067 |
	# 55:	:(	captured warning:
	# 56:		Watch Out World 4 at Log-Shiras-Switchboard-TapWarn-example.pl line 94. ):
	# 57:!!!WATCH OUT WORLD 4 AT LOG-SHIRAS-SWITCHBOARD-TAPWARN-EXAMPLE.PL LINE 94.!!!
	# 58:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0085 |
	# 59:	:(	The warning was sent to -1- destination(s) ):
	# 60:subroutine - Log::Shiras::TapWarn::re_route_warn | line - 0049 |
	# 61:	:(	You are currently attempting to Hijack warnings.
	# 62:		BEWARE, this will slow all warnings down!!!!
	# 63:		Going foward, all warnings will be routed through the switchboard to
	# 64:			the -run- report with an urgency level of -warn-. ):
	# 65:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0067 |
	# 66:	:(	captured warning:
	# 67:		Watch Out World 5 at Log-Shiras-Switchboard-TapWarn-example.pl line 101. ):
	# 68:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0089 |
	# 69:	:(	Message approved by the switchboard but it found no outlet! ):
	# 70:Watch Out World 5 at Log-Shiras-Switchboard-TapWarn-example.pl line 101.
	#######################################################################################

	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is activated
	# 	the Log::Shiras::TapWarn self reporting is UNBLOCKED to info
	# 	the Log::Shiras::Switchboard::get_operator self reporting is UNBLOCKED to info
	# 	the Log::Shiras::Switchboard::_flush_buffer self reporting is UNBLOCKED to info
	#	the fail_over attribute is NOT activated
	# 01:subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 02:	:(	Switchboard finished updating the following arguments: 
	# 03:		self_report
	# 04:		buffering
	# 05:		reports
	# 06:		name_space_bounds ):
	# 07:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0067 |
	# 08:	:(	captured warning:
	# 09:		Watch Out World 1 at Log-Shiras-Switchboard-TapWarn-example.pl line 71. ):
	# 10:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0097 |
	# 11:	:(	Message blocked by the switchboard!
	# 12:		Report -log_file- is NOT UNBLOCKed for the name-space: main ):
	# 13:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0117 |
	# 14:	:(	Failover is blocked - no printing of:
	# 15:		-->Watch Out World 1 at Log-Shiras-Switchboard-TapWarn-example.pl line 71.<-- ):
	# 16:subroutine - Log::Shiras::TapWarn::re_route_warn | line - 0045 |
	# 17:	:(	No urgency level was defined in the 're_route_warn' method call so future warnings will be sent at: 11 (These go to 11) ):
	# 18:subroutine - Log::Shiras::TapWarn::re_route_warn | line - 0049 |
	# 19:	:(	You are currently attempting to Hijack warnings.
	# 20:		BEWARE, this will slow all warnings down!!!!
	# 21:		Going foward, all warnings will be routed through the switchboard to
	# 22:			the -quiet- report with an urgency level of -11-. ):
	# 23:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0067 |
	# 24:	:(	captured warning:
	# 25:		Watch Out World 2 at Log-Shiras-Switchboard-TapWarn-example.pl line 77. ):
	# 26:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0085 |
	# 27:	:(	The warning was sent to -buffer- destination(s) ):
	# 28:subroutine - Log::Shiras::Switchboard::get_operator | line - 0074 |
	# 29:	:(	Starting get operator
	# 30:		With updates to:
	# 31:		buffering ):
	# 32:subroutine - Log::Shiras::Switchboard::_flush_buffer | line - 0771 |
	# 33:	:(	There are messages to be flushed for: quiet ):
	# 34:--->watch out world 2 at log-shiras-switchboard-tapwarn-example.pl line 77.<---
	# 35:subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 36:	:(	Switchboard finished updating the following arguments: 
	# 37:		buffering ):
	# 38:subroutine - Log::Shiras::TapWarn::re_route_warn | line - 0049 |
	# 39:	:(	You are currently attempting to Hijack warnings.
	# 40:		BEWARE, this will slow all warnings down!!!!
	# 41:		Going foward, all warnings will be routed through the switchboard to
	# 42:			the -quiet- report with an urgency level of -debug-. ):
	# 43:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0067 |
	# 44:	:(	captured warning:
	# 45:		Watch Out World 3 at Log-Shiras-Switchboard-TapWarn-example.pl line 88. ):
	# 46:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0097 |
	# 47:	:(	Message blocked by the switchboard!
	# 48:		The destination -quiet- is UNBLOCKed but not to the -debug- level at the name space: main ):
	# 49:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0117 |
	# 50:	:(	Failover is blocked - no printing of:
	# 51:		-->Watch Out World 3 at Log-Shiras-Switchboard-TapWarn-example.pl line 88.<-- ):
	# 52:subroutine - Log::Shiras::TapWarn::re_route_warn | line - 0049 |
	# 53:	:(	You are currently attempting to Hijack warnings.
	# 54:		BEWARE, this will slow all warnings down!!!!
	# 55:		Going foward, all warnings will be routed through the switchboard to
	# 56:			the -loud- report with an urgency level of -info-. ):
	# 57:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0067 |
	# 58:	:(	captured warning:
	# 59:		Watch Out World 4 at Log-Shiras-Switchboard-TapWarn-example.pl line 94. ):
	# 60:!!!WATCH OUT WORLD 4 AT LOG-SHIRAS-SWITCHBOARD-TAPWARN-EXAMPLE.PL LINE 94.!!!
	# 61:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0085 |
	# 62:	:(	The warning was sent to -1- destination(s) ):
	# 63:subroutine - Log::Shiras::TapWarn::re_route_warn | line - 0049 |
	# 64:	:(	You are currently attempting to Hijack warnings.
	# 65:		BEWARE, this will slow all warnings down!!!!
	# 66:		Going foward, all warnings will be routed through the switchboard to
	# 67:			the -run- report with an urgency level of -warn-. ):
	# 68:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0067 |
	# 69:	:(	captured warning:
	# 70:		Watch Out World 5 at Log-Shiras-Switchboard-TapWarn-example.pl line 101. ):
	# 71:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0089 |
	# 72:	:(	Message approved by the switchboard but it found no outlet! ):
	# 73:subroutine - Log::Shiras::TapWarn::__ANON__ | line - 0117 |
	# 74:	:(	Failover is blocked - no printing of:
	# 75:		-->Watch Out World 5 at Log-Shiras-Switchboard-TapWarn-example.pl line 101.<-- ):
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

L<Log::Shiras::Switchboard|https://metacpan.org/module/Log::Shiras::Switchboard>

=back

=head1 SEE ALSO

=over

L<Capture::Tiny|https://metacpan.org/module/Capture::Tiny>

=cut

#########1#########2 <where> - main pod documentation end  6#########7#########8#########9