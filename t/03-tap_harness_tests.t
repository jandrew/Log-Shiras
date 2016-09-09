#!perl
#########1 Run all tests      3#########4#########5#########6#########7#########8#########9
my	$dir 	= './';
my	$tests	= 'Log/Shiras/';
my	$up		= '../';
for my $next ( <*> ){
	if( ($next eq 't') and -d $next ){
		$dir	= './t/';
		$up		= '';
		last;
	}
}

use	TAP::Formatter::Console;
my $formatter = TAP::Formatter::Console->new({
					jobs => 1,
					#~ verbosity => 1,
				});
my	$args ={
		lib =>[
			$up . 'lib',
			$up,
			$up . 'examples',
			#~ $up . '../Log-Shiras/lib',
		],
		test_args =>{
			load_test					=>[],
			pod_test					=>[],
			types_test					=>[],
			unhide_test					=>[],
			switchboard_test			=>[],
			telephone_test				=>[],
			log_space_test				=>[],
			tap_print_test				=>[],
			tap_warn_test				=>[],
			report_csv_test				=>[],
			meta_message_test			=>[],
		},
		formatter => $formatter,
	};
my	@tests =(
		[  $dir . '01-load.t', 'load_test' ],
		[  $dir . '02-pod.t', 'pod_test' ],
		[  $dir . $tests . '01-types.t', 'types_test' ],
		[  $dir . $tests . '02-unhide.t', 'unhide_test' ],
		[  $dir . $tests . '03-switchboard.t', 'switchboard_test' ],
		[  $dir . $tests . '04-telephone.t', 'telephone_test' ],
		[  $dir . $tests . '05-log_space.t', 'log_space_test' ],
		[  $dir . $tests . '06-tap_print.t', 'tap_print_test' ],
		[  $dir . $tests . '07-tap_warn.t', 'tap_warn_test' ],
		[  $dir . $tests . 'Report/01-csv.t', 'report_csv_test' ],
		[  $dir . $tests . 'Report/02-meta_message.t', 'meta_message_test' ],
	);
use	TAP::Harness;
use	TAP::Parser::Aggregator;
my	$harness	= TAP::Harness->new( $args );
my	$aggregator	= TAP::Parser::Aggregator->new;
	$aggregator->start();
	$harness->aggregate_tests( $aggregator, @tests );
	$aggregator->stop();
use Test::More;
explain $formatter->summary($aggregator);
pass( "Test Harness Testing complete" );
done_testing();
