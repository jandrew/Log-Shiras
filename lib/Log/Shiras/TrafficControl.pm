package Log::Shiras::TrafficControl;#used to create $instance for get_pointsman

use Moose;# This is not a role so lots of unique instances can be created in the code
use MooseX::StrictConstructor;
#~ use Smart::Comments '###', '####';#
### Smart-Comments turned on for Log-Shiras-TrafficControl and Silent
### Smart-Comments required to debug since there are recursion issues otherwise
use version 0.94; our $VERSION = qv('0.007_001');
#~ use Hash::Merge qw( merge );
use MooseX::Types::Moose qw(
		HashRef
	);
use Moose::Exporter;
Moose::Exporter->setup_import_methods(
    as_is => [ 'get_pointsman' ],#
);
use lib '../../../lib';##Change for Scite vs non Scite testing
use Log::Shiras::Types v0.11 qw(
		location
		filename
		posInt
		runloggerlevelname
		allloggerlevelname
		loggerlevelint
		loggerspaceref
	);
#~ use Parsing::HashRef v0.01;

################################  Public Attributes ################################

has 'loggerspace' =>(
        is      => 'ro',
        isa     => location,
        writer  => 'set_loggerspace',
        reader  => 'get_loggerspace',
    );

has 'levelref' =>(
        is      => 'ro',
        isa     => HashRef,
        writer  => 'set_levelref',
        reader  => 'get_levelref',
    );

has 'init_pointsman_file' =>(
        is      => 'ro',
        isa     => filename,
        reader  => 'get_init_pointsman_file',
        writer  => 'set_init_pointsman_file',
    );

has 'init_pointsman_package' =>(
        is          => 'ro',
        isa         => location,
        writer      => 'set_init_pointsman_package',
        reader      => 'get_init_pointsman_package',
    );

has 'init_pointsman_location' =>(
        is          => 'ro',
        isa         => location,
        writer      => 'set_init_pointsman_location',
        reader      => 'get_init_pointsman_location',
    );

has 'init_pointsman_line' =>(
        is          => 'ro',
        isa         => posInt,
        writer      => 'set_init_pointsman_line',
        reader      => 'get_init_pointsman_line',
    );

##############  Public Methods  ####################################

sub get_pointsman{### deputyandy
    my ( $loggerspace ) = @_;
    ###  <where> - Reached TrafficControl-get_pointsman
    ####  <where> - Different loggerspace defined: $loggerspace
      my ( 
        $package, $filename, $line,
    )   = (caller( 0 ))[0,1,2];
    ####  <where> - Caller 0 package is    : $package
    ####  <where> - Caller 0 filename is   : $filename
    ####  <where> - Caller 0 line is       : $line
    my  $subroutine     = 
            ( (caller( 1 ))[3] and (caller( 1 ))[3] !~ /^Test/ ) ?### Ignore test modules as calling methods for location
                (caller( 1 ))[3] : $package ;#Other values available
    my  $nextlocation   =
        ( $loggerspace ) ?  $loggerspace :
        ( $subroutine ) ?   $subroutine :
                            $package ;
    $nextlocation =~ s/\./::/g;
    my  $levelref = _collect_logger_levels( to_loggerspaceref( $nextlocation ) );
    ####  <where> - Calling location is        : $subroutine
    ####  <where> - Calculated loggerspace is  : $nextlocation
    ####  <where> - the calling location processes to: $levelref
    my  $pointsman;
    if( $levelref ) {
        ###  <where> - There is a reason to call for a pointsman from Traffic Control
        $pointsman = Log::Shiras::TrafficControl->new(
                loggerspace             => $nextlocation,
                levelref                => $levelref,
                init_pointsman_file     => $filename,
                init_pointsman_package  => $package,
                init_pointsman_line     => $line,
                init_pointsman_location => $subroutine,
            );
    } else {
        ###  <where> - There is NO reason to call for a pointsman from Traffic Control
        $pointsman = Silent->new();
    }
    ####  <where> - The final pointsman result is: $pointsman
    return $pointsman;
}

sub send_traffic{
    my ( $self, $appender, @passeddata ) = @_;
    my ( $calledlevel ) = ( 0 );
    ###  <where> - Reached /TrafficControl/ traffic ($send->traffic( 'appender', 'Some message' ))
    ####  <where> - The appender is: $appender
    ####  <where> - The passed data for formatting is: @passeddata
    Silent::_exclude_run( $appender );
    ####  <where> - Check if a runlogger level is called
    if( is_runloggerlevelname( $appender ) ){
        ####  <where> - Identified a run logger call for level: $appender
        $calledlevel    = to_loggerlevelint( $appender );
        $appender       = 'run';
        ####  <where> - Then new appender is: $appender
    } else {
        ####  <where> - The called appender is not a run logger
    }
    ####  <where> - The called level is (now): $calledlevel
    ####  <where> - TODO add a real time update to the stored logger state when a flag is set
    ####  <where> - Checking if there is an active appender for: $appender
    my $outputline = 0;
    if( exists $self->get_levelref->{$appender} ) {
        ####  <where> - There is an appender for: $appender
        ####  <where> - Check if the called level is greater than or equal to the approved config level: $self->get_levelref->{$appender}
        if( $self->get_levelref->{$appender} <= $calledlevel ) {
            ### <where> - All checks cleared - Now logging
            #### <where> - Call the appender instance from the global namespace
            my  $appenderinst = $Log::Shiras::currentlogger->{'appenders'}->{$appender};
            ####  <where> - TODO check for formatter calls for information and only provide needed data
            my ( 
                $package, $filename, $line,
            )   = (caller( 0 ))[0,1,2];
            my  $location     = 
                    ( (caller( 1 ))[3] and (caller( 1 ))[3] !~ /^Test/ ) ?### Ignore test subroutines as calling methods for location
                        (caller( 1 ))[3] :
                        $package ;#Other values available
            #### <where> - traffic package : $package
            #### <where> - traffic filename: $filename
            #### <where> - traffic line    : $line
            #### <where> - traffic location: $location
            #### <where> - Level name      : to_allloggerlevelname( $calledlevel )
            ### <where> - send the data to the appender
            $appenderinst->set_loggerspace( $self->get_loggerspace );
            $appenderinst->set_level( to_allloggerlevelname( $calledlevel ) );
            $appenderinst->set_file( $filename );
            $appenderinst->set_package( $package );
            $appenderinst->set_location( $location );
            $appenderinst->set_line( $line );
            $appenderinst->set_init_pointsman_file( $self->get_init_pointsman_file );
            $appenderinst->set_init_pointsman_package( $self->get_init_pointsman_package );
            $appenderinst->set_init_pointsman_location( $self->get_init_pointsman_location );
            $appenderinst->set_init_pointsman_line( $self->get_init_pointsman_line );
            ##### <where> - The updated appender is: $appender
            $outputline = $appenderinst->add_line( @passeddata );
            ### <where> - Sending the output: $outputline
            die $outputline if $calledlevel == 4; 
        }
    }
    if( $calledlevel == 4 ){
        ### <where> - The logger is silent but die still needs to be called
        die join ', ', ( ( $outputline ) ? $outputline : @passeddata );
    }
    return $outputline;
}

##############  Private Methods  ####################################

sub _collect_logger_levels{### Quiet (no logging) to avoid recursion
    my ( $locationref, $loggerbounds, $levelref ) = @_;
    ### <where> - Reached _collect_logger_levels
    #### <where> - The passed location ref is  : $locationref
    #### <where> - The passed loggerbounds are : $loggerbounds
    #### <where> - The passed levelref is      : $levelref
    #### <where> - The global logger values are: $Log::Shiras::currentlogger
    $loggerbounds //= $Log::Shiras::currentlogger->{'loggers'};
    #### <where> - Updated loggerbounds are: $loggerbounds
    if( exists $loggerbounds->{'LOGGER'} ) {
        #### <where> - Found logger at this level
        $levelref = merge( $loggerbounds->{'LOGGER'}, $levelref );
        #### <where> - The function result of merge: %{ merge( $levelref, $loggerbounds->{'LOGGER'} ) }
        #### <where> - The resulting levelref of the merged values: $levelref
    } else {
        #### <where> - No LOGGER at this level
    }
    my  $nextkey  = shift @$locationref;
    #### <where> - Checking the next level: $nextkey
    if( !$nextkey ){
        #### <where> - No additional levels to check!
    }elsif( exists $loggerbounds->{$nextkey} ){
        #### <where> - Another level exists to check: $nextkey
        $levelref = _collect_logger_levels( $locationref, $loggerbounds->{$nextkey}, $levelref );
    }else{
        #### <where> - Cant match the established logging boundaries to: $nextkey
    }
    ### <where> - Returning levelref: $levelref
    return $levelref;
}
    

#################### Phinish with a Phlourish ######################

no Moose;
__PACKAGE__->meta->make_immutable;

#################### a brand new (non-Moose) package ###############

### Silent - A lightweight (non-Moose) package to return when logging is off
package Silent;
use lib '../../../lib';##Change for Scite vs non Scite testing
use Log::Shiras::Types v0.11 qw(
        runstring
    );

sub new{ 
    ### <where> - Starting Silent with new
    return bless{}; 
};

sub send_traffic{
    my ( $self, $appender, @passeddata ) = @_;
    ### <where> - Reached /Silent/ traffic (->send_traffic( 'appender', 'Some message' ))
    #### <where> - Calling appender: $appender
    _exclude_run( $appender );
    if( $appender =~ /fatal/i ) {
        #### <where> - fatal appender found (and handled)
        die join ', ', @passeddata;
    } else {
        #### <where> - No logging of: @passeddata
        return 0;
    }
}

sub _exclude_run{
    my ( $appendername ) = @_;
    ###  <where> - Reached _exclude_run test for: $appendername
    if( is_runstring( $appendername ) ){
        die 'send_traffic( ' . 
            "'$appendername', 'Some message' ) failed because -run- " .
            'is not allowed as a direct call.  It must be inferred ' .
            'from a -run- appender level call';
    } else {
        ###  <where> - called appender approved
        return 1;
    }
}

1;
# The preceding line will help the package return a true value

#################### main pod documentation begin ##################

__END__

=head1 NAME

Log::Shiras::TrafficControl - Log::Shiras output direction handling

=head1 SYNOPSIS

    ### This is a Moose::Role !!!!! 
    ####! C:/Perl/bin/perl
    package MyPackage;

    use Moose;
    use Modern::Perl;#Suggested
    use MooseX::StrictConstructor;#Suggested
    use version 0.77; our $VERSION = qv('1.00');
    use lib '../lib';# As needed
    with    'Parsing::Formatter'    => { -VERSION =>  1.00 },
            'Parsing::DateData'     => { -VERSION =>  1.00 };

    has 'test_value' =>(
        is => 'rw',
    );

    no Moose;
    __PACKAGE__->meta->make_immutable;

    1;

    package main;
    use Modern::Perl;
    
    my  $firstinst = MyPackage->new(  
            test_value  => 'Remember ',
            date_one    => '9/11/2001' 
        );
    say $firstinst->test_value;#1
    $firstinst->set_format_string( '%%%2$d %1$d %5$d %d %3$d' );
    say $firstinst->output_string( 12,34,1,2,3);#2
    $firstinst->set_format_string( '%%%i0{test_value}M%i0{get_date_one->ymd}M%%' );
    say $firstinst->output_string();#3
    $firstinst->test_value( 'Always Remember ' );
    say $firstinst->output_string();#4
    $firstinst->set_format_string( '%%%-20i0{test_value}M%%' );
    say $firstinst->output_string();#5
    $firstinst->set_format_string( '%%%-.5i0{test_value}M%%' );
    say $firstinst->output_string();#6
    $firstinst->set_format_string( '%%%-*.*i*{test_value}M%%' );
    say $firstinst->output_string(20,5,0);#7
    $firstinst->set_format_string( '%%%-.*i*{test_value}M%%' ),;
    say $firstinst->output_string(6);#8
    $firstinst->set_format_string( '%%%-*.*l*{get_date_one->ymd}M%%' );
    say $firstinst->output_string( 20, 7, 1, "/" );#9
    $firstinst->set_format_string( '%%%l*{super_size_sub}S%%' );
    say $firstinst->output_string( 2, 'pooper', 'scooper' );#10
    $firstinst->set_format_string( '#%d %l*{main::super_size_sub}S%s' );
    say $firstinst->output_string( 1, 1, 'paratrooper', '<-------' );#11
    $firstinst->clear_format_string;
    say $firstinst->output_string( '%Polly picked a peck of pickeled peppers%' ); #12

    sub super_size_sub{
        return ('Super duper ' . join ' ', @_);
    }
    
    ###  Output  #######
    # 1: Remember 
    # 2: %34 12 3 12 1
    # 3: %Remember 2001-09-11%
    # 4: %Always Remember 2001-09-11%
    # 5: %Always Remember     %
    # 6: %Alway%
    # 7: %Alway               %
    # 8: %Always%
    # 9: %2001/09             %
    # 10: %Super duper pooper scooper%
    # 11: #1 Super duper paratrooper<-------
    # 12: %Polly picked a peck of pickeled peppers%
    ####################

=head1 DESCRIPTION

This is a moose role that provides 'extended' sprintf like capabilities.  I<Some 
elements of sprintf are not supported!>  A 'format_string' attribute is set 
and then the 'output_string' method is used to accept an array or list and 
return a formatted string from the format previously provided.  The goal is to 
stay reasonably true to the sprintf format and leverage sprintf as much as 
possible.  If the format string that is passed is pure sprintf using the 
supported elements of sprintf then the output will effectively call sprintf 
directly on the array with the previously validated string.  

When one of the extended sprintf-like formats are called then the format string 
will be broken in the sprintf and non sprintf segments.  Each sprintf segment will have 
boundaries based on expected input counts.  The non-sprintf formatting segments will 
also have the boundaries tested but will have additional information linked to the segment 
in order to provide the correct output.  The output_string method will then build each 
segment and concatenate the results with a '.' join.  The goal is to build as much of the 
parsing into the 'format_string' method so that the 'output_string' just calls sprintif, 
concatenates '.', and any realtime method or subroutine calls needed.

=head2 sprintf elements not supported

=head3 size (the size of the number in memory)

(l , h , V , q, L , or ll) modifiers for numbers
  
B<IMPORTANT> 
    
This is a Log4perl enabled module.  All comments and warnings are
sent through Log4perl.  Please reveiw Log4perl documentation for use of this
feature.  If you do not create a logger instance the role will live and die
fairly silently.  An example of a simple log.conf file can be found in the
t/ folder.  All Log4perl loggers for this role are called by;

    __PACKAGE__ . '::method_name';

=head2 Attributes

=head3 format_string

=over

=item B<Definition:> this is a string that accepts sprintf formats as well 
as the new sprintf-like formats added with this Role.

=item B<Default> Not required ( acts as a pass-through for strings if 
no format string is provided )

=item B<Range> all sprintf formats defined in perl 5.14 with the exception 
of the number modifiers (lhVqLll).  This also accepts the new format/conversion 
types M and S.  M and S are converted to %s sprintf format strings with all the 
sprintfiness available to them with the exeption of the \d$ call for 
non-sequential input arguments.  M and S require two additional arguments.  
First the [il](*|\d*) argument.  The [il] says to send the arguments to the method 
as either input I<$method->( @inputs )> or lvalues I< $method( @inputs )>.  
The (*|\d*) portioin tells the formatter how many places of the input array to 
send to the method.  The second argument {$method} contains a method or subroutine call.  
B<This will not accept coderefs!>  The method M call can accept a 
modifier i.e. $method->modifier but the passed arguements will be sent to the 
modifier not the method.

=back

=head2 Methods

=head3 output_string

=over

=item B<Definition:> This is the call to pass the values and modifiers to the 
format string.

=item B<Accepts:> this accepts the values for each formatting element in order

=item B<Returns:> a formatted string

=back

=head1 BUGS

Send them to my email directly (Currently I'm not on CPAN)

=head1 TODO

=over

=item ??

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

=over 4

=item L<Modern::Perl>

=item L<MooseX::StrictConstructor>

=item L<Moose::Util::TypeConstraints>

=item L<String::Flogger>

=item L<String::Format>

=back

=cut

#################### main pod documentation end ###################