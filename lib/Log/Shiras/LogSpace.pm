package Log::Shiras::LogSpace;
use version; our $VERSION = qv('v0.23_1');

use Moose::Role;
use Types::Standard qw(
		Str
    );
use Carp 'cluck';
use Data::Dumper;
my $test = qr/^(Module::Runtime|Moose|Moose::Util|Moose::Exporter|Eval::Closure::Sandbox_\d*)$/;

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has log_space =>(
		isa		=> Str,
		reader	=> 'get_log_space',
		writer	=> 'set_log_space',
		default	=> sub{
			my $x = 0;
			print "Testing: " . (caller( $x ))[0] . "\nAgainst" . $test;
			while( (caller( $x ))[0] =~ $test ){
				print "don't use: " . (caller( $x ))[0] . "\n";
				$x++;
			}
			print "Using: " . (caller( $x ))[0] . "\n";
			return (caller( $x ))[0];
		},
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

Log::Shiras::LogSpace - Log::Shiras Role for namespaces

=head1 DESCRIPTION

B<This documentation is written to explain ways to extend this package.  To use the data 
extraction of Excel workbooks, worksheets, and cells please review the documentation for  
L<Spreadsheet::XLSX::Reader::LibXML>,
L<Spreadsheet::XLSX::Reader::LibXML::Worksheet>, and 
L<Spreadsheet::XLSX::Reader::LibXML::Cell>>

Normally the attribute justs belong in the package but it is nice to have in a 
pluggable role for sub unit testing.

=head1 SYNOPSIS
	
	#!perl
	package MyPackage;
	###LogSD with 'Log::Shiras::LogSpace';

=head2 Attributes

Data passed to new when creating an instance of the consuming class.  For modification of 
these attributes see the listed L<Methods|/Methods>.

=head3 log_space

=over

B<Definition:> This is provided for external use by the logging package L<Log::Shiras
|https://github.com/jandrew/Log-Shiras>.

B<Default> __PACKAGE__

B<Range> Any string, but Log::Shiras will look for '::' separators
		
=back

=head2 Methods

This is a method to access the attribute.

=head3 get_log_space

=over

B<Definition:> This is the way to read the set name_space. (there is no way to modify it)

B<Accepts:>Nothing

B<Returns:> the 'name_space' value

=back

=head1 SUPPORT

=over

L<github Spreadsheet::XLSX::Reader::LibXML/issues
|https://github.com/jandrew/Spreadsheet-XLSX-Reader-LibXML/issues>

=back

=head1 TODO

=over

B<1.> Make this not even load for the package if 
L<Log::Shiras|https://github.com/jandrew/Log-Shiras> qw( :debug ) is not enabled

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

This software is copyrighted (c) 2014 by Jed Lund

=head1 DEPENDENCIES

=over

L<Spreadsheet::XLSX::Reader::LibXML>

=back

=head1 SEE ALSO

=over

L<Spreadsheet::ParseExcel> - Excel 2003 and earlier

L<Spreadsheet::XLSX> - 2007+

L<Spreadsheet::ParseXLSX> - 2007+

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9