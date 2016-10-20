package Log::Shiras::Report::Upsert;
use version; our $VERSION = version->declare("v0.48.0");
use strict;
use warnings;
use 5.010;
use utf8;
use lib '../../../';
use Log::Shiras::Unhide qw( :InternalReporTUpserT );
###InternalReporTUpserT	warn "You uncovered internal logging statements for Log::Shiras::Report::Upsert-$VERSION" if !$ENV{hide_warn};
###InternalReporTUpserT	use Log::Shiras::Switchboard;
###InternalReporTUpserT	my	$switchboard = Log::Shiras::Switchboard->instance;
use Moose::Role;
requires
###InternalReporTUpserT	'get_log_space',
qw( method_fails_gracefully			is_primary_key					get_headers
	is_destination_ready			set_destination_ready			add_error_to_ref
	has_table_name					get_table_name					prepare_statement
	get_primary_keys				not_pkey_headers				has_headers
);
#~ use MooseX::Types::Moose qw( ArrayRef HashRef CodeRef );
use Log::Shiras::Types qw( JsonFile FileHash );
use Carp 'confess';
my $merge_types = qr/^(
		use_new_data|		use_old_data|		attempt_merge|		use_old_except\[.+\]|
		use_earlier_date|	use_later_date|		use_new_except\[.+\]
	)$/x;

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has merge_rules =>( 
		isa => FileHash,
		traits =>['Hash'],
		reader => 'get_merge_rules',
		predicate => 'has_merge_rules',
		handles =>{
			merge_columns => 'keys',
			get_merge_rule => 'get',
			modify_merge_rule => 'set',
			has_merge_rule => 'exists',
			remove_merge_rule => 'delete',
		},
		coerce => 1,
	);

has merge_modify =>(
		isa => FileHash,
		traits =>['Hash'],
		reader => '_get_merge_modify',
		predicate => '_has_merge_modify',
		handles =>{
			_merge_modify_columns => 'keys',
			_get_merge_modify_rule => 'get',
		},
		coerce => 1,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub add_line{

    my ( $self, $input_ref ) = @_;
	###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 2,
	###InternalReporTUpserT		name_space => $self->get_all_space( 'add_line' ),
	###InternalReporTUpserT		message =>[ 'Adding a line to the table -' . $self->get_table_name . '- :', $input_ref ], } );
	my $message_ref;
	#~ my( $first_ref, @other_args ) = @{$input_ref->{message}};
	#~ if( !$first_ref ){# No failing gracefully since this would be caused by an error in the code passing data not the data itself
		#~ confess "No data was found in the leading message array ref position";
	#~ }elsif( @other_args ){# No failing gracefully since this would be caused by an error in the code passing data not the data itself
		#~ confess "Upsert insists that all information to load be in the first position of the message arrayref\n" .
				#~ "Additional arguments passed: " . join( "~|~", @other_args );
	#~ }elsif( is_HashRef( $first_ref ) ){
		#~ ###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 1,
		#~ ###InternalReporTUpserT		name_space => $self->get_all_space( 'add_line::_find_the_actual_message' ),
		#~ ###InternalReporTUpserT		message =>[ 'Using the ref as it stands:', $first_ref ], } );
		#~ $message_ref = $self->_build_message_from_hashref( $first_ref );
	#~ }else{# No failing gracefully since this would be caused by an error in the code passing data not the data itself
		#~ confess "Upsert expects to receive a hashref in the first position of the message arrayref\n" . 
				#~ "Instead it found: " . $first_ref;
	#~ }
	#~ ###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 3,
	#~ ###InternalReporTUpserT		name_space => $self->get_all_space( 'add_line' ),
	#~ ###InternalReporTUpserT		message =>[ "committing the message:", $message_ref ], } );
	#~ $self->_send_array_ref( $self->_get_file_handle, $message_ref );
	
	
    #~ my(	$self, $args_ref, ) = @_;
#~ ###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 2, 
#~ ###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::add_line' ),
#~ ###InternalReporTUpserT		message =>[ 'Upserting a line to the table -' . $self->get_table_name . '- :', $args_ref, @other_args ], } );

	#~ my $message_ref;
	#~ my( $first_ref, @other_args ) = @{$input_ref->{message}};
	#~ if( !$first_ref ){
		#~ ###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 1,
		#~ ###InternalReporTUpserT		name_space => $self->get_all_space( 'add_line::_find_the_actual_message' ),
		#~ ###InternalReporTUpserT		message =>[ 'No data in the first position - adding an empty row' ], } );
		#~ $message_ref = $self->_build_message_from_arrayref( [] );
	#~ }elsif( @other_args ){
		#~ ###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 1,
		#~ ###InternalReporTUpserT		name_space => $self->get_all_space( 'add_line::_find_the_actual_message' ),
		#~ ###InternalReporTUpserT		message =>[ 'Multiple values passed - treating the inputs like a list' ], } );
		#~ $message_ref = $self->_build_message_from_arrayref( [ $first_ref, @other_args ] );
	#~ }elsif( is_HashRef( $first_ref ) ){
		#~ ###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 1,
		#~ ###InternalReporTUpserT		name_space => $self->get_all_space( 'add_line::_find_the_actual_message' ),
		#~ ###InternalReporTUpserT		message =>[ 'Using the ref as it stands:', $first_ref ], } );
		#~ $message_ref = $self->_build_message_from_hashref( $first_ref );
	#~ }else{
		#~ ###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 3,
		#~ ###InternalReporTUpserT		name_space => $self->get_all_space( 'add_line::_find_the_actual_message' ),
		#~ ###InternalReporTUpserT		message =>[ 'Treating the input as a one element string' ], } );
		#~ $message_ref = $self->_build_message_from_arrayref( [ $first_ref ] );
	#~ }
	#~ ###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 3,
	#~ ###InternalReporTUpserT		name_space => $self->get_all_space( 'add_line' ),
	#~ ###InternalReporTUpserT		message =>[ "committing the message:", $message_ref ], } );
	#~ $self->_send_array_ref( $self->_get_file_handle, $message_ref );
	
	return 1;
}

sub set_up_the_data_path{
	my( $self, $args_ref ) = @_;
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 2,
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::set_up_the_data_path' ),
###InternalReporTUpserT		message =>[ 'setting up the upsert queries and testing merge state], } );
	my $error_ref;

	# Ensure a good connection
	if( $self->is_destination_ready and $self->has_table_name ){
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 0, 
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::set_up_the_data_path' ),
###InternalReporTUpserT		message =>[ 'Database and table are valid - building upsert elements' ], } );


		#Make any passed merge data changes
		my @db_col_minus_pkeys = @{$self->not_pkey_headers};
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 1, 
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::set_up_the_data_path' ),
###InternalReporTUpserT		message =>[ "Working with the column list:", @db_col_minus_pkeys ], } );
		if( $self->has_merge_rules or $self->_has_merge_modify ){
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 1, 
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::set_up_the_data_path' ),
###InternalReporTUpserT		message =>[ "Handling the merge_rules and merge_modify contents", 
###InternalReporTUpserT					$self->get_merge_rules, $self->_get_merge_modify ], } );
		
			# Merge the lists
			for my $key ( $self->_merge_modify_columns ){
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 1, 
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::set_up_the_data_path' ),
###InternalReporTUpserT		message =>[ "Adjusting the merge rule for header -$key- to: " . $self->_get_merge_modify_rule( $key ), ], } );
				$self->modify_merge_rule( $key => $self->_get_merge_modify_rule( $key ) );
			}
		
			# Check for allowed merge actions
			for my $key ( $self->merge_columns ){
				if( $self->is_primary_key( $key ) or $key eq 'source_list' ){ # Primary keys and source_list are special
					$self->remove_merge_rule( $key );
					next;
				}
				my $test_method = $self->get_merge_rule( $key ) ;
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 1, 
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::set_up_the_data_path' ),
###InternalReporTUpserT		message =>[ "Checking if the merge rule -$test_method- is allowed", ], } );
				if( $test_method =~ $merge_types ){
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 0, 
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::set_up_the_data_path' ),
###InternalReporTUpserT		message =>[ "Valid rule found" ], } );
				}else{
					push @$error_ref, $self->method_fails_gracefully( 
						$self->get_all_space( 'Upsert::set_up_the_data_path' ),
						'merge_rules setup', 'allowed key',
						"For key -$key- merge rule -$test_method- is not allowed" );
				}
			}
		
			# Check that all the table column names have merge rules
			for my $header ( @db_col_minus_pkeys ){ # Primary keys don't merge
				next if $header eq 'souce_list'; # the Source list has a default rule
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 0, 
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::set_up_the_data_path' ),
###InternalReporTUpserT		message =>[ "Checking for merge rule on header: $header", ], } );
				if( !$self->has_merge_rule( $header ) ){
					push @$error_ref, $self->method_fails_gracefully( 'Upsert::set_up_the_data_path',
						'merge_rules setup', 'matches the table',
						"Header -$header- requires a merge rule (but it's missing)"  );
				}
			}
		}
	
		# handle found errors
		if( $error_ref ){
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 0, 
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::set_up_the_data_path' ),
###InternalReporTUpserT		message =>[ "Failing merge rule tests:", $error_ref ], } );
			$self->_set_destination_ready( 0 );
			map{ $self->add_error_to_ref( $_ ) } @$error_ref;
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 1, 
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::set_up_the_data_path' ),
###InternalReporTUpserT		message =>[ "Current database state: " . $self->is_destination_ready ], } );
			return;
		}
		
		# Set the duplicate test
		my	@primary_keys = @{$self->get_primary_keys};
		my	$table_name = $self->get_table_name;
		my	$query_string = "SELECT* FROM $table_name WHERE ";
		my $i = 0;
		for my $column ( @primary_keys ){
			$query_string .= "$column = ?";
			$query_string .= ' AND ' if $i != $#primary_keys;
			$i++;
		}
		$query_string .= ';';
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 1, 
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::set_up_the_data_path' ),
###InternalReporTUpserT		message =>[ "Loading duplicate row query as: ", $query_string ], } );
		$self->_set_duplicate_row_sql( $self->prepare_statement( $query_string ) );
		
		# Set update row query
		my	$num_rows = int( scalar( @db_col_minus_pkeys )/ 40 );
		my	$remainder = scalar( @db_col_minus_pkeys ) % 40;
		my	$update_statement   = 	qq{UPDATE $table_name\nSET (\n};
			$update_statement  .=	"\t" . ( join ",\n\t", @db_col_minus_pkeys ) . "\n) = (\n\t";
		if( $num_rows ){
			for my $row ( 1 .. $num_rows ){
				$update_statement .= join( ', ', ('?') x 40 );
				$update_statement .= ",\n" if $row != $num_rows;
			}
			$update_statement .= ",\n" if $remainder;
		}
		$update_statement .= join( ', ', ('?') x $remainder ) if $remainder;
		$update_statement .= "\n) WHERE ( ";
		my	@input_list;
		for my $key ( @primary_keys ){
			push @input_list, "$key = ?";
		}
		$update_statement  .= join( ' AND ', @input_list ) . " )";
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 1, 
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::set_up_the_data_path' ),
###InternalReporTUpserT		message =>[ "Loading update query as:", $update_statement ], } );
		$self->_set_update_row_sql( $self->prepare_statement( $update_statement ) );
		
		# Set insert row statement
		my	@full_column_list = @{$self->get_headers};
			$num_rows = int( scalar( @full_column_list )/ 40 );
			$remainder = scalar( @full_column_list ) % 40;
		my	$insert_statement   = 	qq{INSERT INTO $table_name (\n};
			$insert_statement  .=	"\t" . ( join ",\n\t", @full_column_list ) . "\n) VALUES (\n\t";
		if( $num_rows ){
			for my $row ( 1 .. $num_rows ){
				$insert_statement .= join( ', ', ('?') x 40 );
				$insert_statement .= ",\n" if $row != $num_rows;
			}
			$insert_statement .= ",\n" if $remainder;
		}
		$insert_statement .= join( ', ', ('?') x $remainder ) if $remainder;
		$insert_statement .= "\n)\n";
###InternalReporTUpserT	$switchboard->master_talk( { report => 'log_file', level => 1, 
###InternalReporTUpserT		name_space => $self->get_all_space( 'Upsert::set_up_the_data_path' ),
###InternalReporTUpserT		message =>[ 'Insert query is:', $insert_statement,], } );
		$self->_set_insert_row_sql( $self->prepare_statement( $insert_statement ) );
	}
	
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has '_duplicate_row_sql' =>(
	isa		=> 'DBI::st',
	writer	=> '_set_duplicate_row_sql',
	clearer	=> '_clear_duplicate_row_sql',
	handles =>{
		execute_duplicate_row_sql	=> 'execute',
		get_duplicate_row_hash		=> 'fetchrow_hashref',
	},
);

has '_insert_row_sql' =>(
	isa		=> 'DBI::st',
	writer	=> '_set_insert_row_sql',
	clearer	=> '_clear_insert_row_sql',
	handles =>{
		execute_insert_row_sql => 'execute',
	},
);

has '_update_row_sql' =>(
	isa		=> 'DBI::st',
	writer	=> '_set_update_row_sql',
	clearer	=> '_clear_update_row_sql',
	handles =>{
		execute_update_row_sql => 'execute',
	},
);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

#~ sub _build_message_from_arrayref{
	#~ my( $self, $array_ref )= @_;
	#~ ###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	#~ ###InternalReporTCSV		name_space => $self->get_all_space( 'Upsert::add_line::_build_message_from_arrayref' ),
	#~ ###InternalReporTCSV		message =>[ 'Testing the message from an array ref: ' . ($self->should_test_first_row//0), $array_ref ], } );
	#~ my @expected_headers = $self->has_headers ? @{$self->get_headers} : ();
	#~ if( $self->should_test_first_row ){
		#~ ###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
		#~ ###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_arrayref' ),
		#~ ###InternalReporTCSV		message =>[ 'First row - testing if the list matches the header count' ], } );
		
		#~ if( $#$array_ref != $#expected_headers ){
			#~ if( scalar( @expected_headers ) == 0 ){
				#~ ###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 3,
				#~ ###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_arrayref' ),
				#~ ###InternalReporTCSV		message =>[ 'Adding dummy file headers' ], } );
				#~ my $dummy_headers;
				#~ map{ $dummy_headers->[$_] = "header_" . $_ } ( 0 .. $#$array_ref );
				#~ ###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 1,
				#~ ###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_arrayref' ),
				#~ ###InternalReporTCSV		message =>[ 'New dummy headers:', $dummy_headers ], } );
				#~ cluck "Setting dummy headers ( " . join( ', ', @$dummy_headers ) . " )" if !$ENV{hide_warn};
				#~ $self->set_reconcile_headers( 1 );
				#~ $self->set_headers( $dummy_headers );
			#~ }else{
				#~ cluck 	"The first added row has -" . scalar( @$array_ref ) .
						#~ "- items - but the report expects -" .
						#~ scalar( @expected_headers ) . "- items" if !$ENV{hide_warn};
			#~ }
		#~ }
		#~ $self->_test_first_row ( 0 );
	#~ }
	#~ ###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	#~ ###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_arrayref' ),
	#~ ###InternalReporTCSV		message =>[ 'Returning message ref:', $array_ref ], } );
	#~ return $array_ref;
#~ }

#~ sub _build_message_from_hashref{
	#~ my( $self, $hash_ref )= @_;
	#~ ###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	#~ ###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_hashref' ),
	#~ ###InternalReporTCSV		message =>[ 'Building the array ref from the hash ref: ' . ($self->should_test_first_row//0), $hash_ref ], } );
	
	#~ # Scrub the hash
	#~ my( $better_hash, @missing_list );
	#~ for my $key ( keys %$hash_ref ){
		#~ my $fixed_key = $self->_scrub_header_string( $key );
		#~ ###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
		#~ ###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_hashref' ),
		#~ ###InternalReporTCSV		message =>[ "Managing key -$fixed_key- for key: $key" ], } );
		#~ push @missing_list, $fixed_key if $self->should_test_first_row and !$self->_has_header_named( $fixed_key );
		#~ $better_hash->{$fixed_key} = $hash_ref->{$key};
	#~ }
	#~ $self->_test_first_row( 0 );
	#~ ###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 0,
	#~ ###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_hashref' ),
	#~ ###InternalReporTCSV		message =>[ "Updated hash message:", $better_hash,
	#~ ###InternalReporTCSV					"...with missing list:", @missing_list ], } );
	
	#~ # Handle first row errors
	#~ if( @missing_list ){
		#~ my @expected_headers = $self->has_headers ? @{$self->get_headers} : ();
		#~ push @expected_headers, @missing_list;
		#~ ###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 3,
		#~ ###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_hashref' ),
		#~ ###InternalReporTCSV		message =>[ "Updating the expected headers with new data", [@expected_headers] ], } );
		#~ cluck "Adding headers from the first hashref ( " . join( ', ', @missing_list ) . " )" if !$ENV{hide_warn};
		#~ $self->set_reconcile_headers( 1 );
		#~ $self->set_headers( [@expected_headers] );
	#~ }
	
	#~ # Build the array_ref
	#~ my $array_ref = [];
	#~ ###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	#~ ###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_hashref' ),
	#~ ###InternalReporTCSV		message =>[ 'Building an array ref with loookup:', $self->_get_header_lookup ], } );
	#~ for my $header ( keys %$better_hash ){
		#~ if( $self->_has_header_named( $header ) ){
			#~ $array_ref->[$self->_get_header_position( $header )] = $better_hash->{$header};
		#~ }else{
			#~ cluck "found a hash key in the message that doesn't match the expected header ( $header )" if !$ENV{hide_warn};
		#~ }
	#~ }
	
	#~ ###InternalReporTCSV	$switchboard->master_talk( { report => 'log_file', level => 2,
	#~ ###InternalReporTCSV		name_space => $self->get_all_space( 'add_line::_build_message_from_hashref' ),
	#~ ###InternalReporTCSV		message =>[ 'Returning message array ref:', $array_ref ], } );
	#~ return $array_ref;
#~ }
#~ #########1 Merge Actions      3#########4#########5#########6#########7#########8#########9
#~ #########1 Input : $input_value, $db_value, $modifier(optional)                 8#########9
#~ #########1 Output: $result, $result_value                                       8#########9

#~ sub use_new_data{
	#~ my ( $self, $input_value, $db_value ) = @_;
	#~ my ( $result, $final_value ) = ( 0, $db_value );
	#~ my $phone = Log::Shiras::Telephone->new(
				#~ name_space => $self->meta->name . '::add_row::use_new_data' );
	#~ no warnings 'uninitialized';
	#~ $phone->talk( level => 'debug',
		#~ message => [	"Reached the 'use_new_data' merge action input " .
						#~ "value -$input_value- and database value -$db_value-" ] );
	#~ if( !defined $input_value ){
		#~ $phone->talk( level => 'debug',
			#~ message => ["No value in the new row - the old value -$db_value- stands" ] );
	#~ }elsif( !defined $db_value and defined $input_value ){
		#~ $phone->talk( level => 'debug',
			#~ message => [	"No value in the database row - the new value " .
							#~ "-$input_value- will be used" ] );
		#~ ( $result, $final_value ) = ( 1, $input_value );
	#~ }elsif( $input_value ne $db_value ){
		#~ $phone->talk( level => 'debug',
			#~ message => [	"The database value -$db_value- does not equal the " .
							#~ "new value -$input_value- the new value will be used" ] );
		#~ ( $result, $final_value ) = ( 1, $input_value );
	#~ }
	#~ use warnings 'uninitialized';
	#~ return ( $result, $final_value );
#~ }

#~ sub use_old_data{
	#~ my ( $self, $input_value, $db_value ) = @_;
	#~ my ( $result, $final_value ) = ( 0, $db_value );
	#~ my $phone = Log::Shiras::Telephone->new(
				#~ name_space => $self->meta->name . '::add_row::use_old_data' );
	#~ if( !defined $db_value and defined $input_value ){
		#~ $phone->talk( level => 'debug', message =>[
			#~ "No value in the database row - the new value -$input_value- will be used" ] );
		#~ ( $result, $final_value ) = ( 1, $input_value );
	#~ }elsif( !defined( $db_value ) and !defined( $input_value ) ){
		#~ $phone->talk( level => 'debug', message =>[
			#~ "No value in either the database or new row" ] );
		#~ ( $result, $final_value ) = ( 1, undef );
	#~ }else{
		#~ $phone->talk( level => 'debug', message =>[
			#~ "Merge action 'use_old_data' will pass the database value -$db_value-" ] );
	#~ }
	#~ return ( $result, $final_value );
#~ }

#~ sub attempt_merge{
	#~ my ( $self, $input_value, $db_value ) = @_;
	#~ my ( $result, $final_value ) = ( 0, $db_value );
	#~ my $phone = Log::Shiras::Telephone->new(
				#~ name_space => $self->meta->name . '::add_row::attempt_merge' );
	#~ no warnings 'uninitialized';
	#~ $phone->talk( level => 'debug',
		#~ message => [	"Reached the 'attempt_merge' merge action input " .
						#~ "value -$input_value- and database value -$db_value-" ] );
	#~ use warnings 'uninitialized';
	#~ if( !defined $input_value ){
		#~ no warnings 'uninitialized';
		#~ $phone->talk( level => 'debug',
			#~ message => ["No value in the new row - the old value -$db_value- stands" ] );
		#~ use warnings 'uninitialized';
	#~ }elsif( !defined $db_value and defined $input_value ){
		#~ $phone->talk( level => 'debug',
			#~ message => [	"No value in the database row - the new value " .
							#~ "-$input_value- will be used" ] );
		#~ ( $result, $final_value ) = ( 1, $input_value );
	#~ }else{
		#~ my	$lc_input	= lc( $input_value );
		#~ my	$lc_db		= lc( $db_value );
			#~ $lc_input	=~ s/[^\x20-\x7E]//g;
			#~ $lc_db		=~ s/[^\x20-\x7E]//g;
		#~ if( $lc_input eq $lc_db ){
			#~ $phone->talk( level => 'debug',
				#~ message => [	"The database value -$db_value- effectivly equals the " .
								#~ "new value -$input_value- the database value will be used" ] );
		#~ }elsif( $lc_db =~ /\Q$lc_input\E/ ){
			#~ $phone->talk( level => 'debug',
				#~ message => [	"The new value -$input_value- is a subset of the " .
								#~ "database value -$db_value- the database value will be used" ] );
		#~ }elsif( $lc_input =~ /\Q$lc_db\E/ ){
			#~ $phone->talk( level => 'debug',
				#~ message => [	"The database value -$db_value- is a subset of the " .
								#~ "new value -$input_value- the new value will be used" ] );
			#~ ( $result, $final_value ) = ( 1, $input_value );
		#~ }else{
			#~ $phone->talk( level => 'debug',
				#~ message => [	"The new value -$input_value- and the " .
								#~ "database value -$db_value- are different and will be merged" ] );
			#~ ( $result, $final_value ) = ( 2, "$db_value ~|~ $input_value" );
		#~ }
	#~ }
	#~ return ( $result, $final_value );
#~ }

#~ sub use_old_except{
	#~ my ( $self, $input_value, $db_value, $modifier ) = @_;
	#~ my ( $result, $final_value ) = ( 0, $db_value );
	#~ my $phone = Log::Shiras::Telephone->new(
				#~ name_space => $self->meta->name . '::add_row::use_old_except' );
	#~ no warnings 'uninitialized';
	#~ $phone->talk( level => 'debug',
		#~ message => [	"Reached the 'use_old_except' merge action with input " .
						#~ "value -$input_value- and database value -$db_value- ",
						#~ 'Modified by:', $modifier ] );
	#~ if( !defined $db_value and defined $input_value ){
		#~ $phone->talk( level => 'debug',
			#~ message => [	"No value in the database row - the new value " .
							#~ "-$input_value- will be used" ] );
		#~ ( $result, $final_value ) = ( 1, $input_value );
	#~ }elsif( defined $db_value and defined $input_value ){
		#~ my	$no_match = 1;
		#~ for my $test_value ( @$modifier ){
			#~ if( $test_value eq $db_value ){
				#~ ( $result, $final_value ) = ( 1, $input_value );
				#~ $phone->talk( level => 'debug',
					#~ message => [	"The database value -$db_value- is excluded - the " .
									#~ "new value -$input_value- will be used" ] );
				#~ $no_match = 0;
				#~ last;
			#~ }
		#~ }
		#~ if( !$no_match ){
			#~ for my $test_value ( @$modifier ){
				#~ if( $test_value eq $input_value ){
					#~ ( $result, $final_value ) = ( 0, $db_value );
					#~ $phone->talk( level => 'debug',
						#~ message => [	"The new value -$input_value- is excluded as well!  " .
										#~ "the database value -$db_value- will still be used" ] );
					#~ last;
				#~ }
			#~ }
		#~ }
		#~ if( $no_match ){
			#~ ( $result, $final_value ) = ( 0, $db_value );
			#~ $phone->talk( level => 'debug',
				#~ message => [ "The database value -$db_value- is selected" ] );
		#~ }
	#~ }else{
		#~ ( $result, $final_value ) = ( 0, $db_value );
		#~ $phone->talk( level => 'debug',
			#~ message => [ "There is no change, the database value -$db_value- will be used" ] );
	#~ }
	#~ use warnings 'uninitialized';
	#~ return ( $result, $final_value );
#~ }

#~ sub use_new_except{
	#~ my ( $self, $input_value, $db_value, $modifier ) = @_;
	#~ my ( $result, $final_value ) = ( 0, $db_value );
	#~ my $phone = Log::Shiras::Telephone->new(
				#~ name_space => $self->meta->name . '::add_row::use_new_except' );
	#~ no warnings 'uninitialized';
	#~ $phone->talk( level => 'debug',
		#~ message => [	"Reached the 'use_new_except' merge action with input " .
						#~ "value -$input_value- and database value -$db_value- ",
						#~ 'Modified by:', $modifier ] );
	#~ if( !defined $input_value ){
		#~ $phone->talk( level => 'debug',
			#~ message => ["No value in the new row - the old value -$db_value- stands" ] );
	#~ }elsif( !defined $db_value and defined $input_value ){
		#~ $phone->talk( level => 'debug',
			#~ message => [	"No value in the database row - the new value " .
							#~ "-$input_value- will be used" ] );
		#~ ( $result, $final_value ) = ( 1, $input_value );
	#~ }elsif( $input_value ne $db_value ){
		#~ my	$no_match = 1;
		#~ for my $test_value ( @$modifier ){
			#~ if( $test_value eq $input_value ){
				#~ ( $result, $final_value ) = ( 0, $db_value );
				#~ $phone->talk( level => 'debug',
					#~ message => [	"The new value -$input_value- is excluded - the " .
									#~ "database value -$db_value- will be used" ] );
				#~ $no_match = 0;
				#~ last;
			#~ }
		#~ }
		#~ if( !$no_match ){
			#~ for my $test_value ( @$modifier ){
				#~ if( $test_value eq $db_value ){
					#~ ( $result, $final_value ) = ( 1, $input_value );
					#~ $phone->talk( level => 'debug',
						#~ message => [	"The database value -$db_value- is excluded as well!  " .
										#~ "the new value -$input_value- will still be used" ] );
					#~ last;
				#~ }
			#~ }
		#~ }
		#~ if( $no_match ){
			#~ ( $result, $final_value ) = ( 1, $input_value );
			#~ $phone->talk( level => 'debug',
				#~ message => [ "The new value -$input_value- is selected" ] );
		#~ }
	#~ }else{
		#~ ( $result, $final_value ) = ( 0, $db_value );
		#~ $phone->talk( level => 'debug',
			#~ message => [ "There is no change, the database value -$db_value- will be used" ] );
	#~ }
	#~ use warnings 'uninitialized';
	#~ return ( $result, $final_value );
#~ }

#~ sub use_later_date{
	#~ my ( $self, $input_value, $db_value, $modifier ) = @_;
	#~ my ( $result, $final_value ) = ( 0, $db_value );
	#~ my $phone = Log::Shiras::Telephone->new(
				#~ name_space => $self->meta->name . '::add_row::use_later_date' );
	#~ no warnings 'uninitialized';
	#~ $phone->talk( level => 'debug',
		#~ message => [	"Reached the 'use_later_date' merge action with input " .
						#~ "value -$input_value- and database value -$db_value- ",
						#~ 'Modified by:', $modifier ] );
	#~ if( !defined $input_value ){
		#~ $phone->talk( level => 'debug',
			#~ message => ["No value in the new row - the old value -$db_value- stands" ] );
	#~ }elsif( !defined $db_value and defined $input_value ){
		#~ $phone->talk( level => 'debug',
			#~ message => [	"No value in the database row - the new value " .
							#~ "-$input_value- will be used" ] );
		#~ ( $result, $final_value ) = ( 1, $input_value );
	#~ }else{
		#~ my	@date_list;
		#~ my	$test_date = $self->set_date_three( $input_value )->clone;
		#~ push @date_list, $test_date;
		#~ push @date_list, $self->set_date_three( $db_value )->clone;
		#~ @date_list = sort @date_list;
		#~ if( !DateTime->compare_ignore_floating( $test_date, $date_list[1] ) ){
			#~ $phone->talk( level => 'debug', message =>[
				#~ "The new row value is more recent, the value -$input_value- will be used" ] );
			#~ ( $result, $final_value ) = ( 1, $input_value );
		#~ }
	#~ }
	#~ use warnings 'uninitialized';
	#~ return ( $result, $final_value );
#~ }



#########1 Phinish    	      3#########4#########5#########6#########7#########8#########9

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Log::Shiras::Report::MetaMessage - Add data to messages for reports

=head1 SYNOPSIS

	use MooseX::ShortCut::BuildInstance qw( build_class );
	use Log::Shiras::Report;
	use Log::Shiras::Report::MetaMessage;
	use Data::Dumper;
	my	$message_class = build_class(
			package => 'Test',
			add_roles_in_sequence => [
				'Log::Shiras::Report',
				'Log::Shiras::Report::MetaMessage',
			],
			add_methods =>{
				add_line => sub{ 
					my( $self, $message ) = @_;
					print Dumper( $message->{message} );
					return 1;
				},
			}
		);
	my	$message_instance = $message_class->new( 
			prepend =>[qw( lets go )],
			postpend =>[qw( store package )],
		); 
	$message_instance->add_line({ message =>[qw( to the )], package => 'here', });
	
	#######################################################################################
	# Synopsis output to this point
	# 01: $VAR1 = [
	# 02:           'lets',
	# 03:           'go',
	# 04:         	'to',
	# 05:           'the',
	# 06:           'store',
	# 07:           'here'
	# 08:         ];
	#######################################################################################
	
	$message_instance->set_post_sub(
		sub{
			my $message = $_[0];
			my $new_ref;
			for my $element ( @{$message->{message}} ){
				push @$new_ref, uc( $element );
			}
			$message->{message} = $new_ref;
		}
	);
	$message_instance->add_line({ message =>[qw( from the )], package => 'here', });
	
	#######################################################################################
	# Synopsis output addition to this point
	# 01: $VAR1 = [
	# 02:           'LETS',
	# 03:           'GO',
	# 04:           'FROM',
	# 05:           'THE',
	# 06:           'STORE',
	# 07:           'HERE'
	# 08:         ];
	#######################################################################################
	
	$message_instance = $message_class->new(
		hashpend => {
			locate_jenny => sub{
				my $message = $_[0];
				my $answer;
				for my $person ( keys %{$message->{message}->[0]} ){
					if( $person eq 'Jenny' ){
						$answer = "$person lives in: $message->{message}->[0]->{$person}" ;
						last;
					}
				}
				return $answer;
			}
		},
	);
	$message_instance->add_line({ message =>[{ 
		Frank => 'San Fransisco',
		Donna => 'Carbondale',
		Jenny => 'Portland' }], });
	
	#######################################################################################
	# Synopsis output addition to this point
	# 01: $VAR1 = [
	# 02:           {
	# 03:             'locate_jenny' => 'Jenny lives in: Portland',
	# 04:             'Donna' => 'Carbondale',
	# 05:             'Jenny' => 'Portland',
 	# 06:             'Frank' => 'San Fransisco'
	# 07:           }
	# 08:         ];
	#######################################################################################
	
	$message_instance->set_pre_sub(
		sub{
			my $message = $_[0];
			my $lookup = {
					'San Fransisco' => 'CA',
					'Carbondale' => 'IL',
					'Portland' => 'OR',
				};
			for my $element ( keys %{$message->{message}->[0]} ){
				$message->{message}->[0]->{$element} .=
					', ' . $lookup->{$message->{message}->[0]->{$element}};
			}
		} 
	);
	$message_instance->add_line({ message =>[{
		Frank => 'San Fransisco',
		Donna => 'Carbondale',
		Jenny => 'Portland' }], });
	
	#######################################################################################
	# Synopsis output addition to this point
	# 01: $VAR1 = [
	# 02:           {
	# 03:             'locate_jenny' => 'Jenny lives in: Portland, OR',
	# 04:             'Donna' => 'Carbondale, IL',
	# 05:             'Jenny' => 'Portland, OR',
	# 06:             'Frank' => 'San Fransisco, CA'
	# 07:           }
	# 08:         ];
	#######################################################################################
    
=head1 DESCRIPTION

This is Moose role that can be used by L<Log::Shiras::Report> to massage the message prior 
to 'add_line' being implemented in the report.  It uses the hook built in the to Report 
role for the method 'manage_message'.

There are five ways to affect the passed message ref.  Each way is set up as an L<attribute
|/Attributes> of the class.  Details of how each is implemented is explained in the 
Attributes section.

=head2 Warning

'hashpend' and 'prepend' - 'postpend' can conflict since 'hashpend' acts on the first 
message element as if it were a hashref and the next two act as if the message is a list.  
A good rule of thumb is to not use both sets together unless you really know what is going 
on.

=head2 Attributes

Data passed to ->new when creating an instance.  For modification of these attributes 
after the instance is created see the attribute methods.

=head3 pre_sub

=over

B<Definition:> This is a place to store a perl closure that will be passed the full
$message_ref including meta data.  The results of the closure are not used so any 
desired change should be done to the $message_ref itself since it is persistent.  The 
action takes place before all the other attributes are implemented so the changes will 
NOT be available to process.  See the example in the SYNOPSIS.

B<Default:> None

B<Required:> No

B<Range:> it must pass the is_CodeRef test

B<attribute methods>

=over

B<clear_pre_sub>

=over

B<Description> removes the stored attribute value

=back

B<has_pre_sub>

=over

B<Description> predicate for the attribute

=back

B<get_pre_sub>

=over

B<Description> returns the attribute value

=back

B<set_pre_sub( $closure )>

=over

B<Description> sets the attribute value

=back

=back

=back

=head3 hashpend

=over

B<Definition:> This will update the position %{$message_ref->{message}->[0]}.  If 
that position is not a hash ref then. It will kill the process with L<Carp> - 
confess.  After it passes that test it will perform the following assuming the 
attribute is retrieved as $hashpend_ref and the entire message is passed as 
$message_ref;

	for my $element ( keys %$hashpend_ref ){
		$message_ref->{message}->[0]->{$element} =
			is_CodeRef( $hashpend_ref->{$element} ) ? 
				$hashpend_ref->{$element}->( $message_ref ) : 
			exists $message_ref->{$hashpend_ref->{$element}} ? 
				$message_ref->{$hashpend_ref->{$element}} :
				$hashpend_ref->{$element} ;
	}
	
This means that if the value of the $element is a closure then it will use the results 
of that and add that to the message sub-hashref.  Otherwise it will attempt to pull 
the equivalent key from the $message meta-data and add it to the message sub-hashref or 
if all else fails just load the key value pair as it stands to the message sub-hashref.

B<Default:> None

B<Required:> No

B<Range:> it must be a hashref

B<attribute methods>

=over

B<clear_hashpend>

=over

B<Description> removes the stored attribute value

=back

B<has_hashpend>

=over

B<Description> predicate for the attribute

=back

B<get_all_hashpend>

=over

B<Description> returns the attribute value

=back

B<add_to_hashpend( $key => $value|$closure )>

=over

B<Description> this adds to the attribute and can accept more than one $key => $value pair

=back

B<remove_from_hashpend( $key )>

=over

B<Description> removes the $key => $value pair associated with the passed $key from the 
hashpend.  This can accept more than one key at a time.

=back

=back

=back

=head3 prepend

=over

B<Definition:> This will push elements to the beginning of the list 
@{$message_ref->{message}}.  The elements are pushed in the reverse order that they are 
stored in this attribute meaning that they will wind up in the stored order in the message 
ref.  The action assumes that 
the attribute is retrieved as $prepend_ref and the entire message is passed as 
$message_ref;

	for my $element ( reverse @$prepend_ref ){
		unshift @{$message_ref->{message}}, (
			exists $message_ref->{$element} ? $message_ref->{$element} :
			$element );
	}
	
Unlike the hashpend attribute it will not handle CodeRefs.

B<Default:> None

B<Required:> No

B<Range:> it must be an arrayref

B<attribute methods>

=over

B<clear_prepend>

=over

B<Description> removes the stored attribute value

=back

B<has_prepend>

=over

B<Description> predicate for the attribute

=back

B<get_all_prepend>

=over

B<Description> returns the attribute value

=back

B<add_to_prepend( $element )>

=over

B<Description> this adds to the end of the attribute and can accept more than one $element

=back

=back

=back

=head3 postpend

=over

B<Definition:> This will push elements to the end of the list @{$message_ref->{message}}.  
The elements are pushed in the order that they are stored in this attribute.  The action 
below assumes that the attribute is retrieved as $postpend_ref and the entire message is 
passed as $message_ref;

	for my $element ( reverse @$postpend_ref ){
		push @{$message_ref->{message}}, (
			exists $message_ref->{$element} ? $message_ref->{$element} :
			$element );
	}
	
Unlike the hashpend attribute it will not handle CodeRefs.

B<Default:> None

B<Required:> No

B<Range:> it must be an arrayref

B<attribute methods>

=over

B<clear_postpend>

=over

B<Description> removes the stored attribute value

=back

B<has_postpend>

=over

B<Description> predicate for the attribute

=back

B<get_all_postpend>

=over

B<Description> returns the attribute value

=back

B<add_to_postpend( $element )>

=over

B<Description> this adds to the end of the attribute and can accept more than one $element

=back

=back

=back

=head3 post_sub

=over

B<Definition:> This is a place to store a perl closure that will be passed the full
$message_ref including meta data.  The results of the closure are not used so any 
desired change should be done to the $message_ref itself since it is persistent.  The 
action takes place after all the other attributes are implemented so the changes will 
be available to process.  See the example in the SYNOPSIS.

B<Default:> None

B<Required:> No

B<Range:> it must pass the is_CodeRef test

B<attribute methods>

=over

B<clear_post_sub>

=over

B<Description> removes the stored attribute value

=back

B<has_post_sub>

=over

B<Description> predicate for the attribute

=back

B<get_post_sub>

=over

B<Description> returns the attribute value

=back

B<set_post_sub( $closure )>

=over

B<Description> sets the attribute value

=back

=back

=back

=head2 Methods

=head3 manage_message( $message_ref )

=over

B<Definition:> This is a possible method called by L<Log::Shiras::Report> with the 
intent of implementing the L<attributes|/Attributes> on each message passed to a 
L<Log::Shiras::Switchboard/reports>.  Actions taken on that message vary from attribute 
to attribute and the specifics are explained in each.  The attributes are implemented in 
this order.

	pre_sub -> hashpend -> prepend -> postpend -> post_sub
	

B<Returns:> the (updated) $message_ref

=back

=head1 GLOBAL VARIABLES

=over

=item B<$ENV{hide_warn}>

The module will warn when debug lines are 'Unhide'n.  In the case where the you 
don't want these notifications set this environmental variable to true.

=back

=head1 SUPPORT

=over

L<Log-Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 TODO

=over

B<1.> Nothing L<currently|/SUPPORT>

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

=head1 DEPENDENCIES

=over

L<perl 5.010|perl/5.10.0>

L<utf8>

L<version>

L<Moose::Role>

L<MooseX::Types::Moose>

L<Carp> - confess

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9