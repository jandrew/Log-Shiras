package Log::Shiras::Report;

use Moose;
use MooseX::StrictConstructor;
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;#'###', '####'
	### Smart-Comments turned on for Log-Shiras-Report ...
}
use version 0.94; our $VERSION = qv('0.007_001');
use Carp qw( cluck );
use MooseX::Types::Moose qw(
        Bool
		ArrayRef
		HashRef
		Str
		Object
    );
#~ use lib '../../../lib';
#~ use Log::Shiras::Switchboard;

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has or_print =>(
	is 		=> 'ro',
	isa 	=> Bool,
	default	=> 0,
	writer	=> 'set_or_print',
);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub add_line {
    my  ( $self, $first_ref, @list ) = @_;
	my  $message_ref;
    ### <where> - Reached add_line ...
	if( is_HashRef( $first_ref ) ){
		### <where> - Do nothing with hash ref: $first_ref
		$message_ref = $first_ref;
	}elsif( is_ArrayRef( $first_ref ) ){
		### <where> - Do nothing with array ref: $first_ref
		$message_ref->{message} = $first_ref;
	}elsif( is_Str( $first_ref ) ){
		$message_ref->{message} = [ $first_ref ];
	}
	push @{$message_ref->{message}}, @list if @list;
	### <where> - formatting data for: $message_ref
	my  $line;
	if( $self->can( '_use_formatter' ) ){
		#### <where> - Sending traffic to the formatter: $message_ref
		$line = $self->_use_formatter( $message_ref );
	}else{
		$line = join ',', @{$message_ref->{message}};
	}
	### <where> - acting on the line: $line
	if( $self->can( '_load_appender' ) ){
        #### <where> - an appender role is active - sending the line to the appender
        $self->_load_appender( $line );
    }elsif( $self->or_print ){
		### <where> - no appender or buffer active - printing line ...
		print STDOUT "$line\n";
	}
    return $line;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _switchboard_hook =>(
	is			=> 'ro',
	isa			=> 'Log::Shiras::Switchboard',
	writer		=> '_set_switchboard_hook',
	weak_ref	=> 1,
);
	


#########1 Private Methods    3#########4#########5#########6#########7#########8#########9
	

#~ sub DEMOLISH{
	#~ my ( $self, ) = @_;
	#~ my $meta = $self->meta;
	#~ ### $meta
	#~ ### <where> - Flush the buffers in DEMOLISH - TODO ...
#~ }

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable;

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::Report - Report base-class for Log::Shiras

=head1 SYNOPSIS

    #! C:/Perl/bin/perl
    
    use Modern::Perl;
    use Parsing::Logger::Appender v0.06;
    
    my  $testinst = Parsing::Logger::Appender->new();
    $testinst->add_line('foo','bar','baz');# Prints
    say $testinst->count_buffer_lines;
    $testinst->set_buffer_state( 1 );# Start buffering
    $testinst->add_line('foo','bar','baz');# Doesn't print
    say $testinst->count_buffer_lines;
    $testinst->add_line('Scooby','Dooby','Doo');# Doesn't print
    say $testinst->count_buffer_lines;
    say $testinst->get_buffer_line( 1 );# Show buffer
    say $testinst->get_buffer_line( 0 );# Show buffer
    $testinst->send_buffer_to_output;# Prints two lines
    say $testinst->count_buffer_lines;# Now it's empty
    $testinst->set_buffer_state( 0 );# Stop buffering
    $testinst->add_line('foo','bar','baz');# Prints one line
    say $testinst->count_buffer_lines;# Still empty
        
    ###############################
    # Synopsis Screen Output
    # 01: foo,bar,baz
    # 02: 0
    # 03: 1
    # 04: 2
    # 05: Scooby,Dooby,Doo
    # 06: foo,bar,baz
    # 07: foo,bar,baz
    # 08: Scooby,Dooby,Doo
    # 09: 0
    # 10: foo,bar,baz
    # 11: 0
    ###############################
    
=head1 DESCRIPTION

This is a Moose class for buffered result logging.  The goal is to create a class 
that can inherit various output and formatting roles that will be used to manage 
logging.  Since some of the formatting roles will want the location of the logged 
line available and the traffic management is done elsewhere this class will have 
attributes that can be loaded with logging source information called by the traffic 
management class.  This role also allows for buffer management so that logged data 
can be abandoned on a bad branch.

=head2 Attributes

Data passed to ->new when creating an instance.  For modification of these attributes 
see L</Methods>

=head3 name

=over

=item B<Definition:> This is the appender name.  The appender name is used to avoid 
confusion between multiple active loggers.  Appender managers can then call each appender 
by name.

=item B<Default> GENERIC

=item B<Range> cannot be debug, info, warn, or fatal (case insensitive)

=back

=head3 bufferstate

=over

=item B<Definition:> This sets the state of appender buffering.  If buffering is on the 
appender inputs go to the buffer.  If buffering is off then the inputs go straight to the 
defined appender output.

=item B<Default> 0 (off)

=item B<Range> this is a boolean variable

=back

=head3 loggerspace I<experimental>

=over

=item B<Definition:> This is an attribute that is set by TrafficControl to be used 
by any formatting roles.  It represents the loggerspace name defining where in the 
loggerspace the TrafficControl sent the message from.

=item B<Default> empty

=item B<Range> this is defined by the location type I<see L<Parsing::Types>>

=back

=head3 level I<experimental>

=over

=item B<Definition:> This is an attribute that is set by TrafficControl to be used 
by any formatting roles.  It represents the logging level of the message sent from 
TrafficControl.

=item B<Default> empty

=item B<Range> this is defined by the allloggerlevelname type I<see L<Parsing::Types>>

=back

=head3 file I<experimental>

=over

=item B<Definition:> This is an attribute that is set by TrafficControl to be used 
by any formatting roles.  It represents the file name of the Program that called 
TrafficControl.

=item B<Default> empty

=item B<Range> this is defined by the filename type I<see L<Parsing::Types>>

=back

=head3 package I<experimental>

=over

=item B<Definition:> This is an attribute that is set by TrafficControl to be used 
by any formatting roles.  It represents the module name of the program that called 
TrafficControl.

=item B<Default> empty

=item B<Range> this is defined by the location type I<see L<Parsing::Types>>

=back

=head3 location I<experimental>

=over

=item B<Definition:> This is an attribute that is set by TrafficControl to be used 
by any formatting roles.  It represents the full method name that called TrafficControl.

=item B<Default> empty

=item B<Range> this is defined by the location type I<see L<Parsing::Types>>

=back

=head3 line I<experimental>

=over

=item B<Definition:> This is an attribute that is set by TrafficControl to be used 
by any formatting roles.  It represents the line number where send_traffic was called.

=item B<Default> empty

=item B<Range> this is defined by the posInt type I<see L<Parsing::Types>>

=back

=head3 init_pointsman_file I<experimental>

=over

=item B<Definition:> This is an attribute that is set by TrafficControl to be used 
by any formatting roles.  It represents the file name where the TrafficControl instance 
was created (not where send_traffic was called against that instance).

=item B<Default> empty

=item B<Range> this is defined by the filename type I<see L<Parsing::Types>>

=back

=head3 init_pointsman_package I<experimental>

=over

=item B<Definition:> This is an attribute that is set by TrafficControl to be used 
by any formatting roles.  It represents the module name where the TrafficControl instance 
was created (not where send_traffic was called against that instance).

=item B<Default> empty

=item B<Range> this is defined by the location type I<see L<Parsing::Types>>

=back

=head3 init_pointsman_location I<experimental>

=over

=item B<Definition:> This is an attribute that is set by TrafficControl to be used 
by any formatting roles.  It represents the full method name where the TrafficControl 
instance was created (not where send_traffic was called against that instance).

=item B<Default> empty

=item B<Range> this is defined by the location type I<see L<Parsing::Types>>

=back

=head3 init_pointsman_line I<experimental>

=over

=item B<Definition:> This is an attribute that is set by TrafficControl to be used 
by any formatting roles.  It represents the line number where the TrafficControl 
instance was created (not where send_traffic was called against that instance).

=item B<Default> empty

=item B<Range> this is defined by the posInt type I<see L<Parsing::Types>>

=back

=head2 Methods

Methods are used to manipulate both the public and private attributes of this role.  
All attributes of this role are set as 'ro' so other than ->new(  ) these methods are
the only way to change, read, or clear attributes.

=head3 new( %attributes )

=over

=item B<Definition:> This will initialize a new instance of an appender.

=item B<Accepts:> a hash or hashref of L<attribute|/Attributes> calls

=item B<Returns:> a new appender instance.

=back

=head3 add_line( @input )

=over

=item B<Definition:> This will receive an array of information, format it, 
and then send it to the defined output.  The default formatting behavior is;

=over

=item $result = join ',', @input;

=back

the default output is to;

=over

=item print $result;

=back

By appending roles to this class you can manage much more complex formatting 
and output behaviors.  See L</Building Output Roles> and L</Building Formatter 
Roles>.  The easiest way to join this Class to new Rolls without writing a whole 
new class is to 'use' L<Moose::Util> qw( with_traits );

=item B<Accepts:> a list or array

=item B<Returns:> the formatted output string

=back

=head3 send_buffer_to_output()

=over

=item B<Definition:> This will send the complete appender buffer to the output 
line by line and then clear the buffer without turning buffering off.

=item B<Accepts:> Nothing

=item B<Returns:> 1

=back

=head3 set_buffer_state( $bool )

=over

=item B<Definition:> This will set appender buffering to off or on

=item B<Accepts:> a boolean value

=item B<Returns:> the resulting value of the attribute bufferstate

=back

 
        get_buffer_state
        all_buffer_lines
        get_buffer_line
        count_buffer_lines
        buffer_is_empty
        clear_buffer
        get_loggerspace
        set_loggerspace
        set_level
        get_level
        get_file
        set_file
        get_package
        set_package
        get_location
        set_location
        get_line
        set_line
        get_init_pointsman_file
        set_init_pointsman_file
        get_init_pointsman_package
        set_init_pointsman_package
        get_init_pointsman_location
        set_init_pointsman_location
        get_init_pointsman_line
        set_init_pointsman_line

=head3 get_file_name()

=over

=item B<returns> The currently active file name (from the attribute) that is being used

=back

=head3 is_newfile_state()

=over

=item B<returns> a boolean value showing if the current log file was just created.

=back

=head3 set_method_in_filename( 'methodname' )

=over

=item B<Definition:> This is the method name call for values auto appended to the 
passed file name.  ex. 'date_one'

=item B<Accepts:> any method attached to the package

=item B<Returns:> the method name

=back

=head3 get_method_in_filename()

=over

=item B<Definition:> This will retrieve the current method name used to append the 
filename.

=item B<Accepts:> Nothing

=item B<Returns:> the method name

=back

=head3 has_header()

=over

=item B<returns> a boolean value showing the existence of a (known) header.  Pre-existing 
headers will not be tracked.

=back

=head3 get_header()

=over

=item B<returns> the (known) header.  Pre-existing headers will not be tracked.

=back

=head3 set_header()

=over

=item B<Definition:> This is the way to change the header string prior to changing the 
file.  It is only useful for the next file.  B<It will not change a current file!>

=item B<Accepts:> A string without newlines. (any passed newlines will be coereced out)

=item B<returns> the header.

=back

=head3 set_buffer_state( boolean )

=over

=item B<Definition:> This is used to change the buffering state

=item B<Accepts:> 1|0

=item B<returns> the buffer state

=back

=head3 get_buffer_state()

=over

=item B<returns> a boolean value representing the current buffer state 
( 1 = buffered ).

=back

=head3 all_buffer_lines()

=over

=item B<returns> an array of all lines in the buffer.

=back

=head3 get_buffer_line( number )

=over

=item B<Definition:> This is used to retrieve specific buffer lines.   
B<Counting from 0!>

=item B<Accepts:> integers (negative numbers count back from the end)

=item B<returns> the string in the buffer line 'number'.

=back

=head3 count_buffer_lines()

=over

=item B<returns> a count of the stored lines in the buffer.

=back

=head3 send_buffer_to_file()

=over

=item B<Definition:> This is the method used to flush the buffer to the 
permanant file.

=item B<returns> 'normal exit'

=back

=head3 clear_buffer()

=over

=item B<Definition:> This is the method used to clear the buffer without 
sending the contents to the file.  Used for failed branches of code.

=item B<returns> 'normal exit'

=back

=head3 buffer_is_empty()

=over

=item B<returns> a boolean value indicating if there is content in the buffer. 
(1 = empty)

=back

=head3 add_line( ( list ) )

=over

=item B<Definition:> This is the way data is sent to the file.

=item B<Accepts:> an array or list with data to be formatted. see L</format_string>

=item B<returns> The processed string sent to the output

=back
##############################################################################
=item count_file_lines()

=over

=item B<returns> a count of the lines in the file.  (Including the header if it exists).

=back

=item get_file_line( number )

=over

=item B<returns> the value in the file line 'number' counting from 0.

=back

=item all_file_lines()

=over

=item B<returns> the whole file as an array.

=back

=item file_is_empty()

=over

=item B<returns> a boolean value indicating if there is content in the log file.

=back

=item file_exists()

=over

=item B<returns> a boolean value representing the file existance.

=back

=item get_logger( $Category )

=over

=item B<returns> a logger instance set to $Category.  For more information review 
L<Log::Log4perl|http://search.cpan.org/~mschilli/Log-Log4perl-1.32/lib/Log/Log4perl.pm#Categories>

=back

=item See L<Parsing::ExcelDates> and L<Parsing::Log4perlInit> for more possible methods

=over

=item B<Explanation:> Method (and modifier) documentation for these 
Roles is maintained in their documentation.

=back

=back

=head1 BUGS

Send them to my email directly (Currently I'm not on CPAN)

=head1 TODO

=head2 attributes

=over

=item Configuration file

=over

=item B<Explanation:> add the possiblity for setup with a configuration file.

=back

=back

=head2 methods

=over

=item ??

=back

=head2 method modifiers / Role?

=over

=item Formatting

=over

=item B<Explanation:>  It's not clear if this should be a modifier or a Role but 
the ability to format output including the addition of Meta data in the line.  
Some possiblities for meta data include dates, times, position, and names.

=back

=back

=head1 SUPPORT

Email me, I'm not on CPAN

=head1 AUTHOR

=over

=item Jed Lund

=item XIP

=item jlund@xip.net

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

=over

=item L<Moose>

=item L<Modern::Perl>

=item L<MooseX::StrictConstructor>

=item L<Moose::Util::TypeConstraints>

=item L<Tie::File>

=item L<YAML::Any>

=item L<version>

=item L<Parsing::ExcelDates>

=over

=item L<DateTime::Format::Excel>

=item L<DateTime::Format::DateManip>

=back

=item L<Parsing::Log4perlInit>

=over

=item L<Log::Log4perl>

=item L<Log::Log4perl::Level>

=back

=back

=cut

#################### main pod documentation end ###################