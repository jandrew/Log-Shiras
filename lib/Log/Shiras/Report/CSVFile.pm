package Log::Shiras::Report::CSVFile;
use version; our $VERSION = qv("0.019_001");

use Moose;
use Text::CSV_XS;
use	MooseX::StrictConstructor;
use	MooseX::HasDefaults::RO;
use Data::Dumper;
#~ use	IO::File;
use Carp qw( confess cluck );
use Fcntl qw( :flock LOCK_EX LOCK_UN);# SEEK_END
use Types::Standard qw(
		FileHandle		ArrayRef	is_ArrayRef
		is_HashRef		Str
    );
use lib '../../../../lib';
###LogSSR use Log::Shiras::UnhideSelfReport;
###LogSSR with 'Log::Shiras::LogSpace';
###LogSSR use Log::Shiras::Telephone;
use Log::Shiras::Types qw(
        textfile		headerstring
    );
my $csv = Text::CSV_XS->new ({ binary => 1, eol => "\n"});#, auto_diag => 1

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has 'file' =>(
        isa         => FileHandle|Str,
        reader      => 'get_file',
        predicate   => '_has_file',
        clearer     => '_clear_file',
        required    => 1,
    );

has 'headers' =>(
        isa         => ArrayRef[headerstring],
		traits		=> ['Array'],
        predicate   => 'has_header_ref',
        reader      => 'get_header_ref',
        clearer     => '_clear_header_ref',
		handles	=>{
			header_size => 'count',
		},
    );

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9



#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _load_appender{
	my ( $self, $line_ref ) = 
	@_; 
	###LogSSR	my	$phone = Log::Shiras::Telephone->new(
	###LogSSR					name_space 	=> $self->get_log_space . '::_load_appender', );
	###LogSSR		$phone->talk( level => 'info', message =>[
	###LogSSR			"Arrived at _load_appender with line ref:", $line_ref ] );
	###LogSSR	if( $self->has_header_ref and $self->header_size != scalar( @$line_ref ) ){
		###LogSSR	$phone->talk( level => 'warn', message =>[
		###LogSSR		"The passed line has a different number of columns than the header" ] );
	###LogSSR	}
	return $csv->print( $self->get_file, $line_ref );
}

around BUILDARGS => sub{
    my $orig	= shift;
    my $class	= shift;
	my $arg_ref	= is_HashRef( $_[0] ) ? $_[0] : { @_ }; 
	###LogSSR	my	$phone = Log::Shiras::Telephone->new(
	###LogSSR					name_space 	=> $self->get_log_space . '::add_line', );
	###LogSSR		$phone->talk( level => 'info', message =>[
	###LogSSR			"Arrived at BUILDARGS with args:", $arg_ref ] );
	#~ print "Arrived at BUILDARGS with args:" . Dumper( $arg_ref );
	my $old_headers;
	my $file_name = $arg_ref->{file};
	if( $file_name !~ /\.csv/ ){
		confess "The passed filename -$file_name- doesn't have a .csv extention";
	}elsif( -e $file_name and  -s $file_name ){
		open my $fh, "<:encoding(utf8)", $file_name or confess "$file_name: $!";
		$old_headers = $csv->getline( $fh );
		close $fh; 
		#~ print "Retreived old headers:"  . Dumper( $old_headers );
	}
	#~ print "Finished fishing for old files\n";
	if( exists $arg_ref->{headers} ){
		###LogSSR	$phone->talk( level => 'info', message =>[
		###LogSSR		"Handling headers:", $arg_ref->{headers} ] );
		#~ print "Managing passed headers: " . Dumper( $arg_ref->{headers} );
		if( !is_ArrayRef( $arg_ref->{headers} ) ){
			###LogSSR	$phone->talk( level => 'info', message =>[
			###LogSSR		"Converting headers strings to arrays:" ] );
			if( $csv->parse( $arg_ref->{headers} ) ){
				$arg_ref->{headers} = [ $csv->fields ];
				###LogSSR	$phone->talk( level => 'info', message =>[
				###LogSSR		"Converting header array:", $arg_ref->{headers} ] );
			}else{
				confess "unable to convert the header string because: " . $csv->error_diag();
			}
		}
		s/[\n\r]//g for @{$arg_ref->{headers}};# Take out the newlines
		# Test old and new headers for compatability
		if( $old_headers ){
			#~ print "You will use the old headers no matter what\n";
			if( $#$old_headers != $#{$arg_ref->{headers}} ){
				###LogSSR	$phone->talk( level => 'info', message =>[
				###LogSSR		"Starting a new file since there are are different number of headers in the old file" ] );
				cluck "There are a different amount of old headers compared to the new headers";
			}else{
				for my $x ( 0 .. $#$old_headers ){
					###LogSSR	$phone->talk( level => 'info', message =>[
					###LogSSR		"Testing position: $x" ] );
					#~ print "Testing old header: $old_headers->[$x]\n";
					#~ print "..against new header: $arg_ref->{headers}->[$x]\n";
					if( $old_headers->[$x] !~ /^$arg_ref->{headers}->[$x]$/i ){
						cluck "failed to match old header -$old_headers->[$x]- to new header: $arg_ref->{headers}->[$x]";
					}
				}
			}
			$arg_ref->{headers} = $old_headers;
		}
	}elsif( $old_headers ){
		#~ print "Just using old headers: " . Dumper( $old_headers );
		$arg_ref->{headers} = $old_headers;
	}
	# Convert file name to file handle
	#~ print "Opening the file to append: $file_name";
	open my $fh, ">>:encoding(utf8)", $file_name or confess "$file_name: $!";
	flock( $fh, LOCK_EX );
	if( !$old_headers and exists $arg_ref->{headers} ){
		$csv->print( $fh, $arg_ref->{headers} );
	}
	$arg_ref->{file} = $fh;
	###LogSSR		$phone->talk( level => 'info', message =>[
	###LogSSR			"Final args:", $arg_ref ] );
	#~ print "Building with: " . Dumper( $arg_ref );
	return $class->$orig($arg_ref);
};

sub DEMOLISH{
	my ( $self ) = @_;
	###LogSSR	my	$phone = Log::Shiras::Telephone->new(
	###LogSSR					name_space 	=> $self->get_log_space .  '::add_line', );
	###LogSSR		$phone->talk( level => 'info', message =>[
	###LogSSR			"Arrived at DEMOLISH" ] );
	flock( $self->get_file, LOCK_UN );
	close( $self->get_file );
	$self->_clear_file;
}

#################### Phinish with a Phlourish #######################

no Moose;
__PACKAGE__->meta->make_immutable;

1;
# The preceding line will help the module return a true value

#################### main pod documentation begin ###################

__END__

=head1 NAME

Log::Shiras::Report::CSVFile.pm - A possible report base for csv files

=head1 SYNOPSIS


    
=head1 DESCRIPTION

No written yet!

=cut

#################### main pod documentation end ###################