package Log::Shiras;
use version 0.77; our $VERSION = version->declare("v0.30.0");
use utf8;
#########1 main pod docs      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras - A Moose based logging and reporting tool

=begin html

<a href="https://www.perl.org">
	<img src="https://img.shields.io/badge/perl-5.10+-brightgreen.svg" alt="perl version">
</a>

<a href="https://travis-ci.org/jandrew/Log-Shiras">
	<img alt="Build Status" src="https://travis-ci.org/jandrew/Log-Shiras.png?branch=master" alt='Travis Build'/>
</a>

<a href='https://coveralls.io/github/jandrew/Log-Shiras?branch=master'>
	<img src='https://coveralls.io/repos/github/jandrew/Log-Shiras/badge.svg?branch=master' alt='Coverage Status' />
</a>

<a href='https://github.com/jandrew/Log-Shiras'>
	<img src="https://img.shields.io/github/tag/jandrew/Log-Shiras.svg?label=github version" alt="github version"/>
</a>

<a href="https://metacpan.org/pod/Log::Shiras">
	<img src="https://badge.fury.io/pl/Log-Shiras.svg?label=cpan version" alt="CPAN version" height="20">
</a>

<a href='http://cpants.cpanauthors.org/dist/Log-Shiras'>
	<img src='http://cpants.cpanauthors.org/dist/Log-Shiras.png' alt='kwalitee' height="20"/>
</a>

=end html

=head1 SYNOPSIS

	#!perl
	use Modern::Perl;
	use lib 'lib', '../lib',;
	use Log::Shiras::Unhide qw( :debug);#
	use Log::Shiras::Switchboard;
	use Log::Shiras::Telephone;
	use Log::Shiras::Report::Stdout;
	$| = 1;

	sub shout_at_me{
		my $telephone = Log::Shiras::Telephone->new( report => 'run' );
		$telephone->talk( carp_stack => 1, level => 'info', message =>[ @_ ] );
	}

	###LogSD warn "lets get ready to rumble...";
	my $operator = Log::Shiras::Switchboard->get_operator(
			name_space_bounds =>{
				main =>{
					UNBLOCK =>{
						# UNBLOCKing the run reports (destinations)
						# 	at the 'main' caller name_space and deeper
						run	=> 'trace',
					},
				},
			},
			reports =>{
				run =>[ Log::Shiras::Report::Stdout->new, ],
			},
		);
	###LogSD warn "Getting a Telephone";
	my $telephone = Log::Shiras::Telephone->new( report => 'run' );# or just '->new'
	$telephone->talk( message => 'Hello World 1' );
	###LogSD warn "message was sent to the report 'run' without sufficient permissions";
	$telephone->talk( level => 'info', message => 'Hello World 2' );
	###LogSD warn "message sent with sufficient permissions";
	shout_at_me( 'Hello World 3' );

	#####################################################################################
	#	Synopsis screen output
	# 01: Using Log::Shiras::Unhide-v0.29_1 strip_match string: (LogSD) at ../lib/Log/Shiras/Unhide.pm line 87.
	# 02: lets get ready to rumble... at log_shiras.pl line 15.
	# 03: Getting a Telephone at log_shiras.pl line 30.
	# 04: message was sent to the report 'run' without sufficient permissions at log_shiras.pl line 33.
	# 05: | level - info   | name_space - main
	# 06: | line  - 0034   | file_name  - log_shiras.pl
	# 07: 	:(	Hello World 2 ):
	# 08: message sent with sufficient permissions at log_shiras.pl line 35.
	# 09: | level - info   | name_space - main::shout_at_me
	# 10: | line  - 0012   | file_name  - log_shiras.pl
	# 11: 	:(	Hello World 3
	# 12: 		 at ..\lib\Log-Shiras\lib\Log\Shiras\Telephone.pm line 148.
	# 13: 		Log::Shiras::Telephone::talk(Log::Shiras::Telephone=HASH(0x144cc18), "carp_stack", 1, "level", "info", "message", ARRAY(0xa14cd8)) called at log_shiras.pl line 12
	# 14: 		main::shout_at_me("Hello World 3") called at log_shiras.pl line 36 ):
	#####################################################################################

=head1 DESCRIPTION

L<Shiras|http://en.wikipedia.org/wiki/Moose#Subspecies> - A small subspecies of
Moose found in the western United States (of America).

This is L<one of many loggers|https://metacpan.org/search?q=Log> you can choose from in
CPAN.  The ultimate goal of this package is to add name-space control to any of your
programs outputs that you want name-space control of.  As the program stands today there
are three relevant name-spaces.  First, the file name-space, file name-space is the
name-space that we apply to specific files (modules or scripts).  The file name-space in
this package is treated as flat (no heirarchy) and is managed using L<source code filters
|Log::Shiras::Unhide>.  File name-space filtering is therefore done at compile time with
no run time changes available.  The second name-space is a run time caller name-space that
can be adjusted as the program operates.  Run time name-space applied to the source of the
output.  Run time name-space is hierarchical and each output source can be assigned a level
of urgency.  This allows run time name-space filtering to be applied lower in the heirarchy
and remain in force out in the branch.  Permissions for run time name-space can also change
during run time.  Finally, there is a destination name-space.  Not all sources will wish to
call the same destination.  Destination name-space is flat and less flexible but still
somewhat editable at run time.  To sort of stich the last three concepts together mentally
I have used terminology associated with the old land line telephone system.  Run time or
caller name-space is managed through L<telephones|Log::Shiras::Telephone>.  Run time
permissions are managed through a L<switchboard|Log::Shiras::Switchboard> with switchboard
operators.  And destinations are called L<reports|Log::Shiras::Switchboard/reports>.  This
last term does not follow the terminology of the old land lines since communication through
this package is one direction.  Reports cannot send messages back on the same connection
that they use to receive information.

All in all this can create a complex name-space landscape.  For this package all name-spaces
in the run environment are shared and caution should be used to manage uniqueness.  I would
encourage starting simple and working out if you don't have a lot of logging experience.
This package is most related in concept to L<Log::Dispatch>.

=head2 Acknowledgement

I was a strong user of L<Log::Log4perl> and L<Smart::Comments> prior to writing this package.
I borrowed heavily from them when writing this.

=head1 Differentiation

Why choose this Logger over one of the many other options?  Here are some implementation
ecisions that I made that may or may not help that decision.  Many if not all exist in
other loggers.  I don't think they all exist together an any other logger.

=head2 Buffer behavior

This package has a destination buffer in the switchboard (default off) for each report
name.  This allows for some messages to be discarded after they were collected based on
branches in the code.  A use case for this is when you are recursively parsing some logic
but only want to log the actions in the path that yielded results.  This is different than
a print buffer that always goes to the output but the send is just delayed.

=head2 L<Log::Shiras::Test2>

A dedicated test module for testing logged messages that will capture messages at
the switchboard level rather than requiring a connection to the final destination
of the report to review output.  This leverages the buffering behavior above.
The test methods include several ways of checking for output existence.  This
means that 'Telephone' output can be tested without building a 'Report' to
receive it.  Testing report content should be done traditionally.

=head2 Headers

The 'Report' class in this package for CSV files L<Log::Shiras::Report::CSVFile>
only adds the header to a file when it is new.  If the file connection
is dropped and then reconnected the header will not be added again if the
file is not empty.  It will also manage (or at least warn) on header drift.

=head2 Custom formatting

I wanted to be able to use method calls and code references when formatting
'Report' output.  The
L<Log::Shiras::Report::ShirasFormat
|http://search.cpan.org/~jandrew/Log-Shiras/lib/Log/Shiras/Report/ShirasFormat.pm>
Role for the 'Report' class does just that.  While the API isn't as mature as
Log4perl's 'PatternLayout' it does support full perl sprintf formatting.

=head2 L<Moose|Moose::Manual>

This package is Moose based.  You probably already have an opinion on Moose so this
may tip you one way or the other.

=head2  Multiple output paths

Allowing more than one destination from the same source is helpful.  This means
you can write your output to multiple sources without wiring up the connection until
later.  See also L<Log::Dispatch>.

=head2  Source filtering

Excessive outputs for troubleshooting will overburden code.  Having a source filter
will allow the code to remain in source control (no retyping of print statements)
while still not burdening run time operations generally.

=head2  Custom urgency levels

If you feel the need you can re-define the urgency level words

=head2 Re-routing print statements

See L<Log::Shiras::TapPrint>

=head2 Re-routing warn statements

See L<Log::Shiras::TapWarn>

=head2 Message meta data

When messages are sent the switchboard bundles them with meta-data.  Mostly this
is basic stuff like where did I come from and when was I made.  For details
review L<Log::Shiras::Switchboard/master_talk( $args_ref )>

=head1 Build/Install from Source

=over

B<1.> Download a compressed file with the code

B<2.> Extract the code from the compressed file.

=over

If you are using tar this should work:

	tar -zxvf Log-Shiras-v0.xx.tar.gz

=back

B<3.> Change (cd) into the extracted directory.

B<4.> Run the following

=over

(For Windows find what version of make was used to compile your perl)

	perl  -V:make

(for Windows below substitute the correct make function (s/make/dmake/g)?)

=back

	>perl Makefile.PL

	>make

	>make test

	>make install # As sudo/root

	>make clean

=back

=head1 SUPPORT

=over

=item L<github Log::Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 TODO

=over

B<1.> Build a Database connection Report role

B<2.> Add TapFatal with a fatal gracefully feature

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

This software is copyrighted (c) 2012, 2016 by Jed Lund

=head1 DEPENDANCIES

See individual modules

=head1 SEE ALSO

=over

=item L<Log::Log4perl>

=item L<Log::Dispatch>

=item L<Log::Report>

=back

=cut

#########1 main POD end      3#########4#########5#########6#########7#########8#########9
