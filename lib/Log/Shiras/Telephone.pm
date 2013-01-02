package Log::Shiras::Telephone;

use version 0.94; our $VERSION = qv('0.001_003');
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;
}
if( $ENV{ Moose_Phone } ){
	use Moose;
}
use Carp qw( cluck confess );

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub talk{
	my ( $self, @passed ) = @_;
	my $x = 0;
	### <where> - check if the phone is turned off ...
	if( $self->{works} ){
		my 	$data_ref =
			(	exists $passed[0] and
				ref $passed[0] eq 'HASH' and
				exists $passed[0]->{message} ) ?
				$passed[0] :
			( 	@passed % 2 == 0 and
				( 	exists {@passed}->{message} or
					exists {@passed}->{level}		) ) ?
				{@passed} :
				{ message => [ @passed ] };
		### reached talk for: $data_ref
		$data_ref->{level_ref} = $self->{level_ref};
		### Needed - Level_ref, caller level, message, report - get approved reports
		$x = $self->{switchboard}->_attempt_to_report( $data_ref );
	}else{
		### <where> - the phone is out of (the) service (namespace) ...
	}
	return $x;
}

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _new{
	##### <where> - Starting a new telephone instance with the passed info: @_
	return bless $_[1], $_[0];
}

1;

#########1 Phinish            3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::Telephone - Used to call the Shiras logger

=head1 SYNOPSIS
    
This package is only meant to be used as an accessory to L<Log::Shiras::Switchboard>
    
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