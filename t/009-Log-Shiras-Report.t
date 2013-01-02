#!perl
#######  Test File for Log::Shiras::Report  #######

package Attribute::Add;
use Moose::Role;
has 'test_value' =>( is => 'rw', ); 
no Moose::Role;

package main;
$| = 1;
use Modern::Perl;
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;#'###'
	### Smart-Comments turned on for 003-Log-Shiras-Report.t
}

use Test::Most;
use Test::Moose;
use YAML::Any;
use Capture::Tiny 0.12 qw(
		capture_stdout
		capture_stderr
	);
use MooseX::ShortCut::BuildInstance 0.003;
use lib '../lib', 'lib', '../../DateTimeX-Mashup-Shiras/lib';
use DateTimeX::Mashup::Shiras 0.007;
BEGIN{
    #~ $ENV{Smart_Comments} = '### ####'; #####
}
use Log::Shiras::Report 0.007;
my  ( 
		$new_class,
		$test_instance,
		$print_capture,
		$capturefilename,
		$error_message,
		$wait,
		$ScitePrefix,
	);

#~ my  ( $wait, $test_instance, $newclass, $capturefilename );
if( -e 't' ){
	#~ map{ print "$_\n" } <t/*>;
	explain "prove running";
}else{
	$ScitePrefix = '../';
	#~ map{ print "$_\n" } <*>;
}
my  $firstfile      = ($ScitePrefix) ? $ScitePrefix . 't/happygolucky.txt' : 't/happygolucky.txt';
my  $secondfile     = ($ScitePrefix) ? $ScitePrefix . 't/NewFile.csv' : 't/NewFile.csv';
my  $header         = "A test header\nwith embedded newlines\n";

my  @attributes = qw(
        or_print
    );

my  @methods = qw(  
        new
        add_line
    );
    
$| = 1;
### Clean the workbench (from previous failed runs)
lives_ok{
			unlink  $firstfile   if( -f $firstfile )
}											'First Cleanup prep step';#1
lives_ok{
			unlink  $secondfile  if( -f $secondfile )
}											'Fourth Cleanup prep step';#4

# easy questions
map{
has_attribute_ok
			'Log::Shiras::Report', $_,		"Check that the new instance has the -$_- attribute",
}			@attributes;											
map{									#Check that the new instance can use all methods
can_ok		'Log::Shiras::Report', $_,
}			@methods;
### <where> - harder questions ...
lives_ok{
			$test_instance = Log::Shiras::Report->new( or_print => 1, );
}											"Start a Report instance";
			$print_capture = capture_stdout{
is			$test_instance->add_line( ['foo','bar','baz' ] ), 'foo,bar,baz',
											'Test that the add line command works( should also print out )';
			};
is			$print_capture, "foo,bar,baz\n",
											'Test that the report sent the correct stuff to the output';
is			$test_instance->set_or_print( 0 ), 0,
											"Turn off 'or_print'";
lives_ok{
			$test_instance = build_instance(
				package 		=> 'Report::ShirasFormat::Test',
				superclasses	=> [ 'Log::Shiras::Report' ],
				roles			=> [ 
					'Log::Shiras::Report::ShirasFormat', 
					'DateTimeX::Mashup::Shiras',
					'Attribute::Add',
				],
				format_string	=> '%%%2$d %1$d %5$d %d %3$d',
				date_one		=> '9/11/2001',
				test_value		=> 'Remember',
			);
}											"Build an instance for testing ShirasFormat processing( with a non-sequential format string)";
is			$test_instance->add_line( 12,34,1,2,3), "%34 12 3 12 1",
											'Send the supported perl 5.14 sprintf documentation inputs and check that they (effectivly) match the supported 5.14 documentation outputs';
ok			$test_instance->set_format_string(  
				'<% d><%+d><%6s><%-6s><%06s><%#o><%#x><%#X><%#b><%#B>' .
				'<%+ d><% +d>' .
				'<%#.5o><%#.5o><%#.0o>' .
				'%vd,address is %*vX' .
				',bits are %0*v8b,' .
				'%*24$vX,%*24$vX,%*24$vX'
			),								'Send additional supported perl 5.14 sprintf documentation formats to the format string as a test';
is			$test_instance->add_line(  
				12,12,12,12,12,12,12,12,12,12,
				12,12,
				012,012345,0,
				"AB\x{100}",":",10.20.30.40.50.60,
				" ",'10011101',
				100.200.300.400,200.300.400.500,300.400.500.600,":"
			),
			"< 12><+12><    12><12    ><000012><014><0xc><0XC><0b1100><0B1100>" .
			"<+12><+12>" .
			"<00012><012345><0>" .
			"65.66.256,address is A:14:1E:28:32:3C" .
			",bits are 00110001 00110000 00110000 00110001 00110001 00110001 00110000 00110001," .
			"64:C8:12C:190,C8:12C:190:1F4,12C:190:1F4:258"
			,								'Send the additional supported perl 5.14 sprintf documentation inputs and check that they (effectivly) match the supported 5.14 documentation outputs';
ok			$test_instance->set_format_string(  
				'<%s><%6s><%*s><%*3$s><%2s>' .
				'<%f><%.1f><%.0f><%e><%.1e>' .
				'<%g><%.10g><%g><%.1g><%.2g><%.5g><%.4g>' .
				'<%.6d><%+.6d><%-10.6d><%10.6d><%010.6d><%+10.6d>' .
				'<%.6x><%#.6x><%-10.6x><%10.6x><%010.6x><%#10.6x>' .
				'<%.5s><%10.5s>' .
				'<%.6x><%.*x>' .
				'<%.*s><%.*s><%.*s><%.*s><%.*d><%.*d><%.*d>'
			),                              'Send (more) additional supported perl 5.14 sprintf documentation formats to the format string as a test' ;
is			$test_instance->add_line(  
				"a","a",6,"a","a","long",
				1,1,1,10,10,
				1,1,100,100,100.01,100.01,100.01,
				1,1,1,1,1,1,1,1,1,1,1,1,
				"truncated","truncated",
				1,6,1,7,"string",3,"string",0,"string",-1,"string",1, 0,0, 0,-1, 0
			),
			"<a><     a><     a><     a><long>" .
			"<1.000000><1.0><1><1.000000e+001><1.0e+001>" .
			"<1><1><100><1e+002><1e+002><100.01><100>" .
			"<000001><+000001><000001    ><    000001><    000001><   +000001>" .
			"<000001><0x000001><000001    ><    000001><    000001><  0x000001>" .
			"<trunc><     trunc>" .
			"<000001><000001>" .
			"<string><str><><string><0><><0>" ,
											'Send (more) additional supported perl 5.14 sprintf documentation inputs and check that they (effectivly) match the supported 5.14 documentation outputs';
dies_ok{
			$test_instance->set_format_string( '%%%{test_value}Ks %{get_date_one}M(m,ymd)s%%' )
}											"Set a format that includes a bad 'new type' callout '%%%{test_value}Ks %{get_date_one}M(m,ymd)s%%' (should die)";
like		$@,  qr/\QCoersion to 'acmeformat' failed because of an unrecognized modifier -K- found in format string -{test_value}Ks -\E/sxm, 
											"... and check for the correct output";
ok			$test_instance->set_format_string( "%%%{test_value}Ms %{get_date_one}M( m => 'ymd' )s%%" ),
											"Set a format that with two new attribute type examples '%%%{test_value}Ms %{get_date_one}M( m => 'ymd' )s%%'";
is			$test_instance->add_line(),	 '%Remember 2001-09-11%',
											'...and test getting the information back when called';
ok			$test_instance->test_value('Always Remember' ),
											'Change the test attribute';
is			$test_instance->add_line(),'%Always Remember 2001-09-11%',
											'..and test that the output is dynamically adjusted';
ok			$test_instance->set_format_string( '%%%-20{test_value}Ms%%' ), 
											"Send a new format left justified with a good minimum width for testing '%%%-20{test_value}Ms%%'";
is			$test_instance->add_line(), '%Always Remember     %',
											'...and test getting the output back with the extra spaces and correctly justified when called';
ok			$test_instance->set_format_string( '%%%-.5{test_value}Ms%%' ), 
											"Send a new format with a good maximum width for testing '%%%-.5{test_value}Ms%%'";
is			$test_instance->add_line(), '%Alway%',
											'...and test getting the output back with the output correctly truncated when called';
ok			$test_instance->set_format_string( '%%%-*.*{test_value}Ms%%' ),
											"Send a new format with referenced minimum and maximum width as well as the inputs referenced '%%%-*.*{test_value}Ms%%'";
is			$test_instance->add_line(20,5), '%Alway               %',     
											'...and test getting the output back with the output correctly truncated when called';
ok			$test_instance->set_format_string( '%%%-.*{test_value}Ms%%' ),
											"Send a new format with referenced maximum width as well as the inputs referenced '%%%-.*{test_value}Ms%%'";
is			$test_instance->add_line(6), '%Always%',
											'...and test getting the output back with the output correctly truncated when called';
ok			$test_instance->set_format_string( '%%%-*.*{get_date_one}M(m=>ymd,l=>*)s%%' ), 
											"Send a new format with a referenced minimum and maximum width and a referenced quantity passed variable '%%%-*.*{get_date_one}M(m=>ymd,l=>*)%%'";
is			$test_instance->add_line( 20, 7, 1, "/" ), '%2001/09             %', 
											'...and test getting the output back with the output correctly formatted when called (where minimum is larger than maximum)';
ok			$test_instance->set_format_string( '%%%-*.*{get_date_one}M(m=>format_cldr,l=>1)s%%' ), 
											"Send a cldr specific date format as a new format with referenced minimum and maximum width and a referenced quantity passed variable '%%%-*.*{get_date_one}M(m=>format_cldr,l=>1)s%%'";
is			$test_instance->add_line( 20, 17, 'yyyy-MMMM-d'), '%2001-September-11   %', 
											'...and test getting the output back with the output correctly formatted when called (where minimum is larger than maximum)';
throws_ok{
			$test_instance->set_format_string( '%%%{super_size_sub}M(i=>*)s%%' )
}			qr/\Q'super_size_sub' is a subroutine of main and can only accept 'lvalue' inputs (should be 'l' passed 'i')\E/x,
											"Send a new format subroutine ref with a referenced input array size but the wrong input type and check the error '%%%{super_size_sub}M(i=>*)s%%'";
ok			$test_instance->set_format_string( '%%%{super_size_sub}M(l=>*)s%%' ), 
                                            "Send a new format subroutine ref with a referenced input array size '%%%{super_size_sub}M(l=>*)s%%'";
is			$test_instance->add_line( 2, 'pooper', 'scooper' ), '%Super duper pooper scooper%', 
                                            '...and test getting the output back with the output correctly formatted when called';
ok			$test_instance->set_format_string( '#%d %{main::super_size_sub}M(l=>*)s%s' ), 
                                            "Send a new format subroutine ref calling package and subroutine '#%d %{main::super_size_sub}M(l=>*)s%s'";
is			$test_instance->add_line( 1, 1, 'paratrooper', '<-------' ), '#1 Super duper paratrooper<-------', 
                                            '...and test getting the output back with the output correctly formatted when called';
ok			$test_instance->clear_format_string,                            'Clear the format string to see if the pass through mode works';
is			$test_instance->add_line( '%Polly picked a peck of pickeled peppers%' ), '%Polly picked a peck of pickeled peppers%', 
                                            '...and test a toungue twister pass through value';
ok			$test_instance->set_format_string( '%16{find_yourself}M(l=>5)s' ),
											"Set the format string for the next (overstated) inputs using a sub '%16{find_yourself}M(l=>5)s'";
is			$test_instance->add_line( 'Scooby', 'Dooby', 'Do' ), 'Scooby - Dooby - Do ...Where are you?',
											"Test sending an array to the new formatter 'find_yourself'";
			$new_class = build_class(
				package 		=> 'Report::TieFile::Test',
				superclasses	=> [ 'Log::Shiras::Report' ],
				roles			=> [ 
					'Log::Shiras::Report::ShirasFormat',
					'Log::Shiras::Report::TieFile',
				],
			);
lives_ok{
			$test_instance = $new_class->new(
                header   		=> $header,
                filename  		=> $firstfile,
			);
}											"Build an instance for testing TieFile processing";
is			$test_instance->get_filename, $firstfile,                        
											'Test retreiving the file name';
ok			$test_instance->file_exists,	'Check that the file exists';
is			$test_instance->is_newfile_state, 1,
											'Check that it is a new file';
is			$test_instance->count_file_lines, 1,
											'Check that the line count is 1';
			$error_message = capture_stderr{
is			$test_instance->set_filename( $secondfile ), $secondfile,        
											'Test changing the file name';
			};
like		$error_message, 
			qr/Disconnecting. (.{3})?t\/happygolucky\.txt at (.{3})?lib\/Log\/Shiras\/Report\/TieFile\.pm line \d{2,3}\./,#
											'... check the associated warning';
lives_ok{ 
			$capturefilename = $test_instance->get_filename 
}          									'Check that the new file name is captured';#51
is			$capturefilename, $secondfile,	'Check the file name for correlation';#52
			$error_message = capture_stderr{
is			$test_instance->set_filename( $firstfile ), $firstfile,
											"Test that changing the file back to the first name doesn't fail";#53
			};
like		$error_message, 
			qr/Disconnecting. (.{3})?t\/NewFile\.csv at (.{3})?lib\/Log\/Shiras\/Report\/TieFile\.pm line \d{2,3}\./,
											'... check the associated warning';
ok			unlink( $capturefilename ),	'... and that the second file can be deleted' ;#54
is			$test_instance->get_filename, $firstfile,
											'Test retreiving the file name';#55
ok			$test_instance->file_exists,
											'Check that the file exists';#56
is			$test_instance->is_newfile_state, 0,
											'Check that it is NOT a new file';#57
is			$test_instance->count_file_lines, 1,
											'Check that the line count is still 1';#58
is			$test_instance->get_filename, $firstfile,
											'Check the file name (again) for correlation';#60
lives_ok{
			$capturefilename = $test_instance->get_filename 
}											'Check that the new file name is captured';#61
lives_ok{
			$test_instance = undef
}                                   		'Delete the instance';#62
lives_ok{
			$test_instance = $new_class->new(
				filename => $firstfile,
				format_string	=> '%% - %s - %s - %s - %%',
			);
}											'Relink the file';
is			$test_instance->get_file_line( 0 ), 'A test header with embedded newlines',
											'Test that the prior header is still there and has the headers (with out new-lines)';#67
lives_ok{
			$test_instance->add_line('foo','bar','baz')
}              								'Test that the add line command works';#68
#~ $wait = <>;
is			$test_instance->count_file_lines, 2,
											'Test that a header and 1 line is loaded to the  file';#69
is			$test_instance->get_file_line( 1 ), '% - foo - bar - baz - %',
											'Test that the loaded line is formatted as expected' ;#70
is			$test_instance = undef, undef,	'Unlink the active instance';
is			-f $firstfile, 1,				"Test that -$firstfile- is found";#122
ok			unlink( $firstfile ),			"Test that -$firstfile- is deleted";#123
explain										"... Test Done";
done_testing;

### subroutine called in test #31 and used in #32
sub super_size_sub{
    ### <where> - Made it to super_size_sub ...
	### <where> - passed: @_
    return ('Super duper ' . join ' ', @_);
}

### subroutine called in tests 41 and 42
sub find_yourself{
    ### Made it to find_yourself
    ### @_
    return (join ' - ', @_) . ' ...Where are you?';
}

#~ package Explain;

#~ sub call_someone{
	#~ shift;
	#~ $test_instance->add_line( @_ );
#~ }
1;