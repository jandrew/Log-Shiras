#!perl
#~ BEGIN{
	#~ $ENV{ Smart_Comments } = '###';
#~ }
#~ use Smart::Comments '###';
#~ use Modern::Perl;
$| = 1;
use lib 
		'lib', 
		'../lib',
		'../Data-Walk-Extracted/lib',
		'../../Data-Walk-Extracted/lib';
use Log::Shiras::Switchboard 0.013;
use Log::Shiras::Telephone 0.005;
sub get_telephone{
	return Log::Shiras::Telephone->new;
}
my $telephone = Log::Shiras::Telephone->new; #get_telephone;
### <where> - current telephone: $telephone
$telephone->talk( message => 'Hello World 0' );
### <where> - No printing here (the operator is not loaded) ...
my $operator = Log::Shiras::Switchboard->get_operator( 
		name_space_bounds =>{
			UNBLOCK =>{
				log_file => 'trace',
			},
			main =>{
				UNBLOCK =>{
					log_file => 'warn',
					report => 'warn',
				},
			},
			Log =>{
				Shiras =>{
					UNBLOCK =>{
						log_file => 'warn',
					},
					Telephone =>{
						new =>{
						},
					},
				},
			},
		},
		reports =>{
			report =>[
				Excited::Print->new,
			],
			log_file =>[
				Log::Print->new,
			],
		},
		buffering =>{
			log_file => 1,
		},
	);
### <where> - getting another operator ...
$telephone = Log::Shiras::Telephone->new;
$telephone->talk( message => 'Hello World 1' );
my $other_operator = Log::Shiras::Switchboard->get_operator( 
		buffering =>{
			log_file => 0,
		},
	);
### <where> - should have printed here ...
$telephone->talk(# level too low
	report  => 'report',
	level 	=> 'debug',
	message => 'Hello World 2',
);
$telephone->talk(# level OK
	report  => 'report',
	level 	=> 'warn',
	message => 'Hello World 3',
);
### <where> - should have printed here too...
$telephone->talk(# level OK , report wrong
	report 	=> 'run',
	level 	=> 'warn',
	message => 'Hello World 4',
);

package Excited::Print;
sub new{
	bless {}, __PACKAGE__;
}
sub add_line{
	### <where> - reached add_line with: @_[ 1 .. $#_ ]
	### <where> - from: caller( 1 )
	shift;
	my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ? @{$_[0]->{message}} : $_[0]->{message};
	chomp @input;
	print '!!!' . join( ' ', @input ) . "!!!\n";
	#~ my $wait = <>;
}

package Log::Print;
sub new{
	bless {}, __PACKAGE__;
}
sub add_line{
	### <where> - reached add_line with: @_[ 1 .. $#_ ]
	### <where> - from: caller( 1 )
	shift;
	my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ? @{$_[0]->{message}} : $_[0]->{message};
	chomp @input;
	print "subroutine - $_[0]->{subroutine}; line - $_[0]->{line} " . ':( ' . join( ' ', @input ) . " ):\n";
	#~ my $wait = <>;
}
1;