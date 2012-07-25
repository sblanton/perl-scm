
package SCM::Tool::VersionControl::Subversion;

BEGIN {

    use vars qw($VERSION @ISA @EXPORT $DL);

    use SCM;
    use SCM::Tool::VersionControl;

    #-- Inherits exporter functions to export functions
    @ISA = qw(Exporter SCM::Tool::VersionControl);

    @EXPORT = qw (

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
# PUBLIC OBJECT METHODS
#####################################################

#####################################################
# Commit files
#####################################################
sub commit {

    my $self     = shift;
    my @itemlist = @_;
    $self->{PROGRAM} = 'svn';
    $self->{ACTION}  = 'commit';
    my $message = $self->{MESSAGE};

    my $cp = $self->_checkParms(
        qw (
          PROGRAM
          ACTION
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $logger->logconfess("No files to commit.")
      if @itemlist == ();

    my @full_url_itemlist;

    if ( $self->{SVNROOT} ne '' ) {
        foreach my $item (@itemlist) {
            $item = $self->{SVNROOT} . "/$item";
            push @full_url_itemlist, $item;
        }
    }

    my $command = "svn commit -m \"$message\" @full_url_itemlist";

    $logger->debug("COMMAND: $command");

    my @output = `$command`;

    my $RC = $?;

    $self->_handleReturnCode( $RC, @output );

    return $RC;

}

#####################################################
# Make Repository folder
#####################################################
sub mkdir {

    my $self    = shift;
    my @dirlist = @_;
    $self->{PROGRAM} = 'svn';
    $self->{ACTION}  = 'mkdir';
    my $message = $self->{MESSAGE};

    my $cp = $self->_checkParms(
        qw (
          PROGRAM
          ACTION
          MESSAGE
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $logger->logconfess("No files to commit.")
      if @dirlist == ();

    my @full_url_dirlist;

    if ( $self->{SVNROOT} ne '' ) {
        foreach my $item (@dirlist) {
            $item = $self->{SVNROOT} . "/$item";
            push @full_url_dirlist, $item;
        }
    }

    my $command = "svn mkdir -m \"$message\" @full_url_dirlist";

    $logger->debug("COMMAND: $command");

    my @output = `$command`;

    my $RC = $?;

    $self->_handleReturnCode( $RC, @output );

    return $RC;

}

#####################################################
# PRIVATE OBJECT METHODS
#####################################################

sub _checkParms {
    my $self           = shift;
    my @required_parms = @_;
    my $PARM_RC        = 0;

    foreach my $parm (@required_parms) {
        $logger->debug("Checking parm: $parm");
        unless ( $self->{$parm} ) {
            $logger->error("Required parameter $parm not supplied.");
            $PARM_RC = 1;
        }
    }

    return ( ( $PARM_RC == 0 ) ? 0 : 1 );

}

sub _handleReturnCode {
    my $self       = shift;
    my $RC         = shift;
    my @cmd_output = @_;

    if ( $RC > 0 ) {
        $logger->error(@cmd_output)

    }
    else {
        $logger->info(@cmd_output);
    }
}

sub _getLog {
    my $self = shift;
    my $log  = shift;

    if ( $self->{LOGDIR} ) {
        $log = $self->{LOGDIR} . $DL . $log;
    }

    return $log;
}

#####################################################
# Synonyms

#sub put { my $self = shift; return $self->CheckInAndRelease(@_) }
#*get = *hcoBrowse;
#sub get_and_lock { my $self = shift; return $self->CheckOutForUpdate(@_) }
#sub synch { my $self = shift; return $self->hcoSynchRecursive(@_) }
#sub lock { my $self = shift; return $self->hcoReserve(@_) }

#####################################################

1;

