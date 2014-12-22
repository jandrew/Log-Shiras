package Log::Shiras::UnhideDebug;
use version; our $VERSION = version->declare("v0.21_1");

use 5.010;
use strict;
use warnings;

use File::Temp qw(tempfile);
use File::Spec;
use Carp qw( cluck );

use constant INTERNAL_DEBUG => 0;
my	$my_unhide_skip_check =
		qr/(
			^MooseX.ShortCut|	^Archive.Zip|		^File|
			^UNIVERSAL|			^IO.File|			^Compress.Raw|
			^FileHandle|		^File.Copy|			^Time.Local|
			^XML.LibXML|		^Encode|			^XML.SAX|
			^Log|				^Type|				^DateTime(?!X)|
			^Class.Factory|		^Module.Pluggable	^Devel|
			^Clone				^Moose(?!X)
		)/x;

###########################################
sub import {
###########################################
	print "Loading Log::Shiras::UnhideDebug\n" if INTERNAL_DEBUG;
	
    if( defined $ENV{log_shiras_filter_on} ) {
		cluck "\$ENV{log_shiras_filter_on} is active - Log::Shiras::UnhideDebug should kick in" if INTERNAL_DEBUG;
		resurrector_init();
	}
}

##################################################
sub resurrector_fh {
##################################################
    my($file) = @_;

    local($/) = undef;
    open FILE, "<$file" or die "Cannot open $file";
    my $text = <FILE>;
    close FILE;

    print "Read ", length($text), " bytes from $file\n" if INTERNAL_DEBUG;

    my($tmp_fh, $tmpfile) = tempfile( UNLINK => 1 );
    print "Opened tmpfile $tmpfile\n" if INTERNAL_DEBUG;

    $text =~ s/^(\s*)###LogSD\s/$1         /mg;

    #~ print "Text=[$text]\n" if INTERNAL_DEBUG;
	print "--------->Module Scrub complete\n" if INTERNAL_DEBUG;

    print $tmp_fh $text;
    seek $tmp_fh, 0, 0;

    return $tmp_fh;
}

###########################################
sub resurrector_loader {
###########################################
    my ($code, $module) = @_;

    print "resurrector_loader (debug unhider) called with $module\n" if INTERNAL_DEBUG;

      # Skip Log4perl appenders
    if($module =~ $my_unhide_skip_check) {
		cluck "Don't scrub $module (it's on the skip list)\n" if INTERNAL_DEBUG;
        return undef;
    }else{
		print "Module: $module\nDoesn't match: $my_unhide_skip_check\n" if INTERNAL_DEBUG;;
	}

    my $path = $module;
	print "Testing module: $module\n" if INTERNAL_DEBUG;
      # Skip unknown files
    if(!-f $module) {
          # We might have a 'use lib' statement that modified the
          # INC path, search again.
        $path = pm_search($module);
        if(! defined $path) {
            print "File $module not found\n" if INTERNAL_DEBUG;
            return undef;
        }
        print "File $module found in $path\n" if INTERNAL_DEBUG;
    }

    print "Unhiding debug in module $path\n" if INTERNAL_DEBUG;

    my $fh = resurrector_fh($path);

    my $abs_path = File::Spec->rel2abs( $path );
    print "Setting %INC entry of $module to $abs_path\n" if INTERNAL_DEBUG;
    $INC{$module} = $abs_path;

    return $fh;
}
use Data::Dumper;
###########################################
sub pm_search {
###########################################
    my($pmfile) = @_;

	print "Reviewing: $pmfile\n" if INTERNAL_DEBUG;
    for(@INC) {
          # Skip subrefs
		print "Next file: $_\n" if INTERNAL_DEBUG;
        next if ref($_);
		print "Passed the ref test...\n" if INTERNAL_DEBUG;
        my $path = File::Spec->catfile($_, $pmfile);
        return $path if -f $path;
    }

    return undef;
}

###########################################
sub resurrector_init {
###########################################
    unshift @INC, \&resurrector_loader;
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9
	
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::UnhideDebug - Unhides Log::Shiras from ###LogSD in @ISA

=head1 SYNOPSIS
	
	use Log::Shiras::Switchboard qw( :debug );#
	my	$operator = Log::Shiras::Switchboard->get_operator(#
					name_space_bounds =>{
							UNBLOCK =>{
								log_file => 'trace',
							},
					},
					reports =>{
						log_file =>[ MyLogger->new ],
					},
				);
	###LogSD use Log::Shiras::UnhideDebug;
	use	MyModule::With::Log::Shiras::DebugLines;
    
=head1 DESCRIPTION

This class is stolen unashamedly from L<Log::Log4perl::Resurrector>.  Any mistakes are my 
own and the genious is from there.  Log::Log4perl::Resurrector also credits the 
L<Acme::Incorporated> CPAN module, written by L<chromatic|/https://metacpan.org/author/CHROMATIC>. 
Long live CPAN!

This package definitly falls in the dark magic catagory and will only slow your code down.  
Don't use it if you arn't willing to pay the price.  The value is all the interesting 
information you receive from the debugged code.

=head1 SUPPORT

=over

L<Log-Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 TODO

=over

B<1.> Nothing L<currently|/SUPPORT>

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

L<version>

L<Type::Utils>

L<Type::Library>

L<Types::Standard>

L<MooseX::ShortCut::BuildInstance::TempFilter>

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9