package Log::Shiras::Telephone;
use version; our $VERSION = qv("v0.21_3");
use 5.010;# defined or
use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(
		Bool
		ArrayRef
    );
#~ Moose::Exporter->setup_import_methods(
    #~ as_is => [ 'debug_line' ],#
#~ );
use lib '../../../lib',;
use Log::Shiras::Types qw(
		namespace
	);
BEGIN{
	use Log::Shiras::Switchboard;
}
my	$switchboard= Log::Shiras::Switchboard->instance;

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has 'name_space' =>(
	is		=> 'ro',
	isa		=> namespace,
	writer	=> 'set_name_space',
	default	=> sub{ 
		my $name_space = $switchboard->get_caller( 10 )->{up_sub};
		$switchboard->_internal_talk( { report => 'log_file', level => 3,######### Logging
			name_space => 'Log::Shiras::Telephone::name_space',
			message =>	[ "No name_space set so  Log::Shiras::Telephone will use: $name_space" ], } );
		return $name_space;
	},
	coerce	=> 1,
);

has 'fail_over' =>(
	is		=> 'ro',
	isa		=> Bool,
	writer	=> 'set_fail_over',
	default	=> sub{ 
		$switchboard->_internal_talk( { report => 'log_file', level => 3,######### Logging
			name_space => 'Log::Shiras::Telephone::fail_over',
			message => [ 'No fail_over attribute set so  Log::Shiras::Telephone will use: 0' ], } );
		return 0;
	},
);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub talk{
	my ( $self, @passed ) = @_;
	my 	$data_ref =
		(	exists $passed[0] and
			ref $passed[0] eq 'HASH' and
			exists $passed[0]->{message} ) ?
			$passed[0] :
		( 	@passed % 2 == 0 and
			( 	exists {@passed}->{message} or
				exists {@passed}->{ask}		) ) ?
			{@passed} :
			{ message => [ @passed ] };
	$data_ref->{message} //= '';
	my	$go_back = 0;
	return undef if !$switchboard;
	return undef if $switchboard->has_recursion_block;
	$switchboard->set_recursion_block( 1 );
	$switchboard->_internal_talk( { report => 'log_file', level => 0,######### Logging
		name_space => 'Log::Shiras::Telephone::talk',
		message => [ 'Arrived at Log::Shiras::Telephone::talk to say:', $data_ref->{message} ], } );
	if( !$data_ref->{report} ){
		$switchboard->_internal_talk( { report => 'log_file', level => 3,######### Logging
			name_space => 'Log::Shiras::Telephone::report',
			message =>	"No report destination was defined so the message will be sent to -log_file-", } );
		$data_ref->{report}	= 'log_file';
	}
	if( !$data_ref->{level} ){
		$switchboard->_internal_talk( { report => 'log_file', level => 3,######### Logging
			name_space => 'Log::Shiras::Telephone::level',
			message =>	"No urgency level was defined so the message will be sent at level -11- (These go to eleven)", } );
		$data_ref->{level}	= 11;
	}
	$data_ref->{name_space} = $self->name_space;
	$switchboard->_internal_talk( { report => 'log_file', level => 1,######### Logging
		name_space => 'Log::Shiras::Telephone::talk',
		message	=> [ "With urgency -$data_ref->{level}- to destination -" . 
			$data_ref->{report} . '- sending the message:', $data_ref->{message} ], } );
	my $x = 0;
	if(	$switchboard->_can_communicate( 
			$data_ref->{report}, $data_ref->{level}, $self->{name_space} ) ){
		$switchboard->_internal_talk( { report => 'log_file', level => 0,######### Logging
			name_space => 'Log::Shiras::Telephone::talk',
			message => [ 'Message cleared - sending it to the switchboard', $data_ref->{message} ]} );
		$x = $switchboard->_attempt_to_report( $data_ref );
		if( $x ){
			$switchboard->_internal_talk( { report => 'log_file', level => 2,######### Logging
				name_space => 'Log::Shiras::Telephone::talk',
				message => [ "The message was sent to -$x- destination(s)", ], } );
		}else{
			$go_back = 1;
			$switchboard->_internal_talk( { report => 'log_file', level => 3,######### Logging
				name_space => 'Log::Shiras::Telephone::talk',
				message => [ "Message approved by the switchboard but it found no outlet!" ], } );
		}
	}else{
		$go_back = 1;
		$switchboard->_internal_talk( {
			report => 'log_file', level	=> 3,
			name_space 	=> 'Log::Shiras::Telephone::talk',
			message	=>	[ 	"Message blocked by the switchboard!", 
							$switchboard->_last_error,  ],
		} );
	}
	if( $go_back ){
		my $ref = is_ArrayRef( $data_ref->{message} ) ?
					$data_ref->{message} : [ $data_ref->{message} ];
		if( $self->fail_over ){
			### <where> - failover back to STDOUT ...
			print STDOUT join( "\n\t", @$ref ) . "\n";
		}else{
			### <where> - sending warning for unprinted message ...
			my $message = "Failover is off and no reporting occured";
			if( $ref->[0] ){
				$ref->[0] = '-->' . $ref->[0];
				$ref->[-1] .= '<--';
				$message .= ' for:';
				$message = [ $message, $ref ];
			}
			$switchboard->_internal_talk( {
				report => 'log_file', level	=> 3,
				name_space 	=> 'Log::Shiras::Telephone::talk',
				message	=>	$message,	} );
		}
	}
	$switchboard->_internal_talk( { report => 'log_file', level => 0,######### Logging
		name_space => 'Log::Shiras::Telephone::talk', message => "The return value is: $x", } );
	$switchboard->set_recursion_block( 0 );
	return $x;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable(
	inline_constructor => 0,
);
	
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::Telephone - A connection to Log::Shiras::Switchboard
    
=head1 DESCRIPTION

L<Shiras|http://en.wikipedia.org/wiki/Moose#Subspecies> - A small subspecies of 
Moose found in the western United States (of America).
    
This module is only meant to be used as an accessory to L<Log::Shiras::Switchboard
|https://metacpan.org/module/Log::Shiras::Switchboard>. There are two methods in this 
class.  One, L<new|/new> to obtain a telephone.  During the new command telephone 
L<attributes|/Attributes> can be set.  Two, L<talk|/talk> to send messages through the 
switchboard to output destinations in L<reports
|https://metacpan.org/module/Log::Shiras::Report>.  For a high level overview of all the 
elements of this package review the L<Log::Shiras|https://metacpan.org/module/Log::Shiras> 
documentation.

All Telephone instances come pre-built with a connection to 
L<Log::Shiras::Switchboard|https://metacpan.org/module/Log::Shiras::Switchboard>.  
This allows the phone to place calls (or 'talk') to reports. Traffic permissions and 
handling are all managed by calls to the 'Switchboard' class.

=head2 Attributes

Data passed to ->new when creating an instance.  For modification of these attributes 
after the instance is created see L<Methods|/Methods>.

=head3 name_space

=over

B<Definition:> This attribute stores the specific point in the name-space used by the 
instance of this class.  The name-space is stored in a string where levels of the 
name-space in the string are marked with '::'.  If this attribute receives an array 
ref then it joins the elements of the array ref with '::'.

B<Default:> If no name-space is passed then this attribute defaults to the switchboard 
L<get_caller-E<gt>{subroutine}
|https://metacpan.org/module/Log::Shiras::Switchboard#get_caller-level> value retrieved 
where the ->new command is called.

=back

=head3 fail_over

=over

B<Definition:> This attribute stores a boolean value that acts as a switch to turn off or 
on an outlet to messages sent via ->talk that are not succesfully sent to at least one 
report instance.  If the outlet is on then the elements stored in the value for the key 
'message' passed to ->talk are printed to STDOUT.  (joined by "\n\t",) This is a helpfull 
feature when writing code containing the Telephone but you don't want to set up a 
switchboard to see what is going on.  You can managage a whole script by having a 
$fail_over variable at the top that is used to set each of the fail_over attributes for 
new telephones.  That way you can turn this on or off for the whole script at once if 
you want.

B<Default:> off = 0 no fail over printing

=back

=head1 Methods

=head2 new( %args )

=over

B<Definition:> This creates a new instance of the Telephone class.  It is used to talk 
to L<reports|https://metacpan.org/module/Log::Shiras::Switchboard#reports> through the 
switchboard.

B<Range:> This is a L<Moose|https://metacpan.org/module/Moose::Manual> class and new 
is managed by Moose.

B<Returns:> A phone instance that can be used to 'talk' to reports.

=back

=head2 talk( %args )

=head3 Definition

This is the method to place a call to a L<report
|https://metacpan.org/module/Log::Shiras::Report> name.  The talk command accepts 
strings, hashrefs, and fat comma lists.  First the phone will process the input into a 
hashref format.  Next, it will fill in any required missing key => value pairs as follows;

	{
		message => '',
		report	=> 'log_file',
		level	=> 11,#This is equivalent to the highest urgency
	}
	
Next, the phone will check if it has permissions to place a call with the specified report 
based on it's name-space and passed urgency level.  Finally, if it has permisisons, it will 
send the message for processing.  See the Log::Shiras::Switchboard attribute 
L<name_space_bounds|https://metacpan.org/module/Log::Shiras::Switchboard#name_space_bounds> 
for more information on blocked or unblocked calls.  I<Note: the switchboard will set the 
urgency level of a call to 0 if a level name is sent but it does not match the level list.>

=head3 Accepts

The following keys in a hash or hashref

=head4 report

This is the name of the destination report for the call.

=head4 level

This is a string indicating the level of the call being made.  It should 
match one of the L<defined
|https://metacpan.org/module/Log::Shiras::Switchboard#get_log_levels-report_name> levels 
for that report.  It also accepts integers 0 - 11.  Any level strings that do not match 
will be treated as being sent at level 0.  If the level matches fatal (=~/fatal/i) then 
the code will die after sending the message to the report.  However, if the level is sent 
as an integer equivalent to fatal then it will not die.

=head4 message

This is the data to be recorded in the report.  The value can be either 
a string or an array ref.  I suggest that this be an array ref of content only to allow 
for extensibility.  Formatting can be managed in the report instance definition.  

=head4 ask

This can be ommitted but if it is set to 1 then the Switchboard will ask for 
STDIN (command prompt) input prior to proceding and append the input to the message.

=head3 Returns

The number of times L<add_line|https://metacpan.org/module/Log::Shiras::Report#add_line-message_ref> 
was run by the switchboard. ( 0 if silent )

=head2 print_data( %args )

=over

B<Definition:> This is a wrapper for the print_data function in the L<Switchboard
|https://metacpan.org/module/Log::Shiras::Switchboard#print_data-ref>.

B<Range:> See the switchboard for a full definition - accepts a list of things to print.

B<Returns:> a string representation of the passed data

=back

=head1 Self Reporting

This logging package will L<self report
|https://metacpan.org/module/Log::Shiras::Switchboard#self_report>.  It is possible to turn on 
different levels of logging to trace the internal actions of the report.  All internal reporting 
is directed at the 'log_file' report.  In order to receive internal messages B<including 
warnings>, you need to set the 'self_report' attribute to 1 and then UNBLOCK the correct 
L<name_space|https://metacpan.org/module/Log::Shiras::Switchboard#name_space_bounds> for the 
targeted messages.  I determined which level each message should be sent them with integer 
equivalent urgencies to allow for possible renameing of log_file levels without causing this to 
break.  If you are concerned with availability of messages or dispatched urgency level please let 
L<me|/AUTHOR> know.

=head2 Listing of Internal Name Spaces

=over

=item Log

=over

=item Shiras

=over

=item Telephone

=over

=item name_space

=item level

=item report

=item fail_over

=item talk

=back

=back

=back

=back

=head1 SYNOPSIS

This is pretty long so I put it at the end
    
	#!perl
	use Log::Shiras::Switchboard;
	use Log::Shiras::Telephone;
	$| = 1;
	my $fail_over = 0;# Set fail_over here
	### <where> - lets get ready to rumble...
	my $telephone = Log::Shiras::Telephone->new( fail_over => $fail_over );
	$telephone->talk( message => 'Hello World 0' );
	### <where> - No printing here (the switchboard is not set up) ...
	my 	$operator = Log::Shiras::Switchboard->get_operator( 
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
				#~ Log =>{
					#~ Shiras =>{
						#~ Telephone =>{
							#~ UNBLOCK =>{
								#~ # UNBLOCKing the log_file report
								#~ # 	at Log::Shiras::Telephone and deeper
								#~ #	(self reporting)
								#~ log_file => 'info',
							#~ },
						#~ },
						#~ Switchboard =>{
							#~ get_operator =>{
								#~ UNBLOCK =>{
									#~ # UNBLOCKing log_file
									#~ # 	at Log::Shiras::Switchboard::get_operator
									#~ #	(self reporting)
									#~ log_file => 'info',
								#~ },
							#~ },
							#~ _flush_buffer =>{
								#~ UNBLOCK =>{
									#~ # UNBLOCKing log_file
									#~ # 	at Log::Shiras::Switchboard::_flush_buffer
									#~ #	(self reporting)
									#~ log_file => 'info',
								#~ },
							#~ },
						#~ },
					#~ },
				#~ },
			},
			#~ self_report => 1,# required to UNBLOCK log_file reporting in Log::Shiras
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
					$_[0]->{subroutine}, $_[0]->{line}, 
					join( "\n\t\t", @new_list ) 						);
	}
	1;
        
	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is -don't care- (off for speed)
	# 	the Log::Shiras::Telephone self reporting is BLOCKED
	# 	the Log::Shiras::Switchboard::get_operator self reporting is BLOCKED
	# 	the Log::Shiras::Switchboard::_flush_buffer self reporting is BLOCKED
	#	the fail_over attribute is NOT activated
	# 01: --->hello world 2<---
	# 02: !!!HELLO WORLD 4!!!
	#######################################################################################
			
	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is -don't care- (off for speed)
	# 	the Log::Shiras::Telephone self reporting is BLOCKED
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
	# 	the Log::Shiras::Telephone self reporting is UNBLOCKED to warn
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
	# 08: subroutine - Log::Shiras::Telephone::talk | line - 0065 |
	# 09: 	:(	No report destination was defined so the message will be sent to -log_file- ):
	# 10: subroutine - Log::Shiras::Telephone::talk | line - 0071 |
	# 11: 	:(	No urgency level was defined so the message will be sent at level -11- (These go to eleven) ):
	# 12: subroutine - Log::Shiras::Telephone::talk | line - 0100 |
	# 13: 	:(	Message blocked by the switchboard!
	# 14: 		Report -log_file- is NOT UNBLOCKed for the name-space: main ):
	# 15: Hello World 1
	# 16: subroutine - Log::Shiras::Telephone::talk | line - 0071 |
	# 17: 	:(	No urgency level was defined so the message will be sent at level -11- (These go to eleven) ):
	# 18: subroutine - Log::Shiras::Telephone::talk | line - 0088 |
	# 19: 	:(	The message was sent to -buffer- destination(s) ):
	# 20: subroutine - Log::Shiras::Switchboard::get_operator | line - 0074 |
	# 21: 	:(	Starting get operator
	# 22: 		With updates to:
	# 23: 		buffering ):
	# 24: subroutine - Log::Shiras::Switchboard::_flush_buffer | line - 0771 |
	# 25: 	:(	There are messages to be flushed for: quiet ):
	# 26: --->hello world 2<---
	# 27:subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 28:	:(	Switchboard finished updating the following arguments: 
	# 29:		buffering ):
	# 30: subroutine - Log::Shiras::Telephone::talk | line - 0100 |
	# 31: 	:(	Message blocked by the switchboard!
	# 32: 		The destination -quiet- is UNBLOCKed but not to the -debug- level at the name space: main ):
	# 33: Hello World 3
	# 34: !!!HELLO WORLD 4!!!
	# 35: subroutine - Log::Shiras::Telephone::talk | line - 0088 |
	# 36: 	:(	The message was sent to -1- destination(s) ):
	# 37: subroutine - Log::Shiras::Telephone::talk | line - 0094 |
	# 38: 	:(	Message approved by the switchboard but it found no outlet! ):
	# 39: Hello World 5
	#######################################################################################

	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is activated
	# 	the Log::Shiras::Telephone self reporting is UNBLOCKED to info
	# 	the Log::Shiras::Switchboard::get_operator self reporting is UNBLOCKED to info
	# 	the Log::Shiras::Switchboard::_flush_buffer self reporting is UNBLOCKED to info
	#	the fail_over attribute is NOT activated
	# 01: subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 02: 	:(	Switchboard finished updating the following arguments: 
	# 03: 		self_report
	# 04: 		buffering
	# 05: 		reports
	# 06: 		name_space_bounds ):
	# 07: subroutine - Log::Shiras::Telephone::talk | line - 0065 |
	# 08: 	:(	No report destination was defined so the message will be sent to -log_file- ):
	# 09: subroutine - Log::Shiras::Telephone::talk | line - 0071 |
	# 10: 	:(	No urgency level was defined so the message will be sent at level -11- (These go to eleven) ):
	# 11: subroutine - Log::Shiras::Telephone::talk | line - 0100 |
	# 12: 	:(	Message blocked by the switchboard!
	# 13: 		Report -log_file- is not UNBLOCKed for the name-space: main ):
	# 14: subroutine - Log::Shiras::Telephone::talk | line - 0117 |
	# 15: 	:(	Failover is off and no reporting occured for:
	# 16:		-->Hello World 1<-- ):
	# 17: subroutine - Log::Shiras::Telephone::talk | line - 0071 |
	# 18: 	:(	No urgency level was defined so the message will be sent at level -11- (These go to eleven) ):
	# 19: subroutine - Log::Shiras::Telephone::talk | line - 0088 |
	# 20: 	:(	The message was sent to -buffer- destination(s) ):
	# 21: subroutine - Log::Shiras::Switchboard::get_operator | line - 0074 |
	# 22: 	:(	Starting get operator
	# 23: 		With updates to:
	# 24: 		buffering ):
	# 25: subroutine - Log::Shiras::Switchboard::_flush_buffer | line - 07771 |
	# 26: 	:(	There are messages to be flushed for: quiet ):
	# 27: --->hello world 2<---
	# 28:subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 29:	:(	Switchboard finished updating the following arguments: 
	# 30:		buffering ):
	# 31: subroutine - Log::Shiras::Telephone::talk | line - 0100 |
	# 32: 	:(	Message blocked by the switchboard!
	# 33: 		The destination -quiet- is UNBLOCKed but not to the -debug- level at the name space: main ):
	# 34: subroutine - Log::Shiras::Telephone::talk | line - 0117 |
	# 35: 	:(	Failover is off and no reporting occured for:
	# 36: 		-->Hello World 3<-- ):
	# 37: !!!HELLO WORLD 4!!!
	# 38: subroutine - Log::Shiras::Telephone::talk | line - 0088 |
	# 39: 	:(	The message was sent to -1- destination(s) ):
	# 40: subroutine - Log::Shiras::Telephone::talk | line - 0094 |
	# 41: 	:(	Message approved by the switchboard but it found no outlet! ):
	# 42: subroutine - Log::Shiras::Telephone::talk | line - 0117 |
	# 43: 	:(	Failover is off and no reporting occured for:
	# 44: 		-->Hello World 5<-- ):
	#######################################################################################

=head2 SYNOPSIS EXPLANATION

=head3 my $telephone = Log::Shiras::Telephone->new( fail_over => $fail_over )

This obtains a 'Telephone' to send messages. It allows two L<attributes|/Attributes>
to be set.  The name_space attribute affects when the message is reported.  The 
fail_over attribute opens a path to STDOUT for all unreported ->talk messages.  This 
allows the talk output to be reviewed in development on the fly without setting up a 
switchboard to see the core message.  a suggestion is to set up a script with a 
$fail_over variable at the top used for all new telephones.  That way you can change 
$fail_over in one place and affect the whole script output between debugging and 
production with a small (1|0) change.

=head3 $telephone->talk( message => 'Hello World 0' )

This is a first attempt to send a message.  Since the switchboard is not set up yet all 
messages are blocked.  The only time something happens here is if the fail_over attribute 
is set in the previous step.  If it is on then 'Hello World' goes to STDOUT.  If failover 
is blocked even the warning messages will not be collected.

=head3 my $operator = Log::Shiras::Switchboard->get_operator( %args )

This uses the get_operator method to get an instance of the L<Log::Shiras::Switchboard
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
by a phone message.  The items in the array ref are report object instances.  For a 
pre-built class that only needs role modification review the documentation for 
L<Log::Shiras::Report|https://metacpan.org/module/Log::Shiras::Report>

=head4 buffering =>{ %args }

This sets the switchboard buffering state by report name.

=head3 $telephone->talk( report => 'quiet'

This is a third attempt to send a message (with the same phone).  This time the message 
is approved but it is buffered since the message was sent to a report name with buffering 
turned on.

=head3 my $other_operator = Log::Shiras::Switchboard->get_operator( buffering =>{ quiet => 0, }, )

This opens another operator instance and sets the 'quiet' buffering to off.  I<This 
overwrites the original operators setting of on.>  As a consequence the existing buffer 
contents are flushed to the report instance(s).

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

B<1.> Add self_report messages to the test file

B<2.> Add method to pull a caller($x) stack that can be triggered in the namespace 
boundaries.  Possibly this would be blocked on or off by talk() command (so only the 
first talk of the method would get it).

B<3.> Explain recursion flag in the POD

B<4.> hide internal reporting with source filters like UnhideDebug and then add a recursion flag

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

=head1 DEPENDENCIES

=over

L<Moose|https://metacpan.org/module/Moose>

L<MooseX::StrictConstructor|https://metacpan.org/module/MooseX::StrictConstructor>

L<MooseX::Types::Moose|https://metacpan.org/module/MooseX::Types::Moose>

L<version|https://metacpan.org/module/version>

L<5.010|http://perldoc.perl.org/perl5100delta.html> (for use of 
L<defined or|http://perldoc.perl.org/perlop.html#Logical-Defined-Or> //)

L<Log::Shiras::Switchboard|https://metacpan.org/module/Log::Shiras::Switchboard>

=back

=head1 SEE ALSO

=over

L<Log::Shiras::TapPrint|https://metacpan.org/module/Log::Shiras::TapPrint>

L<Log::Shiras::TapWarn|https://metacpan.org/module/Log::Shiras::TapWarn>

L<Log::Shiras::Report|https://metacpan.org/module/Log::Shiras::Report>

L<Log::Shiras|https://metacpan.org/module/Log::Shiras>

L<Log::Log4perl|https://metacpan.org/module/Log::Log4perl>

L<Log::Dispatch|https://metacpan.org/module/Log::Dispatch>

L<Log::Report|https://metacpan.org/module/Log::Report>

=back

=cut

#########1#########2 <where> - main pod documentation end  6#########7#########8#########9