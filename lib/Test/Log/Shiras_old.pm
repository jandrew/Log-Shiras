package Test::Log::Shiras;

use 5.008;
use Moose;
use MooseX::StrictConstructor;
use YAML::Any;
use MooseX::NonMoose;
extends 'Test::Builder::Module';
if( $ENV{Smart_Comments} ){
	use Smart::Comments -ENV;#'###'
}
### Smart-Comments turned on for Test-Buffered-Output
use version 0.94; our $VERSION = qv('0.007_001');
use Carp;
use MooseX::Types::Moose qw(
        ScalarRef
        FileHandle
        Bool
        RegexpRef
        HashRef
        ArrayRef
        Ref
        Str
    );
our $test_buffer = {};
my  $class = __PACKAGE__;
my  $action_ref ={
        alt_fh =>{
            exists =>{
                STDOUT      => '_has_STDOUT_buffer_fh',
                STDERR      => '_has_STDERR_buffer_fh',
                _DEFAULT_   => '_noop',
            },
            clear =>{
                STDOUT  => '_clear_STDOUT_buffer_fh',
                STDERR  => '_clear_STDERR_buffer_fh',
            },
        },
        old_fh =>{
            get =>{
                STDOUT  => '_get_old_STDOUT',
                STDERR  => '_get_old_STDERR',
            },
        },
        buffer =>{
            set =>{
                STDOUT      => '_set_STDOUT_buffer',
                STDERR      => '_set_STDERR_buffer',
                _DEFAULT_   => '_set_global_buffer',
            },
            has =>{
                STDOUT      => '_has_STDOUT_buffer',
                STDERR      => '_has_STDERR_buffer',
                _DEFAULT_   => '_has_global_buffer',
            },
            list =>{
                STDOUT      => '_get_attribute_list',
                STDERR      => '_get_attribute_list',
                _DEFAULT_   => '_get_global_list',
            },
            raw =>{
                STDOUT      => '_get_STDOUT_buffer',
                STDERR      => '_get_STDERR_buffer',
                _DEFAULT_   => '_get_global_buffer',
            },
            close =>{
                STDOUT      => '_close_STDOUT_buffer',
                STDERR      => '_close_STDOUT_buffer',
                _DEFAULT_   => '_close_global_buffer',
            },
        },
        start_capture =>{
            STDOUT      => '_start_screen_buffer',
            STDERR      => '_start_screen_buffer',
            _DEFAULT_   => '_set_global_buffer',
        },
        set_capture =>{
            STDOUT      => '_set_screen_buffer',
            STDERR      => '_set_screen_buffer',
            _DEFAULT_   => '_set_global_buffer',
        },
    };
my ( $wait );
### Yes the variable $testbuffer pollutes the global namespace but I'm not 
### sure how to find one instance from another running instance in Moose 
### Send the answer to jandrew@cpan.org if you know

###############  Public Attributes  ####################################

has 'keep_matches' =>(
    is      => 'ro',
    isa     => Bool,
    default => 0,
    writer  => 'set_match_retention',
);

###############  Public Methods  #######################################

sub get_buffer{
    my ( $self, $buffer ) =@_;
    ### <where> - Reached get_buffer for    : $buffer
    my  $exists = $self->_get_method( 'buffer', 'has', $buffer );
    ### <where> - Running exists            : $exists
    my  $action = $self->_get_method( 'buffer', 'list', $buffer );
    ### <where> - Running action            : $action
    my @result = ( $self->$exists( $buffer ) ) ?
        $self->$action( $buffer ) : () ;
    ### <where> - the result is: @result
    return @result;
}

###############  Test Methods  #########################################

sub capture_output{
    my ( $self, $buffer, $test_description ) = @_;
    ### <where> - made it to capture_output
    ### <where> - target source is  : $buffer
    ### <where> - test description  : $test_description
    my $action = $self->_get_method( 'start_capture', $buffer );
    ### <where> - Running action    : $action
    my  $result = $self->$action( $buffer );
    my  $tb     = $class->builder;
    $tb->ok($result, $test_description);
    if( !$result ){
        $tb->diag( "Could not initiate buffer capture for -$buffer-: $!" );
    }
}

sub has_buffer{
    my ( $self, $buffer, $test_description ) =@_;
    ### <where> - reached has_buffer for: $buffer
    $self->_check_buffer( $buffer, 1, $test_description );
}

sub no_buffer{
    my ( $self, $buffer, $test_description ) =@_;
    ### <where> - reached no_buffer for: $buffer
    $self->_check_buffer( $buffer, 0, $test_description );
}

sub return_to_screen{
    my ( $self, $buffer, $test_description ) = @_;
    ### <where> - made it to return_to_screen for: $buffer
    ### <where> - with test description          : $test_description
    my $result;
    if( $buffer =~ /^STD(OUT|ERR)$/ ){
        $result = $self->_restore_filehandle( $buffer );
    }else{
        $result = 0;
    }
    ### <where> - the result is: $result
    my  $tb     = $class->builder;
    $tb->ok($result, $test_description);
    if( !$result ){
        $tb->diag( "Cannot restore to the screen a non screen buffer -$buffer-" );
    }
}

sub buffer_count{
    my ( $self, $guess, $buffer, $test_description ) =@_;
    ### <where> - testing the row count loaded in the buffer
    ### <where> - Reached for   : $buffer
    ### <where> - Guess         : $guess
    my  $actual_count = scalar( $self->get_buffer( $buffer ) );
    my  $tb     = $class->builder;
    $tb->ok($actual_count == $guess, $test_description);
    if( $actual_count != $guess ){
        $tb->diag( "Expected -$guess- items but found -$actual_count- items" );
    }
}

sub clear_buffer{
    my ( $self, $buffer, $test_description ) =@_;
    ### <where> - Reached clear_buffer for  : $buffer
    my $result = 0;
    my $description = "No buffer found for -$buffer-";
    my  $exists = $self->_get_method( 'buffer', 'has', $buffer );
    ### <where> - testing: $exists
    if( $self->$exists( $buffer ) ){
        my  $action = $self->_get_method( 'set_capture', $buffer );
        ### <where> - Running action: $action
        $result = $self->$action( $buffer, );
        ### <where> - the result is: $result
        $description = "Could not clear the -$buffer- buffer";
    }
    my  $tb = $class->builder;
    ### <where> - the result is: $result
    $tb->ok($result, $test_description);
    if( !$result ){
        $tb->diag( $description );
    }
}

sub close_buffer{
    my ( $self, $buffer, $test_description ) =@_;
    ### <where> - Reached close_buffer for  : $buffer
    my  $action = $self->_get_method( 'buffer', 'close', $buffer );
    ### <where> - Running action            : $action
    my  $result = $self->$action( $buffer );
    ### <where> - the result is: $result
    my  $tb     = $class->builder;
    $tb->ok($result, $test_description);
    if( !$result ){
        $tb->diag( "Could not close the -$buffer- buffer" );
    }
}
    

sub match_output{
    my ( $self, $buffer, $line, $test_description ) = @_;
    chomp $line;
    ###  <where> - Reached match_output
    ####  <where> - The buffer name passed is  : $buffer
    ####  <where> - The line passed is         : $line
    ####  <where> - The test explanation is    : $test_description
    my  $result = 0;
    my  $i      = 0;
    my  @failarray;
    my  $exists = $self->_get_method( 'buffer', 'has', $buffer );
    ### <where> - testing: $exists
    if( $self->$exists( $buffer ) ){
        ####  <where> - The buffer exists!
        my @buffer_list = $self->get_buffer( $buffer );
        #### <where> - The buffer list is: @buffer_list
        @failarray = (
            'Expected to find: ',
            $line,
            "but could not match it to data in -$buffer-..."
        );
        if( !@buffer_list ){
            ### <where> - The buffer list is EMPTY!
            push @failarray, 'Because the test buffer is EMPTY!';
        }else{
            for my $buffer_line ( @buffer_list ){
                ### <where> - testing line: $buffer_line
                if( (   is_RegexpRef( $line ) and 
                        $buffer_line =~ $line       ) or
                    ( $buffer_line eq $line )           ){
                    #### <where> - found a match!
                    $result = 1;
                    last;
                }else{
                    #### <where> - no match here!
                    push @failarray, "---$buffer_line";
                    $i++;
                }
            }
        }
        ### <where> - the match test result: $result
        if( !$self->keep_matches and $result ){
            ### <where> - splicing out match
            splice( @buffer_list, $i, 1);
            my $action = $self->_get_method( 'set_capture', $buffer );
            ### <where> - Reloading the buffer with the method: $action
            $self->$action( $buffer, [@buffer_list] );
            ### <where> - splice propagated to the buffer
        }
    } else {
        ####  <where> - The test buffer does not contain the source: $buffer
        @failarray = ( "Because the test buffer is not active for: $buffer" );
    }
    ### <where> - passing results to Test_Builder
    my  $tb = $class->builder;
    $tb->ok($result, $test_description);
    if( !$result ) {
        map{ $tb->diag( $_ ) } @failarray;
        return 0;
    }
}

sub cant_match_output{
    my ( $self, $buffer, $line, $test_description ) = @_;
    ###  <where> - Reached cant_match_output
    ####  <where> - The logger name passed is  : $buffer
    ####  <where> - The line passed is         : $line
    ####  <where> - The test explanation is    : $test_description
    my  $result = 1;
    my  $tb     = $class->builder;
    my  $i      = 0;
    my  @failarray;
    my  $exists = $self->_get_method( 'buffer', 'has', $buffer );
    ### <where> - testing: $exists
    if( $self->$exists( $buffer ) ){
        ####  <where> - The buffer exists!
        my @buffer_list = $self->get_buffer( $buffer );
        for my $test_line ( @buffer_list) {
            if( is_RegexpRef( $line ) and $test_line =~ $line ){
                ####  <where> - Found a regular expression match to: $line
                $result = 0;
                push @failarray, (
                        "For the -$buffer- buffer a no match condition was desired",
                        "for the regex -$line-",
                        "a match was found at position -$i-",
                        "(The line was not removed from the buffer!)"
                    );
                last;
            } elsif ( $test_line eq $line ) {
                ####  <where> - Found a match to: $line
                $result = 0;
                push @failarray, (
                        "For the -$buffer- buffer a no match condition was desired",
                        "for the string -$line-",
                        "a match was found at position -$i-",
                        "(The line was not removed from the buffer!)"
                    );
                last;
            } else {
                $i++;
                ####  <where> - No match for: $test_line
            }
        }
        if( $result ) {
            ####  <where> - Test buffer exists but the line was not found in: $buffer
        }
    } else {
        ####  <where> - Pass! appender not found
    }
    $tb->ok($result, $test_description);
    if( !$result ) {
        map{ $tb->diag( $_ ) } @failarray;
    }
}

###############  Private Attributes  ###################################

has '_old_STDOUT' =>(
    is      => 'ro',
    isa     => FileHandle,
    default => sub{
        ### <where> - loading _old_STDOUT ...
        (open my $fh, ">&STDOUT") or croak "Can't dup STDOUT: $!";
        return $fh;
    },
    reader  => '_get_old_STDOUT',
);

has '_old_STDERR' =>(
    is      => 'ro',
    isa     => FileHandle,
    default => sub{
        ### <where> - loading _old_STDERR ...
        (open my $fh, ">&STDERR") or croak "Can't dup STDERR: $!";
        return $fh;
    },
    reader  => '_get_old_STDERR',
);

has '_STDOUT_buffer' =>(
    is          => 'ro',
    isa         => ScalarRef,
    lazy        => 1,
    default     => sub{ \'' },
    reader      => '_get_STDOUT_buffer',
    writer      => '_set_STDOUT_buffer',
    clearer     => '_close_STDOUT_buffer',
    predicate   => '_has_STDOUT_buffer',
);

has '_STDERR_buffer' =>(
    is          => 'ro',
    isa         => ScalarRef,
    lazy        => 1,
    default     => sub{ \'' },
    reader      => '_get_STDERR_buffer',
    writer      => '_set_STDERR_buffer',
    clearer     => '_close_STDERR_buffer',
    predicate   => '_has_STDERR_buffer',
);

has '_STDOUT_buffer_fh' =>(
    is          => 'ro',
    isa         => FileHandle,
    predicate   => '_has_STDOUT_buffer_fh',
    reader      => '_get_STDOUT_buffer_fh',
    writer      => '_set_STDOUT_buffer_fh',
    clearer     => '_clear_STDOUT_buffer_fh',
);

has '_STDERR_buffer_fh' =>(
    is          => 'ro',
    isa         => FileHandle,
    predicate   => '_has_STDERR_buffer_fh',
    reader      => '_get_STDERR_buffer_fh',
    writer      => '_set_STDERR_buffer_fh',
    clearer     => '_clear_STDERR_buffer_fh',
);
    

#################### Private Methods ################################

after '_set_STDOUT_buffer' => sub{
    ### <where> - reached after _set_STDOUT_buffer 
    my ( $self ) = @_;
    if( $self->_has_STDOUT_buffer_fh() ){
        close $self->_get_STDOUT_buffer_fh();
    }
    open( my $fh, ">&STDOUT" ) or croak "Can't dup the new STDOUT: $!";
    $self->_set_STDOUT_buffer_fh( $fh );
    ### <where> - completed after _set_STDOUT_buffer 
};

#Use print statements for STDERR troubleshooting
after '_set_STDERR_buffer' => sub{
    my ( $self ) = @_;
    if( $self->_has_STDERR_buffer_fh() ){
        close $self->_get_STDERR_buffer_fh();
    }
    open( my $fh, ">&STDERR" ) or croak "Can't dup the new STDERR: $!";
    $self->_set_STDERR_buffer_fh( $fh );
};

before '_close_STDOUT_buffer' => sub{
    ### <where> - reached after _close_STDOUT_buffer 
    my ( $self ) = @_;
    $self->_restore_filehandle( 'STDOUT' );
    ### <where> - completed before _close_STDOUT_buffer 
};

#Use print statements for STDERR troubleshooting
before '_close_STDERR_buffer' => sub{
    my ( $self ) = @_;
    $self->_restore_filehandle( 'STDERR' );
};

sub _check_buffer{
    my ( $self, $buffer, $expected, $test_description ) = @_;
    my $action = $self->_get_method( 'buffer', 'has', $buffer );# || $buffer_existence->{_DEFAULT_};
    ### <where> - Reached _check_buffer for : $buffer
    ### <where> - Running action            : $action
    ### <where> - test description          : $test_description
    my $result = $self->$action( $buffer );
    ### <where> - resulting in: $result
    my  $tb     = $class->builder;
    $tb->ok( $result == $expected, $test_description);
    if( $result != $expected ){
        if( !$result ){
            $tb->diag( "Expected to find a buffer for -$buffer- but it didn't exist" );
        }else{
            $tb->diag( "A buffer for -$buffer- was un-expectedly found" );
        }
    }
}

sub _start_screen_buffer{
    my ( $self, $buffer ) = @_;#, $array_ref
    ### <where> - Reached _start_screen_buffer for: $buffer
    if( $buffer !~ /^STD(OUT|ERR)$/ ){
        confess "Attempting to start a screen buffer on a non screen name -$buffer-";
    }
    my  $buffer_ref;
    no strict 'refs';
    close *{$buffer};
    open $buffer, ">", \$buffer_ref  or 
            croak "Can't dup the new $buffer: $!";
    #~ print( $buffer join( "\n", @$array_ref) ) if $array_ref;
    use strict 'refs';
    my  $action = $self->_get_method( 'buffer', 'set', $buffer );
    ### <where> - Running action: $action
    $self->$action( \$buffer_ref );
}

sub _set_screen_buffer{
    my ( $self, $buffer, $array_ref ) = @_;
    ### <where> - Reached _set_screen_buffer for: $buffer
    ### <where> - using array ref: $array_ref
    if( $buffer !~ /^STD(OUT|ERR)$/ ){
        confess "Attempting to set a screen buffer on a non screen name -$buffer-";
    }
    my  $action = $self->_get_method( 'buffer', 'raw', $buffer );
    my  $buffer_ref = $self->$action;
    my  $buffer_line = ( $array_ref ) ?
        ( join "\n", @$array_ref ) : '' ;
    $$buffer_ref = $buffer_line;
    return 1;
}

sub _set_global_buffer{
    my ( $self, $buffer, $array_ref ) = @_;
    ### <where> - Reached _set_global_buffer for: $buffer
    ### <where> - loading array ref: $array_ref
    $test_buffer->{$buffer} = 
    ( $array_ref ) ? $array_ref : [];
}
    
sub _has_global_buffer{
    my ( $self, $buffer ) = @_;
    ### <where> - Reached _has_global_buffer for: $buffer
    return (exists $test_buffer->{$buffer});
}

sub _get_global_buffer{
    my ( $self, $buffer ) = @_;
    ### <where> - Reached _get_global_buffer for: $buffer
    return $test_buffer->{$buffer};
}

sub _get_global_list{
    my ( $self, $buffer ) = @_;
    ### <where> - Reached _get_global_buffer for: $buffer
    return @{$test_buffer->{$buffer}};
}

sub _get_attribute_list{
    my ( $self, $buffer ) = @_;
    my  $method = $self->_get_method( 'buffer', 'raw', $buffer );
    ### <where> - Reached _get_attribute_buffer for : $buffer
    ### <where> - using method                      : $method
    my @buffer_array = ( ${$self->$method} ) ?
        ( split "\n", ${$self->$method} ) : ();
    ### <where> - the buffer is: $buffer
    return @buffer_array;
}

sub _restore_filehandle{
    my ( $self, $buffer ) =@_;
    ### <where> - Reached _restore_filehandle for: $buffer
    my $method = $self->_get_method( 'old_fh', 'get', $buffer );
    ### <where> - using method: $method
    my $fh = $self->$method;
    ##### <where> - filehandle stuff: Dump( $$fh )
    no strict 'refs';
    (open "$buffer", ">&", $fh) or 
        croak "Can't dup the old $buffer: $!";
    #~ print $buffer "Filehandle works now";
    use strict 'refs';
    ### <where> - finished restoring the filehandle
    return 1;
}

sub _close_global_buffer{
    my ( $self, $buffer ) = @_;
    ### <where> - Reached _close_global_buffer for: $buffer
    return (delete $test_buffer->{$buffer});
}

sub _get_method{
    my ( $self, @command_list ) = @_;
    ### <where> - reached the _get_method resolver with: @command_list
    my $method = { %$action_ref };#copy the action ref
    for my $command ( @command_list ){
        if( is_Ref( $method ) ){
            if( exists $method->{$command} ){
                $method = $method->{$command};
            }elsif( exists $method->{_DEFAULT_} ){
                $method = $method->{_DEFAULT_};
            }else{
                confess "Attempting to find a command based on the string\n" .
                    join( ", ", @command_list ) . "\n" .
                    "... but failed with the command ->$command";
            }
        }else{
            croak "An excessive resolution list was passed to the method resolver\n" .
                join( ", ", @command_list ) . "\n" .
                "... the command chain ended with -$method-";
        }
    }
    if( is_Str( $method ) ){
        ### <where> - succesfully resolved to method: $method
        return $method;
    }else{
        croak "The following list was insufficient to resolve to a command\n" .
            join( ", ", @command_list );
    }
}

sub DEMOLISH{
    my ( $self ) = @_;
    ### reached DEMOLISH
    map{ $self->_restore_filehandle( $_ ) } ( 'STDOUT', 'STDERR'  );
    return 1;
}

#################### Phinish with a Phlourish #######################

no Moose;
# no need to fiddle with inline_constructor here
__PACKAGE__->meta->make_immutable;
  
1;
# The preceding line will help the module return a true value

#################### main pod documentation begin ###################
__DATA__

=head1 NAME

Test::Buffered::Output - Test the contents of a global buffer

=head1 SYNOPSIS

    use Test::Most;
    use Test::Exception;
    use Smart::Comments '###';
    use Carp;
    use Test::Buffered::Output v0.003;
    my  ( $test_inst, $expected_count );
    $| = 1;
    ### hard questions
    lives_ok{ $test_inst = Test::Buffered::Output->new(); }      "Test that a new test instance begins";
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
    $test_inst->cant_match_output( 'STDERR', "You can't win, Darth. If you strike me down, I shall become more powerful than you can possibly imagine.",       
                                                            "Test that Obi-wans last corporeal words were (NOT) captured" );
    $test_inst->capture_output( 'STDERR',                   "Test turning on the capture for STDERR" );
    $expected_count = ( $test_inst->get_buffer( 'STDERR' ) );
    dies_ok{ croak "You can't win, Darth. If you strike me down, I shall become more powerful than you can possibly imagine."}          
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
    $test_inst->match_output( 'STDERR', qr/You can't win, Darth. If you strike me down, I shall become more powerful than you can possibly imagine./,   
                                                            "Test that Obi-wans last corporeal words were captured" );
    $expected_count--;
    $test_inst->buffer_count( $expected_count, 'STDERR',    "... check that the 'STDERR' buffer has one fewer lines" );
    lives_ok{ $test_inst->set_match_retention( 1 ) }        "... change line matching behaviour to keep the line in the buffer after it is matched";
    $test_inst->match_output( 'STDERR', qr/This is a test death/,   
                                                            "Test that the subroutine test error was captured" );
    $test_inst->buffer_count( $expected_count, 'STDERR',    "... check that the 'STDERR' buffer has the expected number of lines" );
    ### Testing the global variable buffer ...
    $test_inst->no_buffer( 'GENERIC',                       "Test that the buffer for 'GENERIC' has not been created yet" );
    lives_ok{ $Test::Buffered::Output::test_buffer->{GENERIC} = [
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
    
    ###############################
    # Synopsis Screen Output
    # All tests should pass!
    ###############################
    
=head1 DESCRIPTION

The goal of this module it to test buffered output with L<Test::Builder>.  This module 
L<provides the global buffers|/capture_output( $buffer, $test_description )> that are 
tested.  The primary value of this test is to allow logging code to fork it's output to 
a buffer for test rather than always requireing the test to inspect the final result of 
the log.  This allows the reporting functions to the log file to be tested and then use a 
lighter touch set of tests for log file testing in general reporting.

All buffers are expected to be ArrayRef's of content.  For external code to test for 
the existence of a buffer a simple  
B<exists $Test::Buffered::Output::test_buffer-E<gt>{$buffer_name}> works.  Of course 
there is a L<test method|/has_buffer( $buffer, $test_description )> below for the test 
file to do the same.

B<Warning:> This is an OO test module.  I<No stand alone methods are exported.>


=head2 Attributes

Data passed to ->new when creating an instance using a class.  For modification of this
attribute see L<set_match_retention|/set_match_retention( $bool )>.

=head3 keep_matches( $bool )

=over

=item B<Definition:> this determines whether a line is deleted from the capture buffer after 
it is matched using a match test.  I<The line will never be deleted in a 
L<cant_match_output|/cant_match_output( $buffer, $line, $description )> test!>

=item B<Default> False (0) = 'delete matches'

=item B<Range> This is a Boolean data type and generally accepts 1 or 0
    
=back

=head2 Non Test Methods

These are class methods that do something but do B<NOT> produce L<TAP> output.

=head3 set_match_retention( $bool )

=over

=item B<Definition:> This is the way to change the L<keep_matches|/keep_matches( $bool )> 
attribute

=item B<Accepts:> a Boolean value (1/0)

=item B<Returns:> ''

=back

=head3 get_buffer( $buffer )

=over

=item B<Definition:> This method will return any items in the buffer list.  If 
there is no buffer it will return an empty list.  If the buffer exists but is 
empty it will return an empty list. (You can't use this to test for list 
existence. See L<has_buffer|/has_buffer( $buffer, $test_description )>)

=item B<Accepts:> a $string that can be used as a buffer name (must comply with 
all hash key naming restrictions.  Can include STDERR and STDOUT.

=item B<Returns:> An array (not a ref) of the buffer lines.  For STDOUT and STDERR 
the array is split on newlines so if the output contained newlines there will be 
one item per line.

=back

=head2 Test Methods

These are tests that will produce standard L<TAP> output.  They are built with 
L<Test::Builder>.

=head3 capture_output( $buffer, $test_description )

=over

=item B<Definition:> This method will create a buffer named $buffer.  If the value of 
$buffer is either 'STDERR' or 'STDOUT' then these filehandles are redirected to a 
hidden buffer dedicated to that name. (and therefore no-longer print to screen.)  
All other names create a hash key with the $buffer name in the global buffer namespace 
like B<$Test::Buffered::Output::test_buffer-E<gt>{$buffer}>.  This method always clears the 
buffer of that name!

=item B<Accepts:> 

=over

=item $buffer - a $string that can be used as a buffer name (must comply with 
all hash key naming restrictions.

=item $test_description - Text explaining the purpose of the test

=back

=item B<Returns:> TAP output - passing means there is (now) a cleared buffer 
for that name

=back

=head3 has_buffer( $buffer, $test_description )

=over

=item B<Definition:> This method tests for the existence of a buffer.


=item B<Accepts:> 

=over

=item $buffer - a $string that can be used as a buffer name (must comply with 
all hash key naming restrictions.

=item $test_description - Text explaining the purpose of the test

=back

=item B<Returns:> TAP output - passes if the buffer exists

=back

=head3 no_buffer( $buffer, $test_description )

=over

=item B<Definition:> This method checks to make sure that a buffer does NOT 
exist.  Specifically STDERR and STDOUT are placed as hidden attributes in the 
class and all other names are assumed to exist as top level keys in $test_buffer.


=item B<Accepts:> 

=over

=item $buffer - a $string that can be used as a buffer name (must comply with 
all hash key naming restrictions.

=item $test_description - Text explaining the purpose of the test

=back

=item B<Returns:> TAP output - passes if the buffer does not exist

=back

=head3 clear_buffer( $buffer, $test_description )

=over

=item B<Definition:> This method clears the contents of the named buffer but does 
not delete it.  If the buffer does not exist the test fails.


=item B<Accepts:> 

=over

=item $buffer - a $string that can be used as a buffer name (must comply with 
all hash key naming restrictions.

=item $test_description - Text explaining the purpose of the test

=back

=item B<Returns:> TAP output that passes if the buffer exists and is cleared.

=back

=head3 return_to_screen( $buffer, $test_description )

=over

=item B<Definition:> This method takes STDERR or STDOUT and changes the output 
back to the screen.


=item B<Accepts:> 

=over

=item $buffer - Only accepts 'STDERR' or 'STDOUT'

=item $test_description - Text explaining the purpose of the test

=back

=item B<Returns:> TAP output - passes if 'STDERR' or 'STDOUT' are sent back to 
the screen.

=back

=head3 close_buffer( $buffer, $test_description )

=over

=item B<Definition:> This method closes the buffer.  Future tests for that buffer 
will show that it doesn't exist.  If the buffer is STDERR or STDOUT the output 
will be redirected to the screen prior to closure.


=item B<Accepts:> 

=over

=item $buffer - a $string that can be used as a buffer name (must comply with 
all hash key naming restrictions.

=item $test_description - Text explaining the purpose of the test

=back

=item B<Returns:> TAP output - passes if the buffer is succesfully closed.

=back

=head3 buffer_count( $expected_count, $buffer, $test_description )

=over

=item B<Definition:> This method checks to see if the expected number of 
items are in the buffer indicated.  B<This is not an existence test.  
Non existent buffers will return a quantity of 0!>


=item B<Accepts:> 

=over

=item $expected_count - a number that will be used in a '==' compare to 
scalar( @buffer ).

=item $buffer - a $string that can be used as a buffer name (must comply with 
all hash key naming restrictions.

=item $test_description - Text explaining the purpose of the test

=back

=item B<Returns:> TAP output - passes if the buffer has the expected number 
of items.

=back

=head3 match_output( $buffer, $line, $description )

=over

=item B<Definition:> This test will search the $buffer for a $line.  If a 
string is passed an exact match is required.  if a regex (qr/something/) 
is passed then each item of the @$buffer will be bound to the regex attempting 
a match.  The test will pass if a match is found.  See the 
L<keep_matches|/keep_matches( $bool )> attribute for the disposition of the 
matched line in the buffer.  For 'STDOUT' and 'STDERR' the buffers are stored as 
strings and then returned as lists split on \n so multiline matches require multiple 
tests.  For global buffers the data goes in any way you load it with the assumption 
that it is stored as an ArrayRef.

=item B<Accepts:>

=over

=item $buffer - the name of the buffer (to determine which buffer to search)

=item $output - what output to match (accepts a string or regular expression)

=item $test_description - The test description used for TAP output

=back

=item B<Returns:> TAP output - pass indicates that a match was found

=back

=head3 cant_match_output( $buffer, $line, $description )

=over

=item B<Definition:> This test will search the $buffer for $line.  If a 
string is passed an exact match is required.  if a regex (qr/something/) 
is passed then each item of the @$buffer will be bound to the regex attempting 
a match.  The test will fail if a match is found.  Even if a match is found 
the matching line is not removed from the buffer.  For 'STDOUT' and 'STDERR' the 
buffers are stored as strings and then returned as lists split on \n so 
multiline matches require multiple tests.  For global buffers the data goes in 
any way you load it with the assumption that it is stored as an ArrayRef.

=item B<Accepts:>

=over

=item $buffer - the name of the buffer (to determine which buffer to search)

=item $output - what output to match (accepts strings or regular expressions)

=item $test_description - The test description used for TAP output

=back

=item B<Returns:> the TAP output where pass indicates that NO match was found

=back

=head1 TODO

=over

=item Figure out how to send @$ from L<Test::Exception> 'dies_ok' to go straight 
to STDERR without an additional step when capture_output( 'STDERR' ) is turned on.

=back

=head1 SUPPORT

=over

=item L<github Test-Buffered-Output/issues|https://github.com/jandrew/Test-Buffered-Output/issues>

=back

=head1 AUTHOR

=over

=item jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DEPENDENCIES

=over

=item L<5.008|http://perldoc.perl.org/perl58delta.html> - 
uses the print to in-memory string capability

=item L<Smart::Comments>

with the '-ENV' option set

=item L<Moose>

=item L<MooseX::StrictConstructor>

=item L<MooseX::NonMoose>

=item L<YAML::Any>

Only used if $ENV{Smart_Comments} = '#####'
is called.  (Dumps some nice file handle info)

=item L<Test::Builder>

=item L<Test::Builder::Module>

=item L<MooseX::StrictConstructor>

=item L<version>

=item L<Carp>

=item L<MooseX::Types::Moose>

=back

=head1 SEE ALSO

=over

=item L<Test::Output>

=item L<Test::Exception>

=item L<Test::Carp>

=back

=cut

#################### main pod documentation end ###################
