
package SCM::System::Lawson;

BEGIN {

    use vars qw($VERSION @ISA );
    use SCM::System;

    #-- Inherits exporter functions to export functions
    @ISA = qw( SCM::Platform );

    $VERSION = 2.02;

}

use strict;    #-- helps to find syntax errors
use Carp;      #-- helps for debugging
use Log::Log4perl qw( get_logger );
use Cwd;
use Openmake::Path;

my $logger = get_logger('SCM.Platform.Lawson');

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

    #-- set common LAWSON variables from environmetn variables

    foreach my $env_var ( keys %ENV ) {
        if ( $env_var =~ /^LAW/ ) {
            $self->{$env_var} = $ENV{$env_var};

        }
    }

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

    $logger->debug( "New context loaded. Product Line=" . $self->{LAWPL} );
}

sub dumpProgram {

    my $self = shift;

    $logger->logconfess("LAWPL not defined.")
      unless $self->{LAWPL};

    $logger->logconfess("LAWSC not defined.")
      unless $self->{LAWSC};

    my $program = shift || $self->{PROGRAM};

    $logger->logconfess("Program not defined.")
      unless $program;

    chmod 0777, "src/$program.dmp";

    #-- if we are not the owner, we may not
    #   be able to change permissions, but
    #   we can still delete it

    unlink "src/$program.dmp"
      unless ( -w "src/$program.dmp" );

    my $command = "pgmdump "
      . $self->{LAWPL} . " "
      . $self->{LAWSC} . " "
      . $self->{LAWSC}
      . "src/$program.dmp $program";

    my @output = `$command`;
    my $RC     = $?;

    if ( $RC > 0 ) {
        chmod 0777, "src/$program.dmp";
        unlink "src/$program.dmp";

    }

    return handleRC( $RC, @output );

}

sub validateCommonArgs {
    my $self = shift;
    my $RC;

    $logger->logconfess("PROGRAM not set!"), $RC = 1
      unless $self->{PROGRAM};

    $logger->logconfess("LAWPL not set!"), $RC = 1
      unless $self->{LAWPL};

    $logger->logconfess("LAWDIR not set!"), $RC = 1
      unless $self->{LAWDIR};

    $logger->logconfess("System code, LAWSC, not set!"), $RC = 1
      unless $self->{LAWSC};

    return $RC;

}

sub getProgramFiles {

    my $self = shift;

    my $source_dir =
      $self->{LAWDIR} . $DL . $self->{LAWPL} . $DL . $self->{LAWSC} . "src";
    opendir DIR, $source_dir;

    my @allfiles = readdir DIR;

    my $program = $self->{PROGRAM};

    my @regular_files =
      grep /^$program\.scr$|^$program\.rpt$|^${program}WS$|^${program}PD$/,
      @allfiles;
    my @user_exit_files = grep /^${program}[BME]WS$|^${program}[BME]PD$/,
      @allfiles;

    my @program_files;

    foreach my $file ( @regular_files, @user_exit_files ) {
        push @program_files, $self->{LAWSC} . "src" . $DL . $file;
    }

    return @program_files;

}

sub readArgs {

    my $self = shift;

    my @args = ();

    while ( $_[$#_] =~ /^\-/ ) {
        push @args, $_[$#_];
        pop;
    }

    my $program = pop @_;
    $program = uc $program;

    $self->set( PROGRAM => $program );

    if ( $#_ >= 0 ) {
        my $sc = pop @_;
        $self->set( LAWSC => $sc );

    }

    if ( $#_ >= 0 ) {
        my $pl = pop @_;
        $self->set( LAWPL => $pl );

    }

    return @args;

}

sub vctl_put {

    my $self = shift;
    $self->{VCTL}->put( $self, @_ );

}

sub vctl_get_and_lock {

    my $self = shift;
    $self->{VCTL}->get_and_lock( $self, @_ );

}

1;
