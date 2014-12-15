package Log::Shiras::Report::ShirasFormat;

use Moose::Role;
use Carp qw( confess );
use version 0.94; our $VERSION = qv('0.007.001');
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;
	### Smart-Comments turned on for Log-Shiras-Report-ShirasFormat ...
}
use MooseX::Types::Moose qw(
        ArrayRef
		Bool
    );
use lib '../../../../lib';##Change for Scite vs non Scite testing
use Log::Shiras::Types 0.013 qw(
        acmeformat
    );
        #~ newtypeformat
		#~ callerformat

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has 'format_string' =>(
        is          => 'ro',
        isa         => acmeformat,
		traits		=> ['Hash'],
        coerce      => 1,
        reader      => '_get_format',
        writer      => 'set_format_string',
        predicate   => 'has_format_string',
        clearer     => 'clear_format_string',
		handles		=>{
			_get_item => 'get',
		},
        trigger     => \&_validate_coderef,
    );

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9



#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _new_format_precall =>(
        is          => 'ro',
        isa         => ArrayRef,
        reader      => '_get_format_precall',
        writer      => '_set_format_precall',
        #~ weak_ref    => 1,#I'm not clear this is useful
    );
	
has _position_shift =>(
		is		=> 'ro',
		isa		=> ArrayRef,
		traits	=> ['Array'],
		handles	=>{
			_add_position => 'push',
			_get_position => 'get',
		},
	);
	
#~ has _contains_caller =>(
		#~ is  	=> 'ro',
		#~ isa		=> Bool,
		#~ writer	=> '_set_contains_caller',
		#~ default	=> 0,
	#~ );

#~ has _report_hook =>(
	#~ is			=> 'ro',
	#~ isa			=> 'Log::Shiras::Switchboard',
	#~ writer		=> '_set_report_hook',
	#~ weak_ref	=> 1,
#~ );

##############  Private Methods  ###################################

sub _use_formatter{
    my ( $self, $message_ref ) = @_;
    ### <where> - Reached _use_formatter
    #### <where> - Building output with: $message_ref
    my  $output;
    if ( $self->has_format_string ) {
		### <where> - format string: $self->_get_format
        #### <where> - Implementing current format string ...
		my $input_ref = $self->_get_item( 'list_modifier' );
		if( $input_ref ){
			confess "I don't have the method and passed value process set up yet";
		}
		$output = sprintf $self->_get_item( 'final' ), @{$message_ref->{message}};
	}else{
		### <where> - no output string registered ...
		$output = join ',', @{$message_ref->{message}};
	}
    ### <where> - Final output is: $output
    return $output;
}

#~ sub _new_format_string{
    #~ my ( $self, $formatref, $precall, $passedref, @array ) = @_;
    #~ ### <where> - Reached _new_format_string
    #~ #### <where> - Recieved formatref  : $formatref
    #~ #### <where> - The precall is      : $precall
    #~ #### <where> - The passedref is    : $passedref
    #~ my  $inputcount = 
            #~ ( $formatref->{'inputcount'} eq '*' ) ?
                #~ pop @$passedref :
                #~ $formatref->{'inputcount'} ;
    #~ my  @inputarray;
    #~ #### <where> - Check if there are inputs needed
    #~ if ( $inputcount ) {
        #~ #### <where> - There are inputs needed - handle if the inbound values are short
        #~ $inputcount = ( @array < $inputcount ) ? @array : $inputcount;
        #~ map { push @inputarray, shift @array } ( 1 .. $inputcount );
        #~ #### <where> - The current input array is: @inputarray
    #~ }
    #~ my  $attribute  = $formatref->{'method'};
    #~ my  $modifier = $formatref->{'modifier'};
    #~ #### <where> - Using method: $attribute
    #~ #### <where> - and modifier: $modifier
    #~ my  $methodresult;
    #~ if( $precall eq 'self' ) {
        #~ #### <where> - found a method of the appender
        #~ $methodresult = 
            #~ ( $modifier ) ?
                #~ ( ( scalar @inputarray ) ?
                    #~ ( ( $formatref->{'inputtype'} eq 'i' ) ?
                        #~ $self->$attribute->$modifier->( @inputarray ) :
                        #~ $self->$attribute->$modifier( @inputarray )     ) :
                    #~ $self->$attribute->$modifier                            ) :
                #~ ( ( scalar @inputarray ) ?
                    #~ ( ( $formatref->{'inputtype'} eq 'i' ) ?
                        #~ $self->$attribute->( @inputarray ) :
                        #~ $self->$attribute( @inputarray )    ) :
                    #~ $self->$attribute                                       ) ;
    #~ } elsif ( $precall eq 'main' ) {
        #~ #### <where> - Found a subroutine called from main
        #~ #### <where> - Calling sub method: $attribute
        #~ my $call = $precall . '::' . $attribute;
        #~ ### TODO testing for risk when turning off strict "refs" done in the SubTypes
        #~ no  strict "refs";# I don't know how to call a subroutine that is not a CodeRef
        #~ $methodresult = 
            #~ ( $modifier ) ?
                #~ ( ( scalar @inputarray ) ?
                    #~ ( ( $formatref->{'inputtype'} eq 'i' ) ?
                        #~ &$call->$modifier->( @inputarray ) :
                        #~ &$call->$modifier( @inputarray )     ) :
                    #~ &$call->$modifier                            ) :
                #~ ( ( scalar @inputarray ) ?
                    #~ ( ( $formatref->{'inputtype'} eq 'i' ) ?
                        #~ &$call->( @inputarray ) :
                        #~ &$call( @inputarray )    ) :
                    #~ &$call                                        ) ;
        #~ use strict "refs";
    #~ } else {
        #~ ### <where> - Calling the method on: $precall
        #~ $methodresult = 
            #~ ( $modifier ) ?
                #~ ( ( scalar @inputarray ) ?
                    #~ ( ( $formatref->{'inputtype'} eq 'i' ) ?
                        #~ $precall->$attribute->$modifier->( @inputarray ) :
                        #~ $precall->$attribute->$modifier( @inputarray )     ) :
                    #~ $precall->$attribute->$modifier                            ) :
                #~ ( ( scalar @inputarray ) ?
                    #~ ( ( $formatref->{'inputtype'} eq 'i' ) ?
                        #~ $precall->$attribute->( @inputarray ) :
                        #~ $precall->$attribute( @inputarray )    ) :
                    #~ $precall->$attribute                                       ) ;
    #~ }
    #~ $methodresult //= '';
    #~ ### <where> - Loading method/sub result: $methodresult
    #~ push @$passedref, $methodresult;
    #~ return( $passedref, @array );
#~ }

sub _validate_coderef{
    my ( $self, @other ) = @_;
    ### <where> - Reached _validate_coderef
    #### <where> - passed: @other
    #### <where> - Checking if there are any method or subroutine calls that should be validated
    #### <where> - checking attribute: $self->_get_format
    my  $arrayref = $self->_get_format;
    #### <where> - The current arrayref is:$arrayref
    my  $callsequence = [];
    for my $segment( @$arrayref ) {
        #### <where> - Validating the segment: $segment
        if( $segment->{formatchar} and $segment->{formatchar} eq 'M' ) {
            #### <where> - This is a new style format
            #### <where> - Reached method validation for: $segment->{'method'}
            if( $self->can( $segment->{'method'} ) ) {
                #### <where> - Confirmed this is a method call on the instance
                push @$callsequence, 'self';
                next;
            }
            if( main->can( $segment->{'method'} ) ) {
                #### <where> - Confirmed this is a subroutine call from the main script
                if( $segment->{'inputtype'} eq 'i' ) {
                    die "'$segment->{'method'}' is a subroutine of main and can only accept 'lvalue' inputs (should be 'l' passed 'i')";
                }
                push @$callsequence, 'main';
                next;
            }
            my  $meta = $self->meta;
            my  @superclasses = $meta->superclasses;
            #### <where> - The current superclasses: @superclasses
            for my $class ( @superclasses ) {
                if ( $class->can( $segment->{'method'} ) ) {
                    #### <where> - Confirmed this is a method call on the consumer instance: $class
                    push @$callsequence, $class;
                    next;
                }
            }
            #### <where> - TODO get the moose equivalent of %INC
            #### <where> - Now checking INC: %INC
            for my $class ( keys %INC ) {
                #### <where> - Strip the module extention for: $class
                $class =~ s/\.pm$//;
                if ( $class->can( $segment->{'method'} ) ) {
                    #### <where> - Confirmed this is a method call on the consumer instance: $class
                    push @$callsequence, $class;
                    next;
                }
            }
            #### <where> - TODO other method of attribute finding
            confess "This appender cannot use -$segment->{'method'}-";
        }else {
           #### <where> - This segment is not a method call formatted segment
        }
    }
    $self->_set_format_precall( $callsequence );
    #### <where> - The call sequence is: $callsequence
    #### <where> - Check it was loaded: $self->_get_format_precall
    return 1;
}

#~ after _set_switchboard_hook => sub{
	#~ my ( $self, $value ) = @_;
	#~ $self->_set_report_hook( $value );
#~ };

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;
# The preceding line will help the module return a true value

#########1 main POD docs      3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Parsing::DateData - Moose Role for handling Dates

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