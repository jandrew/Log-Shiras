package Log::Shiras::Report;
use version 0.77; our $VERSION = qv("v0.20.4");

use Moose::Role;
use Data::Dumper;
use Carp qw( cluck );
use Types::Standard qw(
        Bool		ArrayRef		HashRef
		Str			Object			is_HashRef
		is_ArrayRef
    );
###LogSSR use Log::Shiras::UnhideSelfReport;
###LogSSR use Log::Shiras::Telephone;
	
use Text::CSV_XS;
my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1, eol => "\n" });

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has to_stdout =>(
	isa 	=> Bool,
	default	=> 0,
	writer	=> 'set_to_stdout',
	reader	=> 'send_to_stdout',
);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub add_line {
    my  ( $self, $first_ref, @list ) = @_;
	my  $message_ref;
	###LogSSR	my	$phone = Log::Shiras::Telephone->new(
	###LogSSR					name_space 	=> $self->get_log_space .  '::add_line', );
	###LogSSR		$phone->talk( level => 'info', message =>[
	###LogSSR			"Arrived at add_line with:", $first_ref, @list ] );
	if( is_HashRef( $first_ref ) ){
		###LogSSR		$phone->talk( level => 'info', message =>[
		###LogSSR			"Use the hashref as is:", $first_ref, ] );
		#~ print "The message is a hashref:" . Dumper( $first_ref );
		if( exists $first_ref->{message} and
			(!is_ArrayRef( $first_ref->{message} ) or scalar( @{$first_ref->{message}} ) == 1 ) ){
				#~ print "Identified a string where I want an array\n";
			if( $csv->parse( !is_ArrayRef( $first_ref->{message} ) ? $first_ref->{message} : $first_ref->{message}->[0] ) ){
				$first_ref->{message} = [ $csv->fields ];
				###LogSSR	$phone->talk( level => 'info', message =>[
				###LogSSR		"Converting the message string to an array:", $arg_ref->{headers} ] );
				#~ print "Fixed the hash:" . Dumper( $first_ref );
			}else{
				###LogSSR	$phone->talk( level => 'warn', message =>[
				###LogSSR		"unable to convert the header string because: " . $csv->error_diag() ] );
				#~ confess "unable to convert the header string because: " . $csv->error_diag();
			}
		}
		$message_ref = $first_ref;
	}elsif( is_ArrayRef( $first_ref ) ){
		#~ print "The message is an arrayref:" . Dumper( $first_ref );
		$message_ref->{message} = $first_ref;
		###LogSSR		$phone->talk( level => 'info', message =>[
		###LogSSR			"Adjust the first arrayref to:", $message_ref, ] );
	}elsif( is_Str( $first_ref ) ){
		#~ print "The message is a string:" . Dumper( $first_ref );
		if( $csv->parse( $first_ref ) ){
			$message_ref->{message} = [ $csv->fields ];
			###LogSSR	$phone->talk( level => 'info', message =>[
			###LogSSR		"Converting the string to an array:", $arg_ref->{headers} ] );
		}else{
			###LogSSR	$phone->talk( level => 'warn', message =>[
			###LogSSR		"unable to convert the header string because: " . $csv->error_diag() ] );
			#~ confess "unable to convert the header string because: " . $csv->error_diag();
			$message_ref->{message} = [ $first_ref ];
		}
	}
	push @{$message_ref->{message}}, @list if @list;
	#~ confess "Loading message ref:", Dumper( $message_ref );
	###LogSSR		$phone->talk( level => 'info', message =>[
	###LogSSR			"Final message ref with added list:", $message_ref, ] );
	my  $line_ref;
	if( $self->can( '_use_formatter' ) ){
		###LogSSR		$phone->talk( level => 'info', message =>[
		###LogSSR			"Sending traffic to the formatter:", $message_ref, ] );
		$line_ref = $self->_use_formatter( $message_ref );
	}else{
		###LogSSR		$phone->talk( level => 'info', message =>[
		###LogSSR			"Using the straight up message list", $message_ref->{message}, ] );
		$line_ref = $message_ref->{message};
	}
		
	###LogSSR		$phone->talk( level => 'info', message =>[
	###LogSSR			"Acting on the message: $line", ] );
	if( $self->send_to_stdout ){
		###LogSSR		$phone->talk( level => 'info', message =>[
		###LogSSR			"The message is redirected to STDOUT:", $line_ref, ] );
		
		$csv->print( *STDOUT, $line_ref );
	}elsif( $self->can( '_load_appender' ) ){
		###LogSSR		$phone->talk( level => 'info', message =>[
		###LogSSR			"Sending the message to the active appender:", $line_ref, ] );
        $self->_load_appender( $line_ref );
    }
    return $line_ref;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9
	


#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::Report - Report Role (Interface) for Log::Shiras

=head1 SYNOPSIS
    
=head1 DESCRIPTION

Documenation not written yet

=cut

#################### main pod documentation end ###################