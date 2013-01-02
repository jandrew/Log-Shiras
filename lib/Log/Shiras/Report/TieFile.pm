package Log::Shiras::Report::TieFile;

use Moose::Role;
use Tie::File;
use YAML::Any;
use Carp qw( confess );
use version 0.94; our $VERSION = qv('0.007_001');
use Fcntl qw( :flock );# SEEK_END 
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;
	### Smart-Comments turned on for Log-Shiras-Report-TieFile ...
}
use MooseX::Types::Moose
        qw(
            Bool
            ArrayRef
            FileHandle
            Object
        );
use lib '../../../../lib';##Change for Scite vs non Scite testing
use Log::Shiras::Types v0.013 qw(
        textfile
        headerstring
    );

###############  Public Attributes  ####################################

has 'filename' =>(
        is          => 'ro',
        isa         => textfile,
        writer      => 'set_filename',
        reader      => 'get_filename',
        predicate   => '_has_filename',
        required    => 1,
        trigger     => \&_process_filename,
        clearer     => '_clear_filename',
        # No default or builder is provided
        #   to ensure the trigger is always called
    );

has 'header' =>(
        is          => 'ro',
        isa         => headerstring,
        predicate   => 'has_header',
        reader      => 'get_header',
        writer      => 'set_header',
        clearer     => '_clear_header',
        coerce      => 1,
    );

###############  Public Methods / Modifiers  ##########################

sub file_exists{
    my ( $self ) = @_;
    ### <where> - Reached file_exists
    if( $self->_has_filename ){
        return -f $self->get_filename;
    } else {
        warn "No filename currently defined for testing!";
        return 0;
    }
}

###############  Private Attributes  ###################################

has '_newfile'  =>  (
                        is          => 'ro',
                        isa         => Bool,
                        reader      => 'is_newfile_state',
                        writer      => '_set_newfile_state',
                        default     => 1,
                    );

has '_filetie'  =>  (
                        is          => 'ro',
                        isa         => ArrayRef,
						traits		=> ['Array'],
                        writer      => '_load_filetie_ref',
                        reader      => '_get_filetie_ref',
                        handles => {
                            get_file_line       => 'get',
                            _set_line			=> 'set',
                            count_file_lines    => 'count',
                            _load_appender		=> 'push',
                            _unshift_output     => 'unshift',
                        },
                        predicate   => '_filetie_exists',
                        clearer     => '_clear_filetie',
                    );

###############  Private Methods / Modifiers  ##########################

sub _process_filename{
    my  $self       = shift;
    my  $filename   = shift;
    my  $oldfile    = shift;
    ### <where> - Reached _process_file_name
    #### <where> - Setting up the new filename : $filename
    #### <where> - The old filename is         : $oldfile
    if ( $oldfile and -f $oldfile ) {
        warn "Disconnecting: $oldfile";
    }
    #### <where> - Test (and remember) if the filename pre-existed as a file
    if ( -f $filename ) {
        #### <where> - pre-existing file
        $self->_set_newfile_state( 0 );
    } else {
        #### <where> - The file is new!
        $self->_set_newfile_state( 1 );
    }
    ### <where> - Opening file for use: $filename
    $self->_tie_to_file_name( $filename );
    return $filename;
}

sub _tie_to_file_name{
    my  $self       = shift;
    my  $filename   = shift;
    ### <where> - Reached method _tie_to_file_name for (attribute _filetie): $filename
	my	$file_ref;
	my  $o = tie @$file_ref, 'Tie::File', $filename;
    if( !$o ){
        ### file is locked!!!
        confess "Cannot open -$filename- because it is currently locked";
    } else {
        $o->flock;
        ### <where> - flock complete
    }
    $self->_load_filetie_ref( $file_ref );
    #### <where> - handle loading the header as needed
    $self->_test_for_new_header;
}

sub _test_for_new_header {
    my  $self   = shift;
    my  $header = $self->get_header;
    ### <where> - Reached method _test_for_new_header
    #### <where> - Potential new header: $header
    #### <where> - Testing file and attribute state
    if ( $self->count_file_lines > 0 ) {
        my  $firstline = $self->get_file_line( 0 );
        chomp $firstline;
        #### <where> - The file is not empty
        #### <where> - The first line is: $firstline
        if( $self->has_header ) {
            #### <where> - The header is    : $self->get_header
            if ($self->get_header eq $firstline ) {
                #### <where> - The existing file header matches the passed file header - no action
            } else {
                warn "There is already a header in place and it doesn't match - using pre-existing value";
                $self->set_header( $firstline );
            }
        } else {
            #### <where> - There is an ambiguous state with no header attribute
        }
    } else {
        #### <where> - The file is empty
        if( $self->has_header ) {
            #### <where> - Loading the header to the file
            ##### <where> - The current filetie object is: $self->_get_filetie_ref
            $self->_load_appender( $header );
        } else {
            #### <where> - No header to load to the file
        }
    }
    return 1;
}

sub disconnect_file{
    my ( $self ) = @_;
    ### <where> - Reached delete_filetie
    if( $self->_filetie_exists ){
        ### <where> - filetie found - unlocking and deleting
        my $tied_ref = $self->_get_filetie_ref;
		### <where> - filetie_array: $tied_ref
		untie @$tied_ref;
    }
	$self->_clear_filetie;
	$self->_clear_filename;
}

#################### Phinish with a Phlourish #######################

no Moose::Role;

1;
# The preceding line will help the module return a true value

#################### main pod documentation begin ###################

__END__

=head1 NAME

Parsing::Logger - Moose Role result logger with buffering

=head1 SYNOPSIS

    #! C:/Perl/bin/perl
    package MyPackage;

    use Moose;
    use Modern::Perl;#Suggested
    use MooseX::StrictConstructor;#Suggested
    use version 0.77; our $VERSION = qv('1.00');
    with    'Parsing::Logger'   => { -VERSION =>  0.03 },
            'Parsing::DateData' => { -VERSION =>  1.00 };

    has 'test_value' =>(
        is => 'rw',
    );

    no Moose;
    __PACKAGE__->meta->make_immutable;

    1;

    package main;
    use Modern::Perl;

    $| = 1;

    my  $firstfile  = 'Testonefile.txt';
    my  $secondfile = 'Testtwofile.txt';
    ### Cleanup
    unlink $firstfile if -f $firstfile;
    unlink $secondfile if -f $secondfile;
    my  $firstinst = MyPackage->new(
                filename            => $firstfile,
                Log4perlInitFile    => 'log.conf',
                test_value          => 'Remember ',
                date_one            => '9/11/2001' ,
        );
    say $firstinst->test_value;#1
    say $firstinst->get_date_one->ymd;#2
    say $firstinst->get_file_name;#3
    say $firstinst->count_file_lines;#4
    say $firstinst->file_is_empty;#5
    say $firstinst->change_file_name( $secondfile );#6
    unlink $firstfile if -f $firstfile;
    say $firstinst->get_file_name;#7
    $firstinst = undef;
    unlink $secondfile if -f $secondfile;
    my  $secondinst = MyPackage->new(    
                filename                    => $secondfile,
                bufferstate                 => 1,
                date_one                    => '9/11/2001',
                method_append_to_filename   => "get_date_one->ymd( '' )",
                format_string               => '%l10{find_yourself}S',
                header                      => 'The Doby Gillis Show!',
            );
    say $secondinst->get_file_name;#8
    say $secondinst->count_file_lines;#9
    $secondinst->add_line('Scooby', 'Dooby', 'Do');
    say $secondinst->count_file_lines;#10
    say $secondinst->count_buffer_lines;#11
    say $secondinst->send_buffer_to_file;#12
    say $secondinst->count_file_lines;#13
    say $secondinst->count_buffer_lines;#14
    map {say $_} ($secondinst->all_file_lines);#15
    ### Cleanup
    $secondfile = $secondinst->get_file_name;
    $secondinst = undef;
    say $secondfile;#16
    unlink $secondfile if -f $secondfile;

    sub find_yourself{
        return (join ' - ', @_) . ' ...Where are you?';
    }
        
    ###############################
    # Synopsis Screen Output
    # 1:  Remember 
    # 2:  2001-09-11
    # 3:  Testonefile.txt
    # 4:  0
    # 5:  1
    # 6:  Testtwofile.txt
    # 7:  Testtwofile.txt
    # 8:  Testtwofile_20010911.txt
    # 9:  1
    # 10: 1
    # 11: 1
    # 12: 2
    # 13: 0
    # 15 - 1: The Doby Gillis Show!
    # 15 - 2: Scooby - Dooby - Do ...Where are you?
    # 16: Testtwofile_20010911.txt
    ###############################
    
=head1 DESCRIPTION

This is a moose role for buffered result logging built on L<Tie::File>.  The there 
were several use cases that lead to the creation of this package over adopting 
L<Log::Log4perl>.

=over

=item B<First>, the Log4perl buffer doesn't allow for buffer clearance, meaning that 
I want to choose whether the buffer is loaded to the error file depending on branches 
in the code.  This allows for line logging as code persues a branch of investigation 
but then if the branch is later abandoned the logs for that branch can also 
be abandoned.  This also allows the L<Tie::File> print buffer to operate separate from 
the role buffer.  The L<Tie::File> buffer has some magic to optimize read-write operations 
that may not follow branch collection of data write timing.

=item B<Second>, the Log4perl module doesn't handle the header of files that are 
dropped and then reconnected in the way I would like.  Meaning I only want the header 
at the top of the file not at the beginning of each connection to a persistant file.

=item B<Third>, I wanted to provide some easy methods for accessing the file and buffer 
directly.  Mostly for testing purposes.  Moose Native Delegations 
L<Moose::Meta::Attribute::Native> combined with the direct accessors built into L<Tie::File> 
made it easier than falling off a bike so I added them.  This makes testing this role 
easier as well.

=item B<Fourth>, I wanted to be able roll method calls and subroutine references into the 
line formats.  I do this by adding the L<Parsing::Formatter> Role.  While the API isn't 
quite as mature as the Log::Log4perl 'PatternLayout' it does support full sprintf formatting.  
And since this is a Moose Role any package that has this role loaded can potentially call 
B<all> methods from that package added as potential calls for the formatting string 
automatically!

=back

With that said I still (for now) use log4perl as my runtime debuging logger 
(L<Parsing::Log4perlInit>) due to it's very mature appender and logrouting functions.  
It is also important to note that this logger is designed with the primary function of 
results collection not program tracking activities.  A subtle but important distinction 
that led to these different design priorities.  Ultimatly when the TODO list below is 
complete this program may be able to handle both event and results logging without 
Log4perl.  No disrespect intended it just makes sence to be a one stop shop.

B<Included Roles>

=over 

=item B<L<Parsing::Log4perlInit>>
    
This is B<(for now)> a Log4perl enabled module with the role (L<Parsing::Log4perlInit>)
added.  The method B<get_logger> is exported by default.  All run time comments and 
warnings are sent through Log4perl.  Please reveiw the L<Log::Log4perl> and 
L<Parsing::Log4perlInit> documentation for use of their features.  B<If you do 
not pass a log file to Log4perlInitFile in the initial I<new> or initialize Log4perl 
in other ways the logging built in will live and possibly die fairly silently.>  An 
example of a simple log.conf file can be found in the t/ folder.  The categories for 
this role follow the convention.

    'Parsing::Logger::' . 'the_method_name'

=item B<L<Parsing::Formatter>> 
    
This is a moose role that provides 'extended' sprintf like capabilities to the logger.  
I<a few elements of sprintf are not supported!>  A 'format_string' attribute is set 
and then when the 'add_line' method is called the format string is used to take the 
input array and build a string that is sent to the file or buffer.  See the Role POD 
for more details.

=back

=head2 Attributes

Data passed to ->new when creating an instance.  For modification of these attributes 
see L</Methods>

=head3 filename

=over

=item B<Definition:> this is the file name used for logging.  B<This attribute 
is likely to be changed by the 1.00 version to make way for I<possibly multiple> 
defined appender calls in -E<gt>new or a config file.>

=item B<Default> No default provided.  This attribute is required! B<(for now)>

=item B<Range> Defined by your file system

=back

=head3 method_append_to_filename

=over

=item B<Definition:> this is the name of the method result that will be 
appended to the file name when the file is created.  (a date from 
L<Parsing::DateData> for example)

=item B<Default> No default provided.  When this is blank the file name is not 
modified.

=item B<Range> Defined by the available methods active at the time when the file 
name is added

=back

=head3 header

=over

=item B<Definition:> this is the header string for your error file.  This will only 
be loaded when the file is first created.  B<The header string will be ignored if 
the file is pre-existing!>

=item B<Default> None.  The first row will contain data if the header is not called in ->new

=item B<Range> No Newlines (coerced out of the line with a regex turning midline returns 
into ' ' chomping them out at the end!)

=back

=head3 bufferstate

=over

=item B<Definition:> This is a boolean value that sets the buffer handling.  For true (1) 
all writes go to the buffer.  For false (0) all writes go straight to the file.  This behavior 
will likely change when a separate appender processes are written for v1.00.

=item B<Default> 1 - Data is buffered by default.

=item B<Range> 1|0

=back

=head3 format_string

=over

=item B<Definition:> This is the string used to format the output sent to the file by 'add_line' 

=item B<Default> undef - this passes the result of C<join ',', @_> when undef

=item B<Range> Most 'sprintf' formatting plus method and subroutine calls added by 
L<Parsing::Formatter>

=back

=head2 Methods

Methods are used to manipulate both the public and private attributes of this role.  
All attributes of this role are set as 'ro' so other than ->new(  ) these methods are
the only way to change, read, or clear attributes.  See the roles for role attribute 
selection methods.

=head3 change_file_name( 'filename' )

=over

=item B<Definition:> This will disconnect from the current file and connect to a new 
file.  The new file will receive the current header attribute value.

=item B<Accepts:> Any value that can be opened as a file.

=item B<Returns:> the new file name

=back

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