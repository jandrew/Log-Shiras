package Test::Log::Shiras;
use version; our $VERSION = version->declare("v0.018.002");

use	Moose;
use MooseX::StrictConstructor;
use MooseX::NonMoose;
extends 'Test::Builder::Module';
use MooseX::Types::Moose qw(
        RegexpRef
		Bool
		ArrayRef
    );
use lib 	
		'../../../lib',
		'../lib';
use Log::Shiras::Switchboard 0.018;
use Log::Shiras::Types qw(
		posInt
	);

our	$last_buffer_position = 11;# This one goes to eleven :^|

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has 'last_buffer_position' =>(
	is 		=> 'ro',
	isa		=> posInt,
	default	=> sub{ $last_buffer_position },#
	writer	=> 'change_test_buffer_size',
	trigger => \&_set_buffer_size,
);

has 'keep_matches' =>(
    is      => 'ro',
    isa     => Bool,
    default => 0,
    writer  => 'set_match_retention',
);


#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub get_buffer{
	my ( $self, $report_name ) = @_;
	### <where> - getting the buffer for: $report_name
	my	$buffer_ref = [];
	if( $self->_get_switchboard()->_has_test_buffer( $report_name ) ){
		$buffer_ref = $self->_get_switchboard()->_get_test_buffer( $report_name );
	}
	### <where> - returning: $buffer_ref
	return $buffer_ref;
}

#########1 Test Methods       3#########4#########5#########6#########7#########8#########9

sub clear_buffer{
    my ( $self, $report_name, $test_description ) = @_;
    ### <where> - Reached clear_buffer for  : $report_name
	$self->_get_switchboard()->_set_test_buffer( $report_name => [] );
    my  $tb = __PACKAGE__->builder;
    $tb->ok( 1, $test_description);#always passes
}

sub has_buffer{
    my ( $self, $report_name, $test_description ) = @_;
    ### <where> - reached has_buffer for: $report_name
    $self->_check_buffer( $report_name, 1, $test_description );
}

sub no_buffer{
    my ( $self, $report_name, $test_description ) = @_;
    ### <where> - reached no_buffer for: $report_name
    $self->_check_buffer( $report_name, 0, $test_description );
}

sub buffer_count{
    my ( $self, $guess, $report_name, $test_description ) = @_;
    ### <where> - testing the row count loaded in the buffer ...
    ### <where> - Reached for   : $report_name
    ### <where> - Guess         : $guess
    my  $actual_count = scalar( @{$self->get_buffer( $report_name )} );
    my  $tb     = __PACKAGE__->builder;
    $tb->ok($actual_count == $guess, $test_description);
    if( $actual_count != $guess ){
        $tb->diag( "Expected -$guess- items but found -$actual_count- items" );
    }
}

sub match_message{
    my ( $self, $report_name, $line, $test_description ) = @_;
    chomp $line;
    ###  <where> - Reached match_output
    ####  <where> - The report name passed is  : $report_name
    ####  <where> - The line passed is         : $line
    ####  <where> - The test explanation is    : $test_description
    my  $result = 0;
    my  $i      = 0;
    my  @failarray;
    ### <where> - checking if the buffer exists
    if( $self->_get_switchboard()->_has_test_buffer( $report_name ) ){
        ####  <where> - The buffer exists! ...
        my @buffer_list = @{$self->_get_switchboard()->_get_test_buffer( $report_name )};
        #### <where> - The buffer list is: @buffer_list
        @failarray = (
            'Expected to find: ',  $line,
            "but could not match it to data in -$report_name-..."
        );
        if( !@buffer_list ){
            ### <where> - The buffer list is EMPTY!
            push @failarray, 'Because the test buffer is EMPTY!';
        }else{
            TESTALL: for my $buffer_line ( @buffer_list ){
				$buffer_line = $buffer_line->{message};
                ### <where> - testing line: $buffer_line
				if( is_ArrayRef( $buffer_line ) ){
					### <where> - do nonthing ...
				}else{
					$buffer_line = [ $buffer_line ];
				}
				for my $ref_element ( @$buffer_line ){
					if( (	is_RegexpRef( $line ) and 
							$ref_element =~ $line		) or
						( $ref_element eq $line )           ){
						#### <where> - found a match!
						$result = 1;
						last TESTALL;
					}else{
						#### <where> - no match here!
						push @failarray, "---$ref_element";
						$i++;
					}
				}
            }
        }
        ### <where> - the match test result: $result
        if( !$self->keep_matches and $result ){
            ### <where> - splicing out match
            splice( @buffer_list, $i, 1);
            ### <where> - Reloading the buffer ...
            $self->_get_switchboard()->_set_test_buffer( $report_name => [@buffer_list] );
            ### <where> - splice propagated to the buffer
        }
    } else {
        ####  <where> - The test buffer does not contain the source: $report_name
        @failarray = ( "Because the test buffer is not active for: $report_name" );
    }
    ### <where> - passing results to Test_Builder
    my  $tb = __PACKAGE__->builder;
    $tb->ok($result, $test_description);
    if( !$result ) {
        map{ $tb->diag( $_ ) } @failarray;
        return 0;
    }		
	
}

sub cant_match_message{
    my ( $self, $report_name, $line, $test_description ) = @_;
    ###  <where> - Reached cant_match_output
    ####  <where> - The report name passed is  : $report_name
    ####  <where> - The line passed is         : $line
    ####  <where> - The test explanation is    : $test_description
    my  $result = 1;
    my  $tb     = __PACKAGE__->builder;
    my  $i      = 0;
    my  @failarray;
    ### <where> - checking if the buffer exists
    if( $self->_get_switchboard()->_has_test_buffer( $report_name ) ){
        ####  <where> - The buffer exists! ...
        my @buffer_list = @{$self->_get_switchboard()->_get_test_buffer( $report_name )};
        #### <where> - The buffer list is: @buffer_list
        TESTMISS: for my $test_line ( @buffer_list) {
			if( is_ArrayRef( $test_line ) ){
				### <where> - do nonthing ...
			}else{
				$test_line = [ $test_line ];
			}
			for my $line_element ( @$test_line ){
				if( is_RegexpRef( $line ) and $line_element =~ $line ){
					####  <where> - Found a regular expression match to: $line
					$result = 0;
					push @failarray, (
							"For the -$report_name- buffer a no match condition was desired",
							"for the for the regex -$line-",
							"a match was found at position -$i-",
							"(The line was not removed from the buffer!)"
						);
					last;
				} elsif ( $line_element eq $line ) {
					####  <where> - Found a match to: $line
					$result = 0;
					push @failarray, (
							"For the -$report_name- buffer a no match condition was desired",
							"for the string -$line-",
							"a match was found at position -$i-",
							"(The line was not removed from the buffer!)"
						);
					last;
				} else {
					$i++;
					####  <where> - No match for: $line_element
				}
			}
        }
        if( $result ) {
            ####  <where> - Test buffer exists but the line was not found in: $report_name
        }
    } else {
        ####  <where> - Pass! no buffer found ...
    }
    $tb->ok($result, $test_description);
    if( !$result ) {
        map{ $tb->diag( $_ ) } @failarray;
    }
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has '_switchboard_link' =>(# Connect to the singlton
    is		=> 'ro',
	isa		=> 'Log::Shiras::Switchboard',
	reader	=> '_get_switchboard',
	default	=> sub{ get_operator(); },
);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

after 'change_test_buffer_size' => \&_set_buffer_size;

sub _set_buffer_size{
	my ( $self, $new_size ) = @_;
	### <where> - setting the new test buffer size to: $new_size
	$last_buffer_position = $new_size;
}

sub _check_buffer{
    my ( $self, $report_name, $expected, $test_description ) = @_;
    ### <where> - Reached _check_buffer for : $report_name
    ### <where> - test description          : $test_description
	my 	$result = $self->_get_switchboard()->_has_test_buffer( $report_name );
    ### <where> - resulting in: $result
    my  $tb     = __PACKAGE__->builder;
    $tb->ok( $result == $expected, $test_description);
    if( $result != $expected ){
        if( !$result ){
            $tb->diag( "Expected to find a buffer for -$report_name- but it didn't exist" );
        }else{
            $tb->diag( "A buffer for -$report_name- was un-expectedly found" );
        }
    }
}

sub DEMOLISH{
	my ( $self, ) = @_;
	### <where> - clearing ALL the test buffers
	$self->_get_switchboard()->_clear_all_test_buffers;
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable(
	inline_constructor => 0,
);

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Test::Log::Shiras - Used to test traffic handled by Log::Shiras

=head1 SYNOPSIS
    

    
=head1 DESCRIPTION

This is the object sent from L<Log::Shiras::Switchboard> to be used to communicate with 
the  reports. It has two other troubleshooting methods which can be used when running 
in debug or max reporting mode.

=head1 Methods

Methods are used to place calls on the Telephone instance by interacting with the Switchboard.  
When a method is executed the namespace and level of the call along with the report destination 
will be tested to see if a connection can be made.  The methods will then perform their function 
if a connection is available.  Otherwize the methods return 0;

=head2 talk( %args )

=over

=item B<Definition:> This is the method to place a call to a report.  The arguments include 
the message, the level the call should be placed at, and the report the call should be placed to.  
If the call is successful the switchboard will return an array ref of reports coinciding with the 
call.  The telephone will run the following sequence for the array reference.
	
	my $x = 0;
	for my $target ( @report_list ){
		$target->add_line( $args{message} );
		$x++;
	}

I<The method only works if the telephone is inside the defined name space!>

=item B<Accepts:> the following keys in a hash or hashref

=over

=item B<report> =E<gt> This is the name of the destination report for the call.

=item B<level> =E<gt> This is a string indicating the level of the call being made.  It should match 
either one of the items in the pre-defined level array for the defined report or match an item 
the default level array.

=item B<message> =E<gt> This is the data to be recorded in the report.  I suggest that this be an 
ArrayRef of content only.  All formatting is better managed in the report definition.

=item B<ask> =E<gt> This can be ommitted but if it is set to 1 then the progam will ask for STDIN 
input prior to proceding.

=item B<dont_report> =E<gt> This can be ommitted but if it is set to 1 then the progam will not send 
'message' to the report even if it othewise would.  This really only makes sence for an ask =E<gt> 1 
scenario or a 'fatal' level.

=back

=item B<Returns:> The number of add_line methods run. ( 0 if silent ) See L<Log::Shiras::Report> 
for more information.

=back

=head2 GLOBAL VARIABLES

=over

=item B<$ENV{Smart_Comments}>

The module uses L<Smart::Comments> if the '-ENV' option is set.  The 'use' is 
encapsulated in a BEGIN block triggered by the environmental variable to comfort 
non-believers.  Setting the variable $ENV{Smart_Comments} will load and turn 
on smart comment reporting.  There are three levels of 'Smartness' available 
in this module '### #### #####'.

=item B<$ENV{Moose_Phone}>

The module doesn't need L<Moose> so it is not loaded by default but if you want Moose 
tricks to be used on the phone then this will turn the Class into a Moose Class.

=back

=head1 SUPPORT

=over

=item L<github Log-Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 TODO

=over

=item * other possible namespace triggered methods?

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

=head1 DEPENDANCIES

=over

=item L<Log::Shiras::Switchboard>

=item L<Carp>

=back

=head1 SEE ALSO

=over

=item L<Log::Log4perl>

=item L<Log::Dispatch>

=item L<Log::Report>

=item L<Moose>

=item L<Smart::Comments>

=cut

#################### <where> - main pod documentation end ###################