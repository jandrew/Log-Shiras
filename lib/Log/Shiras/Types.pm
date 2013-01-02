#!perl
package Log::Shiras::Types;

use Carp qw( confess );
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;
	### Smart-Comments turned on for Log-Shiras-Types ...
}
use version 0.94; our $VERSION = qv('0.013_01');
use YAML::Any qw( Dump LoadFile );
use JSON::XS;
use Moose::Util qw( with_traits );
use MooseX::Types -declare => [ qw(
        posInt
		elevenArray
		elevenInt
		newmodifier
		acmeformat
		sprintfformat
        textfile
        headerstring
		reportobject
		yamlfile
		jsonfile
		argshash
		
		filehash
    ) ];
		#~ producerformat
		#~ newtypeformat
use MooseX::Types::Moose qw(
        Int
        ArrayRef
		HashRef
		Str
		Object
    );
use lib '../../../../MooseX-ShortCut-BuildInstance/lib';
use MooseX::ShortCut::BuildInstance 0.003;

#########1 Package Variables  3#########4#########5#########6#########7#########8#########9

my	$standard_char	= qr/[csduoxefgXEGbB]/;		# Legacy conversions not supported
my	$producer_char	= qr/[pn%]/;  				# sprintf standards that don't take arguments
my	$new_type_char	= qr/[MP]/;					# M = method style, P = passed data style 
#~ my	$modifier_char	= qr/[MP0-9\s+#v\-]/;#     (new format type callout)
#~ my	$test_list		=[ qw(
		#~ sprintf producer unknown string
	#~ ) ];
#~ my  $test_dispatch	={
		#~ sprintf		=> sub{ is_sprintfformat( $_[0]->{'formatchar'} ) },
		#~ producer	=> sub{ is_producerformat( $_[0]->{'formatchar'} ) },
		#~ unknown		=> sub{ $_[0]->{'formatchar'} },
		#~ string		=> sub{ 1 },
	#~ };
#~ my 	$format_dispatch ={
		#~ sprintf		=> \&_process_sprintf_format,
		#~ producer 	=> \&_process_producer_format,
		#~ string		=> sub{ $_[0] },
	#~ };
my	$split_regex	= qr/
        ([^%]*)							# inserted string
        (%([^%]*?)			# get modifiers
			(	($producer_char)|		# get terminator characters
				($standard_char)))	# 
    /x;
my	$sprintf_dispatch =[
		[ \&_append_to_string, ],# 0
		[ \&_does_not_consume, \&_append_to_string, ], # 1
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
		[ \&_does_not_consume, \&_set_insert_call, ], # 18
		[ sub{ $_[1] }, ],# pass through # 19
		[ \&_append_to_string, \&_set_consumption, ], # 20
		[ \&_append_to_string, ], # 21
		[ sub{ confess "No methods here!!" }, ],# 22
		[ sub{ confess "No methods here!!" }, ],# 23
	];
my  $sprintf_regex 	= qr/
		\A[%]      					# (required) sequence start
        ([\s\-\+0#]{0,2})       	# (optional) flag(s)
        ([1-9]\d*\$)?				# (optional) get the formatted value
									#		some position other than the next position
        (((\*)([1-9]\d*\$)?)?		# (optional) vector flag with optional index and reference
			(v))?					#		for gathering a defined vector separator
        (							# (optional) minimum field width formatting
			((\*)([1-9]\d*\$)?)|	# 		get field from input with possible position call
            ([1-9]\d*)			)?	# 		fixed field size definition
        ((\.)(                  	# (optional) maximum field width formatting
			(\*)|					# 		get field from input with possible position call
            ([0-9]\d*)		))?		# 		fixed field size definition
			($new_type_char)?		#		get input from a method or passed source
		(							# (required) conversion type
			($standard_char)|		#		standard character
			($producer_char)	)	#		producer character
        \Z                  		# End of the line
    /sxmp;
my  $textfileext    = qr/[.](txt|csv)/;
my  $yamlextention	= qr/\.(?i)(yml|yaml)/;
my  $jsonextention	= qr/\.(?i)(jsn|json)/;
my  $coder 			= JSON::XS->new->ascii->pretty->allow_nonref;#
my 	$switchboard_attributes = [ qw(
		name_space_bounds reports buffering 
		ignored_caller_names will_cluck logging_levels
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

subtype sprintfformat, as Str,
    where{ $_ =~ /\A$standard_char\Z/sxm },
    message{ "'$_' does not match $standard_char" };

subtype acmeformat, as HashRef,
    message { $_ };

coerce acmeformat, from Str,
    via {
        my ( $input, ) = @_;
		### <where> - passed: $input
        my ( $x, $finished_ref, ) = ( 1, {} );
		my $escape_off = 1;
		### <where> - check for a pure sprintf string
		if( $input !~ /{/ ){
			### <where> - no need to parse this string ...
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
					return "Coersion to 'acmeformat' failed for section -$pre- in " . 
						__FILE__ . " at line " . __LINE__ . ".\n";
				}
				if( $post =~ /^([^{]*){([^}]*)}(.)(\(([^)]*)\))?(.*)$/ ){
					my @list = ( $1, $2, $3, $4, $5, $6 );
					### <where>- list: @list
					if( !is_newmodifier( $list[2] ) ){
						return "Coersion to 'acmeformat' failed because of an unrecognized " .
							"modifier -$list[2]- found in format string -$post- by ".
							__FILE__ . " at line " . __LINE__ . ".\n";
					}
					push @{$finished_ref->{alt_input}}, [ @list[1,2,4] ];
					push @{$finished_ref->{init_parse}}, join '', @list[0,2,5];
				}elsif( $post =~ /[{}]/ ){
					return "Coersion to 'acmeformat' failed for section -$post- using " .
						__FILE__ . " at line " . __LINE__ . ".\n";
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
				return "Coersion to 'acmeformat' failed for the segment: " . $list[1] .
					" using " . __FILE__ . " at line " . __LINE__ . ".\n";
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
				return "Coersion to 'acmeformat' failed for the modified " .
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
    where {  $_ =~ /$textfileext\Z/sxm  };

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
				"Log::Shiras::Types 'acmeformat' line " . __LINE__ . ".\n";
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
	
coerce reportobject, from filehash,
	via{ 
		### <where> - the passed value is: $_
		return build_instance( %$_ );
	};
	
#~ coerce reportobject, from yamlfile,
	#~ via{ 
		#~ ### <where> - the passed value is: $_
		#~ my $filehash = to_filehash( $_ );
		#~ return build_instance( %{$filehash} );
	#~ };
	
#~ coerce reportobject, from jsonfile,
	#~ via{ 
		#~ ### <where> - the passed value is: $_
		#~ my $filehash = to_filehash( $_ );
		#~ return build_instance( %{$filehash} );
	#~ };

#########1 Private Methods	  3#########4#########5#########6#########7#########8#########9

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
					$i++;
				}
			}
			$x++;
		}
    } else {
        $ref = "Failed to match -" . $ref->{new_chunk} . "- as a (modified) sprintf chunk";
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
		for my $value ( split /,|=>/, 	$item_ref->{alt_input}->[$item_ref->{alt_position}]->[2] ){
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
	$item_ref->{alt_input}->[$item_ref->{alt_position}]->{start_at} = ( exists $item_ref->{bump_list} ) ?
		$#{$item_ref->{bump_list}} + 1 : 0 ;
	$item_ref->{alt_position}++;
	### <where> - item ref: $item_ref
	#~ my $wait = <>;
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
    use Log::Shiras::Types v0.11 qw(
        someimportedtype# This is not a real type.  Read the code for actual options!!!
        otherimportedtype# This is not a real type.  Read the code for actual options!!!
    );
    
    has 'someattribute' =>(
            isa     => someimportedtype,#Note the lack of quotes
        );
    
    sub valuetestmethod{
        my ( $self, $value ) = @_;
        return is_otherimportedtype( $value );
    }

    no Moose::Role;

    1;

=head1 DESCRIPTION

This is the custom type class that ships with the L<Log::Shiras> package.  
Wherever possible errors to coersions are passed back to the type so coersion 
failure will be explained.

There are only subtypes in this package!  B<WARNING> These types should be 
considered in a beta state.  Future type fixing will be done with a set of tests in 
the test suit of this package.  (currently none are implemented)

See L<MooseX::Types> for general re-use of this module.

=head1 BUGS

L<Github|https://github.com/jandrewlund>

=head1 TODO

=over

=item * write a test suit for the types to fix behavior!

=item * add a log error and clear option rather than fail for type testing

=back

=head1 SUPPORT

L<Github|https://github.com/jandrewlund>

=head1 AUTHOR

=over

=item Jed Lund 

=item jandrewlund@hotmail.com

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DEPENDANCIES

=over

=item L<Modern::Perl>

=item L<Carp>

=item L<Smart::Comments>

=item L<version>

=item L<YAML::Any>

=item L<Moose::Util>

=item L<MooseX::Types>

=item L<MooseX::Types::Moose>

=back

=head1 SEE ALSO

=over

=item L<MooseX::Types::Perl>

=back

=cut

#################### main pod documentation end #####################