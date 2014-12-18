package Log::Shiras::Switchboard;
use version; our $VERSION = version->declare("v0.21_1");

use 5.010;
use MooseX::Singleton;
use MooseX::StrictConstructor;
use	MooseX::HasDefaults::RO;
use DateTime;
use Carp qw( croak );
our @CARP_NOT = qw(
		Log::Shiras::Switchboard
		Log::Shiras::Telephone
	);
use MooseX::Types::Moose qw(
		HashRef
		ArrayRef
		Bool
		Num
		Object
		Str
		RegexpRef
		CodeRef
    );
#~ use Data::Dumper;
#~ use Moose::Exporter;
#~ Moose::Exporter->setup_import_methods(
    #~ as_is => [ 'get_operator', ],#'get_telephone', 
#~ );
use MooseX::ShortCut::BuildInstance 0.008 qw( build_instance );
#~ use lib
	#~ '../../../lib',
	#~ '../../../../Data-Walk-Extracted/lib';
use Data::Walk::Extracted 0.024;
use Data::Walk::Prune 0.024;
use Data::Walk::Clone 0.024;
use Data::Walk::Graft 0.024;
use Data::Walk::Print 0.024;
use lib 
	'../lib', 
	'lib';
use Log::Shiras::Types qw(
		elevenArray
		elevenInt
		reportobject
		argshash
		yamlfile
		jsonfile
		filehash
	);
#~ with Log::Shiras::Caller =>{ VERSION => 0.018 };

#########1 Package Variables  3#########4#########5#########6#########7#########8#########9

my 	@default_levels = ( 
		'trace', 'debug', 'info', 'warn', 'error', 'fatal', 
		undef, undef, undef, undef, undef, 'eleven',# This one goes to eleven :^|
	);
my $time_zone = DateTime::TimeZone->new( name => 'local' );
our	$debug_filter = 0;
###### <where> - time_zone: $time_zone

#########1 import   2#########3#########4#########5#########6#########7#########8#########9

sub import {
    my( $class, @args ) = @_;
 
    my(%tags) = map { $_ => 1 } @args;
	my	$instance;
    if(exists $tags{':debug'}) {
		#~ print "Found :debug tag in Log::Shiras::Switchboard v0.21!\n";
        my $FILTER_MODULE = "Filter::Util::Call";
        if(! "require $FILTER_MODULE" ) {
            die "$FILTER_MODULE required with :debug" .
                "(install from CPAN)";
        }else{
			#~ print "'$FILTER_MODULE' found!\n";
		}
        eval "require $FILTER_MODULE" or die "Cannot pull in $FILTER_MODULE";
        Filter::Util::Call::filter_add(
            sub {
                my($status);
                s/^(\s*)###LogSD\s/$1         /mg if
                    ($status = Filter::Util::Call::filter_read()) > 0;
                $status;
                }
		);
		$debug_filter = 1;
		#~ print "debug filter set for Switchboard v0.21!\n";
        delete $tags{':debug'};
    }
 
    #~ if(exists $tags{':self_report'}) {
		#~ $instance //= shift->instance;#Returns a pre-existing instance if it exists
		#~ $instance->_set_self_report( sub{ s/^\s*###LogSSR//mg } );
		#~ if( !eval{ require Filter::Simple $self->_release_self_report } ){
            #~ die "$FILTER_MODULE required with :resurrect" .
                #~ "(install from CPAN)";
        #~ }
        #~ delete $tags{':resurrect'};
    #~ }
 
    if(keys %tags) {
        # We received an Option we couldn't understand.
        die "Unknown Option(s): @{[keys %tags]}";
    }
}

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has 'name_space_bounds' =>(
    traits	=> ['Hash'],
	is		=> 'ro',
	isa		=> HashRef[HashRef],
	reader	=> 'get_name_space',
	clearer	=> '_clear_all_name_space',
	writer	=> '_set_whole_name_space',
	default	=> sub{ {} },
	trigger	=> \&_clear_can_communicate_cash,
);

has 'reports' =>(
    traits	=> ['Hash'],
	is		=> 'ro',
	isa		=> HashRef[ArrayRef[reportobject]],
	reader	=> 'get_reports',
	writer	=> '_set_all_reports',
	handles	=>{
        #~ has_no_reports	=> 'is_empty',
		_set_report		=> 'set',
		get_report		=> 'get',
		remove_reports	=> 'delete',
	},
	default	=> sub{ {} },
);

has 'logging_levels' =>(
    traits	=> ['Hash'],
	is		=> 'ro',
	isa		=> HashRef[elevenArray],
	handles	=>{
		has_log_level 		=> 'exists',
		add_log_levels 		=> 'set',
		_get_log_levels		=> 'get',
		remove_log_levels 	=> 'delete',
	},
	writer	=> 'set_all_log_levels',
	reader	=> 'get_all_log_levels',
	default	=> sub{ {} },
);

has 'buffering' =>(
    traits	=> ['Hash'],
	is		=> 'ro',
	isa		=> HashRef[Bool],
	reader	=> 'get_all_buffering',
	writer	=> '_set_all_buffering',
	handles	=>{
        has_defined_buffering	=> 'exists',
		set_buffering			=> 'set',
		get_buffering			=> 'get',
		remove_buffering		=> 'delete',
	},
	default	=> sub{ {log_file => 0,} },
);

has 'self_report' =>(
	is 		=> 'ro',
	isa		=> Bool,
	default => 0,
	writer  => 'set_self_report',
);

has 'skip_up_caller' =>(
    traits	=> ['Array'],
	is		=> 'ro',
	isa		=> ArrayRef[RegexpRef|Str],
	writer	=> 'set_all_skip_up_callers',
	handles	=>{
        get_all_skip_up_callers	=> 'elements',
		add_skip_up_caller		=> 'push',
	},
	clearer	=> 'clear_all_skip_up_callers',
	default	=> sub{ [ qw(
		^Test::
		^Capture::
		\(eval\)
		^Class::MOP
	) ] },
);
		#~ TapWarn::__ANON__$

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

#Special MooseX::Singleton instantiation that pulls multiple instances into the same master case
sub get_operator{
	my	$instance	= shift->instance;#Returns a pre-existing instance if it exists
	my	$arguments	=
			( !@_ ) ? undef :
			( ( @_ > 1 ) and ( scalar( @_ ) % 2 == 0 ) ) ? { @_ } : 
			( is_yamlfile( $_[0] ) or is_jsonfile( $_[0] ) ) ? to_filehash( $_[0] ) :
				to_argshash( $_[0] );
	if( $arguments and exists $arguments->{conf_file} ){
		my $file_hash = to_filehash( $arguments->{conf_file} );
		delete $arguments->{conf_file};
		$arguments = $instance->graft_data( tree_ref => $arguments, scion_ref => $file_hash );
	}
	my $level = 0;
	my	$message = [ "Starting get operator" ];
	if( keys %$arguments ){
		$level = 2;
		push @$message, 'With updates to:' , keys %$arguments;
	}
	$instance->_internal_talk( { report => 'log_file', level => $level,###### Logging
		name_space => 'Log::Shiras::Switchboard::get_operator',
		message => $message, } );
	my @action_list;
	for my $key ( keys %$arguments ){
		push @action_list, $key;
		my $method_1 = "add_$key";
		my $method_2 = "set_$key";
		if( $instance->can( $method_1 ) ){
			$instance->$method_1( $arguments->{$key} );
		}else{
			if( is_HashRef( $arguments->{$key} ) ){
				$instance->$method_2( %{$arguments->{$key}} );
			}else{
				$instance->$method_2( $arguments->{$key} );
			}
		}
	}
	$instance->_internal_talk( { report => 'log_file', level => 2,###### Logging
		name_space => 'Log::Shiras::Switchboard::get_operator',
		message =>[ "Switchboard finished updating the following arguments: ", @action_list ], } );
	$instance->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::Switchboard::get_operator',
		message =>[ 'The switchboard instance:', $instance ], } );
	return $instance;
}

sub get_caller{
	my ( $self, $start_level ) = @_;
	my $caller_ref;
	my $level = ( defined $start_level ) ? $start_level : 2;
	$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
		name_space => 'Log::Shiras::Switchboard::get_caller',
		message => "Arrived at get_caller for level: " . ( $level ), } );
	my ( @upwards_caller_array, @last_value_list );
	my @base_caller_array = caller($level);
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::Switchboard::get_caller',
		message => [ 'Initial base caller list:', @base_caller_array ] } );
	if( !$base_caller_array[1] ){#Go down if you're too high!
		$level--;
		@base_caller_array = caller($level);
		$base_caller_array[3] = 'main';
		$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
			name_space => 'Log::Shiras::Switchboard::get_caller',
			message => 'Need to check one level lower', } );
	}
	@last_value_list = @base_caller_array[ 0 .. 3 ];
	$last_value_list[3] = $last_value_list[0];
	$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
		name_space => 'Log::Shiras::Switchboard::get_caller',
		message => [ 'Updated base caller list:', @base_caller_array ], } );
	my $pass = 0;
	CHECKSKIPLIST: while( !$pass ){
		$level++;
		@upwards_caller_array = caller($level);
		if( @upwards_caller_array ){
			$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
				name_space => 'Log::Shiras::Switchboard::get_caller',
				message => [ 'Upwards caller list:', @upwards_caller_array ], } );
			@last_value_list = @upwards_caller_array[ 0 ..3 ];
			for my $skip ( $self->get_all_skip_up_callers ){
				$self->_internal_talk( { report => 'log_file', level => 3,###### Logging
					name_space => 'Log::Shiras::Switchboard::get_caller',
					message => [ "Testing -" . $last_value_list[3] . "- against: $skip" ], } );
				if( $last_value_list[3] =~ /$skip/ ){
					$self->_internal_talk( { report => 'log_file', level => 3,###### Logging
						name_space => 'Log::Shiras::Switchboard::get_caller',
						message => [ "The upwards subroutine", $last_value_list[3],
							"is skiped by matching", $skip ], } );
					next CHECKSKIPLIST;
				}
			}
			$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
				name_space => 'Log::Shiras::Switchboard::get_caller',
				message => [ "PASS!! - No skip_list match found for: " . $last_value_list[3] ], } );
		}else{#Base state
			$self->_internal_talk( { report => 'log_file', level => 3,###### Logging
				name_space => 'Log::Shiras::Switchboard::get_caller',
				message => 'Ran out of space at the top of the caller stack!!!', } );
			last CHECKSKIPLIST;
		}
		$pass = 1;#Complete state
	}
	if( !$upwards_caller_array[3] ){#Go down if you're too high!
		@upwards_caller_array[0 .. 3] = @last_value_list;
	}
	$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
		name_space => 'Log::Shiras::Switchboard::get_caller',
		message => ['Final caller list:', @base_caller_array, @upwards_caller_array[0 .. 3]] } );
	@$caller_ref{ qw(
			package filename line subroutine hasargs wantarray
			evaltext is_require hints bitmask hinthash
			up_package up_file up_line up_sub
		) } = ( @base_caller_array, @upwards_caller_array[0 .. 3] );
	$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
		name_space => 'Log::Shiras::Switchboard::get_caller',
		message => [ 'Caller converted to a hash ref:', $caller_ref ], } );
	return $caller_ref;
}

sub add_name_space_bounds{
	my ( $self, $name_space_ref ) = @_;
	$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::add_name_space_bounds',
		message => [ 'Arrived at add_name_space_bounds with:', $name_space_ref ], } );
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::add_name_space_bounds',
		message =>	[ 'Current master name_space_bounds: ', $self->get_name_space ], 	} );
	my 	$new_sources = 	$self->graft_data(
							tree_ref 	=> $self->get_name_space,
							scion_ref	=> $name_space_ref,
						);
	my	$result = $self->_set_whole_name_space( $new_sources );
	
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::add_name_space_bounds',
		message =>	[ 'Updated master name_space_bounds:', $result ], 	} );
	return $result;
}

sub remove_name_space_bounds{
	my ( $self, $removal_ref ) = @_;
	my	$result;
	$self->_set_error_string( "'You are removing name space elements - There is no warning if you are removing important data!'" );
	$self->_internal_talk( { report => 'log_file', level => 3,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::remove_name_space_bounds',
		message => 'You are removing name space elements - There is no warning if you are removing important data!', } );
	$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::remove_name_space_bounds',
		message => [ 'Removing the elements:', $removal_ref ],				} );
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::remove_name_space_bounds',
		message => [ 'Pre-removal space:', $self->get_name_space ], } );
	$self->_set_whole_name_space(
		$result = $self->prune_data( 	tree_ref => $self->get_name_space, 	slice_ref => $removal_ref, )
	);
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::remove_name_space_bounds',
		message => [ 'the result of pruning is: ', $result ], } );
	return $result;
}

sub add_reports{
	my $self = shift;
	my %report_hash = ( scalar( @_ ) == 1 ) ? %{$_[0]} : @_ ;
	$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::add_reports',
		message =>	[ 'Arrived at add_reports with:', {%report_hash} ], } );
	$self->_internal_talk( { report => 'log_file', level => 0,
		name_space => 'Log::Shiras::SwitchBoard::add_reports',
		message =>	[ 'Current master reports:', $self->get_reports], } );
	for my $name ( keys %report_hash	){
		$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
			message => 'Adding output to the report named: ' . $name,
			name_space => 'Log::Shiras::SwitchBoard::add_reports', } );
		my $report_list = $self->get_report( $name ) // [];
		$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
			name_space => 'Log::Shiras::SwitchBoard::add_reports',
			message => [ 'Report list:', $report_list ], } );
		for my $report ( @{$report_hash{$name}} ){
			$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
				name_space => 'Log::Shiras::SwitchBoard::add_reports',
				message => [ 'processing:', $report], } );
			if( is_reportobject( $report ) ){
				$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
					message => 'no object creation needed for this output',
					name_space => 'Log::Shiras::SwitchBoard::add_reports', } );
			}else{
				$report = to_reportobject( $report );
				$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
					name_space => 'Log::Shiras::SwitchBoard::add_reports',
					message => [ 'after building the instance:', $report ], } );
			}
			push @{$report_list} , $report;
		}
		$self->_set_report( $name => $report_list );
	}
	
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::add_reports',
		message =>	[ 'Updated master name_space_bounds:', $self->get_name_space ], } );
	return 1;
}

sub get_log_levels{
	my ( $self, $report ) = @_;
	$report //= 'log_file';
	my	$output;
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::get_log_levels',
		message => "Reached get_log_levels for report: $report", } );
	my  $x = 0;
	if( $self->has_log_level( $report ) ){
		$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
			name_space => 'Log::Shiras::SwitchBoard:get_log_levels',
			message => "Custom log level for -$report- found", } );
		$output = $self->_get_log_levels( $report );
	}else{
		$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
			name_space => 'Log::Shiras::SwitchBoard::get_log_levels',
			message => "No custome log levels in force for -$report- sending the defaults", } );
		$output = [ @default_levels ];
	}
	no warnings 'uninitialized';#OK to have undef at some levels
	$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::get_log_levels',
		message => "Returning the log levels for -$report-" . join( ', ', @$output ), } );
    use warnings 'uninitialized';
	return $output;
}

sub send_buffer_to_output{
    my ( $self, $report ) = @_;
	$report //= 'log_file';
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::send_buffer_to_output',
		message => "Reached send_buffer_to_output for report: $report", } );
	my  $x = 0;
	if(	!$self->has_defined_buffering( $report ) or !$self->get_buffering( $report ) ){
		$self->_internal_talk( { report => 'log_file', level => 3,###### Logging
			name_space => 'Log::Shiras::SwitchBoard::send_buffer_to_output',
			message => "Attempting to send buffer to output when no buffering is in force!", } );
		$self->_set_error_string( "Attempting to send buffer to output when no buffering is in force!" );
	}else{
		$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
			name_space => 'Log::Shiras::SwitchBoard::send_buffer_to_output',
			message => "Flushing the buffer ...", } );
		$x = $self->_flush_buffer( $report );
	}
	$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::send_buffer_to_output',
		message => "Returning from attempt to flush buffer with: $x", } );
    return $x;
}

sub clear_buffer{
	my ( $self, $report ) = @_;
	$report //= 'log_file';
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::clear_buffer',
		message => "Reached clear_buffer for report: $report", } );
	my  $x = 0;
	if(	!$self->has_defined_buffering( $report ) or !$self->get_buffering( $report ) ){
		$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
			name_space => 'Log::Shiras::SwitchBoard:clear_buffer',
			message => "Attempting to clear a buffer to output when no buffering is in force!", } );
		$self->_set_error_string( "Attempting to empty a buffer when no buffering is in force!" );
		$x = 0;
	}else{
		$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
			name_space => 'Log::Shiras::SwitchBoard::clear_buffer',
			message => "clearing the buffer ...", } );
		$self->_set_buffer( $report => [] );
		$x = 1;
	}
	$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
		name_space => 'Log::Shiras::SwitchBoard::clear_buffer',
		message => "Returning from attempt to clear the buffer with: $x", } );
    return $x;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has '_data_walker' =>(
    is		=> 'ro',
	isa		=> 'Walker',
	default	=> sub{ build_instance(
		package => 'Walker',
		superclasses => ['Data::Walk::Extracted',],
		roles =>[
			'Data::Walk::Graft',
			'Data::Walk::Clone',
			'Data::Walk::Prune',
			'Data::Walk::Print',
		],
		skipped_nodes =>{
			OBJECT => 1,
			CODEREF => 1,
		},
		to_string => 1,
	) },
	handles =>[ qw(graft_data prune_data print_data ) ],
	required => 1,
	init_arg => undef,
);

has '_buffer' =>(
    traits	=> ['Hash'],
	is		=> 'ro',
	isa		=> HashRef[ArrayRef],
	handles	=>{
        has_buffer		=> 'exists',
		_set_buffer		=> 'set',
		get_buffer		=> 'get',
	},
	default	=> sub{ {} },
);

has '_test_buffer' =>(
    traits	=> ['Hash'],
	is		=> 'ro',
	isa		=> HashRef[ArrayRef],
	handles	=>{
        _has_test_buffer	=> 'exists',
		_set_test_buffer	=> 'set',
		_get_test_buffer	=> 'get',
	},
	default	=> sub{ {} },
	clearer	=> '_clear_all_test_buffers',
);

has '_last_error' =>(
    traits	=> ['String'],
	is		=> 'ro',
	isa		=> Str,
	handles	=>{
        _add_to_error	=> 'append',
	},
	default	=> sub{ q{} },
	clearer	=> '_clear_error_string',
	writer	=> '_set_error_string',
);

has '_can_communicate_cash' =>(
    traits	=> ['Hash'],
	is		=> 'ro',
	isa		=> HashRef,
	handles	=>{
        _has_can_com_cash	=> 'exists',
		_set_can_com_cash	=> 'set',
		_get_can_com_cash	=> 'get',
	},
	default	=> sub{ {} },
	clearer	=> '_clear_can_communicate_cash',
);

#~ has _debug_filter =>(
		#~ isa 		=> Bool,
		#~ writer		=> '_set_debug_filter',
		#~ predicate	=> 'has_debug_filter',
		#~ clearer		=> '_turn_debug_off',
	#~ );

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _attempt_to_report{
	my ( $self, $data_ref ) = @_;
	$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
		name_space => 'Log::Shiras::Switchboard::_attempt_to_report',
		message => [ 'Arrived at _attempt_to_report with:', $data_ref ], } );
	$data_ref->{date_time} = DateTime->now( time_zone => $time_zone );
	my 	$caller_ref = $self->get_caller( 2 );
	%$data_ref = ( %$caller_ref, %$data_ref );
	#~ $data_ref->{message} //= '';
	my 	$will_die = 0;
	#~ my 	$report 
	if( !$data_ref->{report} ){
		$data_ref->{report}= 'log_file';
		$self->_internal_talk( { report => 'log_file', level => 3,###### Logging
			name_space => 'Log::Shiras::Switchboard::_attempt_to_report',
			message => "No destination report defined will send to 'log_file'" } );
		$self->_set_error_string( "No destination report defined will send to 'log_file'" );
	}
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::Switchboard::_attempt_to_report',
		message => "Checking for requested input" } );
	my $x = 0;
	if( $data_ref->{ask} ){
		$self->_internal_talk( { report => 'log_file', level => 3,###### Logging
			name_space => 'Log::Shiras::Switchboard::_attempt_to_report',
			message => "Input is requested" } );
		my	$message =
				( exists $data_ref->{message} and ref $data_ref->{message} eq 'ARRAY' ) ? 
					"Adding to message -\n" . join( "\n", @{$data_ref->{message}} ) . "-\n" :
				( exists $data_ref->{message} ) ? 
					"Adding to message -$data_ref->{message}-\n" : '';
		$data_ref->{message} =
			( ref $data_ref->{message} eq 'ARRAY' ) ?
				$data_ref->{message} :
			( $data_ref->{message} ) ?
				[ $data_ref->{message} ] : [];
		push @{$data_ref->{message}}, ("Log::Shiras asked for input with: " . $data_ref->{ask});
		$message .= ( $data_ref->{ask} ) ? ( $data_ref->{ask} . ": " ) :
			"Log::Shiras is asking for input: ";
		print STDOUT $message;
		my 	$input = <>;
		chomp $input;
		if( $input ){
			push @{$data_ref->{message}}, $input;
			$x = $input;
		}
	}
	$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
		name_space => 'Log::Shiras::Switchboard::_attempt_to_report',
		message => [ 'Data ref finalized sending the following to message processing:', $data_ref ], } );
	my	$y = $self->_buffer_decision( $data_ref );
	$x	||= $y;
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::Switchboard::_attempt_to_report',
		message => [ 'Checking if this is a fatal message:', $data_ref ], } );
	if( $data_ref->{level} =~ /fatal/i ){
		no warnings 'uninitialized';
		my $message =
			( !$data_ref->{message} ) ? "Fatal call sent to the switchboard" :
			(
				( ref $data_ref->{message} eq 'ARRAY' ) ?
					join( ' ', @{$data_ref->{message}} ) :
					$data_ref->{message} 					) .
					"<- sent at a 'fatal' level";
		use warnings 'uninitialized';
		$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
			name_space => 'Log::Shiras::Switchboard::_attempt_to_report',
			message => "Final fata message: $message", } );
		croak $message;
	}
	return $x;
}

sub _buffer_decision{
	my ( $self, $report_ref ) = @_;
		$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
			name_space => 'Log::Shiras::Switchboard::_buffer_decision',
			message => [ 'Arrived at _buffer_decision with:', $report_ref ], } );
		$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
			name_space => 'Log::Shiras::Switchboard::_buffer_decision',
			message => "Checking if Test::Log::Shiras is active ...", } );
	if( $Test::Log::Shiras::last_buffer_position ){
		if( !$self->_has_test_buffer( $report_ref->{report} ) ){
			$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
				name_space => 'Log::Shiras::Switchboard::_buffer_decision',
				message => "This is a new buffer request for report " .
					"-$report_ref->{report}- turning the buffer on!", } );
			$self->_set_test_buffer( $report_ref->{report} =>[] );
		}
		$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
			name_space => 'Log::Shiras::Switchboard::_buffer_decision',
			message => "Loading the line to the test buffer", } );
		unshift @{$self->_get_test_buffer( $report_ref->{report} )}, $report_ref;
		while(	$#{$self->_get_test_buffer( $report_ref->{report} )} >
				$Test::Log::Shiras::last_buffer_position	){
			$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
				name_space => 'Log::Shiras::Switchboard::_buffer_decision',
				message => "The buffer has outgrown it's allowed size.  Reducing it from: " .
					$#{$self->_get_test_buffer( $report_ref->{report} )}, } );
			pop @{$self->_get_test_buffer( $report_ref->{report} )};
		}					
	}
	my $x = 0;
	$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
		name_space => 'Log::Shiras::Switchboard::_buffer_decision',
		message => "Checking if regular Log::Shiras buffer is active for: " .
			$report_ref->{report}, } );
	if(	$self->has_defined_buffering( $report_ref->{report} ) and
		$self->get_buffering( $report_ref->{report} ) 				){
		$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
			name_space => 'Log::Shiras::Switchboard::_buffer_decision',
			message => "The buffer is active - sending the message to the buffer (not the report).", } );
		if( !$self->has_buffer( $report_ref->{report} ) ){
			$self->_set_buffer( $report_ref->{report} =>[] );
		}
		push @{$self->get_buffer( $report_ref->{report} )}, $report_ref;
		$x = 'buffer';
	}else{
		$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
			name_space => 'Log::Shiras::Switchboard::_buffer_decision',
			message => "The buffer is not active - sending the message to the report.", } );
		$x = $self->_really_report( $report_ref );
	}
	$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
		name_space => 'Log::Shiras::Switchboard::_buffer_decision',
		message => "Returning: $x", } );
	return $x;
}

sub _really_report{
	my ( $self, $report_ref ) = @_;
	$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
		name_space => 'Log::Shiras::Switchboard::_really_report',
		message => [ 'Arrived at _really_report with:', $report_ref ], } );
	my $x = 0;
	my 	$report_array_ref = $self->get_report( $report_ref->{report} );
	if( $report_array_ref ){
		for my $report ( @{$report_array_ref} ){
			next if !$report;
			$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
				name_space => 'Log::Shiras::Switchboard::_really_report',
				message => [ 'sending message to -:' .  $report_ref->{report}, 
					'with message: ', $report_ref->{message} ], } );
			$report->add_line( $report_ref );
			$x++;
		}
	}else{
		my $message = "The report name -$report_ref->{report}- does not have any destination instances to use!";
		$self->_internal_talk( { report => 'log_file', level => 3,###### Logging
			name_space => 'Log::Shiras::Switchboard::_really_report',
			message => $message, } );
		$self->_set_error_string( $message );
	}
	$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
		name_space => 'Log::Shiras::Switchboard::_really_report',
		message => "Returning: $x", } );
	return $x;
}

sub _get_block_unblock_levels{
	my ( $self, $level_ref, $space_ref ) = @_;
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::Switchboard::_get_block_unblock_levels',
		message => [ 'Arrived at _get_block_unblock_levels for:', $space_ref ], } );
	$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
		name_space => 'Log::Shiras::Switchboard::_get_block_unblock_levels',
		message => [ 'Received the level ref:', $level_ref ], } );
	if( exists $space_ref->{UNBLOCK} ){
		$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
			name_space => 'Log::Shiras::Switchboard::_get_block_unblock_levels',
			message => [ 'Found an UNBLOCK at this level:', $space_ref->{UNBLOCK} ], } );
		for my $report ( keys %{$space_ref->{UNBLOCK}} ){
			$level_ref->{$report} = $space_ref->{UNBLOCK}->{$report};
		}
		$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
			name_space => 'Log::Shiras::Switchboard::_get_block_unblock_levels',
			message => [ 'level ref with UNBLOCK changes:', $level_ref ], } );
	}
	if( exists $space_ref->{BLOCK} ){
		$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
			name_space => 'Log::Shiras::Switchboard::_get_block_unblock_levels',
			message => "Found a BLOCK at this level.", } );
		for my $report ( keys %{$space_ref->{BLOCK}} ){
			delete $level_ref->{$report};
		}
		$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
			name_space => 'Log::Shiras::Switchboard::_get_block_unblock_levels',
			message => [ 'level ref with BLOCK changes:', $level_ref ], } );
	}
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::Switchboard::_get_block_unblock_levels',
		message => [ 'Returning the level ref:', $level_ref ], } );
	return $level_ref;
}

sub _convert_level_name_to_number{
	my ( $self, $level, $report ) = @_;
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::Switchboard::_convert_level_name_to_number',
		message => "Arrived at _convert_level_name_to_number with level -$level" .
			"- and report -$report-", } );
	my 	$x = 0;
	if( is_elevenInt( $level ) ){
		$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
			name_space => 'Log::Shiras::Switchboard::_convert_level_name_to_number',
			message => "-$level- is already an integer in the correct range.", } );
		$x = $level;
	}else{
		my	$level_ref =
				( !$report ) ?
					[ @default_levels ] :
				( $self->has_log_level( $report ) ) ?
					$self->get_log_levels( $report ) :
					[ @default_levels ] ;
		if(	!$level_ref ){
			$self->_internal_talk( { report => 'log_file', level => 3,###### Logging
				name_space => 'Log::Shiras::Switchboard::_convert_level_name_to_number',
				message => "After trying several options no level list could be isolated for report -" . 
						$report . "-.  Level -" . ( $level // 'UNDEFINED' ) . 
						"- will be set to 0 (These go to eleven)", } );
		}else{ 
			$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
				name_space => 'Log::Shiras::Switchboard::_convert_level_name_to_number',
				message =>[ 'Checking for a match to the level ref:', $level_ref ], } );
			my $found = 0;
			for my $word ( @$level_ref ){
				if( $word ){
					$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
						name_space => 'Log::Shiras::Switchboard::_convert_level_name_to_number',
						message => "Checking -$word- for a match.", } );
					if( $level =~ /^$word$/i ){
						$found = 1;
						$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
							name_space => 'Log::Shiras::Switchboard::_convert_level_name_to_number',
							message => "-$word- matches -$level-", } );
						last;
					}
				}else{
					$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
						name_space => 'Log::Shiras::Switchboard::_convert_level_name_to_number',
						message => "Skipping level -$x- since no level urgency word is defined.", } );
				}
				$x++;
			}
			if( !$found ){
				$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
					name_space => 'Log::Shiras::Switchboard::_convert_level_name_to_number',
					message => "No match was found for the level -$level-" .
					" assigned to the report -$report-", } );
				$x = 0;
			}
		}
	}
	$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
		name_space => 'Log::Shiras::Switchboard::_convert_level_name_to_number',
		message => "Returning -$level- as the integer: $x" } );
	return $x;
}

before [ qw( set_buffering remove_buffering ) ] => sub{
	my ( $self, @buffer_list ) = @_;
	$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
		name_space => 'Log::Shiras::Switchboard::_before_xxx_buffer',
		message => [ "Stopped 'before' modifying the buffer state with:", @buffer_list ], } );
	if( $buffer_list[1] and is_Bool( $buffer_list[1] ) ){
		my %buffer_modifications = @buffer_list;
		@buffer_list = ();
		for my $report ( keys %buffer_modifications ){
			$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
				name_space => 'Log::Shiras::Switchboard::_before_xxx_buffer',
				message => "Testing -$report- with setting: $buffer_modifications{$report}", } );
			### <where> - report: $report
			### <where> - level: $self->get_buffering( $report )
			$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
				name_space => 'Log::Shiras::Switchboard::_before_xxx_buffer',
				message => "Old -$report- with setting: " .
					( $self->get_buffering( $report ) // 'NULL' ), } );
			if( !$buffer_modifications{$report} and $self->get_buffer( $report ) ){
				$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
					name_space => 'Log::Shiras::Switchboard::_before_xxx_buffer',
					message => "Report -$report- needs flushing" } );
				push @buffer_list, $report;
			}
		}
	}
	my $count = 0;
	map{ $count += $self->_flush_buffer( $_ ) } @buffer_list;
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::Switchboard::_before_xxx_buffer',
		message => "A total of -$count- messages flushed" } );
	return $count;
};

after '_set_whole_name_space' => sub{ __PACKAGE__->_clear_can_communicate_cash };	

sub _flush_buffer{
	my ( $self, $report ) = @_;
	my $x = 0;
	$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
		name_space => 'Log::Shiras::Switchboard::_flush_buffer',
		message => "Arrived at _flush_buffer for: $report", } );
	if( $self->get_buffer( $report ) ){
		$self->_internal_talk( { report => 'log_file', level => 3,###### Logging
			name_space => 'Log::Shiras::Switchboard::_flush_buffer',
			message => "There are messages to be flushed for: $report", } );
		for my $message_ref ( @{$self->get_buffer( $report )} ) {
			$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
				name_space => 'Log::Shiras::Switchboard::_flush_buffer',
				message => "Sending: $message_ref->{message}", } );
			my $i = $self->_really_report( $message_ref );
			$x += $i;
		}
		$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
			name_space => 'Log::Shiras::Switchboard::_flush_buffer',
			message => "Clearing the -$report- buffer" , } );
		$self->clear_buffer( $report );
	}
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::Switchboard::_flush_buffer',
		message => "A total of -$x- messages flushed" } );
	return $x;
}

sub _can_communicate{
	my ( $self, $report, $level, $name_string ) = @_;
	$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
		name_space => 'Log::Shiras::Switchboard::_can_communicate',
		message => "Arrived at _can_communicate to see if report -$report- " .
			"will accept a call at the urgency of -$level- from the " .
			"name-space: $name_string" } );
	my	$cash_string = $name_string . $report . $level;
	my $pass = 0;
	my $x = "Report -$report- is NOT UNBLOCKed for the name-space: $name_string";
	if( $self->_has_can_com_cash( $cash_string ) ){
		( $pass, $x ) = @{$self->_get_can_com_cash( $cash_string )};
	}else{
		my	$source_space = $self->get_name_space;
		my 	@telephone_name_space = ( split /::/, $name_string );
		$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
			name_space => 'Log::Shiras::Switchboard::_can_communicate',
			message => [ 'Consolidating permissions for the name space:', @telephone_name_space ], } );
		my 	$level_ref = {};
		$level_ref = $self->_get_block_unblock_levels( $level_ref, $source_space );
		### <where> - level ref: $level_ref
		SPACETEST: for my $next_level ( @telephone_name_space ){
			$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
				name_space => 'Log::Shiras::Switchboard::_can_communicate',
				message => "Checking for additional adjustments at: $next_level", } );
			if( exists $source_space->{$next_level} ){
				$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
					name_space => 'Log::Shiras::Switchboard::_can_communicate',
					message => "The next level -$next_level- exists", } );
				$source_space = $source_space->{$next_level};
				$level_ref =	$self->_get_block_unblock_levels( $level_ref, $source_space );
				### <where> - level ref: $level_ref
			}else{
				$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
					name_space => 'Log::Shiras::Switchboard::_can_communicate',
					message => "Didn't find the next level -$next_level-", } );
				last SPACETEST;
			}
		}
		### <where> - level ref: $level_ref
		$self->_internal_talk( { report => 'log_file', level => 1,###### Logging
			name_space => 'Log::Shiras::Switchboard::_can_communicate',
			message => [ 'Final level collection is:', $level_ref ], } );
		$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
			name_space => 'Log::Shiras::Switchboard::_can_communicate',
			message => "Checking for the report name in the consolidated level ref", } );
		REPORTTEST: for my $key ( keys %$level_ref ){
			$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
				name_space => 'Log::Shiras::Switchboard::_can_communicate',
				message => "Testing: $key", } );
			if( $key =~ /$report/i ){
				$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
					name_space => 'Log::Shiras::Switchboard::_can_communicate',
					message => "Matched key to the target report: $report", } );
				my $allowed 	= $self->_convert_level_name_to_number( $level_ref->{$key}, $report );
				$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
					name_space => 'Log::Shiras::Switchboard::_can_communicate',
					message => "The allowed level for -$report- is: $allowed", } );
				my $attempted	= $self->_convert_level_name_to_number( $level, $report );
				$self->_internal_talk( { report => 'log_file', level => 0,###### Logging
					name_space => 'Log::Shiras::Switchboard::_can_communicate',
					message => "The attempted level for -$level- is: $attempted", } );
				if( $attempted >= $allowed ){
					$self->_internal_talk( { report => 'log_file', level => 2,###### Logging
						name_space => 'Log::Shiras::Switchboard::_can_communicate',
						message => "The message clears for report: $report", } );
					$pass = 1 ;
					### <where> - approved report: $report
				}else{
					$x = "The destination -$report- is UNBLOCKed but not to the -$level- level at the name space: $name_string";
				}
				last REPORTTEST;
			}
		}
		$self->_set_can_com_cash( $cash_string => [ $pass, $x ] );
	}
	if( !$pass ){
		$self->_internal_talk( { report => 'log_file', level => 3,###### Logging
			name_space => 'Log::Shiras::Switchboard::_can_communicate',
			message => $x, } );
		$self->_set_error_string( $x );
	}
	return $pass;
}

sub _internal_talk{
	my ( $self, $data_ref ) = @_;
	my $result = 0;
	my $self_report = $self->self_report;
	if(	$self->self_report ){
		$self->set_self_report( 0 );
		if( $self->_can_communicate( $data_ref->{report}, $data_ref->{level}, $data_ref->{name_space} ) ){
			my $caller_ref = $self->get_caller( 1 );
			%$data_ref = ( %$caller_ref, %$data_ref );
			$data_ref->{date_time} = DateTime->now( time_zone => $time_zone );
			$result = $self->_attempt_to_report( $data_ref );
		}
		$self->set_self_report( $self_report );
	}
	return $result;
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no MooseX::Singleton;
__PACKAGE__->meta->make_immutable(
	inline_constructor => 0,
);

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Log::Shiras::Switchboard - Log::Shiras message screening and delivery

=head1 DESCRIPTION

L<Shiras|http://en.wikipedia.org/wiki/Moose#Subspecies> - A small subspecies of 
Moose found in the western United States (of America).

This is the class for message traffic control in the 'Log::Shiras' package.  For a 
general overview of the whole package see L<the top level documentation 
|https://metacpan.org/module/Log::Shiras>.  All traffic is managed using L<name-spaces
|/name_space_bounds> and urgency levels.  The message traffic is (L<mostly
|https://metacpan.org/module/Log::Shiras::TapPrint>) expected to come from the companion 
class L<Log::Shiras::Telephone|https://metacpan.org/module/Log::Shiras::Telephone>.  
This class is also where instances of 'Report' classes are registered ( I suggest using 
L<Log::Shiras::Report|https://metacpan.org/module/Log::Shiras::Report> as a base from 
which to build instances ).  Finally, this class maintains the core hook to the 
L<Test::Log::Shiras|https://metacpan.org/module/Test::Log::Shiras> class.  

In order to make all these connections 'just work' without requiring you to write all 
the links explicitly I used L<MooseX::Singleton
|https://metacpan.org/module/MooseX::Singleton> to manage all these links.  For example, 
this allows a telephone to be set up without explicitly connecting it to a report at the 
time the telephone instance is created.  All these desired connections led me to either 
treat this class as a Singleton or use a global 'our' variable.  I just liked the 
singleton solution better.  Other (better, broader, or at least more creative) solutions 
L<are welcome|/Author>.

To get a new instance of this class you need to use the method L<get_operator
|/get_operator( %args )>.  MooseX::Singleton has some unique creation of an instance of 
the class (instantiation) requirements because of its nature. The instantiation for this 
class also requires that attributes be merged in a different way for each attribute type. 

=head2 Attributes

Data passed to L<get_operator|/get_operator( %args )> when creating an instance.  For 
modification of these attributes see the remaining L<methods|/get_caller( $level )> 
used to act on the operator.

=head3 name_space_bounds

=over

B<Definition:> This attribute stores the boundaries set for the name-space management of 
communications generally from L<Log::Shiras::Telephone
|https://metacpan.org/module/Log::Shiras::Telephone> message data sources. This includes 
where in the name-space, to which L<reports|/reports>, and at L<what level|/logging_levels> 
messages are allows to pass.  Name spaces are stored as a L<hash of hashes
|http://perldoc.perl.org/perldsc.html#HASHES-OF-HASHES> that goes as deep as needed.  To 
open collection of a specific 'report' name at a specific point in a name-space then build 
a hash ref that represents the name-space up to the targeted point and in the value 
(hashref) for that name-space key add the key 'UNBLOCK' with a hashref value containing 
report names as keys and the lowest UNBLOCKed urgency level for values.  Each UNBLOCKed 
report will remain UNBLOCKed at that level and deeper in the name-space until a new UNBLOCK 
key is listed containing that report with a new urgency level.  To block all reporting 
deeper in the namespace us the 'BLOCK' key.  The hashref value for a BLOCK key should 
contain report names but the values of these keys don't matter.  There are a couple of 
significant points for review;

=over

B<*> UNBLOCK and BLOCK should not be used as elements of the defined name-space

B<*> If a caller name-space is not listed or a report name is not explicitly 
UNBLOCKed then the report is blocked by default.

B<*> Initially the default report name 'log_file' is not UNBLOCKed.  It must be 
explicitly UNBLOCKed to be used.

B<*> UNBLOCKing or BLOCKing of a report can occur independant of it's existance.  
This allows the addition of a report later and have it work upon its creation.

B<*> If an UNBLOCK and BLOCK key exist at that same point in a namespace then 
the hashref associated with the UNBLOCK key is evaluated first and the hashref 
associated with the BLOCK key is evaluated second.  This means that the BLOCK 
command can negate a report urgency level setting that the UNBLOCK command 
just made.

B<*> Any name-space on the same branch (but deeper) as an UNBLOCK command remains 
UNBLOCKed for the listed report urgency levels until a deeper relevant UNBLOCK or 
BLOCK is registered.

B<*> When UNBLOCKing a report at a deeper level than an initial UNBLOCK setting the 
level can be set higher or lower than the initial setting.

B<*> BLOCK commands are only valuable deeper than an initial UNBLOCK command.  All 
BLOCK commands completly block the report(s) named for that point and deeper  
independant of the registered urgency value associated with report name in the 
BLOCK hashref.

B<*> The hash key whos hashref value contains an UNBLOCK hash key is the point in 
the namespace where the report is UNBLOCKed to the defined level.

=back

B<Default> all caller name-spaces are blocked (no reporting)

B<Range> The caller name-space is stored and searched as a hash of hashes.  No 
array refs will be correctly read as any part of the name-space definition.  At each 
level the namespace the switchboard will also recognize the special keys 'UNBLOCK' and 
'BLOCK' I<in that order>.  As a consequence UNBLOCK and BLOCK are not supported as 
name-space elements.  Each UNBLOCK (or BLOCK) key should have a hash ref of L<report
|/reports> name keys as it's value.  The hash ref of report name keys should contain 
the minimum allowed urgency level down to which the report is UNBLOCKed.  The value 
associated with any report key in a BLOCK hash ref is not tested since BLOCK closes 
all reporting from that point and deeper.

B<Example>

	name_space_bounds =>{
		Name =>{<-- name-space
			Space =>{<-- name-space
				UNBLOCK =>{
					log_file => 'warn'<-- report name and level
				},
				Boundary =>{<-- name-space
					UNBLOCK =>{
						log_file => 'trace',<-- report name and level changed
						special_report => 'eleven',<-- report name and level
					},
					Place =>{},<-- deeper name-space - log_file still 'trace'
				},
			},
		},
	}

B<Warning>: All active namespaces must coexist in the singleton.  New object 
intances can overwrite existing object instances namespaces.  No cross instance 
name-space protection is done. This requires conscious managment!  I<It is entirely 
possible to call for another operator that changes reporting for a namespace that 
was set differently by another active instance.>  Using L<unique names
|https://metacpan.org/module/Log::Shiras::Telephone#name_space> will help avoid 
unintentional conflicts.
		
=back

=head3 reports

=over

B<Definition:> This attribute stores report names and associated composed class 
instances for that name.  The attribute expects a L<hash of arrays
|http://perldoc.perl.org/perldsc.html#HASHES-OF-ARRAYS>.  Each hash key is the 
report name and the array contains the report instances associated with that name.  Each 
passed array element will be tested to see if it is an object that can( 'add_line' ).  
If not this code will try to coerce the passed reference into an object using 
L<MooseX::ShortCut::BuildInstance|https://metacpan.org/module/MooseX::ShortCut::BuildInstance>.

B<Default> no reports are active.  If a message is sent to a non-existant report 
name then nothing happens unless L<self reporting|/self_report> is fully enabled.  Then 
it is possible to collect various warning messages related to the failure of a 
message.

B<Example>

	reports =>{
		log_file =>[<-- report name
				Excited::Print->new,#<-- a reporting instance of a class ( see Synopsis )
				{#<-- MooseX::ShortCut::BuildInstance definition for a log file
					package => "Log::File::Shiras"#<-- name this (new) class (for Moosey meta-ness)
					superclasses => [#<-- build on the base report class
					   "Log::Shiras::Report"
					],
					roles => [#<-- add data formatting and file handling to the class
					   "Log::Shiras::Report::TieFile"
					   "Log::Shiras::Report::ShirasFormat",
					],
					filename => "file.log",#<-- name the log file
					header => "Date,File,Subroutine,Line,Data1,Data2,Data3",#<-- set the file header
					format_string => "%{date_time}P(m=>'ymd')s," .#<-- define the data output format
						"%{filename}Ps,%{inside_sub}Ps,%{line}Ps,%s,%s,%s",
				}
			],
		other_name =>[],#<-- name created but no report instances added (maybe later?)
	},
	
B<warning:> any re-definition of the outputs for a report name will only push the new 
report instance onto the existing report array ref.  To remove an existing report output 
instance you must L<delete|/remove_reports( @report_list )> all report instances and the 
report name and then re-implement the report name and it's outputs.
	
=back

=head3 logging_levels

=over

B<Definition:> The urgency level of a message L<can be defined
|https://metacpan.org/module/Log::Shiras::Telephone#level> by the sender for each 
message when the message is sent.  Then, in addition to name-space, messages can be 
filtered by the defined urgency levels.  This attribute stores custom urgency 
level name lists by report name to be used in place of the default list.  Each level name 
list associated with the report name is an array of up to twelve (12) elements.  Not all 
of the elements need to be defined.  There can be gaps between defined levels but 
counting undefined positions there can never be more than 12 total positions in the level 
array.  The priority is lowest first to highest last on the list.  Since there are 
default priority names already in place this attribute is a window dressing setting and 
not much more.

B<Default> The default array of priority / urgency levels is; ( L<These go to eleven
|http://en.wikipedia.org/wiki/Up_to_eleven#Original_scene_from_This_Is_Spinal_Tap> :)

	'trace', 'debug', 'info', 'warn', 'error', 'fatal', 
	undef, undef, undef, undef, undef, 'eleven',

Any report name without a custom priority array will use the default array. 

B<Example>

	logging_levels =>{
		log_file =>[ qw(<-- report name (others use the default list)
				foo
				bar
				baz
				fatal
		) ],
	}

B<fatal> The Switchboard will L<die|http://perldoc.perl.org/functions/die.html> 
for all messages sent with a priority or urgency level that matches qr/fatal/i.  The 
switchboard will complete all defined logging first before it dies when a 'fatal' level 
is sent.  'fatal' can be set anywhere in the custom priority list from lowest to highest 
but fatal is the only one that will die.  (priorities higher than fatal will not die) 
B<If the message is blocked for the message I<name-space, report, and level> then the 
code will NOT die.>  If 'fatal' is not found in the custom list then the urgency level 
of the sent message defaults to the lowest level, meaning the code will not die unless 
the report is UNBLOCKed to the lowest level at that point in the name-space.

=back

=head3 buffering

=over

B<Definition:> Buffering in this package is only valuable if you want to eliminate some 
of the sent messages after they were created.  Buffering allows for clearing of sent 
messages from between two save points.  For this to occur buffering must be on and 
L<flushes of the buffer|/send_buffer_to_output( $report_name )> to the report need to 
occur at all known good points.  When some section of prior messages are to be discarded 
then a L<clear_buffer|/clear_buffer( $report_name )> command can be sent and all buffered 
messages after the last flush will be discarded.  If buffering is turned off the 
messages are sent directly to the report for processing with no holding period.  This 
attribute accepts a hash ref where the keys are report names and the values are boolean 
where True = on and False = off values.

B<Default> All buffering is off

B<Example>

	buffering =>{
		log_file => 1,
	}

=back

=head3 self_report

=over

B<Definition:> This module includes pre-built self reporting messages targeted at the 
'log_file' report.  The urgency level of these messages range from 'trace' to 'warn'.  
If you wish to collect any or all of them set this attribute to 1 = on = True, set up the 
log file report to receive them, and then UNBLOCK the 'log_file' reporting in the 
targeted name-space to the level of detail that you wish to collect.  Each module in 
this package has L<a list|/Listing of Internal Name Spaces> of the available namespaces 
for that module.

B<Default> 0 = off = FALSE

=back

=head3 skip_up_caller

=over

B<Definition:> This module includes a fancied-up call to L<caller EXPR
|/get_caller( $level )>.  The method in this module adds a second level of caller 
information above the immediate level called.  While there are several caveats to these 
calls the most significant is that if you want to ignore some intermediate layers 
between the called $level and the level above you can add elements to this attribute that 
will match targeted levels to skip.  The elements of this attribute are matched against 
the subroutine field.  If all levels above are skipped the last skipped level is still 
added to the outcome of get_caller( $level ).

B<Default> Match any of the following elements to skip that level.

	qw(
		^Test::
		^Capture::
		\(eval\)
	)
	
B<Accepts:> an ArrayRef of strings or RegularexpRefs

=back

=head2 Methods

=head3 get_operator( %args )

=over

B<Definition:> This method replaces the call to -E<gt>new or other instantiation 
methods.  The Log::Shiras::Switchboard class is a L<MooseX::Singleton
|https://metacpan.org/module/MooseX::Singleton>  and as such needs to be called in a 
slightly different fashion.  This method can be used to either connect to the existing 
switchboard or start the switchboard with new settings.  Each call to this method will 
implement the settings passed in %args merging them with any pre-existing settings.  
Where pre-existing settings disagree with new settings the new settings take 
precedence.  So be careful!

B<Accepts:> The 'get_operator' function will accept a string that is either an existing 
L<YAML|https://metacpan.org/module/YAML> or L<JSON::XS
|https://metacpan.org/module/JSON::XS> config file name that will be converted into a 
data ref, it will accept a hash or hash ref that has attributes as the top keys with 
the attribute settings in the values, or it will accept a hash ref that includes a top 
key 'conf_file'. In this case the value of that key is processed as either a YAML or 
JSON file into a hash ref.  The remainer of the passed hash ref is then grafted into 
the hash retrived from the config file using the L<Data::Walk::Graft 'graft_data'
|https://metacpan.org/module/Data::Walk::Graft#graft_data-args-arg_ref> function.  
I<Note that any conflicts between the two will cause the passed hash to overwrite the 
config file hash using the graft_data rules.>  Acceptable file name extentions are; 
(.yaml .yml .json .jsn)  This accepts all L<attribute|/Attributes> settings as values 
attached to keys.

B<Returns:> an instance of the Log::Shiras::Switchboard class called an 'operator'.  
This operator can act on the switchboard to effect any future changes using the 
remaining methods.

=back

=head3 get_caller( $level )

=over

B<Definition:> This is basically the perl L<caller EXPR
|http://perldoc.perl.org/functions/caller.html> function repurposed for this class.  If 
the first attempt comes back empty it will go down one level and then try again.  The 
method returns a hash ref with following list in key => value pairs that match the 
queried caller;

	package, filename, line, subroutine, hasargs,
    wantarray, evaltext, is_require, hints, bitmask, hinthash
	
After the base values have been collected the method will try to go up one level to get 
the first four elements of the previous array.  Because there are cases where intermediate 
layers don't need to be tracked this class provides and L<attribute that will manage ignored 
levels|/skip_up_caller> that match the subroutine string.  The method will continue to go up 
skiping all matching levels until it gets a level without a match or an empty set.  In the 
empty set case it gives the last level lower even thought it matched.  This additional data 
is added to the caller hash ref using the 4 caller keys;

	up_package up_file up_line up_sub

B<Accepts:> the stack level to return - (0 is get_caller itself)

B<Returns:> a hash ref of caller values

=back

=head3 get_all_skip_up_callers

=over

B<Definition:> This returns the current list of L<skip_up_caller|/skip_up_caller> values

B<Accepts:> nothing

B<Returns:> an array ref of skip match values

=back

=head3 set_all_skip_up_callers( $array_ref )

=over

B<Definition:> This replaces all the current L<skip_up_caller|/skip_up_caller> list with a 
new one

B<Accepts:> an array ref of skip elements that are strings or regex refs (qr//)

B<Returns:> $array_ref

=back

=head3 add_skip_up_caller( $skip_value )

=over

B<Definition:> This L<push|http://perldoc.perl.org/functions/push.html>es another value to 
the existing L<skip_up_caller|/skip_up_caller> list

B<Accepts:> a string or regex ref (qr//)

B<Returns:> nothing

=back

=head3 clear_all_skip_up_callers

=over

B<Definition:> This clears the whole L<skip_up_caller|/skip_up_caller> list

B<Accepts:> nothing

B<Returns:> nothing

=back

=head3 get_name_space

=over

B<Definition:> This will return a HoH's with the complete currently active 
L<name-space bounds|/name_space_bounds>.

B<Accepts:> nothing

B<Returns:> a HoH ref

=back

=head3 add_name_space_bounds( $ref )

=over

B<Definition:> This will L<graft
|https://metacpan.org/module/Data::Walk::Graft#graft_data-args-arg_ref> more name-space 
boundaries onto the existing name-space.  I<The passed ref will be treated as the 
'scion_ref' using Data::Walk::Graft.>

B<Accepts:> a data_ref (must start at the root) of data to graft to the main 
name_space_bounds ref
 
B<Returns:> The updated name-space data ref

=back

=head3 remove_name_space_bounds( $ref )

=over

B<Definition:> This will L<prune
|https://metacpan.org/module/Data::Walk::Prune#prune_data-args> the name-space 
L<boundaries|/name_space_bounds> using the passed name-space ref. I<The passed ref will 
be treated as the 'slice_ref' using Data::Walk::Prune.>

B<Accepts:> a data_ref (must start at the root) of data used to prune the main 
name_space_bounds ref
 
B<Returns:> The updated name-space data ref

=back

=head3 get_reports

=over

B<Definition:> This will return a HoAoO's with the complete set of registered 
L<report|/reports> names and their object lists.

B<Accepts:> nothing

B<Returns:> a Hash of Arrays of Objects

=back

=head3 get_report( $report_name )

=over

B<Definition:> This will return an AoO's with the L<report|/reports> objects for that 
report name.

B<Accepts:> a report name

B<Returns:> an Array of Object (instances) that are registered for the identified report 
name.

=back

=head3 remove_reports( @report_list )

=over

B<Definition:> This will completely remove the L<report|/reports> name and it's 
registered object (instances) for each named report.

B<Accepts:> a list of report names

B<Returns:> 1

=back

=head3 add_reports( %args )

=over

B<Definition:> This will add more L<report|/reports> output instances to the existing 
named report registered instances.  If the items in the passed report list are not already 
report object instances that -E<gt>can( 'add_line' ) there will be an attempt to build 
them using L<MooseX::ShortCut::BuildInstance build_instance
|https://metacpan.org/module/MooseX::ShortCut::BuildInstance#build_instance-args-args>.  
If (and only if) the report name does not exist then the name will also be added to the 
report registry.

B<Accepts:> a hash of arrays with the report objects as items in the array

B<Returns:> 1

=back

=head3 has_log_level( $report_name )

=over

B<Definition:> Checks for the existence of a L<custom log level|/logging_levels> array

B<Accepts:> a report name

B<Returns:> 1

=back

=head3 add_log_levels( %args )

=over

B<Definition:> This will add L<custom log level|/logging_levels> arrays for report names

B<Accepts:> a L<fat comma|http://perldoc.perl.org/perlop.html#Comma-Operator> list 
with report names as keys and the level names in an array ref as the values.  B<Existing 
report names with custom log level arrays will be overwritten>.

B<Returns:> 1

=back

=head3 get_log_levels( $report_name )

=over

B<Definition:> This will return the L<custom log level|/logging_levels> names for a given 
report name in an array ref.  If no custom levels are defined it will return the default 
level list.

B<Accepts:> a report name

B<Returns:> an array ref of the defined log levels for that report.

=back

=head3 remove_log_levels( @report_list )

=over

B<Definition:> This will remove the L<custom log level|/logging_levels> list for each 
report name in the @report_list.  I<The default log levels will therefor come back into 
force.>

B<Accepts:> a list of report names

B<Returns:> 1

=back

=head3 set_all_log_levels( %args )

=over

B<Definition:> This will reset (from %args) the L<custom log level|/logging_levels> 
arrays that are in force.  I<All unlisted reports will use the default log levels.>

B<Accepts:> a L<fat comma|http://perldoc.perl.org/perlop.html#Comma-Operator> list with 
report names as keys and the level names in an array ref as the values.

B<Returns:> %args

=back

=head3 get_all_log_levels

=over

B<Definition:> This will return a hash of arrays with the complete set of 
L<custom log level|/logging_levels> arrays.

B<Accepts:> Nothing

B<Returns:> a hash ref of array refs

=back

=head3 get_all_buffering

=over

B<Definition:> This will return a hash ref of all managed L<buffer|/buffering> states.

B<Accepts:> Nothing

B<Returns:> a hash ref with the L<report|/reports> names as keys.

=back

=head3 has_defined_buffering( $report_name )

=over

B<Definition:> This will identify if L<buffering|/buffering> has been defined for a given 
$report_name.

B<Accepts:> a report name

B<Returns:> 1 = True if the report name IS registered (but not necessarily on!)

=back

=head3 set_buffering( %args )

=over

B<Definition:> This will (re)set the L<buffer|/buffering> state for all arguments in 
%args.

B<Accepts:>  a L<fat comma|http://perldoc.perl.org/perlop.html#Comma-Operator> list 
with report names as keys and the new (Bool) buffer state as the value for each key.

B<Returns:> 1

=back

=head3 get_buffering( $report_name )

=over

B<Definition:> This will return the L<buffer|/buffering> state associated with the 
$report_name.

B<Accepts:>  a report name

B<Returns:> a Boolean state associated with the buffer name (1|0)

=back

=head3 remove_buffering( @report_list )

=over

B<Definition:> This will remove L<buffer|/buffering> registration and state for all 
reports in the list ( @report_list ).

B<Accepts:>  a @report_list

B<Returns:> 1

=back

=head3 send_buffer_to_output( $report_name )

=over

B<Definition:> This will flush the contents of the named report L<buffer|/buffering> 
to all the report objects.

B<Accepts:>  a $report_name

B<Returns:> The number of times that L<add_line( $message )
|https://metacpan.org/module/Log::Shiras::Report#add_line-message_ref> was called to 
complete the buffer flush.

=back

=head3 has_buffer( $report_name )

=over

B<Definition:> This will identify if an actual L<buffer|/buffering> exists for this 
report name, as opposed to just being turned on.

B<Accepts:>  a $report_name

B<Returns:> A boolean value representing state

=back

=head3 get_buffer( $report_name )

=over

B<Definition:> This will return the L<buffer|/buffering> array ref with all it's 
contents.  (It will not flush the buffer)

B<Accepts:>  a $report_name

B<Returns:> An array ref of the buffer contents. (pre add_line processed)

=back

=head3 clear_buffer( $report_name )

=over

B<Definition:> This will remove all messages currently in the L<buffer|/buffering> 
without sending them to the report.

B<Accepts:>  a $report_name

B<Returns:> 1

=back

=head3 self_report

=over

B<Definition:> This will return the L<self_report|/self_report> state of the Switchboard.

B<Accepts:> Nothing (as a method)

B<Returns:> Bool ( 1 = On | 0 = Off )

=back

=head3 set_self_report( $bool )

=over

B<Definition:> This will change the L<self_report|/self_report> state of the Switchboard.

B<Accepts:> $bool ( 1 = On | 0 = Off )

B<Returns:> The new state

=back

=head3 print_data( $ref )

=over

B<Definition:> This is a function brought over from L<Data::Walk::Print
|https://metacpan.org/module/Data::Walk::Print> with the 'to_string' attribute set to 
1 (True).  This can be useful in rendering data structures in log statements.  
B<Beware it is slow! It is better used on the report side than the phone side.>


B<Accepts:> a data ref to be turned into a human readable string.  
See the L<module|https://metacpan.org/module/Data::Walk::Print#print_data-arg_ref-args-data_ref> 
for full documentation.

B<Returns:> The human readable string.

=back

=head3 graft_data( tree_ref =E<gt> $ref, scion_ref =E<gt> $ref )

=over

B<Definition:> This is a function brought over from L<Data::Walk::Graft
|https://metacpan.org/module/Data::Walk::Graft>

B<Accepts:> a data ref (scion_ref) for grafting and a tree ref to accept the graft.  
See the L<module|https://metacpan.org/module/Data::Walk::Graft#graft_data-args-arg_ref> 
for full documentation.

B<Returns:> The updated tree ref

=back

=head3 prune_data( tree_ref =E<gt> $ref, slice_ref_ref =E<gt> $ref )

=over

B<Definition:> This is a function brought over from L<Data::Walk::Prune
|https://metacpan.org/module/Data::Walk::Prune>

B<Accepts:> a data ref (slice_ref) for pruning and a tree ref to be pruned.  
See the L<module|https://metacpan.org/module/Data::Walk::Prune#prune_data-args> 
for full documentation.

B<Returns:> The updated tree ref

=back

=head1 Self Reporting

This logging package will L<self report|/self_report>.  It is possible to turn on 
different levels of logging to trace the internal actions of Log::Shiras.  All internal 
reporting is directed at the 'log_file' report.  In order to receive internal messages 
B<including warnings>, you need to set the 'self_report' attribute to 1 and then UNBLOCK 
the correct L<name_space|/name_space_bounds> for the targeted messages.  I determined 
which level each message should be and sent them with integer equivalent urgencies to 
allow for possible re-nameing of the log_file to custom levels without causing the self 
reporting to break.  If you are concerned with availability of messages or dispatched 
urgency level please let L<me|/AUTHOR> know.

=head2 Listing of Internal Name Spaces

=over

=item Log

=over

=item Shiras

=over

=item Switchboard

=over

=item get_caller

=item add_name_space_bounds

=item remove_name_space_bounds

=item add_reports

=item get_log_levels

=item send_buffer_to_output

=item clear_buffer

=item _attempt_to_report

=item _buffer_decision

=item _really_report

=item _get_block_unblock_levels

=item _convert_level_name_to_number

=item _before_xxx_buffer

=item _flush_buffer

=item _can_communicate

=back

=back

=back

=back

=head1 SYNOPSIS

This is pretty long so I put it at the end
    
	#!perl
	use lib 'lib', '../lib',;
	use Log::Shiras::Switchboard;
	use Log::Shiras::Telephone;
	$| = 1;
	my $fail_over = 0;# Set fail_over here
	### <where> - lets get ready to rumble...
	my $telephone = Log::Shiras::Telephone->new( fail_over => $fail_over );
	$telephone->talk( message => 'Hello World 0' );
	### <where> - No printing here (the switchboard is not set up) ...
	my 	$operator = Log::Shiras::Switchboard->get_operator(
			#~ self_report => 1,# required to UNBLOCK log_file reporting in Log::Shiras 
			name_space_bounds =>{
				main =>{
					UNBLOCK =>{
						# UNBLOCKing the quiet, loud, and run reports 
						# 	at main and deeper
						#	for Log::Shiras::Telephone->talk actions
						quiet	=> 'warn',
						loud	=> 'info',
						run		=> 'trace',
					},
				},
				Log =>{
					Shiras =>{
						Telephone =>{
							UNBLOCK =>{
								# UNBLOCKing the log_file report
								# 	at Log::Shiras::Telephone and deeper
								#	(self reporting)
								log_file => 'info',
							},
						},
						Switchboard =>{
							get_operator =>{
								UNBLOCK =>{
									# UNBLOCKing log_file
									# 	at Log::Shiras::Switchboard::get_operator
									#	(self reporting)
									log_file => 'info',
								},
							},
							_flush_buffer =>{
								UNBLOCK =>{
									# UNBLOCKing log_file
									# 	at Log::Shiras::Switchboard::_flush_buffer
									#	(self reporting)
									log_file => 'info',
								},
							},
						},
					},
				},
			},
			reports =>{
				loud =>[
					Print::Excited->new,
				],
				quiet =>[
					Print::Wisper->new,
				],
				log_file =>[
					Print::Log->new,
				],
				###########  Add a build_instance example
			},
			buffering =>{
				quiet => 1,
			},
		);
	### <where> - sending a message ...
	$telephone->talk( message => 'Hello World 1' );
	### <where> - message went to the log_file - didnt print ...
	$telephone->talk( report => 'quiet', message => 'Hello World 2' );
	### <where> - message went to the buffer - turning off buffering for the 'quiet' destination ...
	my 	$other_operator = Log::Shiras::Switchboard->get_operator(
			buffering =>{ quiet => 0, }, 
		);
	### <where> - should have printed what was in the buffer ...
	$telephone->talk(# level too low
		report  => 'quiet',
		level 	=> 'debug',
		message => 'Hello World 3',
	);
	$telephone->talk(# level OK
		report  => 'loud',
		level 	=> 'info',
		message => 'Hello World 4',
	);
	### <where> - should have printed here too...
	$telephone->talk(# level OK , report wrong
		report 	=> 'run',
		level 	=> 'warn',
		message => 'Hello World 5',
	);


	package Print::Excited;
	sub new{
		bless {}, shift;
	}
	sub add_line{
		shift;
		my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ?
						@{$_[0]->{message}} : $_[0]->{message};
		my @new_list;
		map{ push @new_list, $_ if $_ } @input;
		chomp @new_list;
		print '!!!' . uc(join( ' ', @new_list)) . "!!!\n";
	}


	package Print::Wisper;
	sub new{
		bless {}, shift;
	}
	sub add_line{
		shift;
		my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ?
						@{$_[0]->{message}} : $_[0]->{message};
		my @new_list;
		map{ push @new_list, $_ if $_ } @input;
		chomp @new_list;
		print '--->' . lc(join( ' ', @new_list )) . "<---\n";
	}

	package Print::Log;
	sub new{
		bless {}, shift;
	}
	sub add_line{
		shift;
		my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ? 
						@{$_[0]->{message}} : $_[0]->{message};
		#### <where> - input: @input
		my @new_list;
		map{ push @new_list, $_ if $_ } @input;
		chomp @new_list;
		printf( "subroutine - %-28s | line - %04d |\n\t:(\t%-31s ):\n", 
					$_[0]->{up_sub}, $_[0]->{line}, 
					join( "\n\t\t", @new_list ) 						);
	}
	1;
        
	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is -don't care- (off for speed)
	# 	the Log::Shiras::Telephone self reporting is BLOCKED
	# 	the Log::Shiras::Switchboard::get_operator self reporting is BLOCKED
	# 	the Log::Shiras::Switchboard::_flush_buffer self reporting is BLOCKED
	#	the fail_over attribute is NOT activated
	# 01: --->hello world 2<---
	# 02: !!!HELLO WORLD 4!!!
	#######################################################################################
			
	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is -don't care- (off for speed)
	# 	the Log::Shiras::Telephone self reporting is BLOCKED
	# 	the Log::Shiras::Switchboard::get_operator self reporting is BLOCKED
	# 	the Log::Shiras::Switchboard::_flush_buffer self reporting is BLOCKED
	#	the fail_over attribute is activated
	# 01: Hello World 0
	# 02: Hello World 1
	# 03: --->hello world 2<---
	# 04: Hello World 3
	# 05: !!!HELLO WORLD 4!!!
	# 06: Hello World 5
	#######################################################################################
			
	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is activated
	# 	the Log::Shiras::Telephone self reporting is UNBLOCKED to warn
	# 	the Log::Shiras::Switchboard::get_operator self reporting is UNBLOCKED to info
	# 	the Log::Shiras::Switchboard::_flush_buffer self reporting is UNBLOCKED to info
	#	the fail_over attribute is activated
	# 01: Hello World 0
	# 02: subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 03: 	:(	Switchboard finished updating the following arguments: 
	# 04: 		self_report
	# 05: 		buffering
	# 06: 		reports
	# 07: 		name_space_bounds ):
	# 08: subroutine - Log::Shiras::Telephone::talk | line - 0065 |
	# 09: 	:(	No report destination was defined so the message will be sent to -log_file- ):
	# 10: subroutine - Log::Shiras::Telephone::talk | line - 0071 |
	# 11: 	:(	No urgency level was defined so the message will be sent at level -11- (These go to eleven) ):
	# 12: subroutine - Log::Shiras::Telephone::talk | line - 0100 |
	# 13: 	:(	Message blocked by the switchboard!
	# 14: 		Report -log_file- is NOT UNBLOCKed for the name-space: main ):
	# 15: Hello World 1
	# 16: subroutine - Log::Shiras::Telephone::talk | line - 0071 |
	# 17: 	:(	No urgency level was defined so the message will be sent at level -11- (These go to eleven) ):
	# 18: subroutine - Log::Shiras::Telephone::talk | line - 0088 |
	# 19: 	:(	The message was sent to -buffer- destination(s) ):
	# 20: subroutine - Log::Shiras::Switchboard::get_operator | line - 0074 |
	# 21: 	:(	Starting get operator
	# 22: 		With updates to:
	# 23: 		buffering ):
	# 24: subroutine - Log::Shiras::Switchboard::_flush_buffer | line - 07771 |
	# 25: 	:(	There are messages to be flushed for: quiet ):
	# 26: --->hello world 2<---
	# 27:subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 28:	:(	Switchboard finished updating the following arguments: 
	# 29:		buffering ):
	# 30: subroutine - Log::Shiras::Telephone::talk | line - 0100 |
	# 31: 	:(	Message blocked by the switchboard!
	# 32: 		The destination -quiet- is UNBLOCKed but not to the -debug- level at the name space: main ):
	# 33: Hello World 3
	# 34: !!!HELLO WORLD 4!!!
	# 35: subroutine - Log::Shiras::Telephone::talk | line - 0088 |
	# 36: 	:(	The message was sent to -1- destination(s) ):
	# 37: subroutine - Log::Shiras::Telephone::talk | line - 0094 |
	# 38: 	:(	Message approved by the switchboard but it found no outlet! ):
	# 39: Hello World 5
	#######################################################################################

	#######################################################################################
	# Synopsis Screen Output for the following conditions
	#	the self_report attribute is activated
	# 	the Log::Shiras::Telephone self reporting is UNBLOCKED to info
	# 	the Log::Shiras::Switchboard::get_operator self reporting is UNBLOCKED to info
	# 	the Log::Shiras::Switchboard::_flush_buffer self reporting is UNBLOCKED to info
	#	the fail_over attribute is NOT activated
	# 01: subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 02: 	:(	Switchboard finished updating the following arguments: 
	# 03: 		self_report
	# 04: 		buffering
	# 05: 		reports
	# 06: 		name_space_bounds ):
	# 07: subroutine - Log::Shiras::Telephone::talk | line - 0065 |
	# 08: 	:(	No report destination was defined so the message will be sent to -log_file- ):
	# 09: subroutine - Log::Shiras::Telephone::talk | line - 0071 |
	# 10: 	:(	No urgency level was defined so the message will be sent at level -11- (These go to eleven) ):
	# 11: subroutine - Log::Shiras::Telephone::talk | line - 0100 |
	# 12: 	:(	Message blocked by the switchboard!
	# 13: 		Report -log_file- is not UNBLOCKed for the name-space: main ):
	# 14: subroutine - Log::Shiras::Telephone::talk | line - 0117 |
	# 15: 	:(	Failover is off and no reporting occured for:
	# 16:		-->Hello World 1<-- ):
	# 17: subroutine - Log::Shiras::Telephone::talk | line - 0071 |
	# 18: 	:(	No urgency level was defined so the message will be sent at level -11- (These go to eleven) ):
	# 19: subroutine - Log::Shiras::Telephone::talk | line - 0088 |
	# 20: 	:(	The message was sent to -buffer- destination(s) ):
	# 21: subroutine - Log::Shiras::Switchboard::get_operator | line - 0074 |
	# 22: 	:(	Starting get operator
	# 23: 		With updates to:
	# 24: 		buffering ):
	# 25: subroutine - Log::Shiras::Switchboard::_flush_buffer | line - 07771 |
	# 26: 	:(	There are messages to be flushed for: quiet ):
	# 27: --->hello world 2<---
	# 28:subroutine - Log::Shiras::Switchboard::get_operator | line - 0092 |
	# 29:	:(	Switchboard finished updating the following arguments: 
	# 30:		buffering ):
	# 31: subroutine - Log::Shiras::Telephone::talk | line - 0100 |
	# 32: 	:(	Message blocked by the switchboard!
	# 33: 		The destination -quiet- is UNBLOCKed but not to the -debug- level at the name space: main ):
	# 34: subroutine - Log::Shiras::Telephone::talk | line - 0117 |
	# 35: 	:(	Failover is off and no reporting occured for:
	# 36: 		-->Hello World 3<-- ):
	# 37: !!!HELLO WORLD 4!!!
	# 38: subroutine - Log::Shiras::Telephone::talk | line - 0088 |
	# 39: 	:(	The message was sent to -1- destination(s) ):
	# 40: subroutine - Log::Shiras::Telephone::talk | line - 0094 |
	# 41: 	:(	Message approved by the switchboard but it found no outlet! ):
	# 42: subroutine - Log::Shiras::Telephone::talk | line - 0117 |
	# 43: 	:(	Failover is off and no reporting occured for:
	# 44: 		-->Hello World 5<-- ):
	#######################################################################################

=head2 SYNOPSIS EXPLANATION

=head3 my $telephone = Log::Shiras::Telephone->new( fail_over => $fail_over )

This obtains an instance of the  L<Telephone
|https://metacpan.org/module/Log::Shiras::Telephone> class to send messages. It allows 
two L<attributes|https://metacpan.org/module/Log::Shiras::Telephone#Attributes>
to be set.  The name_space attribute affects when the message is reported.  The 
fail_over attribute opens a path to STDOUT for all unreported ->talk messages.  This 
allows the talk output to be reviewed in development on the fly without setting up a 
switchboard to see the core message.  a suggestion is to set up a script with a 
$fail_over variable at the top used for all new telephones.  That way you can change 
$fail_over in one place and affect the whole script output between debugging and 
production with a small (1|0) change.

=head3 $telephone->talk( message => 'Hello World 0' )

This is a first attempt to send a message.  Since the switchboard is not set up yet all 
messages are blocked.  The only time something happens here is if the fail_over attribute 
is set in the previous step.  If it is on then 'Hello World' goes to STDOUT.  If failover 
is blocked even the warning messages will not be collected.

=head3 my $operator = Log::Shiras::Switchboard->get_operator( %args )

This uses the get_operator method to get an instance of the 'Switchboard' class and sets 
the initial switchboard settings.

=head4 self_report => Bool

To access the self reporting features of this package you must turn this on!  As this 
attribute implies, the whole package has built-in logging messages to follow the action 
behind the scenes!.  These messages can be captured by UNBLOCKing the name-spaces of 
interest to the level of detail that you wish.  All internal messages are sent to the 
'log_file' report name.

=head4 name_space_bounds =>{ %args }

This is where the name-space bounds are defined.  Each UNBLOCK section can unblock many 
reports to a given urgency level.  Different levels of urgency for each report can be 
definied for each name-space level.

=head4 reports =>{ %args }

This is where the reports are defined for the switchboard.  Each 'report' key is a 
L<report|/reports> name addressable by a phone message.  The items in the array ref 
are report object instances.  For a pre-built class that only needs role modification 
review the documentation for L<Log::Shiras::Report
|https://metacpan.org/module/Log::Shiras::Report>

=head4 buffering =>{ %args }

This sets the switchboard buffering state by report name.

=head3 $telephone->talk( report => 'quiet'

This is a third attempt to send a message (with the same phone).  This time the message 
is approved but it is buffered since the message was sent to a report name with buffering 
turned on.

=head3 my $other_operator = Log::Shiras::Switchboard->get_operator( buffering =>{ quiet => 0, }, )

This opens another operator instance and sets the 'quiet' buffering to off.  I<This 
overwrites the original operators setting of on.>  As a consequence the existing buffer 
contents are flushed to the report instance(s).

=head3 package Print::Log

This is an example of a simple report class that includes formatting of the output.  
This package includes a default report class and a formatting role that should simplify 
building these classes.  see L<Log::Shiras::Report
|https://metacpan.org/module/Log::Shiras::Report>


=head1 SUPPORT

=over

L<github Log-Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 TODO

=over

B<1.> Create a (DESTROY) method to kill the active switchboard

B<2.> Update (DESTROY) to flush the buffer(s) on the way out

B<3.> Create a notation convention for a report instance created in one report name to be 
used in a different report name array.

B<4.> Investigate the possibility of an ONLY keyword instead 
of UNBLOCK - how would this be implemented?

B<5.> Add the top level caller file name to the message meta-data

B<6.> Add method to pull a caller($x) stack that can be triggered in the namespace 
boundaries.  Possibly this would be blocked on or off by talk() command (so only the 
first talk of the method would get it).

B<7.> Self report appears to be be UNBLOCKED by default?  That's bad - fix it.

B<8.> Add a no-mirror ask attribute for the switchboard.  (ask but don't log ask requests)

B<9.> Add a :self_report tag to act with a source filter to turn on source filtering

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

This software is copyrighted (c) 2012 and 2013 by Jed Lund.

=head1 DEPENDENCIES

=over

L<version|https://metacpan.org/module/version>

L<5.010|http://perldoc.perl.org/perl5100delta.html> (for use of 
L<defined or|http://perldoc.perl.org/perlop.html#Logical-Defined-Or> //)

L<DateTime|https://metacpan.org/module/DateTime>

L<MooseX::Singleton|https://metacpan.org/module/MooseX::Singleton>

L<Moose::Exporter|https://metacpan.org/module/Moose::Exporter>

L<MooseX::StrictConstructor|https://metacpan.org/module/MooseX::StrictConstructor>

L<MooseX::Types::Moose|https://metacpan.org/module/MooseX::Types::Moose>

L<MooseX::ShortCut::BuildInstance|https://metacpan.org/module/MooseX::ShortCut::BuildInstance>

L<Data::Walk::Extracted|https://metacpan.org/module/Data::Walk::Extracted>

L<Data::Walk::Prune|https://metacpan.org/module/Data::Walk::Prune>

L<Data::Walk::Print|https://metacpan.org/module/Data::Walk::Print>

L<Data::Walk::Graft|https://metacpan.org/module/Data::Walk::Graft>

L<Data::Walk::Clone|https://metacpan.org/module/Data::Walk::Clone>

L<Log::Shiras::Types|https://metacpan.org/module/Log::Shiras::Types>

=back

=head1 SEE ALSO

=over

L<Log::Shiras|https://metacpan.org/module/Log::Shiras>

L<Log::Shiras::Telephone|https://metacpan.org/module/Log::Shiras::Telephone>

L<Log::Shiras::TapPrint|https://metacpan.org/module/Log::Shiras::TapPrint>

L<Log::Shiras::TapWarn|https://metacpan.org/module/Log::Shiras::TapWarn>

L<Log::Shiras::Report|https://metacpan.org/module/Log::Shiras::Report>

L<Log::Log4perl|https://metacpan.org/module/Log::Log4perl>

L<Log::Dispatch|https://metacpan.org/module/Log::Dispatch>

L<Log::Report|https://metacpan.org/module/Log::Report>

=back

=cut

#########1#########2 <where> - main pod documentation end  6#########7#########8#########9