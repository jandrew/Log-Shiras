#!perl
package Log::Shiras::Types;
use version; our $VERSION = version->declare("v0.018.002");

use Carp qw( confess );
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;
	### Smart-Comments turned on for Log-Shiras-Types ...
}
use YAML::Any qw( Dump LoadFile );
use JSON::XS;
use MooseX::Types -declare => [ qw(
        posInt
		elevenArray
		elevenInt
		shirasformat
        textfile
        headerstring
		yamlfile
		jsonfile
		argshash
		reportobject
		namespace
		
		newmodifier
		filehash
    ) ];
		#~ sprintfmodifier
use MooseX::Types::Moose qw(
        Int
        ArrayRef
		HashRef
		Str
		Object
    );
#~ require MooseX::ShortCut::BuildInstance;
use lib '../../../lib', '../../lib';
#~ with 'Log::Shiras::Caller';
#~ use Log::Shiras::Switchboard;
#~ my	$switchboard = Log::Shiras::Switchboard->instance;

#########1 Package Variables  3#########4#########5#########6#########7#########8#########9

my	$standard_char	= qr/[csduoxefgXEGbB]/;		# Legacy conversions not supported
my	$producer_char	= qr/[pn%]/;  				# sprintf standards that don't take arguments
my	$new_type_char	= qr/[MPO]/;				# M = method style, P = passed data style, O = object style
my	$split_regex	= qr/
        ([^%]*)							# inserted string
        (%([^%]*?)			# get modifiers
			(	($producer_char)|		# get terminator characters
				($standard_char)))	# 
    /x;
my	$sprintf_dispatch =[
		[ \&_append_to_string, ],# 0
		[ \&_alt_position, \&_does_not_consume, \&_append_to_string, ], # 1
		[ sub{ $_[1] }, ],# pass through # 2
		[ sub{ $_[1] }, ],# pass through # 3
		[ \&_append_to_string, \&_set_consumption, ], # 4
		[ \&_append_to_string, \&_remove_consumption, ],# 5
		[ \&_append_to_string, ], # 6
		[ sub{ $_[1] }, ],# pass through # 7
		[ sub{ $_[1] }, ],# pass through # 8
		[ \&_append_to_string, \&_set_consumption, ], # 9
		[ \&_append_to_string, \&_remove_consumption, ], # 10
		[ \&_append_to_string, ],# 11
		[ sub{ $_[1] }, ],# pass through # 12
		[ \&_append_to_string, ], # 13
		[ sub{ $_[1] }, ],# pass through # 14
		[ \&_append_to_string, \&_set_consumption, ], # 15
		[ \&_append_to_string, ], # 17
		[ \&_test_for_position_change, \&_does_not_consume, \&_set_insert_call, ], # 18
		[ sub{ $_[1] }, ],# pass through # 19
		[ \&_append_to_string, \&_set_consumption, ], # 20
		[ \&_append_to_string, ], # 21
		[ sub{ confess "No methods here!!" }, ],# 22
		[ sub{ confess "No methods here!!" }, ],# 23
	];
my  $sprintf_regex 	= qr/
		\A[%]      					# (required) sequence start
        ([\s\-\+0#]{0,2})       	# (optional) flag(s)
        ([1-9]\d*\$)?				# (optional) get the formatted value from
									#		some position other than the next position
        (((\*)([1-9]\d*\$)?)?		# (optional) vector flag with optional index and reference
			(v))?					#		for gathering a defined vector separator
        (							# (optional) minimum field width formatting
			((\*)([1-9]\d*\$)?)|	# 		get field from input with possible position call
            ([1-9]\d*)			)?	# 		fixed field size definition
        ((\.)(                  	# (optional) maximum field width formatting
			(\*)|					# 		get field from input with possible position call
            ([0-9]\d*)		))?		# 		fixed field size definition
			($new_type_char)?		# (optional) get input from a method or passed source
		(							# (required) conversion type
			($standard_char)|		#		standard character
			($producer_char)	)	#		producer character
        \Z                  		# End of the line
    /sxmp;
my	$shiras_format_ref = { 
		final 		=> 1,
		alt_input 	=> 1,
		bump_list	=> 1,
	};
my  $textfileext    = qr/[.](txt|csv)/;
my  $yamlextention	= qr/\.(?i)(yml|yaml)/;
my  $jsonextention	= qr/\.(?i)(jsn|json)/;
my  $coder 			= JSON::XS->new->ascii->pretty->allow_nonref;#
my 	$switchboard_attributes = [ qw(
		name_space_bounds reports buffering 
		conf_file logging_levels
	) ];

#########1 SubType Library    3#########4#########5#########6#########7#########8#########9

subtype posInt, as Int,
    where{ $_ >= 0 },
    message{ "$_ is not a positive integer" };
	
subtype elevenInt, as posInt,
    where{ $_ < 12 },
    message{ "This goes past eleven! :O" };
	
subtype elevenArray, as ArrayRef,
    where{ scalar( @$_ ) < 13 },
    message{ "This goes past the eleventh position! :O" };

subtype newmodifier, as Str,
    where{ $_ =~ /\A$new_type_char\Z/sxm },
    message{ "'$_' does not match $new_type_char" };

subtype shirasformat, as HashRef,
	where{ _has_shiras_keys( $_ ) },
    message { $_ };

coerce shirasformat, from Str,
    via {
        my ( $input, ) = @_;
		### <where> - passed: $input
        my ( $x, $finished_ref, ) = ( 1, {} );
		my $escape_off = 1;
		### <where> - check for a pure sprintf string
		if( $input !~ /{/ ){
			### <where> - no need to pre parse this string ...
			return { final => $input };
		}else{
			### <where> - manage new formats ...
			my $start = 1;
			while( $input =~ /([^%]*)%([^%]*)/g ){
				my  $pre = $1;
				my  $post = $2;
				### <where> - pre: $pre
				### <where> - post: $post
				if( $start ){#
					push @{$finished_ref->{init_parse}}, $pre;
					$start = 0;
				}elsif( $pre ){
					return "Coersion to 'shirasformat' failed for section -$pre- in " . 
						__FILE__ . " at line " . __LINE__ . ".\n";
				}
				if( $post =~ /^([^{]*){([^}]*)}(.)(\(([^)]*)\))?(.*)$/ ){
					my @list = ( $1, $2, $3, $4, $5, $6 );
					### <where>- list: @list
					if( !is_newmodifier( $list[2] ) ){
						return "Coersion to 'shirasformat' failed because of an " .
						"unrecognized modifier -$list[2]- found in format string -" .
						$post . "- by ". __FILE__ . " at line " . __LINE__ . ".\n";
					}
					push @{$finished_ref->{alt_input}}, [ @list[1,2,4] ];
					push @{$finished_ref->{init_parse}}, join '', @list[0,2,5];
				}elsif( $post =~ /[{}]/ ){
					return "Coersion to 'shirasformat' failed for section -$post- " .
					"using " . __FILE__ . " at line " . __LINE__ . ".\n";
				}else{
					push @{$finished_ref->{init_parse}}, $post;
				}
				### <where> - finished ref: $finished_ref
			}
			$input = join '%', @{$finished_ref->{init_parse}};
			delete $finished_ref->{init_parse};
			### <where> - current sprintf ref: $input
		}
		### <where> - build input array modifications ...
		my	$parsed_length = 0;
		my  $total_length = length( $input );
		while( $input =~ /$split_regex/g ){
			my @list = ( $1, $2, $3, $4, $5, $6 );#
			### <where> - matched: @list
			### <where> - for segment: $&
			if( $list[2] and $list[4] and $list[4] eq '%' ){
				return "Coersion to 'shirasformat' failed for the segment: " . 
					$list[1] . " using " . __FILE__ . " at line " . 
					__LINE__ . ".\n";
			}
			my  $pre_string				= $list[0];
			$finished_ref->{string}   .= $list[0] if $list[0];
			$finished_ref->{new_chunk}	= $list[1];
			my 	$consumer_format 		= $list[5];
			my	$producer_format		= $list[4];
				$parsed_length	   	   += 
					length( $finished_ref->{new_chunk} ) + length( $pre_string );
				$input					= ${^POSTMATCH};
			my  $pre_match				= ${^PREMATCH};
			my  $finished_length		= $total_length - length( $input );
			### <where> - length of chunk: $finished_ref->{new_chunk}
			### <where> - parsed length: $parsed_length
			### <where> - finished length: $finished_length
			### <where> - pre match: $pre_match
			### <where> - remaining: $input
			### <where> - producer: $producer_format
			### <where> - consumer: $consumer_format
			if( $finished_length != $parsed_length ){
				return "Coersion to 'shirasformat' failed for the modified " .
					"sprintf segment -$pre_match- using " .
					__FILE__ . " at line " . __LINE__ . ".\n";
			}
			if( $producer_format or $consumer_format ){
				#~ $finished_ref = _process_producer_format( $finished_ref );
			#~ }elsif( $consumer_format ){
				$finished_ref = _process_sprintf_format( $finished_ref );
			}else{
				delete $finished_ref->{new_chunk};
				next;
			}
			
			if( !is_HashRef( $finished_ref ) ){
				### <where> - fail: $finished_ref
				return $finished_ref;
			}
			delete $finished_ref->{new_chunk};
			#### <where> - current: $finished_ref
			$x++;
			### <where> - current input: $input
        }
		### <where> - finished ref: $finished_ref
		### <where> - input length: length( $input )
		if( $input and $finished_ref->{string} !~ /$input$/ ){
			$finished_ref->{string} .= $input;
		}
		### <where> - reviewing: $finished_ref
		my	$parsing_string = $finished_ref->{string};
		### <where> - parsing_string: $parsing_string
		delete $finished_ref->{bump_count};
		delete $finished_ref->{alt_position};
		while( $parsing_string =~ /(\d+)([\$])/ ){
			$finished_ref->{final} .= ${^PREMATCH};
			$parsing_string = ${^POSTMATCH};
			### <where> - updated: $finished_ref
			### <where> - parsing string: $parsing_string
			my $digits = $1;
			my $position = $digits - 1;
			if( exists $finished_ref->{bump_list}->[$position] ){
				$digits += $finished_ref->{bump_list}->[$position];
			}
			### <where> - digits: $digits
			### <where> - position: $position
			$finished_ref->{final} .= $digits;
			$finished_ref->{final} .= '$';
			### <where> - updated: $finished_ref
		}
		$finished_ref->{final} .= $parsing_string;
		delete $finished_ref->{string};
		### <where> - returning: $finished_ref
		return $finished_ref;
    };

subtype textfile, as Str,
    message {  "$_ does not have the correct suffix (\.txt or \.csv)"   },
    where {  $_ =~ /$textfileext\Z/sxm };

subtype headerstring, as Str,
    where{  !$_ or $_ !~ /[\n\r]/sxm  },
    message{ $_ };

coerce headerstring, from Str,
    via {
        if( is_Str( $_ ) ) {
            $_ =~ s/\n(?!$)/ /gsxm;
            $_ =~ s/\r(?!$)/ /gsxm;
            chomp $_;
            return $_;
        } else {
            return "Can not coerce -$_- into a 'headerstring' since it is " .
				"a -" . ref $_ . "- ref (not a string) using " .
				"Log::Shiras::Types 'shirasformat' line " . __LINE__ . ".\n";
        }
    };
	
subtype yamlfile, as Str,
	where{ $_ =~ $yamlextention and -f $_ },
	message{ $_ };

subtype jsonfile, as Str,
	where{ $_ =~ $jsonextention and -f $_ },
	message{ $_ };
	
subtype filehash, as HashRef,
	message{ $_ };

coerce filehash, from yamlfile,
	via{ 
		my @Array = LoadFile( $_ );
		### <where> - downloaded file: @Array
		return ( ref $Array[0] eq 'HASH' ) ?
			$Array[0] : { @Array } ;
	};

coerce filehash, from jsonfile,
	via{
		### <where> - input: $_
		open( my $fh, "<", $_ );
		### <where> - using file handle: $fh
		my 	@Array = <$fh>;
		chomp @Array;
		### <where> - downloaded file: @Array
		my  $ref = $coder->decode( join '', @Array );
		### <where> - downloaded file: $ref
		return $ref ;
	};
	
subtype argshash, as HashRef,
	where{ 
		my  $result = 0;
		for my $key ( @$switchboard_attributes ){
			if( exists $_->{$key} ){
				$result = 1;
				last;
			}
		}
		return $result;
	},
	message{ 'None of the required attributes were passed' };
	
coerce argshash, from filehash,
	via{ $_ };
	
subtype reportobject, as Object,
	where{ $_->can( 'add_line' ) },
	message{ $_ };
	
#~ coerce reportobject, from filehash,
	#~ via{ 
		#~ ### <where> - the passed value is: $_
		#~ return MooseX::ShortCut::BuildInstance::build_instance( %$_ );
	#~ };
	
subtype namespace, as Str,
	where{
		my  $result = 1;
		$result = 0 if( !$_ or $_ =~ / / );
		return $result;
	},
	message{ 
		my $passed = ( ref $_ eq 'ARRAY' ) ? join( '::', @$_ ) : $_;
		return "-$passed- could not be coerced into a string without spaces";
	};
	
coerce namespace, from ArrayRef,
	via{ return join( '::', @$_ ) };
		

#########1 Private Methods	  3#########4#########5#########6#########7#########8#########9

sub _has_shiras_keys{
	my ( $ref ) =@_;
	### <where> - passed information is: $ref
	my 	$result = 1;
	if( ref $ref eq 'HASH' ){
		### <where> - found a hash ref...
		for my $key ( keys %$ref ){
			### <where> - testing key: $key
			if( !(exists $shiras_format_ref->{$key}) ){
				### <where> - failed at key: $key
				$result = 0;
				last;
			}
		}
	}else{
		$result = 0;
	}
	return $result;
}

sub _process_sprintf_format{
    my ( $ref ) = @_;
	### <where> - passed information is: $ref
    if( my @list = $ref->{new_chunk} =~ $sprintf_regex ) {
		### <where> - results of the next regex element are: @list
		$ref->{string} .= '%';
		my $x = 0;
		for my $item ( @list ){
			if( defined $item ){
				### <where> - processing: $item
				### <where> - position: $x
				my $i = 0;
				for my $method ( @{$sprintf_dispatch->[$x]} ){
					#~ ### <where> - running method: $i
					#~ ### <where> - running method: $method
					$ref = $method->( $item, $ref );
					### <where> - updated ref: $ref
					return $ref if ref $ref ne 'HASH';
					$i++;
				}
			}
			$x++;
		}
    } else {
        $ref = "Failed to match -" . $ref->{new_chunk} . 
					"- as a (modified) sprintf chunk";
    }
    ### <where> - after _process_sprintf_format: $ref
    return $ref;
}

sub _process_producer_format{
	my ( $ref ) = @_;
	### <where> - passed information is: $ref
	$ref->{string} .= $ref->{new_chunk};
	delete $ref->{new_chunk};
    ### <where> - after _process_producer_format: $ref
    return $ref;
}

sub _append_to_string{
	my ( $item, $item_ref ) = @_;
	### <where> - reached _append_to_string with: $item
	$item_ref->{string} .= $item;
	return $item_ref;
}

sub _does_not_consume{
	my ( $item, $item_ref ) = @_;
	### <where> - reached _does_not_consume with: $item
	$item_ref->{no_primary_consumption} = 1;
	return $item_ref;
}

sub _set_consumption{
	my ( $item, $item_ref ) = @_;
	### <where> - reached _set_consumption with: $item
	if( !$item_ref->{no_primary_consumption} ){
		push @{$item_ref->{bump_list}}, 
			((exists $item_ref->{bump_count})?$item_ref->{bump_count}:0);
	}
	delete $item_ref->{no_primary_consumption};
	return $item_ref;
}

sub _remove_consumption{
	my ( $item, $item_ref ) = @_;
	### <where> - reached _remove_consumption with: $item
	pop @{$item_ref->{bump_list}};
	return $item_ref;
}

sub _set_insert_call{
	my ( $item, $item_ref ) = @_;
	$item_ref->{alt_position} = ( $item_ref->{alt_position} ) ? 
		$item_ref->{alt_position} : 0 ;
	$item_ref->{bump_count}++;
	### <where> - reached _set_insert_call with: $item
	### <where> - using position: $item_ref->{alt_position}
	### <where> - with new bump level: $item_ref->{bump_count}
	my $new_ref = [ 
		$item_ref->{alt_input}->[$item_ref->{alt_position}]->[1],
		$item_ref->{alt_input}->[$item_ref->{alt_position}]->[0],
	];
	if( $item_ref->{alt_input}->[$item_ref->{alt_position}]->[2] ){
		my $dispatch = undef;
		for my $value ( 
			split /,|=>/, 	
				$item_ref->{alt_input}->[$item_ref->{alt_position}]->[2] ){
			$value =~ s/\s//g;
			$value =~ s/^['"]([^'"]*)['"]$/$1/g;
			### <where> - value: $value
			push @$new_ref, $value;
			if( $dispatch ){
				$item_ref->{bump_count} -= 
					( $value =~/^\d+$/ )? $value :
					( $value =~/^\*$/ )? 1 : 0 ;
				$dispatch = undef;
			}else{
				$dispatch = $value;
			}
		}
	}
	$item_ref->{alt_input}->[$item_ref->{alt_position}] = { commands => $new_ref };
	$item_ref->{alt_input}->[$item_ref->{alt_position}]->{start_at} = 
		( exists $item_ref->{bump_list} ) ?
			$#{$item_ref->{bump_list}} + 1 : 0 ;
	$item_ref->{alt_position}++;
	### <where> - item ref: $item_ref
	return $item_ref;
}

sub _test_for_position_change{
	my ( $item, $item_ref ) = @_;
	### <where> - reached _test_for_position_change with: $item
	if( exists $item_ref->{conflict_test} ){
		$item_ref = "You cannot call for alternative location pull -" .
		$item_ref->{conflict_test} . "- and get data from the -$item- " .
		"source in shirasformat type coersion at line " . __LINE__ . ".\n";
	}
	return $item_ref;
}

sub _alt_position{
	my ( $item, $item_ref ) = @_;
	### <where> - reached _alt_position with: $item
	$item_ref->{conflict_test} = $item if $item;
	return $item_ref;
}

#########1 Phinish    	      3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable;

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::Types - The MooseX::Types library for Log::Shiras

=head1 SYNOPSIS
    
	#! C:/Perl/bin/perl
	package Log::Shiras::Report::MyRole;

	use Modern::Perl;#suggested
	use Moose::Role;
	use Log::Shiras::Types v0.013 qw(
		shirasformat
		jsonfile
	);

	has	'someattribute' =>(
			isa     => shirasformat,#Note the lack of quotes
		);

	sub valuetestmethod{
		return is_jsonfile( 'my_file.jsn' );
	}

	no Moose::Role;

	1;

=head1 DESCRIPTION

This is the custom type class that ships with the L<Log::Shiras> package.  
Wherever possible errors to coercions are passed back to the type so coersion 
failure will be explained.

There are only subtypes in this package!  B<WARNING> These types should be 
considered in a beta state.  Future type fixing will be done with a set of tests in 
the test suit of this package.  (currently few are implemented)

See L<MooseX::Types> for general re-use of this module.

=head1 Types

=head2  posInt

=over

=item B<Definition: >all integers equal to or greater than 0

=item B<Coercions: >no coersion available

=back

=head2  elevenInt

=over

=item B<Definition: >any posInt less than 11

=item B<Coercions: >no coersion available

=back

=head2  elevenArray

=over

=item B<Definition: >an array with up to 12 total positions [0..11] 
L<I<This one goes to eleven>|https://en.wikipedia.org/wiki/This_Is_Spinal_Tap>

=item B<Coercions: >no coersion available

=back

=head2  shirasformat

=over

=item B<Definition: >this is the core of the L<Log::Shiras::Report::ShirasFormat> module.  
When prepared the final 'shirasformat' definition is a hashref that contains three keys;

=over

=item B<final> - a sprintf compliant format string

=item B<alt_input> - an arrayref of input definitions and positions for all the additional 
'shirasformat' modifications allowed

=item B<bump_list> - a record of where and how many new inputs will be inserted 
in the passed data for formatting the sprintf compliant string

=back

In order to simplify sprintf formatting I approached the sprintf definition as having 
the following sequence;

=over

=item B<Optional - Pre-string, > any pre-string that would be printed as it stands 
(not interpolated)

=item B<Required - %, >this indicates the start of a formating definition

=item B<Optional - L<Flags|http://perldoc.perl.org/functions/sprintf.html#flags>, > 
any one or two of the following optional flag [\s\-\+0#] as defined in the sprintf 
documentation.

=item B<Optional - 
L<Order of arguments|http://perldoc.perl.org/functions/sprintf.html#order-of-arguments>, >
indicate some other position to obtain the formatted value.

=item B<Optional - 
L<Vector flag|http://perldoc.perl.org/functions/sprintf.html#vector-flag>, >to treat 
each input character as a value in a vector then you use the vector flag with it's 
optional vector separator definition.

=item B<Optional - 
L<Minimum field width|http://perldoc.perl.org/functions/sprintf.html#(minimum)-width>, >
This defines the space taken for presenting the value

=item B<Optional - 
L<Maximum field width|http://perldoc.perl.org/functions/sprintf.html#precision%2c-or-maximum-width>, >
This defines the maximum length of the presented value.  If maximum width is smaller 
than the minimum width then the value is truncatd to the maximum width and presented 
in the mimimum width space as defined by the flags.

=item B<Required - 
L<Data type definition|http://perldoc.perl.org/functions/sprintf.html#sprintf-FORMAT%2c-LIST>, >
This is done with an upper or lower case letter as described in the sprintf documentation.  Only 
the letters defined in the sprintf documentation are supported.  These letters close the 
sprintf documentation segment started with '%'.

=back

The specific combination of these values is defined in the perldoc 
L<sprintf|http://perldoc.perl.org/functions/sprintf.html>.

The module ShirasFormat expands on this definitions as follows;

=over

=item B<Word in braces {}, > just prior to the L</Data type definition> you can 
begin a sequence that starts with a word (no spaces) enclosed in braces.  This word will 
be the name of the source data used in this format sequence.

=item B<Source indicator qr/[MP]/, > just after the L</Word in braces {}> you must indicate 
where the code should look for this information.  There are only two choices;

=over

=item B<P> - a passed value in the message hash reference.  The word in braces should be an 
exact match to a key in the message hashref. The core value used for this shirasformat 
segemnt will be the value assigned to that key.

=item B<M> - a method name to be discovered by the class.  I<This method must exist at the 
time the format is set!>  When the Shiras format string is set the code will attempt to 
locate the method and save the location for calling this method to speed up implementation of 
ongoing formatting operations.  If the method does not exist when the format string is 
set even if it will exist before data is passed for formatting then this call will fail.  
if you want to pass a closure (subroutine reference) then pass it as the value in the mesage 
hash L<part 
of the message ref|/a passed value in the message hash reference> and call it with 'P'.

=back

=item B<Code pairs in (), following the source indicator> often the passed information 
is a code reference and for that code to be useful it needs to accept input.  These code 
pairs are a way of implementing the code.  The code pairs must be in intended use sequence.  
The convention is to write these in a fat comma list.  There is no limit to code pairs 
quatities. There are three possible keys for these pairs;

=over

=item B<m> this indicates a method call.  If the code passed is actually an object with 
methods then this will call the value of this pair as a method on the code.

=item B<i> this indicates regular input to the method and input will be provided to a 
method using the value as follows;

	$method( 'value' )

=item B<l> this indicates lvalue input to the method and input will be provided to a 
method using the value as follows;

	$method->( 'value' )
	
=item B<[value]> Values to the methods can be provided in one of three ways. A B<string> 
that will be sent to the method directly. An B<*> to indicate that the method will consume 
the next value in the passed message array ref.  Or an B<integer> indicating how many of the 
elements of the passed messay array should be consumed.  When elements of the passed 
message array are consumed they are consumed in order just like other sprintf elements.

=back

When a special shirasformat segment is called the braces and the Source indicator are 
manditory.  The code pairs are optional.

=item B<Coercions: >from a modified sprintf format string

=back

=back

=head2  textfile

=over

=item B<Definition: >a file name with a \.txt or \.csv extention that exists

=item B<Coercions: >no coersion available

=back

=head2  headerstring

=over

=item B<Definition: >a string without any newlines

=item B<Coercions: >if coercions are turned on, newlines will be stripped (\n\r)

=back

=head2  yamlfile

=over

=item B<Definition: >a file name with a qr/(\.yml|\.yaml)/ extention that exists

=item B<Coercions: >none

=back

=head2  jsonfile

=over

=item B<Definition: >a file name with a qr/(\.jsn|\.json)/ extention that exists

=item B<Coercions: >none

=back

=head2  argshash

=over

=item B<Definition: >a hashref that has at least one of the following keys

	name_space_bounds
	reports
	buffering 
	ignored_caller_names
	will_cluck
	logging_levels
	
This are the primary switchboard settings.

=item B<Coersion >from a L</jsonfile> or L</yamlfile> it will attempt to open the file 
and turn the file into a hashref that will pass the argshash criteria

=back

=head2  reportobject

=over

=item B<Definition: >an object that passes $object->can( 'add_line' )

=item B<Coersion 1: >from a hashref it will use 
L<MooseX::ShortCut::BuildInstance|http://search.cpan.org/~jandrew/MooseX-ShortCut-BuildInstance/lib/MooseX/ShortCut/BuildInstance.pm> 
to build a report object if the necessary hashref is passed instead of an object

=item B<Coersion 2: >from a L</jsonfile> or L</yamlfile> it will attempt to open the file 
and turn the file into a hashref that can be used in L</Coersion 1>.

=back

=head1 GLOBAL VARIABLES

=over

=item B<$ENV{Smart_Comments}>

The module uses L<Smart::Comments> if the '-ENV' option is set.  The 'use' is 
encapsulated in an if block triggered by an environmental variable to comfort 
non-believers.  Setting the variable $ENV{Smart_Comments} in a BEGIN block will 
load and turn on smart comment reporting.  There are three levels of 'Smartness' 
available in this module '###',  '####', and '#####'.

=back

=head1 TODO

=over

=item * write a test suit for the types to fix behavior!

=item * write a set of tests for combinations of %n and {string}M

=item * add a log error and clear option rather than fail for type testing

=item * Convert to L<Type::Tiny>

=back

=head1 SUPPORT

=over

=item L<Github Log-Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

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

=item L<Carp> - confess

=item L<Smart::Comments>

=item L<version>

=item L<YAML::Any> - ( Dump LoadFile )

=item L<JSON::XS>

=item L<MooseX::Types>

=item L<MooseX::Types::Moose>

=item L<MooseX::ShortCut::BuildInstance> - 0.003

=back

=head1 SEE ALSO

=over

=item L<Smart::Comments> - is used if the -ENV option is set

=item L<MooseX::Types::Perl>

=back

=cut

#########1 Main POD ends      3#########4#########5#########6#########7#########8#########9