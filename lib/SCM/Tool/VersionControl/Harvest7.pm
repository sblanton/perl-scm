
package SCM::Tool::VersionControl::Harvest7;

BEGIN {

    use vars qw($VERSION @ISA @EXPORT $DL );

    use SCM;
    use SCM::Tool::VersionControl;

    #-- Inherits exporter functions to export functions
    @ISA = qw(Exporter SCM::Tool::VersionControl);

    #-- You must export any new functions here:
    @EXPORT = qw(

    );

    $VERSION = 0.1.0;

}

use strict;    #-- helps to find syntax errors
use Log::Log4perl qw( get_logger );
use Cwd;
use File::Basename;

our $logger;

=head1 Name

=head1 Synopsis

=head1 Description

=head2 Package Functions

=cut

#####################################################
# PACKAGE FUNCTIONS
#####################################################

#-- the pre-command sets a shell variable prior to
#   the executable call. needed in some cases, not
#   others

sub preCommand {
    my $self = shift;
    my $cmd  = shift;
    my $harvest_home;

    unless ($cmd) {
        $logger->logcroak("\$cmd not supplied to preCommand");

    }

    if ( exists $self->{HARVESTHOME} ) {

        $harvest_home = $self->{HARVESTHOME};

    }
    elsif ( exists $ENV{HARVESTHOME} ) {

        $harvest_home = $ENV{HARVESTHOME};

    }
    elsif ( $^O !~ /mswin/i ) {

        $logger->logdie("HARVESTHOME is not set.");
    }

    my $preCmd;

    unless ( $^O =~ /mswin/i ) {
        $preCmd = 'export HARVESTHOME=' . $harvest_home . ';';
        $preCmd .= $harvest_home . "/bin/" . $cmd;

    }
    else {
        $preCmd = $cmd;

    }

    $self->{LOG} = "${cmd}_" . time . '.log';

    return $preCmd;
}

=head2 Public Methods

=cut

#####################################################
# PUBLIC OBJECT METHODS
#####################################################

=over 4

=item AddBaseline

=cut

sub AddBaseline {
    my $self = shift;

    if (@_) {
        $self->{REPOSITORY} = shift;
    }
    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          REPOSITORY
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $self->{LOG} = 'hcbl.log';

    my $command =
        $self->preCommand('hcbl') . ' -b '
      . $self->{BROKER}
      . ' -en "'
      . $self->{PROJECT} . '"' . " -rp "
      . $self->{REPOSITORY}
      . ' -add -rw '
      . $self->_getLogArgs()
      . $self->_getAuthArgs();

    my @output = `$command`;

    my $RC = $?;

    sleep 1;    # wait for log to finish

    return $self->_handleReturnCode( $RC, @output );

}

=over 4

=item AddSnapshotView

=cut

sub AddSnapshotView {
    my $self = shift;

    if (@_) {
        $self->{SNAPSHOT} = shift;
    }
    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          SNAPSHOT
          REPOSITORY
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $self->{LOG} = 'hcbl-ss.log';

    my $command =
        $self->preCommand('hcbl') . ' -b '
      . $self->{BROKER}
      . ' -en "'
      . $self->{PROJECT} . '"' . " -rp "
      . $self->{REPOSITORY}
      . ' -add -rw '
      . ' -ss "'
      . $self->{SNAPSHOT} . '" '
      . $self->_getProcessArgs()
      . $self->_getLogArgs()
      . $self->_getAuthArgs();

    my @output = `$command`;

    my $RC = $?;

    sleep 1;    # wait for log to finish

    return $self->_handleReturnCode( $RC, @output );

}

#####################################################
#
#-- Create Generic Harvest Package
#
#####################################################

=item CreatePackage

Required parameters: BROKER, PROJECT, STATE, PACKAGE

=cut

sub CreatePackage {
    my $self = shift;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          PACKAGE
          USERFILE
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $self->{LOG} = 'hcp.log';

    my $command =
        $self->preCommand('hcp') . ' -b '
      . $self->{BROKER}
      . ' -en "'
      . $self->{PROJECT} . '"'
      . ' -st "'
      . $self->{STATE} . '"'
      . $self->_getAuthArgs()
      . $self->_getLogArgs() . ' "'
      . $self->{PACKAGE} . '"';

    $logger->debug($command);

    my @output = `$command`;

    my $RC = $?;

    return $self->_handleReturnCode( $RC, @output );

}

#####################################################
#
#-- Promote Harvest Package
#
#####################################################

=item PromotePackage

Required parameters: BROKER, PROJECT, STATE, PACKAGE

=cut

sub PromotePackage {
    my $self = shift;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          PACKAGE
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $self->{LOG} = 'hpp.log';

    my $command =
        $self->preCommand('hpp') . ' -b '
      . $self->{BROKER}
      . ' -en "'
      . $self->{PROJECT} . '"'
      . ' -st "'
      . $self->{STATE} . '" '
      . $self->_getProcessArgs()
      . $self->_getAuthArgs()
      . $self->_getLogArgs() . ' "'
      . $self->{PACKAGE} . '"';

    $logger->debug($command);

    my @output = `$command`;

    my $RC = $?;

    return $self->_handleReturnCode( $RC, @output );

}

=item CreateItemPath

Calls the 'hcrtpath' command line program

=cut

sub CreateItemPath {

    my $self = shift;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          )
    );

    my $new_path = shift;
    $logger->logconfess("Item path to create not supplied.")
      unless $new_path;

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $self->{LOG} = 'hcrtpath' . time . '.log';

    my $command =
        $self->preCommand('hcrtpath') . ' -b '
      . $self->{BROKER} . ' -en '
      . $self->{PROJECT} . ' -st '
      . $self->{STATE}
      . " -rp \"$new_path\" ";

    if ( exists $self->{PROCESSNAME} ) {
        $command .= " -cipn \"" . $self->{PROCESSNAME} . "\" ";
    }
    $command .= $self->_getLogArgs() . $self->_getAuthArgs();

    $logger->debug("cmd: $command");

    my @output = `$command`;

    my $RC = $?;

    sleep 1;    # wait for log to finish

    return $self->_handleReturnCode( $RC, @output );

}

#
# Inputs:
#  PROJECT - Harvest project name
#  USER - Harvest user id
#  PASSWORD - password for Harvest user id
#  $repository - the package to reserve to
#

=item DuplicateRepository

=cut

sub DuplicateRepository {
    my $self = shift;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          REPOSITORY
          )
    );

    my $new_repository = shift;
    $logger->logconfess("Destination repository name not supplied.")
      unless $new_repository;

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $self->{LOG} = 'hrepmngr.log';

    my $command =
        $self->preCommand('hrepmngr') . ' -b '
      . $self->{BROKER}
      . ' -dup '
      . " -srn \""
      . $self->{REPOSITORY} . "\" "
      . " -drn \"$new_repository\" "
      . $self->_getProcessArgs()
      . $self->_getLogArgs()
      . $self->_getAuthArgs();

    $logger->debug("cmd: $command");

    my @output = `$command`;

    my $RC = $?;

    sleep 1;    # wait for log to finish

    #-- Unfortunately, the wrong return code seems to be reported:
    # Force success
    $logger->warn(
"Return code forced to be success because of a possible bug in the hrepmngr implementation."
    );

    $RC = 0;

    return $self->_handleReturnCode( $RC, @output );

}

####################################################
#
#-- Add the initial view of a reposiroty to the
#   project baseline
#
# Inputs:
#  PROJECT - Harvest project name
#  USER - Harvest user id
#  PASSWORD - password for Harvest user id
#  $repository - the package to reserve to
#
# Returns:
#  the rc of the hcp command
#
#####################################################

=item AddRepositoryAccess

Not yet implemented

=cut

sub AddRepositoryAccess {
    my $self = shift;

    return 1;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          REPOSITORY
          )
    );

    my $new_repository = shift;
    $logger->logconfess("Destination repository name not supplied.")
      unless $new_repository;

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $self->{LOG} = 'hrepmngr.log';

    my $command =
        $self->preCommand('hrepmngr') . ' -b '
      . $self->{BROKER}
      . " -srn \""
      . $self->{REPOSITORY} . "\" "
      . " -drn \"$new_repository\" "
      . $self->_getProcessArgs()
      . $self->_getLogArgs()
      . $self->_getAuthArgs();

    $logger->debug("cmd: $command");

    my @output = `$command`;

    my $RC = $?;

    sleep 1;    # wait for log to finish

    #-- Unfortunately, the wrong return code seems to be reported:
    # Force success
    $logger->warn(
"Return code forced to be success because of a possible bug in the hrepmngr implementation."
    );

    $RC = 0;

    return $self->_handleReturnCode( $RC, @output );

}

#####################################################
#
#-- Execute Harvest UDP
#
# Inputs:
#  $project - Harvest project name
#  $state   - Harvest state name
#  $user - Harvest user id
#  $password - password for Harvest user id
#  $package - the package to reserve to
#
# Returns:
#  the rc of the command
#
#####################################################

=item ExecUDP

=cut

sub ExecUDP {
    my $self = shift;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          PROCESSNAME
          )
    );

    %_ = @_;

    #-- Handle 'Additional Command Line Parameters'
    my $ACLP = '';
    $ACLP = $_{ACLP}
      if exists $_{ACLP};

    #-- Handle 'Additional Input'
    my $AI = '';
    $AI = $_{AI}
      if exists $_{AI};

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $self->{LOG} = 'hudp_' . time() . '.log';

    my $command =
        $self->preCommand('hudp') . ' -b '
      . $self->{BROKER}
      . ' -en "'
      . $self->{PROJECT} . '"'
      . ' -st "'
      . $self->{STATE} . '"'
      . $self->_getAuthArgs()
      . $self->_getLogArgs() . '-pn "'
      . $self->{PROCESSNAME} . '" ';

    $command .= " -ap \"$ACLP\" "
      if $ACLP;

    $command .= " -ip \"$AI\" "
      if $AI;

    $logger->debug($command);

    my @output = `$command`;

    my $RC = $?;

    return $self->_handleReturnCode( $RC, @output );

}

#####################################################
#
#-- Create a new Harvest Project
#
# Inputs:
#  $newproject - Harvest project name to create
#  PROJECT - Harvest project name to copy from
#  USER - Harvest user id
#  PASSWORD - password for Harvest user id
#
# Returns:
#  the rc of the hcp command
#
#####################################################

sub CreateProject {
    my $self = shift;

    my $newproject = shift;
    my @cpargs     = @_;

    $logger->logconfess("No new project name passed to CreateProject.")
      if $newproject eq '';

    $logger->logconfess(
"No arguments passed to CreateProject. Supply one of '-ina', '-act' or '-tem'"
    ) unless @cpargs;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $self->{LOG} = 'hcpj_' . time() . '.log';

    my $command =
        $self->preCommand('hcpj') . ' -b '
      . $self->{BROKER}
      . ' -cpj "'
      . $self->{PROJECT} . '"'
      . ' -npj "'
      . $newproject . '"'
      . "@cpargs"
      . $self->_getLogArgs()
      . $self->_getAuthArgs();

    my @output = `$command`;

    my $RC = $?;

    return $self->_handleReturnCode( $RC, @output );

}

#####################################################
#
#-- Back up a Harvest Project
#
# Inputs:
#  $newproject - Harvest project name to create
#  PROJECT - Harvest project name to copy from
#  USER - Harvest user id
#  PASSWORD - password for Harvest user id
#
# Returns:
#  the rc of the hcp command
#
#####################################################
sub BackupProject {
    my $self = shift;

    my $newproject = shift;

    $logger->logconfess("No new project name passed to CreateProject.")
      if $newproject eq '';

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          USERFILE
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $self->{LOG} = 'hcpj.log';

    my $command =
        $self->preCommand('hcpj') . ' -b '
      . $self->{BROKER}
      . ' -cpj "'
      . $self->{PROJECT} . '"'
      . ' -npj "'
      . $newproject . '"'
      . ' -cug -tem' . ' -eh '
      . $self->{USERFILE};

    my @output = `$command`;

    my $RC = $?;

    return $self->_handleReturnCode( $RC, @output );

}

#####################################################
#
#-- Check out files for update
#
# Inputs:
#  $project - Harvest project name
#  $state   - Harvest state name
#  $user - Harvest user id
#  $password - password for Harvest user id
#  $viewpath - the root view path of the items in @itemlist
#  $package - the package to reserve to
#  @itemlist - a list of items found in $viewpath to reserver
#
#####################################################
sub CheckOutForUpdate {

    my $self     = shift;
    my @itemlist = @_;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          VIEWPATH
          PACKAGE
          USERFILE
          CLIENTPATH
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $logger->logconfess("No files to reserve.")
      if @itemlist == ();

    #-- a clientpath of '.' will crash hco
    my $clientpath = "";
    if (    $self->{CLIENTPATH} ne ''
        and $self->{CLIENTPATH} ne '.' )
    {
        $clientpath = "-cp \"" . $self->{CLIENTPATH} . "\" ";
    }

    $self->{LOG} = 'hco.log';

    my $command = $self->preCommand('hco')

      . " -b "
      . $self->{BROKER}
      . " -en \""
      . $self->{PROJECT} . "\" "
      . "-st \""
      . $self->{STATE} . "\" "
      . "-vp \""
      . $self->{VIEWPATH} . "\" "
      . $clientpath . "-p \""
      . $self->{PACKAGE} . "\" " . "-up " . "-r "
      . $self->_getLogArgs()
      . $self->_getProcessArgs()
      . $self->_getAuthArgs()
      . " @itemlist";

    $logger->debug($command);

    my @output = `$command`;

    my $RC = $?;

    return $self->_handleReturnCode( $RC, @output );

}

=item CheckOutSnapshot

=cut

sub CheckOutSnapshot {

    my $self = shift;

    my $cp;

    $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          VIEWPATH
          CLIENTPATH
          SNAPSHOT
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    #-- a clientpath of '.' will crash hco
    my $clientpath = "";
    if (    $self->{CLIENTPATH} ne ''
        and $self->{CLIENTPATH} ne '.' )
    {
        $clientpath = "-cp \"" . $self->{CLIENTPATH} . "\" ";
    }

    $self->{LOG} = 'hco.log';

    my $command = $self->preCommand('hco')

      . " -b "
      . $self->{BROKER}
      . " -en \""
      . $self->{PROJECT} . "\" "
      . "-st \""
      . $self->{STATE} . "\" "
      . "-vp \""
      . $self->{VIEWPATH} . "\" "
      . $clientpath
      . "-br -r -s '*' "
      . $self->_getLogArgs()
      . $self->_getProcessArgs()
      . $self->_getAuthArgs() . ' -ss '
      . $self->{SNAPSHOT};

    my @output = `$command`;

    my $RC = $?;

    return $self->_handleReturnCode( $RC, @output );

}

=item CheckOutForBrowse

Required parameters: BROKER PROJECT STATE VIEWPATH CLIENTPATH 

=cut

sub CheckOutForBrowse {

    my $self     = shift;
    my @itemlist = @_;

    my $cp;

    $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          VIEWPATH
          CLIENTPATH
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $logger->logconfess("No files to retrieve.")
      if @itemlist == ();

    my $processname = "";

    #if ( $self->{PROCESSNAME} ne '' ) {
    #    $processname = "-pn \"" . $self->{PROCESSNAME} . "\" ";
    #}

    #-- a clientpath of '.' will crash hco
    my $clientpath = "";
    if (    $self->{CLIENTPATH} ne ''
        and $self->{CLIENTPATH} ne '.' )
    {
        $clientpath = "-cp \"" . $self->{CLIENTPATH} . "\" ";
    }

    $self->{LOG} = 'hco.log';

    my $command = $self->preCommand('hco')

      . " -b "
      . $self->{BROKER}
      . " -en \""
      . $self->{PROJECT} . "\" "
      . "-st \""
      . $self->{STATE} . "\" "
      . "-vp \""
      . $self->{VIEWPATH} . "\" "
      . $clientpath
      . "-br -r "
      . $self->_getLogArgs()
      . $self->_getProcessArgs()
      . $self->_getAuthArgs();

    $command .= " @itemlist";

    my @output = `$command`;

    my $RC = $?;

    return $self->_handleReturnCode( $RC, @output );

}

#####################################################
#
#-- Check in files and release lock
#
# Inputs:
#  $project - Harvest project name
#  $state   - Harvest state name
#  $user - Harvest user id
#  $password - password for Harvest user id
#  $viewpath - the root view path of the items in @itemlist
#  $package - the package to reserve to
#  @itemlist - a list of items found in $viewpath to reserver
#
#####################################################
sub _CheckInProcess {

    my $self     = shift;
    my @itemlist = @_;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          VIEWPATH
          PACKAGE
          USERFILE
          CLIENTPATH
          CHECKIN_OPTS
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    unless ( $self->{CHECKIN_OPTS} =~ /-s/ ) {
        $logger->logconfess("No files to reserve.")
          unless @itemlist;
    }

    #-- remove trailing slash from clientpath or
    #   hci will fail
    $self->{CLIENTPATH} =~ s/\\$//;
    $self->{CLIENTPATH} =~ s/\/$//;

    $self->{LOG} = time . '_hci.log';

    my $command = $self->preCommand('hci')

      . " -b "
      . $self->{BROKER}
      . " -en \""
      . $self->{PROJECT} . "\" "
      . "-st \""
      . $self->{STATE} . "\" "
      . "-vp \""
      . $self->{VIEWPATH} . "\" "
      . "-cp \""
      . $self->{CLIENTPATH} . "\" " . "-p \""
      . $self->{PACKAGE} . "\" "
      . $self->{CHECKIN_OPTS} . " "
      . $self->_getAuthArgs()
      . $self->_getLogArgs()
      . $self->_getProcessArgs()
      . " @itemlist";

    $logger->debug($command);

    my @output = `$command`;

    my $RC = $?;

    return $self->_handleReturnCode( $RC, @output );

}

sub CheckInAndRelease {
    my $self = shift;

    $self->{CHECKIN_OPTS} .= ' -ur ';
    return $self->_CheckInProcess(@_);
}

sub CheckInAndKeep {
    my $self = shift;

    $self->{CHECKIN_OPTS} .= ' -uk ';
    return $self->_CheckInProcess(@_);
}

sub CheckInReleaseOnly {
    my $self = shift;

    $self->{CHECKIN_OPTS} .= ' -ro ';
    return $self->_CheckInProcess(@_);
}

#####################################################
#
#-- Synchronize files with Harvest view
#
# Inputs:
#  $project - Harvest project name
#  $state   - Harvest state name
#  $user - Harvest user id
#  $password - password for Harvest user id
#  $viewpath - the root view path of the items in @itemlist
#
#####################################################
sub _HsyncProcess {

    my $self     = shift;
    my @itemlist = @_;
    $self->{LOG} = 'hsync.log';

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          VIEWPATH
          USERFILE
          CLIENTPATH
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    #-- remove trailing slash from clientpath or
    $self->{CLIENTPATH} =~ s/\\$//;
    $self->{CLIENTPATH} =~ s/\/$//;

    my $command = $self->preCommand('hsync')

      . " -b "
      . $self->{BROKER}
      . " -en \""
      . $self->{PROJECT} . "\" "
      . "-st \""
      . $self->{STATE} . "\" "
      . "-vp \""
      . $self->{VIEWPATH} . "\" "
      . "-cp \""
      . $self->{CLIENTPATH} . "\" " . "-eh "
      . $self->{USERFILE} . " "
      . $self->_getLogArgs()
      . $self->_getProcessArgs()
      . $self->_getAuthArgs();

    if ( $self->{HSYNC_OPTS} ) {
        $command .= " $self->{HSYNC_OPTS} ";
    }

    $command .= " @itemlist";

    $logger->debug($command);

    my @output = `$command`;

    my $RC = $?;

    return $self->_handleReturnCode( $RC, @output );

}

sub _GetActivePackages {

    my $self = shift
      or
      $logger->logconfess("Incorrect arguments. Not called in object context.");

    my $dbh = shift
      or $logger->logconfess(
        "Incorrect arguments. DBI database handle not passed.");

    my $cp = $self->_checkParms(
        qw (
          PROJECT
          STATE
          )
    );

    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    my $project = $self->{PROJECT};
    my $state   = $self->{STATE};

    my $sql = <<GAPSQL;
select distinct(packagename) from harpackage, harenvironment, harstate
where
    harpackage.envobjid = harenvironment.envobjid
and harpackage.stateobjid = harstate.stateobjid
and harenvironment.environmentname = '$project'
and harstate.statename = '$state'
GAPSQL

    my $sth = $dbh->prepare($sql)
      or $logger->logconfess(
        $dbh->errstr . "\nError preparing SQL statement: $sql\n" );

    $sth->execute()
      or $logger->logconfess(
        $dbh->errstr . "\nError executing SQL statement: $sql\n" );

    my @packages = ();

    while ( my @row = $sth->fetchrow_array() ) {
        push @packages, $row[0];

    }

    $sth->finish;
    $dbh->disconnect;

    return @packages;

}

sub HsyncActiveView {
    my $self = shift
      or
      $logger->logconfess("Incorrect arguments. Not called in object context.");

    my $dbh = shift
      or $logger->logconfess(
        "Incorrect arguments. DBI database handle not passed.");

    my @packages = $self->_GetActivePackages($dbh);

    $self->{HSYNC_OPTS} .= ' -av -ps ';
    return $self->_HsyncProcess(@packages);
}

sub HsyncFullView {
    my $self = shift;

    return $self->_HsyncProcess(@_);
}

#####################################################
#
#-- Reserve items to a package through the agent
#
# Inputs:
#  $project - Harvest project name
#  $state   - Harvest state name
#  $user - Harvest user id
#  $password - password for Harvest user id
#  $viewpath - the root view path of the items in @itemlist
#  $package - the package to reserve to
#  @itemlist - a list of items found in $viewpath to reserver
#
#####################################################
sub CheckOutReserveOnly {

    my $self     = shift;
    my @itemlist = @_;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          VIEWPATH
          PACKAGE
          USERFILE
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $logger->logconfess("No files to reserve.")
      if @itemlist == ();

    #-- remove trailing slash from clientpath or
    #   hci will fail
    $self->{CLIENTPATH} =~ s/\\$//;
    $self->{CLIENTPATH} =~ s/\/$//;

    my $command = $self->preCommand('hco')

      . " -b "
      . $self->{BROKER}
      . " -en \""
      . $self->{PROJECT} . "\" "
      . "-st \""
      . $self->{STATE} . "\" "
      . "-vp \""
      . $self->{VIEWPATH} . "\" "
      . "-cp \""
      . $self->{CLIENTPATH} . "\" " . "-p \""
      . $self->{PACKAGE} . "\" " . "-ro " . "-eh "
      . $self->{USERFILE}
      . " @itemlist";

    $logger->debug($command);

    my @output = `$command`;

    my $RC = $?;

    $self->{LOG} = 'hco.log';
    return $self->_handleReturnCode( $RC, @output );

}

=item RenameItem

Takes a hash as an argument, where the key is the full
item path including item name and the value is the new
name to use. This function will call hrnitm in a loop
for each key in the hash.

=cut

#####################################################
sub RenameItem {

    my $self        = shift;
    my $r_item_hash = shift;

    my %item_hash = ();
    %item_hash = %{$r_item_hash};

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          VIEWPATH
          PACKAGE
          USERFILE
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $logger->logconfess("No files to rename.")
      unless %item_hash;

    $self->{LOG} = 'hrnitm.log';

    foreach my $old_name ( keys %item_hash ) {

        my $new_name = '';
        $new_name = basename $item_hash{$old_name};

        my $command = $self->preCommand('hrnitm')

          . " -b "
          . $self->{BROKER}
          . " -en \""
          . $self->{PROJECT} . "\" "
          . "-st \""
          . $self->{STATE} . "\" "
          . "-vp \""
          . $self->{VIEWPATH} . "\" " . "-p \""
          . $self->{PACKAGE} . "\" "
          . $self->_getLogArgs()
          . $self->_getProcessArgs()
          . $self->_getAuthArgs()
          . "-on $old_name "
          . "-nn $new_name ";

        $logger->debug($command);

        my @output = `$command`;

        my $RC = $?;

        $self->_handleReturnCode( $RC, @output );

    }

}

=item CheckOutSnapshot

=cut

#####################################################
#
#-- Run hsv to select versions
#
# Inputs:
#  $project - Harvest project name
#  $state   - Harvest state name
#  $userfile - Harvest user id
#  $viewpath - the root view path of the items in @itemlist
#  @itemlist - a list of items found in $viewpath to reserver
#
#####################################################
sub SelectVersions {

    my $self = shift;
    my ( $iv_option, $it_option, $ib_option, @itemlist ) = @_;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          VIEWPATH
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $self->{LOG} = 'hsv.log';

    my $command =
        $self->preCommand('hsv') . " -b "
      . $self->{BROKER}
      . " -en \""
      . $self->{PROJECT} . "\" "
      . "-st \""
      . $self->{STATE} . "\" "
      . "-vp \""
      . $self->{VIEWPATH} . "\" "
      . $self->_getProcessArgs()
      . $self->_getLogArgs()
      . $self->_getAuthArgs();

    if ( $self->{PACKAGE} ) {
        $command .= "-p \"" . $self->{PACKAGE} . "\" ";
    }

    if ( $self->{HSV_IV_OPTIONS} ) {
        $command .= "-iv $self->{HSV_IV_OPTIONS}";
    }

    if ( $self->{HSV_IT_OPTIONS} ) {
        $command .= "-it $self->{HSV_IT_OPTIONS}";
    }

    if ( $self->{HSV_IB_OPTIONS} ) {
        $command .= "-ib $self->{HSV_IB_OPTIONS}";
    }

    if ( $self->{HSV_RECURSE_PATTERN} ) {
        $command .= "-s \"$self->{HSV_RECURSE_PATTERN}\"";

    }

    $logger->debug($command);

    my @output = `$command`;

    my $RC = $?;

    return $self->_handleReturnCode( $RC, @output );

}

#####################################################
#
#-- Check in all files recursively
#
# Inputs:
#  $path   - the root file system path
#  $project - Harvest project name
#  $state   - Harvest state name
#  $user - Harvest user id
#  $password - password for Harvest user id
#  $viewpath - the root view path of the items in @itemlist
#  $package - the package to reserve to
#
# Outputs:
#   always returns 0
#
#####################################################

sub CheckInRecursive {

    my $self = shift;

    my $pattern = shift;
    $pattern = '*' if $pattern eq '';

    $self->{CHECKIN_OPTS} = "-op pc -s '$pattern'";

    return $self->_CheckInProcess(@_);

}

#####################################################
#
#-- Check in files through the agent
#
# Inputs:
#  @filelist - a list of files found in $path to check in
#
# Outputs:
#  a log file.  always returns 0
#
#####################################################

sub hciRemoteList {

    my $self     = shift;
    my @filelist = @_;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          VIEWPATH
          PACKAGE
          USER
          PASSWORD
          REMOTEUSER
          REMOTEPASSWORD
          CLIENTPATH
          MACHINE
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $logger->logconfess("No files to check in for hci")
      if @filelist == ();

    my $log = $self->{PROJECT} . '-hci.log';

    #-- remove trailing slash from clientpath or
    #   hci will fail

    my $path = $self->{CLIENTPATH};
    $path =~ s/\\$//;
    $path =~ s/\/$//;

    my $cmd = $self->preCommand('hci')

      . " -b "
      . $self->{BROKER}
      . " -o \"$log\" "
      . " -en \""
      . $self->{PROJECT} . "\" "
      . "-st \""
      . $self->{STATE} . "\" " . "-rm "
      . $self->{MACHINE}
      . " -rusr "
      . $self->{REMOTEUSER} . " "
      . "-vp \""
      . $self->{VIEWPATH} . "\" "
      . "-cp \"$path\" " . "-p \""
      . $self->{PACKAGE} . "\" "
      . "-ur -bo -if ne -op pc " . "-usr "
      . $self->{USER} . " ";

    foreach my $file (@filelist) {
        $file =~ s/\\/\\\\/g;
    }

    $logger->info("Checking In Files: @filelist");
    $logger->debug("$cmd -pw XXXX -rpw XXXX @filelist");

    $cmd .= " -pw "
      . $self->{PASSWORD}
      . " -rpw "
      . $self->{REMOTEPASSWORD}
      . " @filelist";

    my @output = `$cmd`;

    my $RC = $?;

    $self->{LOG} = 'hci.log';
    return $self->_handleReturnCode( $RC, @output );

}

#####################################################
#
#-- Get machine directory information through agent
#
# Inputs:
#  $log - a log file to write to
#  $machine - the machine the agent is on
#  $path - the file system path on $machine to retrieve
#          the directory info for
#  $user/$password - the os authentication info
#
#####################################################
sub hcd {
    my $self = shift;

    #-- check required inputs

    my $cp = $self->_checkParms(
        qw (
          BROKER
          CLIENTPATH
          MACHINE
          USER
          PASSWORD
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    my $command =
        'hcd ' . " -b "
      . $self->{BROKER} . " -m "
      . $self->{MACHINE}
      . " -pth \""
      . $self->{CLIENTPATH} . "\""
      . " -usr "
      . $self->{USER};

    $logger->debug("$command -pw XXXX");

    $command .= " -pw " . $self->{PASSWORD};

    my @output = `$command`;

    my $RC = $?;

    $self->{LOG} = 'hcd.log';
    return $self->_handleReturnCode( $RC, @output );

}

#####################################################
#
#-- Recursively check out from a view path, har 5
#
# Inputs:
#  broker - the broker location
#  path - the file system path on $machine to retrieve
#          the directory info for
#  user/password - the os authentication info
#
#####################################################

sub hcoSynchRecursive {

    my $self = shift;

    #-- check required inputs

    my $cp = $self->_checkParms(
        qw (
          BROKER
          CLIENTPATH
          PROJECT
          STATE
          USER
          PASSWORD
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    my $cwd = getwd();

    chdir $self->{CLIENTPATH}
      or $logger->logconfess(
        "Couldn't change directory to " . $self->{CLIENTPATH} . ".\n" );

    my $command =
        $self->preCommand('hco') . " -b "
      . $self->{BROKER}
      . " -en \""
      . $self->{PROJECT} . "\""
      . " -st \""
      . $self->{STATE} . "\""
      . " -vp \""
      . $self->{VIEWPATH} . "\""
      . " -r -op pc -sy ";

    #-- if a process name is specified, use that

    if ( $self->{PROCESSNAME} ne '' ) {
        $command .= " -pn \"" . $self->{PROCESSNAME} . "\" ";

    }

    $command .= " -s \"*\" -usr \"" . $self->{USER} . "\" -pw \"";

    my $publicCommand = $command;

    $command       .= $self->{PASSWORD} . "\"";
    $publicCommand .= "XXXX\"";

    my @output = `$command`;

    my $RC = $?;

    $self->{LOG} = 'hco.log';

    chdir $cwd;
    return $self->_handleReturnCode( $RC, @output );

}

#####################################################
#
#-- Recursively check out from a view path, har 4.x
#
# Inputs:
#  $log - a log file to write to
#  $path - the file system path on $machine to retrieve
#          the directory info for
#  $user/$password - the os authentication info
#
#####################################################

sub hco4SynchRecursive {

    my $self = shift;

    my $orgdir = getcwd();

    #-- check required inputs

    my $cp = $self->_checkParms(
        qw (
          BROKER
          CLIENTPATH
          PROJECT
          STATE
          USER
          PASSWORD
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    my $cwd = getcwd();
    chdir $self->{CLIENTPATH}
      or $logger->logconfess(
        "Couldn't change directory to " . $self->{CLIENTPATH} );

    my $command = $self->preCommand('hco')

      . " -en \""
      . $self->{PROJECT} . "\" "
      . " -st \""
      . $self->{STATE} . "\" "
      . " -vp \""
      . $self->{VIEWPATH}
      . "\" -r -op pc -sy ";

    #-- if a process name is specified, use that

    if ( $self->{PROCESSNAME} ne '' ) {
        $command .= "-pn \"" . $self->{PROCESSNAME} . "\" ";

    }

    $command .= "-s \"*\" -usr \"" . $self->{USER} . "\" -pw \"";

    my $publicCommand = $command;

    $command       .= $self->{PASSWORD} . "\"";
    $publicCommand .= "XXXX\"";

    my @output = `$command`;

    my $RC = $?;

    $self->{LOG} = 'hco.log';

    chdir $cwd;
    return $self->_handleReturnCode( $RC, @output );

}

#####################################################
#
#-- Execute remote OS command via agent
#
# Inputs:
#  $log - the name of a log file to write to (why?)
#  $machine - Harvest project name
#  $program   - the name of the program to execute
#  $args - args for $program
#  $syn - synchronicity: either 'syn' or 'asyn'
#  $user - the OS user id
#  $password - password for the OS user id
#
# Returns:
#  the output of $program if successful, or undef if not
#
#
#####################################################
sub hexecp {

    my $self    = shift;
    my $program = shift;
    my $args    = shift;

    my ( $log, $machine, $syn, $user, $password ) = @_;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          MACHINE
          USER
          PASSWORD
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    #-- process args for shell
    #   handle quoting

    $args =~ s/\"/\\\"/g;    #"

    unless ( $syn =~ /^-/ ) {
        $syn = '-' . $syn;
    }

    my $broker = '';

    $self->{LOG} = 'hexecp.log';

    my $cmd =
"hexecp -b $broker -m $machine -o \"$log\" $syn -prg \"$program\" -args \"$args\" -usr $user -pw $password";

    my @output = `$cmd`;

    my $RC = $?;

    return $self->_handleReturnCode( $RC, @output );

}

#####################################################
#
#-- Load files recursively
#
# Inputs:
#
#  path   - the root file system path
#  project - Harvest project name
#  state   - Harvest state name
#  user - Harvest user id
#  password - password for Harvest user id
#  viewpath - the root view path of the items in @itemlist
#  package - the package to reserve to
#
# Outputs:
#   always returns 0
#
#####################################################

sub LoadRepository {

    my $self = shift;

    my $pattern = shift;
    $pattern = '*' unless $pattern;

    my $orgdir = getcwd();

    my $cp = $self->_checkParms(
        qw (
          BROKER
          VIEWPATH
          CLIENTPATH
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    #-- remove trailing slash from clientpath

    my $path = $self->{CLIENTPATH};
    $path =~ s|\\$||;
    $path =~ s|\/$||;

    my $repository = $self->{VIEWPATH};
    $repository =~ s|^\\||;
    $repository =~ s|^\/||;

    my $cwd = getcwd;
    chdir $self->{CLIENTPATH}
      or
      $logger->logdie( "Couldn't change directory to " . $self->{CLIENTPATH} );

    $self->{LOG} = 'hlr.log';

    my $command =
        $self->preCommand('hlr') . " -b "
      . $self->{BROKER}
      . " -rp \"$repository\""
      . " -cp \".\""
      . " -f '$pattern'"
      . " -cep -r"
      . $self->_getLogArgs()
      . $self->_getAuthArgs();

    my @output = `$command`;

    my $RC = $?;

    chdir $cwd;
    return $self->_handleReturnCode( $RC, @output );

}

#####################################################
#
#-- AddUsersToGroups
#
# Inputs:
#
#  broker - the broker name
#  files - files containing properly formatted input
#            for husrmgr
#
#####################################################

sub AddUsersToGroups {
    my $self   = shift;
    my $rArray = shift;

    my @UserList = @{$rArray};

    my $file = "addusertogroups_" . time() . ".txt";

    $file = $self->{LOGDIR} . "/" . $file
      if $self->{LOGDIR};

    open TMP, ">$file"
      or $logger->logcroak("Couldn't open file for husrmgr input");

    $self->{HUSRMGR_OPTS} = "-dlm '|' -ow ";

    foreach my $user_group (@UserList) {

        my ( $user, $group ) = @{$user_group};

        print TMP "$user||||||||$group\n";

    }

    close TMP;

    return $self->_husrmgr($file);

}

#####################################################
#
#-- _husrmgr
#
#   wrapper for husrmgr, which can do several different
#   operations
#
# Inputs:
#
#  broker - the broker name
#  files - files containing properly formatted input
#            for husrmgr
#  $self->{HUSRMGR_OPTS} - specific purpose
#
#####################################################

sub _husrmgr {

    my $self        = shift;
    my @input_files = @_;

    $logger->logcroak("No file passed to _husrmgr")
      unless @input_files;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $self->{LOG} = 'husrmgr.log';

    my $command =
        $self->preCommand('husrmgr') . " -b "
      . $self->{BROKER} . " "
      . $self->{HUSRMGR_OPTS}
      . $self->_getAuthArgs()
      . $self->_getLogArgs()
      . "@input_files";

    my @output = `$command`;

    return $self->_handleReturnCode( $?, @output );

}

#####################################################
#
#-- Get machine directory information through agent
#
# Inputs:
#  $log - a log file to write to
#  $machine - the machine the agent is on
#  $path - the file system path on $machine to retrieve
#          the directory info for
#  $user/$password - the os authentication info
#
# Outputs:
#  \($RC, $raOutput )
#
#####################################################
sub hsql {
    my $self    = shift;
    my $sqlFile = shift;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          USER
          PASSWORD
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $logger->logconfess("SQL input file not specified.")
      unless $sqlFile;

    my $command =
      'hsql ' . " -b " . $self->{BROKER} . " -t " . " -usr " . $self->{USER};

    #-- Now decide if the input parm is a file with sql in it
    #   or a string.

    #-- If a file with the same name exists, use it. Otherwise
    #   generate a temp file with the contents of the parm and
    #   use it.

    if ( -f $sqlFile ) {    #-- load the file
        $command . " -f \"" . $sqlFile . "\"";

    }
    else {                  #-- create temp file and load it

        my $tempFile = "hsql_" . time . ".sql";

        open TMP, ">$tempFile"
          or $logger->logconfess("Couldn't write to temporary hsql file.");

        print TMP $sqlFile . "\n";
        close TMP;

        $command .= " -f \"" . $tempFile . "\"";

    }

    $logger->debug("$command -pw XXXX");

    $command .= " -pw " . $self->{PASSWORD};

    my @output = `$command`;

    my $RC = $?;

    $self->{LOG} = 'hsql.log';
    return $self->_handleReturnCode( $RC, @output );

}

=back

=back

=cut

#####################################################
# PRIVATE OBJECT METHODS
#####################################################

=head2 Private Object Methods

These functions are private object methods providing common functionality
for the public methods.

=over 4

=item _checkParms 

Checks that there are defined values for each of the named parameters passed
to the function.

=cut

sub _checkParms {
    my $self           = shift;
    my @required_parms = @_;
    my $PARM_RC        = 0;

    $logger = get_logger($self)
      or die "Couldn't get logger!";

    foreach my $parm (@required_parms) {
        $logger->debug("Checking parm: $parm");
        unless ( $self->{$parm} ) {
            $logger->error("Required parameter $parm not supplied.");
            $PARM_RC = 1;
        }
    }

    return ( ( $PARM_RC == 0 ) ? 0 : 1 );

}

=item _handleReturnCode

Reads the log file generated by the command line program.

=back

=cut

sub _handleReturnCode {
    my $self       = shift;
    my $RC         = shift;
    my @cmd_output = @_;

    $logger = get_logger($self)
      or die "Couldn't get logger!";

    my $log = $self->_getLogName();

    $logger->info("Using Harvest log: $log");

    open( HLOG, "<$log" )
      or $logger->warn("Couldn't open log file $log");

    my @output = <HLOG>;
    close HLOG;

    if ( $RC > 0 ) {
        $logger->error( @cmd_output, @output );
        $RC = $RC >> 8;

    }
    elsif ( $RC == -1 ) {
        $logger->error( @cmd_output, @output );

    }
    else {
        $logger->info( @cmd_output, @output );
    }

    return $RC;
}

sub _getLogName {
    my $self = shift;

    if ( $self->{LOGDIR} and $self->{LOG} ) {
        return "$self->{LOGDIR}/$self->{LOG}";

    }
    elsif ( $self->{LOG} ) {
        return "$self->{LOG}";

    }
    else {
        $logger->logcroak->("No log file sent to _getLogName");

    }

}

sub _getLogArgs {
    my $self = shift;

    my $log = $self->_getLogName();

    return " -o \"$log\" ";

}

#-- Process the authentication part of the command
#   line argument string
#-- Support both user/password and encrypted user
#   file

sub _getAuthArgs {
    my $self = shift;

    if ( $self->{USERFILE} ) {
        return " -eh $self->{USERFILE} ";

    }
    elsif ( $self->{USER} and $self->{PASSWORD} ) {
        return " -usr $self->{USER} -pw $self->{PASSWORD} ";

    }
    else {
        $logger->logcroak->("User file or user/password not set!");

    }

}

sub _getRemoteAuthArgs {
    my $self = shift;

    if ( $self->{MACHINE} and $self->{REMOTE_USERFILE} ) {
        return " -reh $self->{REMOTE_USERFILE} ";

    }
    elsif ( $self->{MACHINE}
        and $self->{REMOTE_USER}
        and $self->{REMOTE_PASSWORD} )
    {
        return
" -rm $self->{MACHINE} -rusr $self->{REMOTE_USER} -rpw $self->{REMOTE_PASSWORD} ";

    }
    else {
        return "";

    }

}

#-- Handle case where the default process name is overriden
sub _getProcessArgs {
    my $self = shift;

    if ( exists $self->{PROCESSNAME} ) {
        return " -pn \"" . $self->{PROCESSNAME} . "\" ";
    }

    return "";

}

#####################################################
# Synonyms

sub put { my $self = shift; return $self->CheckInAndRelease(@_) }

#sub put_and_keep_lock { my $self = shift; return $self->CheckInAndRelease(@_) }
sub commit       { my $self = shift; return $self->CheckInAndKeep(@_) }
sub get          { my $self = shift; return $self->CheckOutForBrowse(@_) }
sub get_and_lock { my $self = shift; return $self->CheckOutForUpdate(@_) }
sub update       { my $self = shift; return $self->HsyncFullView(@_) }
sub lock         { my $self = shift; return $self->CheckOutReserveOnly(@_) }
sub unlock       { my $self = shift; return $self->CheckInReleaseOnly(@_) }

#####################################################

1;

