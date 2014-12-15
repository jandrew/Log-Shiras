#! C:/Perl/bin/perl
#######  Test File for Test::Log::Shiras  #######
use Test::Most;
use Test::Exception;
use Smart::Comments '###';
use YAML;
use Carp;
use lib '../lib', 'lib';
use Test::Log::Shiras 0.018;
my  ( $test_inst, $wait, $expected_count );
$| = 1;
### hard questions
lives_ok{ $test_inst = Test::Log::Shiras->new(); }      "Test that a new test instance begins";
print Dump( $Test::Log::Shiras::test_buffer );
### Testing STDOUT ...
$test_inst->cant_match_output( 'STDOUT', qr/Hello\sW/,  "Test that 'Hello World' or a close match was (NOT) captured" );
$test_inst->no_buffer( 'STDOUT',                        "Test that the buffer for 'STDOUT' has not been created yet" );
$test_inst->capture_output( 'STDOUT',                   "Test turning on the capture for STDOUT" );
$test_inst->has_buffer( 'STDOUT',                       "Test that the buffer for 'STDOUT' HAS been created" );
ok print( "Hello World\n" ),                            "Test capturing 'Hello World'";
### Printing a Smart_Comment to ensure that it is NOT captured since it prints to STDERR! ...
$test_inst->return_to_screen( 'STDOUT',                  "Test turning off the capture for STDOUT" );
$test_inst->has_buffer( 'STDOUT',                       "Test that the buffer for 'STDOUT' is still in existence" );
$test_inst->buffer_count( 1, 'STDOUT',                  "... check if the 'STDOUT' buffer has the expected number of lines" );
ok print( "Foo, Bar, Baz\n" ),                          "Test printing 'Foo, Bar, Baz'";
$test_inst->cant_match_output( 'STDOUT', 'Foo, Bar, Baz',
                                                        "Test that 'Foo, Bar, Baz' was (NOT) captured in the print buffer" );
$test_inst->buffer_count( 1, 'STDOUT',    "... check if the 'STDOUT' buffer (still) has the expected number of lines" );
$test_inst->match_output( 'STDOUT', qr/Hello\sW/,       "Test that 'Hello World' or a close match was captured" );
$test_inst->buffer_count( 0, 'STDOUT',                  "... check that the 'STDOUT' buffer has one fewer lines" );
$test_inst->close_buffer( 'STDOUT',                     "Test closing the 'STDOUT' buffer" );
$test_inst->no_buffer( 'STDOUT',                        "Test that the buffer for 'STDOUT' is NOT in existence" );
$test_inst->return_to_screen( 'STDOUT',                 "... and return 'STDOUT' to screen" );
### Testing STDERR ...
$test_inst->cant_match_output( 'STDERR', qr/Watch out\sW/,       
                                                        "Test that 'Watch out World!' or a close match was (NOT) captured" );
$test_inst->capture_output( 'STDERR',                   "Test turning on the capture for STDERR" );
$expected_count = ( $test_inst->get_buffer( 'STDERR' ) );
ok warn( "Watch out World!" ),                          "Test capturing 'Watch out World!'";
$expected_count++;
$test_inst->return_to_screen( 'STDERR',                 "Test turning off the capture for STDERR" );
$test_inst->buffer_count( $expected_count, 'STDERR',    "... check if the 'STDERR' buffer has the expected number of lines" );
ok warn( "Foo, Bar, Baz" ),                             "Test warning 'Foo, Bar, Baz'";
$test_inst->cant_match_output( 'STDERR', 'Foo, Bar, Baz',
                                                        "Test that 'Foo, Bar, Baz' was (NOT) captured in the warning buffer" );
$test_inst->buffer_count( $expected_count, 'STDERR',    "... check if the 'STDERR' buffer (still) has the expected number of lines" );
print "Hello World 1\n";
warn "War of the Worlds";
$test_inst->match_output( 'STDERR', qr/Watch out\sW/,   "Test that 'Watch out World!' or a close match was captured" );
$expected_count--;
print "Hello World 2\n";
warn "Watch out World 2";
$test_inst->cant_match_output( 'STDERR', qr/Watch out World 2/,   
                                                        "Test that 'Watch out World 2' was NOT captured (Bug fix test case)" );
$test_inst->buffer_count( $expected_count, 'STDERR',    "... check that the 'STDERR' buffer has one fewer lines" );
$test_inst->clear_buffer( 'STDERR',                     "Test clearing the 'STDERR' buffer" );
### Testing croak and carp...
$test_inst->capture_output( 'STDERR',                   "Test turning on the capture for STDERR" );
$expected_count = ( $test_inst->get_buffer( 'STDERR' ) );
ok carp( "Grumpity Grumpity Grumpity" ),                "Test capturing 'Grumpity Grumpity Grumpity'";
$expected_count++;
$test_inst->return_to_screen( 'STDERR',                  "Test turning off the capture for STDERR" );
$test_inst->buffer_count( $expected_count, 'STDERR',    "... check if the 'STDERR' buffer has the expected number of lines" );
ok carp( "Foo, Bar, Baz" ),                             "Test carping 'Foo, Bar, Baz'";
$test_inst->cant_match_output( 'STDERR', 'Foo, Bar, Baz',
                                                        "Test that 'Foo, Bar, Baz' was (NOT) captured in the warning buffer" );
$test_inst->buffer_count( $expected_count, 'STDERR',    "... check if the 'STDERR' buffer (still) has the expected number of lines" );
$test_inst->match_output( 'STDERR', qr/Grumpity Grumpity /,   
                                                        "Test that 'Grumpity Grumpity Grumpity' or a close match was captured" );
$expected_count--;
$test_inst->buffer_count( $expected_count, 'STDERR',    "... check that the 'STDERR' buffer has one fewer lines" );
$test_inst->clear_buffer( 'STDERR',                     "Test clearing the 'STDERR' buffer" );
### Testing croak ...
$test_inst->cant_match_output( 'STDERR', "You can’t win, Darth. If you strike me down, I shall become more powerful than you can possibly imagine.",       
                                                        "Test that Obi-wans last corporeal words were (NOT) captured" );
$test_inst->capture_output( 'STDERR',                   "Test turning on the capture for STDERR" );
$expected_count = ( $test_inst->get_buffer( 'STDERR' ) );
dies_ok{ croak "You can’t win, Darth. If you strike me down, I shall become more powerful than you can possibly imagine."}          
                                                        "Die with Obi-wan's last corporeal words";
ok warn( @$ ),                                          "Capture the words for testing";
dies_ok{ live_or_die( 'die', 'This is a test death' ) } "Test dieing by subroutine";
ok warn( @$ ),                                          "Capture the words for testing";
lives_ok{ live_or_die( 'live', 'Princess Padme Amidala, you now have the floor.' ) }
                                                        "Test carping by subroutine";
$expected_count += 10;
$test_inst->return_to_screen( 'STDERR',                 "Test turning off the capture for STDERR" );
$test_inst->buffer_count( $expected_count, 'STDERR',    "... check if the 'STDERR' buffer has the expected number of lines" );
dies_ok{ croak "Foo, Bar, Baz" }                        "Test croaking 'Foo, Bar, Baz'";
ok warn( @$ ),                                          "Send output to 'STDERR' for testing";
$test_inst->cant_match_output( 'STDERR', 'Foo, Bar, Baz',
                                                        "Test that 'Foo, Bar, Baz' was (NOT) captured in the warning buffer" );
$test_inst->buffer_count( $expected_count, 'STDERR',    "... check if the 'STDERR' buffer (still) has the expected number of lines" );
$test_inst->match_output( 'STDERR', qr/You can’t win, Darth. If you strike me down, I shall become more powerful than you can possibly imagine./,   
                                                        "Test that Obi-wans last corporeal words were captured" );
$expected_count--;
$test_inst->buffer_count( $expected_count, 'STDERR',    "... check that the 'STDERR' buffer has one fewer lines" );
lives_ok{ $test_inst->set_match_retention( 1 ) }        "... change line matching behaviour to keep the line in the buffer after it is matched";
$test_inst->match_output( 'STDERR', qr/This is a test death/,   
                                                        "Test that the subroutine test error was captured" );
$test_inst->buffer_count( $expected_count, 'STDERR',    "... check that the 'STDERR' buffer has the expected number of lines" );
### Testing the global variable buffer ...
$test_inst->no_buffer( 'GENERIC',                       "Test that the buffer for 'GENERIC' has not been created yet" );
lives_ok{ $Test::Log::Shiras::test_buffer->{GENERIC} = [
    "Aren't you a little short for a stormtrooper?",
    "That's no moon, it's a space station.",
    "This is some rescue. You came in here and you didn't have a plan for getting out?",
] }                                                     "Test loading buffer 'GENERIC' with some lines";
$test_inst->has_buffer( 'GENERIC',                      "Test that the buffer for 'GENERIC' exists now" );
$test_inst->buffer_count( 3, 'GENERIC',                 "... check that the 'GENERIC' buffer has 3 lines" );
lives_ok{ $test_inst->set_match_retention( 0 ) }        "... change line matching behaviour to discard the line from the buffer after it is matched";
$test_inst->match_output( 'GENERIC', qr/it's a space station/,   
                                                        "Test that a space station exists" );
$test_inst->buffer_count( 2, 'GENERIC',                 "... check that the 'GENERIC' buffer has one less line" );
$test_inst->close_buffer( 'GENERIC',                    "Close the 'GENERIC' buffer" );
$test_inst->no_buffer( 'GENERIC',                       "... and see if the 'GENERIC' buffer is gone" );
### testing done ...
done_testing();

sub live_or_die{
    my ( $input, $text ) = @_;
    if( $input eq 'live' ){
        carp $text if $text;
        return 1;
    }else{
        croak $text || '';
        return 0;
    }
}