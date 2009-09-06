
package SCM::System;

BEGIN {

    use vars qw($VERSION @ISA @EXPORT );

    #-- Inherits exporter functions to export functions
    @ISA = qw(Exporter);

    #-- You must export any new functions here:
    @EXPORT = qw(

      $DL
      $eDL
      $insensitive

      &dumpLog
      &dumpLogError
      &handleRC

    );

    $VERSION = 2.02;

}

use strict;    #-- helps to find syntax errors
use Carp;      #-- helps for debugging
use Log::Log4perl qw( get_logger );
use Cwd;

my $logger = get_logger('SCM.Platform');

#####################################################
# PACKAGE FUNCTIONS
#####################################################

#-- subroutine to log a list
#   as info

sub dumpLog {

    my @lines = @_;

    foreach (@lines) {
        $logger->info($_);

    }

}

#-- subroutine to log a list
#   as error

sub dumpLogError {

    my @lines = @_;

    foreach (@lines) {
        $logger->error($_);

    }

}

sub handleRC {
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

#####################################################
# OBJECT METHODS
#####################################################

# Context constructor

sub new {

    my $proto = shift;

    my $class = ref($proto) || $proto;
    my $self = {};

    my %ctx = @_;    # form a context hash

    foreach ( keys %ctx ) {
        $self->{$_} = $ctx{$_};

    }

    $logger->debug("New instance created.");

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

    my @lines = <CTX>;              # read lines into a list

    @lines = grep( !/^\#|^\s*$/, @lines );    # remove comments

    foreach (@lines) {

        /^(\S+)\s+(.+)/;    # Match on non-space, space and non-space
        $self->{$1} = $2;

    }

}

#-- print out the attributes of the object
#   to the screen

sub print {

    my $self = shift;       # get the object reference

    my %ctx = %$self;       # form a context hash

    foreach ( sort keys %ctx ) {
        if ( $_ eq 'PASSWORD' and $ctx{$_} ne '' ) {
            print "$_ = XXXX\n";

        }
        else {
            print "$_ = $ctx{$_}\n";

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

#-- set values for the context object
#  this sub takes a hash as an argument

sub setTool {
    my $self = shift;    # get the object reference
    my $key  = shift;

    my $class = shift;

    my $location = $class;

    $location =~ s/::/\//g;

    require "${location}.pm";

    $self->{$key} = $class->new()

}

1;

