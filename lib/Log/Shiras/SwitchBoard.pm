package Log::Shiras::Switchboard;

use 5.010;
use MooseX::Singleton;
use MooseX::StrictConstructor;
use DateTime;
use POSIX;
use Carp qw( cluck confess );#
use version 0.94; our $VERSION = qv('0.013_001');
use MooseX::Types::Moose qw(
		HashRef
		ArrayRef
		Bool
		Num
		Object
    );
use Moose::Exporter;
Moose::Exporter->setup_import_methods(
    as_is => [ 'get_telephone', 'get_operator', ],#
);
use YAML::Any qw( LoadFile);
use IO::Callback;
use lib 
	'../lib', 
	'lib', 
	'../../../lib', 
	'../../../../Data-Walk-Extracted/lib',
	'../Data-Walk-Extracted/lib',
	'../../../../MooseX-ShortCut-BuildInstance/lib',
	'../MooseX-ShortCut-BuildInstance/lib';
use MooseX::ShortCut::BuildInstance 0.003 qw( build_instance );
use Data::Walk::Extracted 0.017;
use Data::Walk::Prune 0.011;
use Data::Walk::Clone 0.011;
use Data::Walk::Graft 0.013;
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;
	### <where> - Smart-Comments turned on for Log-Shiras-Switchboard ...
}
use Log::Shiras::Telephone 0.001;
use Log::Shiras::Types 0.013 qw(
		elevenArray
		elevenInt
		reportobject
		argshash
		yamlfile
		jsonfile
		filehash
	);

#########1 Package Variables  3#########4#########5#########6#########7#########8#########9

my 	@default_levels = (# This one goes to eleven :^|
		'trace', 'debug', 'info', 'warn', 
		'error', 'fatal', undef, undef, 
		undef, undef, undef, 'eleven',
	);
my $time_zone = DateTime::TimeZone->new( name => 'local' );
###### <where> - time_zone: $time_zone

#########1 Exported Methods   3#########4#########5#########6#########7#########8#########9

#Special MooseX::Singleton instantiation that pulls multiple instances into the same master case
sub get_operator{
	### <where> - Setting up a switchboard ...
	### <where> - parsing arguments to allow for a YAML file ...
	my	$class = __PACKAGE__;
	my 	$arguments = ( @_ > 1 ) ? { @_ } : $_[0] ;
	### <where> - the passed arguments are: $arguments
	if( $arguments ){
		$arguments = ( is_argshash( $arguments ) ) ? $arguments :
			to_argshash(
				( 	is_yamlfile( $arguments ) or 
					is_jsonfile( $arguments ) ) ?
						to_filehash( $arguments ) : $arguments );
	}
	### <where> - with arguments: $arguments
	my  $instance = $class->instance;#Returns a pre-existing instance if it exists
	### <where> - with instance: $instance
	for my $key ( keys %$arguments ){
		### <where> - setting up data for: $key
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
	##### <where> - instance: $instance
	return $instance;
}

sub get_telephone{
	my	$self = __PACKAGE__->instance;# Singleton trick
	### <where> - getting the permissions for this phone ...
	my	$name_space = $_[0];
	my 	$permissions_ref = $self->_get_permissions( undef, $name_space );
	### <where> - build the telephone based on the name_space rules: $permissions_ref
	my $phone_args;
	if( keys %$permissions_ref ){
		#### <where> - updated level ref: $permissions_ref
		$phone_args->{works} = 1;
		$phone_args->{level_ref} = $permissions_ref;
		$phone_args->{switchboard} = $self;
	}else{
		$phone_args->{works} = 0;
		if( $self->will_cluck ){
			cluck "The phone will not work in this name_space";
		}
	}
	return Log::Shiras::Telephone->_new( $phone_args );
}

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has 'name_space_bounds' =>(
    traits	=> ['Hash'],
	is		=> 'ro',
	isa		=> HashRef[HashRef],
	reader	=> 'get_name_space',
	clearer	=> '_clear_all_name_space',
	writer	=> '_set_whole_name_space',
    handles	=> {
        has_no_name_space 	=> 'is_empty',
    },
	default	=> sub{ {} },
);

has 'reports' =>(
    traits	=> ['Hash'],
	is		=> 'ro',
	isa		=> HashRef[ArrayRef[reportobject]],
	reader	=> 'get_reports',
	writer	=> '_set_all_reports',
	handles	=>{
        has_no_reports	=> 'is_empty',
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
		get_log_levels		=> 'get',
		remove_log_levels 	=> 'delete',
	},
	writer	=> 'set_all_log_levels',
	reader	=> 'get_all_log_levels',
	default	=> sub{ {
		log_file	=> [ @default_levels ],
		STDOUT		=> [ @default_levels ],
		WARN		=> [ @default_levels ],
	} },
);

has 'will_cluck' =>(
	is 		=> 'ro',
	isa		=> Bool,
	default => 0,
	writer  => 'set_will_cluck',
);

has 'ignored_callers' =>(
	is 		=> 'ro',
	isa		=> ArrayRef,
	traits	=> ['Array'],
	default => sub{ [ qw(
		^Test
		^IO::Callback
		^Carp
		^Log::Shiras::Switchboard
		^Log::Shiras::Telephone
		^Log::Shiras::Report
		^Smart::Comments
		^Data::Walk::
	) ] },
	writer  => 'set_ignored_callers',
	handles =>{
		add_ignored_callers => 'push',
	},
);

has 'buffering' =>(
    traits	=> ['Hash'],
	is		=> 'ro',
	isa		=> HashRef[Bool],
	reader	=> 'get_all_buffering',
	writer	=> '_set_all_buffering',
	handles	=>{
        has_no_buffering	=> 'is_empty',
		has_buffering		=> 'exists',
		set_buffering		=> 'set',
		get_buffering		=> 'get',
		remove_buffering	=> 'delete',
	},
	default	=> sub{ {log_file => 0,} },
);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub add_name_space_bounds{
	my ( $self, $name_space_ref ) = @_;
	### <where> - reached add_name_space_bounds with: $name_space_ref
	#### <where> - current master name space: $self->get_name_space
	my 	$new_sources = 	$self->graft_data(
							tree_ref 	=> $self->get_name_space,
							scion_ref	=> $name_space_ref,
						);
	$self->_set_whole_name_space( $new_sources );
	#### <where> - updated master name space: $self->get_name_space
	return 1;
}

sub add_reports{
	my $self = shift;
	my %report_hash = ( scalar( @_ ) == 1 ) ? %{$_[0]} : @_ ;
	### <where> - reached add_reports with: %report_hash
	#### <where> - current master reports: $self->get_reports
	for my $name ( keys %report_hash	){
		### <where> - processing report name: $name
		my $report_list = $self->get_report( $name ) // [];
		for my $report ( @{$report_hash{$name}} ){
			### <where> - adding an additional report to the global report variable: $report
			if( is_yamlfile( $report ) or is_jsonfile( $report ) ){
				### <where> - coercing filename: $report
				$report = to_filehash( $report );
			}
			### <where> - result: $report
			if( is_filehash( $report ) ){
				### <where> - coercing hash ref: $report
				$report = to_reportobject( $report );
			}
			###########################################################   TODO below
			#~ $report->_set_switchboard_hook( $self );
			### <where> - result: $report
			push @{$report_list} , $report;
		}
		$self->_set_report( $name => $report_list );
	}
	#### <where> - current reports: $self->get_reports
	return 1;
}

sub remove_name_space{
	my ( $self, $removal_ref ) = @_;
	### <where> - There will be no warning if you are cutting some other codes name space! ...
	### <where> - reached remove_name_space with: $removal_ref
	#### <where> - name space before pruning is: $self->get_name_space
	$self->_set_whole_name_space(
		$self->prune_data(
			tree_ref => $self->get_name_space,
			slice_ref => $removal_ref,
		)
	);
	#### <where> - the result of pruning is: $self->get_name_space
	return 1;
}

sub set_stdout_level{
	my ( $self, $level ) = @_;
	if( $self->will_cluck ){
		cluck "You are currently attempting to Hijack some STDOUT output.  " .
				"BEWARE, this will slow all printing down!!!!  " .
				"Additionally, all print statements in the reports using " .
				"STDOUT must 'print STDOUT' explicitly to avoid deep recursion.";
	}
	my $report_ref;
	$report_ref->{level} = $self->_convert_level_name_to_number( $level, 'STDOUT' );
	$report_ref->{report} = 'STDOUT';
	my	$code_ref = sub{
			### <where> - processing captured print statments at: (caller(1))[3]
			$report_ref->{message} = $_[0];
			$report_ref->{level_ref} = $self->_get_permissions( 'STDOUT' );
			### <where> - sending: $report_ref
			if( !$self->_attempt_to_report( $report_ref ) ){
				### <where> - no special reporting for this name_space at level: $report_ref->{level}
				print STDOUT $report_ref->{message};
			}
		};
	### <where> - re-pointing standard output to the new coderef ...
	select( IO::Callback->new('>', $code_ref)) or confess "Couldn't redirect STDOUT: $!";
	return 1;
}

sub set_warn_level{
	my ( $self, $level ) = @_;
	if( $self->will_cluck ){
		cluck "You are currently attempting to Hijack some WARN output.\n" .
				"BEWARE, this will slow all warnings down!!!!\n";
	}
	##### <where> - $SIG{__WARN__}: $SIG{__WARN__}
	my $report_ref;
	$report_ref->{level} = $self->_convert_level_name_to_number( $level, 'WARN' );
	$report_ref->{report} = 'WARN';
	my	$code_ref = sub{
			### <where> - processing captured print statments at: caller(1)
			$report_ref->{message} = $_[0];
			### <where> - message: $report_ref
			$report_ref->{level_ref} = $self->_get_permissions( 'WARN' );
			### <where> - sending: $report_ref
			if( !$self->_attempt_to_report( $report_ref ) ){
				### <where> - no special reporting for this name_space at level: $report_ref->{level}
				print STDOUT $report_ref->{message};
			}
		};
	### <where> - implement a sig handler for the new coderef ...
	$SIG{__WARN__} = $code_ref or die "Couldn't redirect __WARN__: $!";
	return 1;
}

sub clear_stdout_level{
	my ( $self, )= @_;
	select( STDOUT ) or 
			die "Couldn't reset STDOUT: $!";
	return 1;
}

sub clear_warn_level{
	my ( $self, )= @_;
	$SIG{__WARN__} = undef;
	return 1;
}

sub clear_buffer{
	my ( $self, $report_name ) = @_;
	$self->_set_buffer( $report_name => [], );
}

sub send_buffer_to_output {
    my ( $self, $report ) = @_;
	$report //= 'log_file';
    ### <where> - Reached send_buffer_to_output for report: $report
	my  $x = 0;
	if( !$self->has_buffering( $report ) or !$self->get_buffering( $report ) ){
		if( $self->will_cluck ){
			cluck "Attempting to send buffer to output when no buffering is in force";
		}
	}else{
		for( @{$self->get_buffer( $report )} ) {
			### <where> - Sending: $_
			my $i = $self->_really_report( $report, $_ );
			$x += $i;
		}
	}
    ### <where> - Clearing the buffer
    $self->clear_buffer( $report );
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
		],
		skipped_nodes =>{
			OBJECT => 1,
			CODEREF => 1,
		},
	) },
	handles =>[ qw(graft_data prune_data ) ],
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

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _attempt_to_report{
	my ( $self, $data_ref ) = @_;
	my 	$will_die = 0;
	### <where> - beginning attempt to report ...
	##### <where> - passed data: @_
	my 	$report = 'log_file';
	if( exists $data_ref->{report} ){
		$report = $data_ref->{report};
	}elsif( $self->will_cluck ){
		cluck "No report name provided.  This test will use -log_file-";
	}
	### <where> - target report is: $report
	if( exists $data_ref->{level} ){
		### <where> - level testing is required ...
		$will_die = 1 if $data_ref->{level} =~ /fatal/i;
		if( !exists $data_ref->{level_ref} ){
			### <where> - need to test the namespace ...
			$data_ref->{level_ref} = $self->_get_permissions( $report );
			### <where> - new data ref: $data_ref
			if(	!is_ArrayRef( $data_ref->{level_ref} ) or
				!exists $data_ref->{level_ref}->{$report}	){
				### <where> - the action is out of the namespace ...
				if( $self->will_cluck ){
					cluck "The -" . $report . 
							"- report is not defined at this point in the name_space";
				}
				return 0;
			}
		}
		my 	$name_space_level = $data_ref->{level_ref}->{$report};
		### <where> - name space level: $name_space_level
		if(	!defined $name_space_level ){
			### <where> - the caller is outside the name space ...
			if( $self->will_cluck ){
				cluck "This call is out of the namespace!";
			}
			return 0;
		}
		my 	$caller_level = $self->_convert_level_name_to_number(
								$data_ref->{level},
								$report,
							);
		### <where> - caller level: $caller_level
		if( $caller_level < $name_space_level ){
			### <where> - the caller is found in the name space but is not loud enough ...
			if( $self->will_cluck ){
				cluck "The caller level of -" . $data_ref->{level} .
						"- is not loud enough to trigger this report at this location " .
						"in the name space";
			}
			return 0;
		}
	}else{
		if( $self->will_cluck ){
			cluck "No telephone (urgency) level provided ... the report is approved by default";
		}
		### <where> - no level testing needed ...
	}
	### <where> - see if input is requested ...
	if( $data_ref->{ask} ){
		### <where> - input requested ...
		if( $SIG{__WARN__} ){
			print STDOUT "Log-Shiras is asking for some input\n";
		}else{
			cluck "Log-Shiras is asking for some input";
		}
		my 	$input = <>;
		chomp $input;
		push @{$data_ref->{message}}, $input;
	}
	### <where> - attempt to send the report ...
	my $x = 0;
	if( !$data_ref->{dont_report} ){
		### <where> - sending the output: $data_ref->{message}
		### <where> - collect the current info ...
		$data_ref = $self->_get_caller( $data_ref );
		$data_ref->{date_time} = DateTime->now( time_zone => $time_zone );
		#### <where> - updated data ref: $data_ref
		$x = $self->_maybe_report( $report, $data_ref );
	}
	### <where> - the end is near? ...
	if( $will_die ){
		### <where> - dieing ...
		my $message =
			( is_ArrayRef( $data_ref->{message} ) )?
				join( ' ', @{$data_ref->{message}} ) :
			( $data_ref->{message} ) ?
				$data_ref->{message} :
				'fatal phone call successfully placed';
		confess $message;
	}
	return $x;
}

sub _maybe_report{
	my ( $self, $report_name, $report_ref ) = @_;
	### <where> - reached _maybe_report for: $report_name
	### <where> - check if Test-Log-Shiras is active ...
	if( $Test::Log::Shiras::last_buffer_position ){
		### <where> - sending report line to the test buffer: $report_ref
		if( !$self->_has_test_buffer( $report_name ) ){
			$self->_set_test_buffer( $report_name =>[] );
		}
		unshift @{$self->_get_test_buffer( $report_name )}, $report_ref;
		while(	$#{$self->_get_test_buffer( $report_name )} >
				$Test::Log::Shiras::last_buffer_position	){
			### <where> - dropping the final line off the end ...
			pop @{$self->_get_test_buffer( $report_name )};
		}					
	}
	my $x = 0;
	if(	$self->has_buffering( $report_name ) and $self->get_buffering( $report_name ) ){
		### <where> - sending report line to the buffer: $report_ref
		if( !$self->has_buffer( $report_name ) ){
			$self->_set_buffer( $report_name =>[] );
		}
		push @{$self->get_buffer( $report_name )}, $report_ref;
		$x = 'buffer';
	}else{
		$x = $self->_really_report( $report_name, $report_ref );
	}
	### <where> - returning: $x
	return $x;
}

sub _really_report{
	my ( $self, $report_name, $report_ref ) = @_;
	### <where> - reached _really_report for: $report_name
	my $x = 0;
	my 	$report_array_ref = $self->get_report( $report_name );
	if( $report_array_ref ){
		for my $report ( @{$report_array_ref} ){
			### <where> - loading message to: $report
			### <where> - Sending: $report_ref
			$report->add_line( $report_ref );
			$x++;
		}
	}else{
		$x = "$report_name not active";
	}
	### <where> - returning: $x
	return $x;
}	

sub _get_report_access_levels{
	my ( $self, $level_ref, $space_ref ) = @_;
	### <where> - reached _get_report_access_levels with current space ref: $space_ref
	### <where> - updating the current level ref: $level_ref
	if( exists $space_ref->{UNBLOCK} ){
		### <where> - found an UNBLOCK at this level ...
		for my $report ( keys %{$space_ref->{UNBLOCK}} ){
			$level_ref->{$report} = $space_ref->{UNBLOCK}->{$report};
		}
	}else{
		### <where> - no UNBLOCK here ...
	}
	return $level_ref;
}

sub _convert_level_name_to_number{
	my ( $self, $level, $report ) = @_;
	### <where> - attempting to convert the level name: $level
	### <where> - for report: $report
	my 	$x = 0;
	if( is_elevenInt( $level ) ){
		### <where> - a number that falls in range was passed: $level
		$x = $level;
	}else{
		my	$level_ref =
				( !$report ) ?
					[ @default_levels ] :
				( $self->has_log_level( $report ) ) ?
					$self->get_log_levels( $report ) :
					[ @default_levels ] ;
		if(	!$level_ref and
			$self->will_cluck ){
				cluck "After trying several options no level list could be isolated for report -" . 
						$report . "-.  Level -" . ( $level // 'UNDEFINED' ) . 
						"- will be set to 0 (These go to eleven)";
		}else{ 
			my $found = 0;
			for my $word ( @$level_ref ){
				### <where> - checking: $word
				if( $word and $level =~ /^$word$/i ){
					$found = 1;
					last;
				}else{ 
					$x++;
				}
			}
			if( !$found and $self->will_cluck ){
				cluck "No match was found for the level -" . $level . "- assigned to the report -" .
						$report . "-";
				$x = 0;
			}
		}
	}
	### <where> - returning: $x
	return $x;
}

sub _get_permissions{
	my ( $self, $report, $name_line ) = @_;
	if( !$name_line	){
		$name_line = $self->_get_caller->{inside_sub};
		### <where> - caller is: $name_line
		if( $self->will_cluck ){
			cluck "No caller name space provided.  " .
					"Using the the caller name space -$name_line-.";
		}
	}
	my 	@telephone_name_space = ( split /::/, $name_line );
	### checking permissions for the name space: @telephone_name_space
	my 	$source_space = $self->get_name_space;
	my 	$level_ref = {};
	### <where> - use the switchboard to collect level rules for this name space ...
	$level_ref = $self->_get_report_access_levels( $level_ref, $source_space );
	SPACETEST: for my $next_level ( @telephone_name_space ){
		### <where> - checking: $next_level
		if( exists $source_space->{$next_level} ){
			### <where> - confirmed the next level exists ...
			$source_space = $source_space->{$next_level};
			$level_ref =	$self->_get_report_access_levels( 
								$level_ref, $source_space 
							);
		}else{
			last SPACETEST;
		}
	}
	### <where> - convert the level words to numbers ...
	for my $key ( keys %$level_ref ){
		$level_ref->{$key} = 
			$self->_convert_level_name_to_number( $level_ref->{$key}, $report );
	}
	### <where> - level ref: $level_ref
	return $level_ref;
}

sub _get_caller{
	my ( $self, $caller_ref ) = @_;
	### <where> - reached _get_caller ...
	my $level = 1;
	my $match_string = '(' . join( '|', @{$self->ignored_callers} ). ')';
	my @caller_array = caller($level++);
	my @last_caller;
	### <where> - checking first name_line: @caller_array
	##### <where> - against the string: $match_string
	while ( $caller_array[3] and $caller_array[3] =~ /$match_string/ ){
		@last_caller = @caller_array;
		### <where> - level: $level
		@caller_array = caller($level++);
		##### <where> - checking new name_line: @caller_array
	}
	@$caller_ref{ qw(
			package filename line subroutine hasargs wantarray
			evaltext is_require hints bitmask hinthash inside_sub
		) } = @last_caller;
	$caller_ref->{inside_sub} = ( $caller_array[3] ) ? $caller_array[3] : 'main' ;
	### <where> - caller is: $caller_ref
	return $caller_ref;
}

#~ sub DESTROY{
	#~ my ( $self, ) = @_;
	#~ ### <where> - getting the reports ...
	#~ ### <where> - current reports: $self->get_reports
#~ }
	

#~ sub DEMOLISH{
	#~ my ( $self, ) = @_;
	#~ ### <where> - clearing any STDOUT or WARN redirection ...
	#~ $self->clear_stdout_level;
	#~ $self->clear_warn_level;
	#~ ### <where> - current reports: $self->get_reports
	#~ ### <where> - Flush the buffers TODO ...
	#~ my $buffer_ref = $self->_buffer;
	#~ ### <where> - buffer ref: $buffer_ref
	#~ for my $report ( keys %$buffer_ref ){
		#~ $self->send_buffer_to_output( $report );
	#~ }
#~ }

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable(
	inline_constructor => 0,
);

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Log::Shiras::Switchboard - Moose based logging and reporting

=head1 SYNOPSIS
    
	#!perl
	use Modern::Perl;
	use Log::Shiras::Switchboard 0.013;
	my $telephone = get_telephone;
	#Switchboard not active
	$telephone->talk( message => 'Hello World 0' );
	my $operator = get_operator( 
			name_space_bounds =>{
				main =>{
					UNBLOCK =>{
						run => 'warn',
					},
				},
			},
			reports =>{
				run =>[
					Excited::Print->new,
				],
			},
		);
	$telephone = get_telephone;
	# use defaults
	$telephone->talk( message => 'Hello World 1' );
	$telephone->talk(# level too low
		report  => 'run',
		level 	=> 'debug',
		message => 'Hello World 2',
	);
	$telephone->talk(# level OK
		report  => 'run',
		level 	=> 'warn',
		message => 'Hello World 3',
	);
	$telephone->talk(# level OK , report wrong
		report 	=> 'other',
		level 	=> 'warn',
		message => 'Hello World 4',
	);

	package Excited::Print;
	sub new{
		bless {}, __PACKAGE__;
	}
	sub add_line{
		shift;
		my @input = ( ref $_[0] eq 'ARRAY' ) ? @{$_[0]} : @_;
		chomp @input;
		print '!!!' . join( ' ', @input ) . "!!!\n";
	}
	1;
        
    ###############################
    # Synopsis Screen Output
    # 01: !!!Hello World 1!!!
    # 02: !!!Hello World 3!!!
    ###############################
#########1#########2#########3#########4#########5#########6#########7#########8#########9
=head1 DESCRIPTION

L<Shiras|http://en.wikipedia.org/wiki/Moose#Subspecies> - A small subspecies of 
Moose found in the western United States (of America).

This is a Moose based logger with the ability to run lean or add functionality using a 
Moose object model.  While no specific element of this logger is unique to the 
L<sea|https://metacpan.org/search?q=Log> of logging modules on CPAN the API is.  
Additionally since the package drifts outside of the pure run logging that 
most loggers implement, I have been brazen enough to use different terms for some 
familiar concepts from the logging world.  Ultimatly the goal is to provide a base 
Moose class which can be used (and abused) for general input and output while leveraging 
some of the really cool flow established in the better logging models in use broadly on 
CPAN.  Some examples of concepts taken from the logging world include logging levels, 
logging name_spaces, config file management of logging, output formatting, and realtime 
input and 
output adjustements from outside of the information generating code.

A core (and intentional) design decision of this module is to split the functions of input and 
output handling into separate classes.   This allows the user to define the amount of overhead 
applied to input and output management.  Additionally for the two separate classes (possibly
running in separate instances) to communicate seamlessly with each other a third class is created 
to handle traffic.  This is primarily done through a global variable.  B<Warning this global varaible 
maintains a global logging name_space that requires conscious managment!>  At least in this initial 
release very little care is given to protecting an existing running name space from a new logging 
instance.  It is entirely possible to turn on a new logger and begin to collect information from a 
name_space that exists in a currently running instance.  Using class names as part of the registered 
name_space will help (but not fully eliminate) this risk.

=head1 TERMS

=head2 Source

=over

=head3 Definition

The timing and location of the information to be collected. 

=head3 Explanation

This term is analogous to "appender" in most logging systems.  Since the 
goal is to stretch the definition a little, the more generic term "source" is used instead.

=back

=head2 Sink

=over

=head3 Definition

The places and methods used for the endpoint of the collected data. 

=head3 Explanation

This term is analogous to "logger" in most logging systems.  Because the timing 
of the output and the purpose of the output can vary from a traditional "log" then 
the term is changed as well.

=back

=head2 Switchboard

=over

=head3 Definition

This is the global connection point for sources and sinks.

=head3 Explanation

The switchboard will only act if it is triggered by the sources.  The sinks will only 
be engaged if activated by the switchboard.

=back



##########################################

and 
formatter roles as desired.  The second part of the L</Synopsis>, L</$thirdinst> 
shows an example of a heavier implementation of sources with roles added.  
The question that comes up is why this package over any of the other (more mature) 
Loggers?  Specifically why not L<Log::Log4perl>?  And why intentionally add Moose 
overhead into a Logger?

=over

=item B<First>, Developing this Logger was a learning experience.  I don't claim any major 
conceptual leap here.  I'm just testing my knowledge of Moose and logging.  I do beleive that 
some of the minor API design decisions that I made here would break backwards compatability 
on the most popular sinks.

=item B<Second>, the Log4perl buffer doesn't allow for buffer clearance.  
meaning that I want to choose whether the buffer is loaded to the error file depending 
on branches in the code.  This allows for line logging as code persues a branch of 
investigation but then if the branch is later abandoned the logs for that branch can 
also be abandoned.

=item B<Third>, I wanted to provide some easy methods for directly accessing output used 
for logging.  Mostly for testing purposes.  Moose and L<Tie::File> did most of the work 
on this so I added direct access.

=item B<Fourth>, the Log4perl module doesn't handle the header of files that are 
dropped and then reconnected in the way I would like.  Meaning I only want the header 
at the top of the file not at the beginning of each connection to a persistant file.  
This module only loads the header on new files.

=item B<Fifth>, I wanted to be able roll method calls and subroutine references into the 
line formats.  I do this by using the Parsing::Formatter::ACMEFormat Role.  While the 
API isn't quite as mature as the Log4perl 'PatternLayout' it does support full 
sprintf formatting.  (see L<Parsing::sink::Formatter::ACMEFormat> for more details)  
Moreover, if you don't like my format role just write your own formatting role following 
the simple parameters listed in L<Parsing::sink::source>.

=item B<Sixth>, why Moose?  Well, first because my uses for this package are not speed 
critical.  I guess that in combination the ease of writing this, the learning experience, 
and the flexibility to add sources and formatters with a simple Moose Role far outweighed 
any speed hit associated with Moose as a technology.  No, I have not yet profiled this for 
speed optimizations.  Wherever I could I pushed the big time-hits to the startup of the 
code so that running it would be as fast as possible.

=item B<Seventh>, I wanted a one stop shop for output.  I think there are two standard 
output types in production code.  First is 'run' logging.  This is the way that code leaves 
tracks from the ongoing process that it follows.  Second is 'report' logging.  When data is 
processed the output of that process results in a new data set.  I really liked the flexibility 
and ease of definition shown in the currently popular logging modules for 'run' logging output 
and would like to extend that to 'report' logging.  This will allow me to define the 'report' 
and 'run' outputs in the code that I am writing but extract the destination and handling to a separate 
location for future flexibility.  Meaning that I wanted to write an output or logging data set 
into some code and then determine later whether to use it and how to use it.

=back

=head1 DESCRIPTION (How do you use it?)

As a design decision I broke the various main (perceived) elements 
of logging into descrete objects.

=over

=item B<L<Parsing::sink::TrafficControl>> The core call to output some data is managed 
with a TrafficControl instance.  TrafficControl instances are built with the auto exported 
L</get_pointsman> method.  For a script or module to log or report some data you would 
begin by getting a TrafficControl instance.  ex. my $deputyandy = get_pointsman  
$deputyandy can then send some traffic using the command L</send_traffic>.  ex. 
$deputyandy->send_traffic( 'myreport', 'Stuff I want in my report', Data1, Data2 )  
The TrafficControl instance $deputyandy will then take the first item in the list as 
the source to use and send the remaining list to that source for processing.  B<Warning> 
There will be no action if the called source isn't active or the current call from 
$deputyandy falls outside of the currently active sinkspace boundaries defined in 
L<Parsing::sink>.


=item B<L<Parsing::sink>> When logging is turned on the expected logging is managed in a 
global variable maintained from Parsing::sink.  B<Any new Parsing::sink instances will 
attempt to overwrite active data in the global Parsing::sink variable.>  I<See L</is_active> 
to test for currently active instances.>  If a previous instance is still active call ->new with 
no attributes and then use the modifiers to add logging requirements.  The risk here of 
course is logging name_space collisions.  The logging managament is broken into two concepts.  
Concept one is the collection of outputs labeled L</sources>.  Concept two is the collection 
of input gates or boundaries labeled L</sinks>.  See the attribute definitions for each to 
understand the specifics of setting and changing these.  Logging will only occur if,

=over

=item 1. a TrafficControl instance calls 

=item 2. an active source 

=item 3. within an approved logging space 

=item 4. (at the correct logging level for 'run' sinks)

=back

=item B<L<Parsing::sink::source>> Each source is a separate object that is 
build using the source.  The core source functionality is very minimal but can be 
significantly expanded using roles that work with the source API.  See the source 
documentation to understand the use of roles with the source.  sources can run 
stand alone as needed but when paired with Parsing::sink each built source 
instance is named and stored in the global Parsing::sink variable and is available 
for TrafficControl to call.


=item B<L<Test::Parsing::sink>> This is an extention of L<Test::Builder::Module>.  
the exported methods will work directy with any test script and provide TAP outputs per 
the TAP standard.  When the test module is active it also sets up a global variable 
that maintains a buffer of logged outputs by source.  Parsing::sink::source will 
double log the output to the global test buffer if the global variable is active.  
This allows testing of logged output without programmatically monitoring the source 
destinations.  If the source is used independently of Parsing::sink then the 
source output is logged under the name GENERIC for the purposes of this module.

=back

=head2 Attributes

Data passed to ->new when creating an instance.  For modification of these attributes 
see L</Methods>.  The ->new function will either accept fat comma lists, a complete 
hash ref that has the possible sources as the top keys, or a YAML based config file 
that passes a hash ref with sources as top keys.  Possible Combinations of these are 
on the TODO list.

=head3 sources

=over

=item B<Definition:> this is where all sources for global logging are initially 
defined.  This module allows for infinite named sources that essentially act as 
report writers. but there is one special source, the 'run' source, that acts like 
a traditional Log::Log4perl sink and can only be called by logging level and not name 
( debug, info, warn, fatal ).  All other sources only have one logging level and are 
called by name.

=item B<Default> No default provided.  This attribute is required! I<see Range>

=item B<Range> Defined by the called sinks.  You can have more sources built than 
sinks called but you must always build an source for every called sink or the 
module will die!  The default source behaviour prints to the screen and joins the 
passed list with commas.  For modification of this behaviour see the more detailed 
documentation at L<Parsing::sink::source>.  A basic run source that outputs to 
the screen and builds the output line with comma joined data from the passed list is 
defined by:

=over

=item sources => { run =>{} },
    
=back
    
=back

=head3 Sinks

=over

=item B<Definition:> Think of this as defining the boundaries of logging.  This module 
essentially thinks of all logging in a HoHoH... name_space.  Unless otherwize provided, 
the name_space will be defined at the double colin of package names and methods.  For 
example method 'get_something' in module My::Module would be found in the name_space 
My=>{ Module=>{ get_something => { sink => logging_definition }, }, },  B<To avoid 
confusion the name 'sink' is not an allowed name_space> because it is used to define 
the actions at the boundaries of the logging space.  So if the logging_definition is 
run => 'debug' in the example above then debug level and higher run sink messages 
for get_something and higher name_space will be sent to the run sink.

=item B<Default> No default provided.  When this is blank no logging occurs

=item B<Range> There must be an source for every name in the sink boundary calls.  
sinks and sources can be built on future (not yet existing for TrafficControl) 
name_spaces.  All defined logging branches can have defined sinks in mid levels 
but must terminate with some logging definition.

=back

=head2 Exported Methods

These are methods exported into a calling modules or scripts name_space.  Care is taken 
to only export items that might be called prior to creating a module instance.

=head3 is_active()

=over

=item B<Definition:> a stand alone test to see if the global variable for the sink 
is already activated somewhere else.

=item B<Accepts:> Nothing

=item B<Returns:> true if the global variable is already activated

=back

=head2 Methods

Methods are used to manipulate both the public and private attributes of this role.  
All attributes of this role are set as 'ro' so other than ->new(  ) these methods are
the only way to change, read, or clear attributes.

=head3 new( sources => { something }, sinks => { something } )

=over

=item B<Definition:> The initial call to Parsing::sink

=item B<Accepts:> either straight attribute calls or a hashref with the attributes as 
the top keys.

=item B<Returns:> a Parsing sink instance

=back

=head3 get_name_space

=over

=item B<Definition:> This will return a HoH's with the sources for the specific logger 
instance in a data_ref

=item B<Accepts:> nothing

=item B<Returns:> a HoH ref

=back

=head3 get_all_sources

=over

=item B<Definition:> This will return a HoH's with all active sources for all Shiras loggers  
in a data_ref

=item B<Accepts:> nothing

=item B<Returns:> a HoH ref

=back

=head3 has_no_name_space

=over

=item B<Definition:> This will check if there are any top level source keys defined

=item B<Accepts:> nothing

=item B<Returns:> 1 or 0

=back

=head3 add_source

=over

=item B<Definition:> This will merge a source definition to the instance source 
tree and the global source tree.  It uses the L<Data::Walk::Graft> method to add 
to the source tree definitions.

=item B<Accepts:> HoH with terminators containing LOGGER and 

=item B<Returns:> 1 or 0

=back




















=head3 clear_sources_and_sinks

=over

=item B<Definition: Warning!> Because the sources and sinks are managed in a global variable 
they won't clear when the instance is cleared so you have to call this method to clear them

=item B<Accepts:> nothing

=item B<Returns:> 1

=back

=head3 get_name_space

=over

=item B<Definition:> gets the active source instances

=item B<Accepts:> nothing

=item B<Returns:> A hash ref of source intances with the top level keys as the 
source names

=back

=head3 get_one_source

=over

=item B<Definition:> Retrieve a targeted source instance.  This will allow you to 
apply source specific methods when needed.

=item B<Accepts:> An source name

=item B<Returns:> Either the source instance or 0

=back

=head3 set_sources( $definitions )

=over

=item B<Definition:> This is a complete reset of all sources.  After the sources 
set the active sink list will be used to ensure that all needed sources have been 
defined.

=item B<Accepts:> $definitions is a hashref of names and source definitions.  
see L<Parsing::sink::source> for more details

=item B<Returns:> the active source list as a hashref or fail

=back

=head3 get_reports

=over

=item B<Definition:> This is request to return the HoHoH... sinkspace definition.

=item B<Accepts:> nothing

=item B<Returns:> the active sinkspace hashref

=back

=head3 set_sinks( $definitions )

=over

=item B<Definition:> This is a complete reset of the whole sinkspace.

=item B<Accepts:> $definitions is a hashref representing the sinkspace boundaries

=item B<Returns:> the called source list from the sinkspace as a hashref 
with the source names as keys

=back

=head3 add_sinks( $hashref )

=over

=item B<Definition:> This uses the L<Parsing::HashRef> 'merge_hashref' function 
to add to the sink space.  The final sinks space must still pass the 
sinkspace definitions.

=item B<Accepts:> A hashref representing new (additional) sinkspace boundaries

=item B<Returns:> the updated (complete) source list from the sinkspace 
as a hashref with the source names as keys

=back

=head3 subtract_sinks( $hashref )

=over

=item B<Definition:> This uses the L<Parsing::HashRef> 'prune_hashref' function 
to remove parts of the sink space.  See the module for more details on how this 
works.  The final sinks space must still pass the sinkspace definitions.

=item B<Accepts:> A hashref representing the hasref points for pruning

=item B<Returns:> the updated source list from the resulting sinkspace 
as a hashref with the source names as keys

=back

=head3 has_sinks

=over

=item B<Definition:> This is a test to see if any sinks are currently named

=item B<Accepts:> nothing

=item B<Returns:> 1 or 0

=back

=head3 clear_sinks

=over

=item B<Definition:> Clears all active sinkspace

=item B<Accepts:> nothing

=item B<Returns:> true

=back

=head2 GLOBAL VARIABLES

=over

=item B<$ENV{Smart_Comments}>

The module uses L<Smart::Comments> if the '-ENV' option is set.  The 'use' is 
encapsulated in a BEGIN block triggered by the environmental variable to comfort 
non-believers.  Setting the variable $ENV{Smart_Comments} will load and turn 
on smart comment reporting.  There are three levels of 'Smartness' available 
in this module '### #### #####'.

=back

=head1 SUPPORT

=over

=item L<github Data-Walk-Extracted/issues|https://github.com/jandrew/Data-Walk-Extracted/issues>

=back

=head1 TODO

=over

=item * Create a (DESTROY) method to kill the active switchboard 

=item * Allow for more than one source per name

=item * Set an attribute for reporting inclusive upward, downward or level only

=over

=item - Possibly allow to pick and choose levels to report

=back

=over

=item B<Explanation:> all calls to that source name would be sent to 
multiple places

=back

=item * Allow mixed startups with config files and passed arguments

=over

=item B<Explanation:> Allow run time modification of the hashref passed 
from a YAML config file.  This would most likely be done through the hash 
merge or prune call.

=back

=item * Provide the ability to pass arguments to a config file

=over

=item B<Explanation:> Allow some parameters to be flexible in a config 
file and then be added at run time later - I don't know what the priority 
of this would be if the previous TODO was implemented

=back

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

=item L<Moose>

=item L<Modern::Perl>

=item L<MooseX::StrictConstructor>

=item L<version>

=item L<Storable> - dclone

#~ =item L<Hash::Merge>

=item L<MooseX::Types::Moose>

=item L<Log::Shiras::Report>

=item L<Log::Shiras::Types>

=back

=head1 SEE ALSO

=over

=item L<Log::Shiras>

=item L<Log::Shiras::TrafficControl>

=item L<Test::Log::Shiras>

=item L<Log::Log4perl>

=item L<Log::Dispatch>

=item L<Log::Report>

=cut

#################### <where> - main pod documentation end ###################