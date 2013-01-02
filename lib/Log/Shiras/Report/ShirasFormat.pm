package Log::Shiras::Report::ShirasFormat;

use Moose::Role;
use YAML::Any qw( Dump );
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
#~ my	$command_dispatch ={
		#~ C 	=> sub{ return( $_[1], $_[3] ) },
		#~ P 	=> sub{ return( $_[3]->{$_[1]}, $_[3], ) },
	#~ };

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
		### <where> - format string: $self->_get_format->{message}
        ##### <where> - Implementing current format: $self->_get_format
		my $alt_input = $self->_get_item( 'alt_input' );
		if( @$alt_input ){
			for my $input_ref ( reverse @$alt_input ){
				##### <where> - processing: $input_ref
				my $command	= undef;
				my $result	= undef;
				my @command_pairs = ();
				for my $item ( @{$input_ref->{commands}} ){
					##### <where> - processing: $item
					if( $command ){
						if( $command eq 'm' and @command_pairs ){
							( $result, $message_ref ) =
								_get_method_value( 
									$result, [ @command_pairs ], 
									$input_ref, $message_ref 
								);
							@command_pairs = ();
						}
						push @command_pairs, $command, $item;
						$command = undef;
					}else{
						$command = $item;
					}
					### <where> - result: $result
				}
				( $result, $message_ref ) =
					_get_method_value( 
						$result, [ @command_pairs ], 
						$input_ref, $message_ref 
					) if @command_pairs;
				### <where> - message ref: $message_ref
				##### <where> - input ref: $input_ref
				splice( @{$message_ref->{message}},$input_ref->{start_at} ,0 ,$result ); 
			}
			### <where> - message ref: $message_ref
		}
		$output = sprintf $self->_get_item( 'final' ), @{$message_ref->{message}};
	}else{
		### <where> - no output string registered ...
		$output = join ',', @{$message_ref->{message}};
	}
    ### <where> - Final output is: $output
    return $output;
}

sub _validate_coderef{
    my ( $self, @other ) = @_;
    ### <where> - Reached _validate_coderef
    #### <where> - passed: @other
    #### <where> - Checking if there are any method or subroutine calls that should be validated
    my  $format_ref = $self->_get_format;
    #### <where> - The current format definition is:$format_ref
    my  $callsequence = [];
    for my $segment( @{$format_ref->{alt_input}} ) {
        #### <where> - Validating the segment: $segment
        if( $segment->{commands}->[0] eq 'M' ) {
            #### <where> - This is a new style format
            #### <where> - Reached method validation for: $segment->{'method'}
			my  $command = $segment->{commands}->[1];
            if( main->can( $command ) ) {
                #### <where> - Confirmed this is a subroutine call from the main script
                if( exists $segment->{commands}->[2] and $segment->{commands}->[2] eq 'i' ) {
                    confess "'$command' is a subroutine of main and can only accept 'lvalue' inputs (should be 'l' passed 'i')";
                }
				$segment->{commands}->[0] = 'm';
				next;
				#~ unshift @{$segment->{commands}}, 'C', 'main';
            }elsif( $self->can( $command ) ) {
                #### <where> - Confirmed this is a method call on the instance
				unshift @{$segment->{commands}}, 'C', $self;
            }
			if( $segment->{commands}->[0] ne 'C' ){
				my  $meta = $self->meta;
				my  @superclasses = $meta->superclasses;
				#### <where> - The current superclasses: @superclasses
				for my $class ( @superclasses ) {
					if ( $class->can( $command ) ) {
						#### <where> - Confirmed this is a method call on the consumer instance: $class
						unshift @{$segment->{commands}}, 'C', $class;
						last;
					}
				}
			}
			if( $segment->{commands}->[0] ne 'C' ){
				#### <where> - TODO get the moose equivalent of %INC
				#### <where> - Now checking INC: %INC
				for my $class ( keys %INC ) {
					#### <where> - Strip the module extention for: $class
					$class =~ s/\.pm$//;
					if ( $class->can( $command ) ) {
						#### <where> - Confirmed this is a method call on the consumer instance: $class
						unshift @{$segment->{commands}}, 'C', $class;
						last;
					}
				}
			}
            #### <where> - TODO other method of attribute finding ...
			if( $segment->{commands}->[0] ne 'C' ){
				confess "This appender cannot use -$command-";
			}else{
				$segment->{commands}->[2] = 'm';
				##### <where> - updated format_ref: $format_ref
			}
        }else {
           #### <where> - This segment is not a method call formatted segment
        }
    }
    return 1;
}

sub _get_method_value{
	my ( $result, $command_ref, $input_ref, $message_ref ) = @_;
	### <where> - passed: @_
	if( $command_ref->[0] eq 'P' ){
		shift( @$command_ref );
		$result = $message_ref->{shift( @$command_ref )};
	}elsif( $command_ref->[0] eq 'C' ){
		shift( @$command_ref );
		$result = shift( @$command_ref );
	}
	### <where> - current result: $result
	### <where> - command ref: $command_ref
	if( @$command_ref ){
		my $input = ( $command_ref->[0] =~ /[il]/ ) ?
						$command_ref->[1] :
					( exists $command_ref->[2] and
						$command_ref->[2] =~ /[il]/ ) ?
						$command_ref->[3] : undef ;
		### <where> - current input: $input
		#### <where> - message ref: $message_ref->{message}
		if( $input and $input =~ /^(\d+)$/ ){
			my $count = $1;
			### <where> - attempting to remove items from the message ref for method input at a count of: $count
			### <where> - starting at point: $input_ref->{start_at}
			my ( @actual_items ) = splice( @{$message_ref->{message}}, $input_ref->{start_at}, $count );
			$input = \@actual_items;
		}elsif( $input and $input =~ /^\*$/ ){
			my $count = splice( @{$message_ref->{message}}, $input_ref->{start_at}, 1, );
			#### <where> - message ref: $message_ref->{message}
			### <where> - attempting to remove items from the message ref for method input at a count of: $count
			### <where> - starting at point: $input_ref->{start_at}
			my ( @actual_items ) = splice( @{$message_ref->{message}}, $input_ref->{start_at}, $count );
			$input = \@actual_items;
		}elsif( $input ){
			$input = [ split /,\s*/, $input ];
		}else{
			$input = [];
		}
		my	$string = $command_ref->[1];
		#### <where> - result: $result
		#### <where> - message ref: $message_ref->{message}
		### <where> - current string: $string
		### <where> - input: $input
		if( $result ){
			if( $command_ref->[0] eq 'm' and !exists $command_ref->[2] ){
				### <where> - processing the result->method only case ...
				$result = $result->$string;
			}elsif( $command_ref->[0] eq 'm' and exists $command_ref->[2] and $command_ref->[2] eq 'i' ){
				### <where> - processing the result->method->( input ) case ...
				$result = $result->$string->( @$input );
			}elsif( $command_ref->[0] eq 'm' and exists $command_ref->[2] and $command_ref->[2] eq 'l' ){
				### <where> - processing the result->method( input ) case ...
				$result = $result->$string( @$input );
			}elsif( $command_ref->[0] eq 'i' ){
				### <where> - processing the method->( input ) case ...
				$result = $result->( @$input );
			}elsif( $command_ref->[0] eq 'l' ){
				### <where> - processing the method( input ) case ...
				$result = &{$result}( @$input );
			}else{
				confess "Can't work out what to do with: " . Dump( $command_ref );
			}
		}elsif( $command_ref->[0] ne 'm' ){
			confess "No method was passed for action in: " . Dump( $command_ref );
		}else{
			if( exists $command_ref->[2] and $command_ref->[2] eq 'i' ){
				### <where> - processing the method->( input ) case ...
				$result = $string->( @$input );
			}elsif( exists $command_ref->[2] and $command_ref->[2] eq 'l' ){
				### <where> - processing the method( input ) case ...
				no strict 'refs';
				$result = &{"main::$string"}( @$input );
			}else{
				### <where> - processing the method only case ...
				no strict 'refs';
				$result = &{"main::$string"};
			}
		}
	}
	### <where> - new result: $result
	return( $result, $message_ref );
}

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