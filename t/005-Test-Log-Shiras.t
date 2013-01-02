#!perl
####### Test File for Test::Log::Shiras  #######
BEGIN{
	#~ $ENV{ Smart_Comments } = '### #### #####';
}
use Test::Most;
use Test::Moose; 
use Carp;
use Capture::Tiny 0.12 qw(
		capture_stdout
		capture_stderr
		capture
	);
use lib '../lib', 'lib', '../../Data-Walk-Extracted/lib';
use Test::Log::Shiras 0.009;
use Log::Shiras::Switchboard 0.013;
my  ( $test_inst, $expected_count, $operator, $telephone, );
$| = 1;
my  		@methods = qw(  
				new
				last_buffer_position
				change_test_buffer_size
				keep_matches
				set_match_retention
				get_buffer
				clear_buffer
				has_buffer
				no_buffer
				buffer_count
				match_message
				cant_match_message
);
my  		@attributes = qw(
				last_buffer_position
				keep_matches
);
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;
}

### <where> - easy questions ...
map 
can_ok( 
			'Test::Log::Shiras', $_ 
), 			@methods;
map 
has_attribute_ok(
			'Test::Log::Shiras', $_ 
), 			@attributes;
### <where> - hard questions ...
lives_ok{
			$test_inst = Test::Log::Shiras->new(); 
}      										"Test that a new test instance begins";
### <where> - Testing STDOUT ...
$test_inst->cant_match_message( 
			'STDOUT', qr/Hello\sW/,  		"Test that 'Hello World' or a close match was (NOT) captured" 
);
$test_inst->no_buffer( 
			'STDOUT',						"Test that the buffer for 'STDOUT' has not been created yet"
);
lives_ok{
			$operator = get_operator( 
							buffering => { 
								STDOUT 	=> 1,
								WARN	=> 1,
							},
							name_space_bounds => { 
								main =>{ 
									UNBLOCK =>{ 
										STDOUT 		=> 'trace',
										WARN		=> 'trace',
										log_file	=> 'trace',
									}, 
								}, 
							},
			);
}											"Start the Switchboard";
lives_ok{
			$operator->set_stdout_level( 'trace' );
}											"... and set the STDOUT call level to trace";
$test_inst->no_buffer( 
			'STDOUT',						"Test that the buffer for 'STDOUT' has not been created" );
ok 			print( "Hello World\n" ),      "Test capturing 'Hello World'";
$test_inst->has_buffer( 
			'STDOUT',						"Test that the buffer for 'STDOUT' HAS been created" );
### <where> - Printing a Smart_Comment to ensure that it is NOT captured since it prints to STDERR! ...
lives_ok{
			$operator->clear_stdout_level;
}											"... and clear the STDOUT call level";
$test_inst->has_buffer( 
			'STDOUT',                       "Test that the buffer for 'STDOUT' is still in existence"
);
$test_inst->buffer_count( 
			1, 'STDOUT',                  	"... check if the 'STDOUT' buffer has the expected number of lines"
);
			capture_stdout{
ok 			print( "Foo, Bar, Baz\n" ),    "Test printing 'Foo, Bar, Baz'";
			};
$test_inst->cant_match_message( 
			'STDOUT', 'Foo, Bar, Baz',		"Test that 'Foo, Bar, Baz' was (NOT) captured in the test buffer"
);
$test_inst->buffer_count(
			1, 'STDOUT',    				"... check if the 'STDOUT' buffer (still) has the expected number of lines"
);
$test_inst->match_message(
			'STDOUT', qr/Hello\sW/,      	"Test that 'Hello World' or a close match was captured"
);
$test_inst->buffer_count( 
			0, 'STDOUT',                  	"... check that the 'STDOUT' buffer has one fewer lines"
);
$test_inst->clear_buffer(
			'STDOUT',                     	"Test clearing the 'STDOUT' buffer"
);
### <where> - Testing WARN ...
$test_inst->cant_match_message( 
			'WARN', qr/Watch out\sW/,		"Test that 'Watch out World!' or a close match was (NOT) captured"
);
lives_ok{
			$operator->set_warn_level( 'trace' );
}											"... and set the WARN call level to trace";
ok 			warn( "Watch out World!" ),    "Test capturing 'Watch out World!'";
lives_ok{
			$operator->clear_warn_level;
}											"... and clear the WARN call level";
$test_inst->buffer_count(
			1, 'WARN',    					"... check if the 'WARN' buffer has the expected number of lines"
);
			capture_stderr{
ok 			warn( "Foo, Bar, Baz" ),		"Test warning 'Foo, Bar, Baz'";
			};
$test_inst->cant_match_message(
			'WARN', 'Foo, Bar, Baz',		"Test that 'Foo, Bar, Baz' was (NOT) captured in the warning buffer"
);
$test_inst->buffer_count(
			1, 'WARN',						"... check if the 'WARN' buffer (still) has the expected number of lines"
);
			capture{
			print "Hello World 1\n";
			warn "War of the Worlds";
$test_inst->match_message(
			'WARN', qr/Watch out\sW/,   	"Test that 'Watch out World!' or a close match was captured"
);
			print "Hello World 2\n";
			warn "Watch out World 2";
$test_inst->cant_match_message(
			'WARN', qr/Watch out World 2/,	"Test that 'Watch out World 2' was NOT captured (Bug fix test case)"
);
$test_inst->buffer_count(
			0, 'WARN',    					"... check that the 'WARN' buffer has one fewer lines"
);
$test_inst->clear_buffer( 
			'WARN',                     	"Test clearing the 'WARN' buffer"
);
			};
### <where> - Testing croak and carp ...
lives_ok{
			$operator->set_warn_level( 'trace' );
}											"... and set the WARN call level to trace";
ok 			carp( "Grumpity Grumpity Grumpity" ),
											"Test capturing 'Grumpity Grumpity Grumpity'";
$test_inst->buffer_count(
			1, 'WARN',    					"... check if the 'WARN' buffer has the expected number of lines"
);
$test_inst->match_message( 
			'WARN', qr/Grumpity Grumpity /,	"Test that 'Grumpity Grumpity Grumpity' or a close match was captured"
);
lives_ok{
			$operator->clear_warn_level;
}											"... and clear the WARN call level";
### <where> - Testing a different buffer ...
$test_inst->no_buffer(
			'log_file',						"Test that the buffer for 'log_file' has not been created yet"
);
ok			$telephone = get_telephone, 	"Get a telephone for testing";
ok			$telephone->talk( message => [ "Aren't you a little short for a stormtrooper?" ] ),
											"Send a message";
ok			$telephone->talk( message => [ "That's no moon, it's a space station." ] ),
											"... send a second message";
ok			$telephone->talk( message => [ "This is some rescue. You came in here and you didn't have a plan for getting out?" ] ),
											"... send a third message";
$test_inst->has_buffer( 
			'log_file',						"Test that the buffer for 'log_file' exists now"
);
$test_inst->buffer_count(
			3, 'log_file',                 	"... check that the 'log_file' buffer has 3 lines"
);
lives_ok{
			$test_inst->set_match_retention( 0 )
}											"... change line matching behaviour to discard the line from the buffer after it is matched";
$test_inst->match_message( 
			'log_file', qr/it's a space station/,   
											"Test that a space station exists"
);
$test_inst->buffer_count(
			2, 'log_file',                 	"... and that the 'log_file' buffer now has 2 lines"
);
explain										"... Test Done";
done_testing();