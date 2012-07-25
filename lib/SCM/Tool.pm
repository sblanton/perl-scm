
package SCM::Tool;

BEGIN {

    use vars qw($VERSION @ISA @EXPORT $DL );

    #-- Inherits exporter functions to export functions
    @ISA = qw(Exporter );

    use SCM;

    #-- You must export any new functions here:
    @EXPORT = qw(

    );

    $VERSION = 2.02;

}

use strict;    #-- helps to find syntax errors
use Log::Log4perl qw( get_logger );
use Cwd;
use Config::Properties;

our $logger;

#####################################################
# PACKAGE FUNCTIONS
#####################################################

#####################################################
# OBJECT METHODS
#####################################################

# Context constructor

sub new {

    my $proto = shift;

    my $class = ref($proto) || $proto;
    my $self = {};

    $logger = get_logger($class)
      or die "Couldn't get logger!";

    my %ctx = @_;    # form a context hash

    foreach ( keys %ctx ) {
        $self->{$_} = $ctx{$_};

    }

    $logger->debug("New instance of $class created.");

    # instantiate and return the reference

    bless( $self, $class );
    return $self;

}

#-- Load in the context values from a file
#

sub load {

    my $self        = shift @_;
    my $contextFile = shift @_;

    $logger->debug("Importing context from file $contextFile");

    open( CTX, "<$contextFile" )    # open the file
      or $logger->logconfess(
        "Couldn't open context file $contextFile for reading.");

    my $p = Config::Properties->new();
    $logger->logconfess(
        "Couldn't load context file. File may not be in properties format.")
      if $p->load(*CTX);

    my %properties = $p->properties();

    foreach my $name ( $p->propertyNames() ) {
        $self->{$name} = $p->getProperty($name);
    }

}

sub save {

    my $self        = shift @_;
    my $contextFile = shift @_;

    my $class = ref($self) || $self;

    $logger->debug("Importing context from file $contextFile");

    open( CTX, ">$contextFile" )    # open the file
      or $logger->logconfess(
        "Couldn't open context file $contextFile for writing.");

    my $p = Config::Properties->new();

    foreach my $key ( keys %$self ) {
        $p->setProperty( $key, $self->{$key} );
    }

    $logger->logconfess(
        "Couldn't load context file. File may not be in properties format.")
      if $p->save( *CTX, "Context properties file for $class" );

}

#-- print out the attributes of the object
#   to the screen

sub print {

    my $self = shift;    # get the object reference

    my %ctx = %$self;    # form a context hash

    foreach ( sort keys %ctx ) {
        if ( $_ eq 'PASSWORD' and $ctx{$_} ne '' ) {
            $logger->info("$_ = XXXX");

        }
        else {
            $logger->info("$_ = $ctx{$_}");

        }
    }

}

#-- set values for the context object
#  this sub takes a hash as an argument

sub set {
    my $self = shift;    # get the object reference

    my %ctx = @_;        # form a context hash

    foreach ( keys %ctx ) {
        chomp $ctx{$_};

        $logger->debug("Setting context parameter $_ to '$ctx{$_}'");

        $self->{$_} = $ctx{$_};

    }

}

sub setParm { my $self = shift; return $self->set(@_) }

sub getParm {
    my $self = shift;
    my $parm = shift;

    return $self->{$parm} or undef;
}

#-- subroutine to log a list
#   as info

sub dumpLog {
    my $self = shift;

    my @lines = @_;

    foreach (@lines) {
        $logger->info($_);

    }

    return;

}

#-- subroutine to log a list
#   as error

sub dumpLogError {
    my $self = shift;

    my @lines = @_;

    foreach (@lines) {
        $logger->error($_);

    }

    return;

}

sub handleRC {
    my $self = shift;

    my $RC    = shift;
    my @lines = @_;

    if ( $RC > 0 ) {
        $logger->error(@lines);

    }
    else {
        $logger->info(@lines);

    }

    return;

}

1;

