package Log::Shiras;
use version; our $VERSION = version->declare("v0.27_1");

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras - A Moose based logging and reporting tool

=head1 SYNOPSIS
    
	#!perl
	use Modern::Perl;
	use Log::Shiras::Switchboard;
	my $operator = get_operator(
		{# Can be replaced with a config file
			reports => {
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
					},
					{
						roles => [
						   "Log::Shiras::Report::ShirasFormat",
						],
						format_string => "Loading -%3\$s- in the phone book for -%1\$s-",
						superclasses => [
						   "Log::Shiras::Report"
						],
						package => "Phone::Log",
						to_stdout => 1
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
				Special =>{
					Name =>{
						Space =>{
							UNBLOCK => {
								killer => "fatal"
							}
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
	my $telephone = get_telephone;
		$telephone->talk( level => 'debug', report => 'log_file', 
			message =>[ qw( humpty dumpty sat on a wall ) ] 
		);
		$telephone->talk( level => 'warn', report => 'log_file', 
			message =>[ qw( humpty dumpty had a great fall ) ] 
		);
		$operator->send_buffer_to_output( 'log_file' );
		$telephone->talk( message =>['Dont', 'Save', 'This'] );
		$operator->clear_buffer( 'log_file' );
		test_sub( 'Scooby', 'Dooby', 'Do' );
		$telephone->talk( message =>['and', 'Scrappy', 'too!'] );
		Activity->call_someone( 'Jenny', '', '867-5309' );
		$operator->send_buffer_to_output( 'log_file' );
	my $phone = get_telephone( 'Special::Name::Space' );
		$phone->talk( message => "Not done yet!", level => 'warn', report => 'killer' );
		$phone->talk( message => "The code is done!", level => 'fatal', report => 'killer' );
		
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
	#	Synopsis screen output
	# 01:Loading -867-5309- in the phone book for -Jenny-
	# 02:The code is done! at ../lib/Log/Shiras/Switchboard.pm line 498, <$fh> line 42.
	# 03-04:(Carp stack)
	#
	#	Synopsis output in phone.csv
	# 01:Name,Area_Code,Number
	# 02:Jenny,,867-5309
	#
	#	Synopsis output in test.csv
	# 01:Date,File,Subroutine,Line,Data1,Data2,Data3
	# 02:DD/MM/YYYY,t\Log-Shiras-example.pl,main,69,humpty,dumpty,had
	# 03:DD/MM/YYYY,t\Log-Shiras-example.pl,main::test_sub,84,Scooby,Dooby,Do
	# 04:DD/MM/YYYY,t\Log-Shiras-example.pl,main,77,and,Scrappy,too!
	# 05:DD/MM/YYYY,t\Log-Shiras-example.pl,Activity::call_someone,95,calling,Jenny,867-5309
	#####################################################################################

=head2 SYNOPSIS EXPLANATION

=head3 L<my	$operator = get_operator( %args )|/my $operator = get_operator(>

This uses the exported method to get an instance of the 
L<Log::Shiras::Switchboard|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Switchboard.pm> 
class and set the initial switchboard settings.

=head3 L<reports =E<gt>{ %args }|/reports =E<gt> {>

This is where the reports are defined for the switchboard using the 
L<Log::Shiras::Report|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Report.pm>
class and the instance builder L<MooseX::ShortCut::BuildInstance>.

=head3 L<name_space_bounds =E<gt>{ %args }|/name_space_bounds =E<gt> {>

This is where the name-space bounds are defined.  Each UNBLOCK section can unblock many 
reports to a given urgency level.  Different levels of urgency for each report can be 
definied for each name-space level.

=head3 L<buffering =E<gt>{ %args }|/buffering =E<gt> {>

This is where you turn on (or off) buffering for each report name.

=head3 L<my $telephone = get_telephone|/my  $telephone = get_telephone;>

This uses the exported method to get an instance of the
L<Log::Shiras::Telephone|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Telephone.pm> 
class in order to send future output.  With no definition the name-space is the 
caller stack namespace with 'main' as the base when in the primary script.

=head3 L<my $telephone = get_telephone( 'Name::Space' )|/my $phone = get_telephone( 'Special::Name::Space' );>

This is an example of re-defining the name-space that the phone will use to 
make a call.  When the switch board receives a call from this $telephone 
it will come from 'Name::Space' rather than the caller stack definition.

=head3 L<$telephone-E<gt>talk( level =E<gt> 'debug'|/$telephone-E<gt>talk( level =E<gt> 'debug',>

This attempt to send a message is blocked because the 'log_file' is only unblocked to 
the 'warn' level for 'main'.

=head3 L<$telephone-E<gt>talk( level =E<gt> 'warn'|/$telephone-E<gt>talk( level =E<gt> 'warn',>

This attempt to send a message works because the message sent to the 'log_file' 
report space is sent at the 'warn' level.  (The message is held in the buffer)

=head3 L<$operator-E<gt>send_buffer_to_output( 'log_file' )|/$operator-E<gt>send_buffer_to_output( 'log_file' );>

This flushes the 'log_file' buffer out to the 'log_file' report(s).

=head3 L<$telephone-E<gt>talk( message =E<gt> [ 'message' ]|/$telephone-E<gt>talk( message =E<gt>>

This sends a new message to the 'log_file' buffer.  (Note that the default urgency is 
the maximum urgency, the default report is 'log_file', and the maximum urgency is 
not fatal.)

=head3 L<$operator-E<gt>clear_buffer( 'log_file' )|/$operator-E<gt>clear_buffer( 'log_file' );>

This clears the 'log_file' buffer of the current data. (1 new line)

=head3 L<$phone-E<gt>talk( message =E<gt> "The code is done!"|/$phone-E<gt>talk( message =E<gt> "The code is done!",>

Normally this code doesn't do anything since there is no report named 'killer'.  
However, it calls for a 'fatal' level on killer and the name-space is unblocked for 
fatal urgency level on the killer report so even though no reporting is done the special 
'fatal' protocol is implemented.  (Meaning the message is confessed using L<Carp>).

=head1 DESCRIPTION

L<Shiras|http://en.wikipedia.org/wiki/Moose#Subspecies> - A small subspecies of 
Moose found in the western United States (of America).

This is a Moose based logger with the ability to run lean or add functionality using a 
Moose class/role model.  While no individual element of this logger is unique to the 
L<sea|https://metacpan.org/search?q=Log> of logging modules on CPAN the combination 
of features and implementation is different.  The goal is to provide a base (set) of 
Moose class(s) which can be used (and abused) for general input and output management.  
The base use-case for this package is to allow debug reporting and module output to be 
directed to multiple different locations and be able to manage these flows with 
centralized logger-style name-spaces, logging-levels and config-files.  This package 
is most related in concept to L<Log::Dispatch|https://metacpan.org/module/Log::Dispatch>.

I felt that the architecture differences in this package from the traditional run of 
logging packages called for some terminology differences as well.  I chose to leverage 
(loosely) the old telephone switchboard L<paradigm|https://en.wikipedia.org/wiki/Paradigm>.  
The new terms are switchboard, operator, phone, and talk.  Ideas unchanged from the 
logging world include logging levels, logging name spaces, config file management of 
logging, and configurable output formatting. I also explicitly call logging output 
'Reports'.

In order to leverage the ability of Moose roles to modifiy behavior I made an 
intentional decision to split the functions of traffic management, output handling, 
and input handling into separate (but tightly linked) classes.  The tight link between 
these classes is maintained by the 
L<Log::Shiras::Switchboard|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Switchboard.pm> 
class.  This class is a L<MooseX::Singleton|https://metacpan.org/module/MooseX::Singleton>.  
An instance of the switchboard class is called an 'Operator'.  You get a 'Switchboard' 
class instance by calling the exported function 'get_operator' rather than -E<gt>new 
so that the singleton magic can work.  The 'Operator's job is to manage the caller 
name-space, the 'Report' name-space, and traffic between them in the 'Switchboard'.  
The caller name-space (and urgency filtering) define what calls get through from where.  
In the 'Switchboard' a 'Report' name-space can have an array of 
L<Log::Shiras::Report|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Report.pm>
instances associated with it.  Each instance can have it's own destination 
and formatting.  This package includes several 'Report' modifying roles or you can 
write your own!  All content sent to a 'Report' namespace will go to each 'Report' 
instance registered to that name.  For a set of code to send output to a 
report (or 'Log' something) the code must first get an instance of the 
L<Log::Shiras::Telephone|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Telephone.pm> 
class.  The 'Switchboard' class exports a function called 'get_telephone' for this 
purpose.  The function effectively calls 'Log::Shiras::Telephone->new( %args )' with 
the addition of adding a prebuilt connection to the switchboard in the instance.  
Since the 'Telephone' is connected to the switchboard the rules registered with 
the switchboard are applied with each use of the telephone.

Warning: The telephone will generally not work for the 'import' sub.  You can use the debug 
unhider there but most of the rest of this package is not available.  If you get it to 
work thats great but it is not supported and therefore no bug reports for issues 
in the import sub will be accepted.


=head1 Differentiation

Why choose this Logger over one of the many other options?  Here are some additional 
implementation decisions that I made that may or may not help that decision.

=head2 Buffer behavior

This package has a report buffer (default off) for each report name.  This allows 
for some messages to be discarded after they were collected based on branches in the 
code.  A use case for this is when you are recursively parsing some logic but only 
want to log the actions in the path that yielded results.  This is different than 
a print buffer that always goes to the output but the send is just delayed.

=head2 L<Test::Log::Shiras>

A dedicated test module for testing logged messages that will capture messages at 
the switchboard level rather than requiring a connection to the final destination 
of the report to review output.  This leverages the buffering behavior above.  
The test methods include several ways of checking for output existence.  This 
means that 'Telephone' output can be tested without building a 'Report' to 
receive it.  Testing report content should be done using links built into 
L<Log::Shiras::Report> roles for each report.  For an example see 
L<Log::Shiras::Report::TieFile>.

=head2 Headers

The 'Report' Role in this package for files 
L<Log::Shiras::Report::TieFile
|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Report/TieFile.pm> 
only adds the header to a file when it is new.  If the file connection 
is dropped and then reconnected the header will not be added again if the 
file is not empty.

=head2 Custom formatting

I wanted to be able to use method calls and code references when formatting 
'Report' output.  The  
L<Log::Shiras::Report::ShirasFormat
|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Report/ShirasFormat.pm> 
Role for the 'Report' class does just that.  While the API isn't as mature as 
Log4perl's 'PatternLayout' it does support full perl sprintf formatting.

=head2 L<Moose|https://metacpan.org/module/Moose::Manual>

This package is Moose based.  You probably already have an opinion on Moose so this 
may tip you one way or the other.  I like Moose and I currently have no plans to 
switch to L<Moo> but I would convert to the new p5-MOP if it gets added to the perl 
core.

=head2  Multiple output paths

I wanted a one stop shop for file outputs.  I mentally group file outputs from 
code into two categories.  First is 'log_file' output.  This is the way that code 
leaves tracks from the ongoing process that it follows.  Second is 'report' output.  
This is when data is generated by code for consumption elsewhere.  If this is the 
only selling point of this package then you will probably prefer  
L<Log::Dispatch|https://metacpan.org/module/Log::Dispatch>.

=head2 Some things don't change

=over

=item B<flexibility:> General flexibility and ease of definition for configuration 
through either config. files or data structures.

=item B<Separation of concerns:> Separation of output creation and destination 
definitions.

=item B<name-spaces:> Output level screening by name-space and urgency.  This 
includes the possibility of custom level definitions by report name-space.

=item B<L<sprintf:|http://perldoc.perl.org/functions/sprintf.html>> sprintf 
output formatting

=back

=head1 Exported Methods

These are methods exported into a calling modules or scripts name_space.  
This module uses L<Moose::Exporter>.

=head3 get_telephone( 'Name::Space' )

=over

=item B<Definition:> This returns an instance of the L<Log::Shiras::Telephone
|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Telephone.pm> 
class with a pre-built attachement to the L<Switchboard
|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Switchboard.pm>.  I<This 
method is actually re-exported from the Switchboard class>.

=item B<Accepts:> a name-space array or string where B<::> are name-space separators 
this represents the name-space origin for messages from the returned instance.  
No passed value will capture the caller() namespace where all scripts start with 'main'.

=item B<Returns:> A 'Telephone' class instance.  See  L<Log::Shiras::Telephone
|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Telephone.pm> for more 
documentation.

=back

=head3 get_operator( %args )

=over

=item B<Definition:> This returns an instance of the L<Log::Shiras::Switchboard
|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Switchboard.pm> 
class and the passed arguments are the initial setup definitions for the Switchboard 
I<This method is actually re-exported from the Switchboard class>.

=item B<Accepts:> all attribute definitions for the 'Switchboard' as key=E<gt>value 
pairs.

=item B<Returns:> A 'Switchboard' class instance.  See  L<Log::Shiras::Switchboard
|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Switchboard.pm> for more 
documentation.

=back

=head1 GLOBAL VARIABLES

=over

=item B<$ENV{Smart_Comments}>

I would eventually like for this package to self report but my first few attempts 
caused ugly deep recursion and my efforts to resolve it just caused more problems.  
So for now the package uses L<Smart::Comments> if the '-ENV' option is set. The 
'use' statement is encapsulated in an 'if' block triggered by an environmental 
variable to comfort non-believers.  Setting the variable $ENV{Smart_Comments} will 
load and turn on L<Smart::Comments> reporting.  There are three levels of 'Smartness' 
available in this module '### #### #####'.

=item B<$ENV{Moose_Phone}>

The one variation from my Moose evangelisim is not using Moose for the 
L<Log::Shiras::Telephone|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Telephone.pm> 
class.  If you want to go all-in on Moose then set this variable to true in a 
BEGIN block and you will get fully Moose enabled telephones.

=back

=head1 SUPPORT

=over

=item L<github Log::Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 TODO

=over

B<1.> Get the package to self report

B<2.> Consider allowing a 'BLOCK' flag in the namespace (Turning off UNBLOCK)

B<3.> Build a Database connection Report role

B<4.> Allow placeholders in a config file for run-time arguments

B<5.> Add TapFatal with a fatal gracefully feature

B<6.> Add method to pull a caller($x) stack that can be triggered in the namespace 
boundaries.  Possibly this would be blocked on or off by talk() command (so only the 
first talk of the method would get it).

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
LICENSE file included with this package

This software is copyrighted (c) 2013 by Jed Lund

=head1 DEPENDANCIES

=over

=item L<5.010>

=item L<DateTime>

=item L<Carp> = cluck confess

=item L<version>

=item L<YAML::Any>

=item L<JSON::XS>

=item L<IO::Callback>

=item L<Moose>

=item L<Moose::Exporter>

=item L<MooseX::Types>

=item L<MooseX::Types::Moose>

=item L<MooseX::Singleton>

=item L<MooseX::StrictConstructor>

=item L<MooseX::ShortCut::BuildInstance>

=item L<Data::Walk::Extracted>

=item L<Data::Walk::Prune>

=item L<Data::Walk::Clone>

=item L<Data::Walk::Graft>

=item L<Log::Shiras::Types>

=item L<Log::Shiras::Switchboard>

=item L<Log::Shiras::Telephone>

=item L<Log::Shiras::Report>

=back

=head1 SEE ALSO

=over

=item L<Log::Log4perl>

=item L<Log::Dispatch>

=item L<Log::Report>

=item L<Log::Shiras::Report::ShirasFormat>

=item L<Log::Shiras::Report::TieFile>

=item L<Test::Log::Shiras>

=cut
	
#########1 main POD end      3#########4#########5#########6#########7#########8#########9