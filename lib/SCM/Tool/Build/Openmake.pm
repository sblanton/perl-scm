
package SCM::Tool::Build::Openmake;

BEGIN {

    use vars qw($VERSION @ISA );
    use SCM::Tool::Build;

    #-- Inherits exporter functions to export functions
    @ISA = qw(SCM::Tool::Build);

    $VERSION = 2.02;

}

use strict;    #-- helps to find syntax errors

#use Carp;    #-- helps for debugging
use Log::Log4perl qw( get_logger );
use Openmake;
use Openmake::Path;

my $logger = get_logger('SCM.Tool.Build.Openmake');

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

    my %ctx = @_;    # form a context hash

    foreach ( keys %ctx ) {
        $self->{$_} = $ctx{$_};

    }

    $self->{TOOL} = 'Openmake';

    $logger->debug("New instance created.");

    # instantiate and return the reference

    bless( $self, $class );
    return $self;

}

sub bldmake {
    my $self = shift;

    my @additional_args = @_;

    $logger->logconfess("PROJECT not specified.")
      unless $self->{PROJECT};

    $logger->logconfess("SEARCHPATH not specified.")
      unless $self->{SEARCHPATH};

    my $command =
        "bldmake " . '"'
      . $self->{PROJECT} . '"' . ' "'
      . $self->{SEARCHPATH}
      . "\" @additional_args ";

    $logger->debug("$command");

    my @output = `$command`;

    return handleRC( $?, @output );

}

sub om {
    my $self = shift;

    my @additional_args = @_;

    my $command = "om " . "@additional_args ";

    $logger->debug("$command");

    my @output = `$command`;

    return handleRC( $?, @output );

}

sub runBuildJob {
    my $self = shift;

    my $omcmdlinejar = FirstFoundInPath('omcmdline.jar');

    $logger->logconfess("BUILDJOB not specified.")
      unless $self->{BUILDJOB};

    my $command =
      "java -jar \"$omcmdlinejar\" -build \"" . $self->{BUILDJOB} . "\"";

    my @output = `$command`;

    return handleRC( $?, @output );

}

sub getMakefile {
    my $self = shift;

    my %OS_MAKEFILE_MAP = (
        'AIX'     => 'aix.mak',
        'Solaris' => 'solaris.mak',
        'Windows' => 'windows.mak',
        'HP-UX'   => 'hp.mak',
        'Linux'   => 'linux.mak'
    );

    return $OS_MAKEFILE_MAP{ $self->{OS} };
}

1;
