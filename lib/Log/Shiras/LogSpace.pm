package Log::Shiras::LogSpace;
use version; our $VERSION = version->declare("v0.37.3");
#~ use lib '../../';
#~ use Log::Shiras::Unhide qw( :InternalLoGSpacE );
###InternalLoGSpacE	warn "You uncovered internal logging statements for Log::Shiras::LogSpace-$VERSION";
use 5.010;
use utf8;
use Moose::Role;
use MooseX::Types::Moose qw( Str );

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has log_space =>(
		isa		=> Str,
		reader	=> 'get_log_space',
		writer	=> 'set_log_space',
		predicate	=> 'has_log_space',
		default	=> sub{
			my( $self ) = @_;
			return ref $self;
		}
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub get_all_space{
	my ( $self ) = @_;
	my	$all_space = $self->get_log_space;
	if( $self->can( 'get_class_space' ) and length( $self->get_class_space ) > 0 ){
		$all_space .= '::' . $self->get_class_space;
	}
	return $all_space;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;
# The preceding line will help the module return a true value

#########1 main POD docs      3#########4#########5#########6#########7#########8#########9

__END__

=head1 NAME

Log::Shiras::LogSpace - Log::Shiras Role for runtime name-spaces

=head1 SYNOPSIS

	use Modern::Perl;
	use MooseX::ShortCut::BuildInstance qw( build_class );
	use	lib
			'../lib',;
	use Log::Shiras::LogSpace;
	my $test_instance = build_class(
			package => 'Generic',
			roles =>[ 'Log::Shiras::LogSpace' ],
			add_methods =>{
				get_class_space => sub{ 'ExchangeStudent' },
				i_am => sub{
					my( $self )= @_;
					print "I am a: " . $self->get_all_space . "\n";
				}
			},
		);
	my $Generic = $test_instance->new;
	my $French = $test_instance->new( log_space => 'French' );
	my $Spanish = $test_instance->new( log_space => 'Spanish' );
	$Generic->i_am;
	$French->i_am;
	$Spanish->i_am;

	#######################################################################################
	# Synopsis Screen Output
	# 01: I am a: Generic::ExchangeStudent
	# 02: I am a: French::ExchangeStudent
	# 03: I am a: Spanish::ExchangeStudent
	#######################################################################################

=head1 DESCRIPTION

This attribute is useful to manage runtime L<Log::Shiras> caller namespace.  In the case
where MyCoolPackage with Log::Shiras lines is used in more than one context then it is
possible to pass a context sensitive name to the attribute log_space on intantiation of the
instance and have the namespace bounds only activate the desired context of the package
rather than have it report everywhere it is used.  The telephone call in this case would
look something like this;

	package MyCoolPackage

	sub get_class_space{ 'MyCoolPackage' }

	sub my_cool_sub{
		my( $self, $message ) = @_;
		my $phone = Log::Shiras::Telephone->new(
						name_space => $self->get_all_space . '::my_cool_sub',
					);
		$phone->talk( level => 'debug',
			message => "Arrived at my_cool_sub with the message: $message" );
		# Do something cool here!
	}

In this case if you used my cool package instances with the log_space set to different
values then only the namespace unblocked for 'FirstInstance::MyCoolPackage::my_cool_sub'
would report.  In the case where no sub 'get_class_space' is available the call to
L<get_all_space|/get_all_space> will return the same value as 'get_log_space'.

=head2 Attributes

Data passed to new when creating an instance of the consuming class.  For modification of
this attribute see the listed L<attribute methods|/attribute methods>.

=head3 log_space

=over

B<Definition:> This will be the base log_space element returned by L<get_all_space
|/get_all_space>


B<Default> the consuming package name

B<Range> Any string, but Log::Shiras will look for '::' separators

B<attribute methods>

=over

B<get_log_space>

=over

B<Definition:> Returns the attribute value

=back

B<set_log_space( $string )>

=over

B<Definition:> sets the attribute value

=back

B<has_log_space>

=over

B<Definition:> predicate test for the attribute

=back

=back

=back

=head2 Method

=head3 get_all_space

=over

B<Definition:> This method collects the stored 'log_space' attribute value and then
joins it with the results of a method call to 'get_class_space'.  The 'get_class_space'
attribute should be provided somewhere else in the class.  The two values are joined with
'::'.

B<Accepts> nothing

B<Returns> log_space . '::' . $self->get_class_space or just log_space if there is no
return from 'get_class_space'

=back

=head1 SUPPORT

=over

L<github Spreadsheet::XLSX::Reader::LibXML/issues
|https://github.com/jandrew/Spreadsheet-XLSX-Reader-LibXML/issues>

=back

=head1 TODO

=over

B<1.> Nothing Yet

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

=head1 DEPENDENCIES

=over

L<Moose::Role>

L<MooseX::Types::Moose>

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9
