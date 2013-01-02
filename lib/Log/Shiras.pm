package Log::Shiras;
use version 0.94; our $VERSION = qv('0.015_003');

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras - More Moose based logging and reporting

=head1 SYNOPSIS
    
	#!perl
	use Modern::Perl;
	use Log::Shiras::Switchboard;
	my	$operator = get_operator(
		{
			reports => {# Can be replaced with a config file
				log_file => [
					{
						roles => [
						   "Log::Shiras::Report::ShirasFormat",
						   "Log::Shiras::Report::TieFile"
						],
						format_string => "%{date_time}P(m=>'ymd')s," .
							"%{filename}Ps,%{inside_sub}Ps,%{line}Ps,%s,%s,%s",
						filename => "test.csv",
						superclasses => [
						   "Log::Shiras::Report"
						],
						header => "Date,File,Subroutine,Line,Data1,Data2,Data3",
						package => "Log::File::Shiras"
					}
				],
				phone_book => [
					{
						roles => [
						   "Log::Shiras::Report::ShirasFormat",
						   "Log::Shiras::Report::TieFile"
						],
						format_string => "%s,%s,%s",
						filename => "phone.csv",
						superclasses => [
						   "Log::Shiras::Report"
						],
						header => "Name,Area_Code,Number",
						package => "Phone::Report"
					}
				]
			},
			name_space_bounds => {
				main => {
					UNBLOCK => {
						log_file => "warn"
					},
					test_sub => {
						UNBLOCK => {
							log_file => "debug"
						}
					}
				},
				Activity => {
					call_someone => {
						UNBLOCK => {
							log_file => "trace",
							phone_book => "eleven"
						}
					}
				}
			},
			buffering => {
				log_file => 1
			}
		}
	);
	my	$telephone = get_telephone;
		$telephone->talk( 
			level => 'debug', report => 'log_file', 
			message =>[ qw( humpty dumpty sat on a wall ) ] 
		);
		$telephone->talk( 
			level => 'warn', report => 'log_file', 
			message =>[ qw( humpty dumpty had a great fall ) ] 
		);
		$operator->send_buffer_to_output( 'log_file' );
		$telephone->talk( message =>['Dont', 'Save', 'This'] );
		$operator->clear_buffer( 'log_file' );
		test_sub( 'Scooby', 'Dooby', 'Do' );
		$telephone->talk( message =>['and', 'Scrappy', 'too!'] );
		Activity->call_someone( 'Jenny', '', '867-5309' );
		$operator->send_buffer_to_output( 'log_file' );
		
	sub test_sub{
		my @message = @_;
		my $phone = get_telephone;
		$phone->talk( level => 'debug', report => 'log_file', message =>[ @message ] );
	}

	package Activity;
	use Log::Shiras::Switchboard;

	sub call_someone{
		shift;
		my $phone = get_telephone;
		my $output;
		$output .= $phone->talk( report => 'phone_book', message => [ @_ ], );
		$output .= $phone->talk( 'calling', @_[0, 2] );
		return $output;
	}
	1;
        
	#####################################################################################
	# Synopsis output in phone.csv
	# 01:Name,Area_Code,Number
	# 02:Jenny,,867-5309
	#
	# Synopsis output in test.csv
	# Date,File,Subroutine,Line,Data1,Data2,Data3
	# 2012-12-31,Log-Shiras-example.pl,main,72,humpty,dumpty,had
	# 2012-12-31,Log-Shiras-example.pl,main::test_sub,87,Scooby,Dooby,Do
	# 2012-12-31,Log-Shiras-example.pl,main,80,and,Scrappy,too!
	# 2012-12-31,Log-Shiras-example.pl,Activity::call_someone,99,calling,Jenny,867-5309
	#####################################################################################


=head1 DESCRIPTION

L<Shiras|http://en.wikipedia.org/wiki/Moose#Subspecies> - A small subspecies of 
Moose found in the western United States (of America).

This is a Moose based logger with the ability to run lean or add functionality using a 
Moose object model.  While no individual element of this logger is unique to the 
L<sea|https://metacpan.org/search?q=Log> of logging modules on CPAN the API 
and scope of intent is somewhat different.  The goal is to provide a base Moose class 
which can be used (and abused) for general input and output while leveraging some of 
the really cool flow established in the better logging models broadly used today.  
This includes differentiating what output goes where.  The base use-case is to allow 
debug reporting and module output to go to two different locations and be able 
to manage both of these flows with centralized logger-style name-space controls.

Since the package drifts outside of the traditional style of logging that most 
loggers implement, I felt that it made sense to use different terms for some familiar 
concepts from the logging world.  I leveraged (loosely) the old telephone switchboard 
model.  The new terms are switchboard, operator, phone, and talk.  Some examples of 
concepts unchanged from the logging world include logging levels, logging name spaces, 
config file management of logging, and configurable output formatting.  Ultimately, 
it is not clear that there is anything revolutionary here but I sure had fun writing 
it!

A core (and intentional) design decision of this package is to split the functions 
of input and output handling into separate classes.  There is a signal handling 
class called a L</Switchboard> and a data capture and retention class called a 
L</Report>.  This allows the user to define the amount of overhead applied to the 
logger.  Additionally the core signal handling is done with a 
L<MooseX::Singleton|https://metacpan.org/module/MooseX::Singleton> class.  Using a 
singleton seemed like a semi-Moosey way to replace the global variable that I would 
have otherwise created in a non-Moose logger for flow control.  There is a third 
class called a L</Telephone> but the instances are all generated by the Switchboard 
when 'get_telephone' is called.  As you might guess the telephone is the instance 
used to talk to the report but it connects through the switchboard.

B<Warning - Multiple connections to the Switchboard Singleton can be active and none 
of the namespace definitions from one connection are protected against meddling 
by other connections.  So ... it would be entirely possible to for one connection to 
clobber some other connections name space!>  One potential way to handle debug logging 
namespace collisions is to use custom class names in the modules producing output with 
L<MooseX::ShortCut::BuildInstance|http://search.cpan.org/~jandrew/MooseX-ShortCut-BuildInstance/lib/MooseX/ShortCut/BuildInstance.pm>.  
Another way is to define a custom reporting name space for each telephone to operate in 
when first obtaining each telephone.

=head1 TERMS

=head2 Switchboard

=head3 Definition

This is the Moose Class that manages the traffic between L</Telephone>s 
and L</Report>s.  This is where configuration from a traditional logger would go.  
This is a MooseX::Singleton Class so any call to the class accesses the same data.

=head2 Operator

=head3 Creation

	my $operator = get_operator( %args );

=head3 Definition

The operator is an instance that will allow code to interact with the Switchboard 
singleton.  The switchboard routings can either be defined when the operator is 
created or by method calls against the operator over time.  The initial call to create 
an operator will accept a config file in YAML or JSON format.

=head2 Telephone

=head3 Creation

	my $telephone = get_telephone( %args );

=head3 Definition

This is the object instance placed in standalone code used to 
L<place a call|/Place a call> to a L</Report>. This is analogous to the '$logger' 
concept from a L<Log::Log4perl|https://metacpan.org/module/Log::Log4perl>.  The 
phone is provided by the switchboard and comes from the switchboard pre-wired.

=head2 Report

=head3 Use

	$report_instance->add_line( %message );

=head3 Definition

These are output objects or destinations for the 'talk' command used by telephones.  
Reports are assigned names by the switchboard with the possibility of having an 
array of reports assigned the same name.  If a telephone makes a call to a report 
name then each report with that name received the message passed from the telephone.

=head2 Place a call

=head3 Use

$telephone->talk( message =>[ 'Hello World!', ] );

=head3 Definition

This is the core action that a script or module would use to generate output for a 
report.  There are several options for this call.

=over

=item B<message:> an array ref of content for the report

=item B<report:> the name of the report destination (default is log_file)

=item B<level:> this is the calling level of the message (default is the maximum)

=item B<other:> the report can have a formatter attached that will use other keys 
from this message to either add content or manage output format.  The talk command 
will attempt to coerce this input to a hashref.

=back


=head1 Differentiation

Why choose this Logger over one of the other hundreds of options?  I have listed some 
potential differentiatiors that you may find valuable.  You may not find all or any 
of these unique in detail but in a group I think they represent something different.

=head2 Buffer behavior

This package has a report buffer (default off) that will allow for some messages to 
be discarded after they were collected based on branches in the code.  A use case 
for this is when you are recursivly parsing some logic but only want to log the actions 
in the path that yeilded results.

=head2 Test::Log::Shiras

A dedicated test module that will capture messages at the switchboard level rather 
than requiring a connection to the final destination of the report to review output.  
This leverages the buffering behavior above.

=head2 Headers

This module only adds the header to a file when it is new.  If the file connection 
is dropped and then reconnected the header will not be added again.  Log4perl 
doesn't do this.

=head2 Custom formatting

I wanted to be able to send method calls and subroutine references as part of the 
line formats.  The 'ShirasFormat' Role for Reports does that.  While the API isn't 
quite as mature as Log4perl's 'PatternLayout' it does support full sprintf formatting.  
Since this is a Role if you don't like it you won't be burdened.

=head2 L<Moose|https://metacpan.org/module/Moose::Manual>

This package is Moose based.  You probably already have an opinion on Moose so this 
may tip you one way or the other.  I like Moose.


=head2  Multiple output paths

I wanted a one stop shop for output.  I mentally group output from code into two 
categories.  First is 'log_file' output.  This is the way that code leaves tracks 
from the ongoing process that it follows.  Second is 'report' output.  This is when 
data is generated by code for consumption elsewhere.  I really liked the flexibility 
and ease of definition shown in the currently popular logging modules for 'log_file' 
output and wanted to extend that to 'report' output.  This package allows me to define 
(multiple) 'report' and 'log_file' outputs in the code in the same way.  The ability 
to extract final destination, level activation, and formatting out of the core 
data generation code is attractive to me.

=head2 GLOBAL VARIABLES

=over

=item B<$ENV{Smart_Comments}>

I would eventually like for this package to self report to a log file but my first few 
attempts caused ugly deep recursion and my efforts to resolve it just caused more 
problems.  So for now the package uses L<Smart::Comments> if the '-ENV' option is set.  
The 'use' statement is encapsulated in an 'if' block triggered by an environmental 
variable to comfort non-believers.  Setting the variable $ENV{Smart_Comments} will 
load and turn on smart comment reporting.  There are three levels of 'Smartness' 
available in this module '### #### #####'.

=back

=head1 SUPPORT

=over

=item L<github Log::Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 TODO

=over

=item * Get the package to self report

=item * Consider allowing a 'BLOCK' flag in the namespace (Turning off UNBLOCK)

=item * Build a Database connection appender

=item * Allow placeholders in a config file for run - time arguments

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
LICENSE file included with this package.

=head1 SEE ALSO

=over

=item L<Log::Log4perl>

=item L<Log::Dispatch>

=item L<Log::Report>

=cut
	
#########1 main POD end      3#########4#########5#########6#########7#########8#########9