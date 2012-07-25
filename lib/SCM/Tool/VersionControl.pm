
package SCM::Tool::VersionControl;

BEGIN {

    use vars qw($VERSION @ISA @EXPORT $DL );

    #-- Inherits exporter functions to export functions
    use SCM;
    use SCM::Tool;

    @ISA = qw(Exporter SCM::Tool);

    #-- You must export any new functions here:
    @EXPORT = qw(

    );

    $VERSION = 0.1.0;

}

use strict;    #-- helps to find syntax errors
use Log::Log4perl qw( get_logger );
use Cwd;

our $logger;

#####################################################
# PACKAGE FUNCTIONS
#####################################################

#####################################################
# OBJECT METHODS
#####################################################

sub get {
    my $self = shift;
    $logger->logconfess(
"Method get has been called for class SCM::Tool::VersionControl but is not overriden by class $self."
    );

    return undef;
}

sub get_with_lock {
    my $self = shift;
    $logger->logconfess(
"Method get_with_lock has been called for class SCM::Tool::VersionControl but is not overriden by class $self."
    );

    return undef;
}

sub put {
    my $self = shift;
    $logger->logconfess(
"Method put has been called for class SCM::Tool::VersionControl but is not overriden by class $self."
    );

    return undef;
}

sub put_and_keep_lock {
    my $self = shift;
    $logger->logconfess(
"Method put_and_keep_lock has been called for class SCM::Tool::VersionControl but is not overriden by class $self."
    );

    return undef;
}

sub lock {
    my $self = shift;
    $logger->logconfess(
"Method lock has been called for class SCM::Tool::VersionControl but is not overriden by class $self."
    );

    return undef;
}

sub unlock {
    my $self = shift;
    $logger->logconfess(
"Method unlock has been called for class SCM::Tool::VersionControl but is not overriden by class $self."
    );

    return undef;
}

1;

