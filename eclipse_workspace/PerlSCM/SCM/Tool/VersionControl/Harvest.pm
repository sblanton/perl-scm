
package SCM::Tool::VersionControl::Harvest;

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

our $logger;

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

    if ( defined $self->{HARVESTHOME} ) {

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

    return $preCmd;
}

#####################################################
# PUBLIC OBJECT METHODS
#####################################################

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
sub AddBaseline {
    my $self = shift;

    if (@_) {
        $self->{REPOSITORY} = shift;
    }
    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          USER
          PASSWORD
          REPOSITORY
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    my $command =
        $self->preCommand('hcbl') . ' -b '
      . $self->{BROKER}
      . ' -en "'
      . $self->{PROJECT} . '"'
      . ' -usr '
      . $self->{USER}
      . " -o $ENV{HOME}/.hcbl.log"
      . " -rp \""
      . $self->{REPOSITORY} . "\""
      . ' -add -rw';

    $logger->debug( $command . " -pw XXXX " );

    $command .= ' -pw ' . $self->{PASSWORD};

    my @output = `$command`;

    my $RC = $?;

    sleep 1;    # wait for log to finish
    $self->_handleReturnCode( $RC, @output );

    return $RC;

}

#####################################################
#
#-- Create Generic Harvest Package
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

sub CreatePackage {
    my $self = shift;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          PACKAGE
          USER
          PASSWORD
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    my $command =
        $self->preCommand('hcp') . ' -b '
      . $self->{BROKER}
      . ' -en "'
      . $self->{PROJECT} . '"'
      . ' -st "'
      . $self->{STATE} . '"'
      . ' -usr '
      . $self->{USER} . ' "'
      . $self->{PACKAGE} . '"';

    $logger->debug( $command . " -pw XXXX " );

    $command .= ' -pw ' . $self->{PASSWORD};

    my @output = `$command`;

    my $RC = $?;

    $self->_handleReturnCode( $RC, @output );

    return $RC;

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

    $logger->logconfess("No new project name passed to CreateProject.")
      if $newproject eq '';

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          USER
          PASSWORD
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    my $command =
        $self->preCommand('hcpj') . ' -b '
      . $self->{BROKER}
      . ' -cpj "'
      . $self->{PROJECT} . '"'
      . ' -npj "'
      . $newproject . '"'
      . ' -cug -act'
      . ' -usr '
      . $self->{USER};

    $logger->debug( $command . " -pw XXXX " );

    $command .= ' -pw ' . $self->{PASSWORD};

    my @output = `$command`;

    my $RC = $?;

    $self->_handleReturnCode( $RC, @output );

    return $RC;

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
    $self->{PROGRAM} = 'hco';

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          VIEWPATH
          PACKAGE
          USER
          PASSWORD
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
      . $self->{PACKAGE} . "\" " . "-up " . "-r " . "-usr "
      . $self->{USER};

    $logger->debug( $command . " -pw XXX @itemlist" );

    $command .= " -pw " . $self->{PASSWORD} . " @itemlist";

    my @output = `$command`;

    my $RC = $?;

    $self->_handleReturnCode( $RC, @output );

    return $RC;

}

#####################################################
#
#-- Check out files for browse (read-only)
#
# Inputs:
#  $project - Harvest project name
#  $state   - Harvest state name
#  $user - Harvest user id
#  $password - password for Harvest user id
#  $viewpath - the root view path of the items in @itemlist
#  @itemlist - a list of items found in $viewpath to reserver
#
#####################################################
sub CheckOutForBrowse {

    my $self     = shift;
    my @itemlist = @_;
    $self->{PROGRAM} = 'hco';

    my $cp;

    $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          VIEWPATH
          USER
          PASSWORD
          CLIENTPATH
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    $logger->logconfess("No files to retrieve.")
      if @itemlist == ();

    my $processname = "";

    if ( $self->{PROCESSNAME} ne '' ) {
        $processname = "-pn \"" . $self->{PROCESSNAME} . "\" ";
    }

    #-- a clientpath of '.' will crash hco
    my $clientpath = "";
    if (    $self->{CLIENTPATH} ne ''
        and $self->{CLIENTPATH} ne '.' )
    {
        $clientpath = "-cp \"" . $self->{CLIENTPATH} . "\" ";
    }

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
      . $processname
      . "-br -r " . "-usr "
      . $self->{USER};

    $logger->debug( $command . " -pw XXX @itemlist" );

    $command .= " -pw " . $self->{PASSWORD} . " @itemlist";

    my @output = `$command`;

    my $RC = $?;

    $self->_handleReturnCode( $RC, @output );

    return $RC;

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
sub CheckInAndRelease {

    my $self     = shift;
    my @itemlist = @_;
    $self->{PROGRAM} = 'hci';

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          VIEWPATH
          PACKAGE
          USER
          PASSWORD
          CLIENTPATH
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
      . $self->{PACKAGE} . "\" " . "-ur " . "-usr "
      . $self->{USER};

    $logger->debug( $command . " -pw XXX @itemlist" );

    $command .= " -pw " . $self->{PASSWORD} . " @itemlist";

    my @output = `$command`;

    my $RC = $?;

    $self->_handleReturnCode( $RC, @output );

    return $RC;

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
sub CheckInReleaseOnly {

    my $self     = shift;
    my @itemlist = @_;
    $self->{PROGRAM} = 'hci';

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          VIEWPATH
          PACKAGE
          USER
          PASSWORD
          CLIENTPATH
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
      . $self->{PACKAGE} . "\" " . "-ro " . "-usr "
      . $self->{USER};

    $logger->debug( $command . " -pw XXX @itemlist" );

    $command .= " -pw " . $self->{PASSWORD} . " @itemlist";

    my @output = `$command`;

    my $RC = $?;

    $self->_handleReturnCode( $RC, @output );

    return $RC;

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

    my $self = shift;
    my ( $project, $state, $user, $password, $viewpath, $package, @itemlist ) =
      @_;

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          VIEWPATH
          PACKAGE
          USER
          PASSWORD
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
      . $self->{PACKAGE} . "\" " . "-ro " . "-usr "
      . $self->{USER};

    $logger->debug( $command . " -pw XXX @itemlist" );

    $command .= " -pw " . $self->{PASSWORD} . " @itemlist";

    my @output = `$command`;

    my $RC = $?;

    $self->_handleReturnCode( $RC, @output );

    return 0;

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

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          STATE
          VIEWPATH
          PACKAGE
          USER
          PASSWORD
          CLIENTPATH
          )
    );

    $logger->debug("_checkParms return code: $cp");
    $logger->logconfess("Required parameter(s) not supplied.")
      if $cp > 0;

    #-- remove trailing slash from clientpath or
    #   hci will fail
    $self->{CLIENTPATH} =~ s/\\$//;
    $self->{CLIENTPATH} =~ s/\/$//;

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
      . "-ur -bo -if ne -op pc "
      . "-s '$pattern' " . "-usr "
      . $self->{USER} . " ";

    $logger->debug("$command -pw XXXX");

    $command .= " -pw " . $self->{PASSWORD};

    my @output = `$command`;

    my $RC = $?;

    $self->_handleReturnCode( $RC, @output );

    return $RC;

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

    $self->_handleReturnCode( $RC, @output );

    return $RC;

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

    $self->_handleReturnCode( $RC, @output );

    return $RC;

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

    $self->_handleReturnCode( $RC, @output );

    return $RC;

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

    $self->_handleReturnCode( $RC, @output );

    return $RC;

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

    my $cmd =
"hexecp -b $broker -m $machine -o \"$log\" $syn -prg \"$program\" -args \"$args\" -usr $user -pw $password";

    my @output = `$cmd`;

    my $RC = $?;

    $self->_handleReturnCode( $RC, @output );

    return $RC;

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

sub hlr {

    my $self = shift;

    my $pattern = shift;
    $pattern = '*' if $pattern eq '';

    my $orgdir = getcwd();

    my $cp = $self->_checkParms(
        qw (
          BROKER
          PROJECT
          VIEWPATH
          CLIENTPATH
          USER
          PASSWORD
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

    chdir $self->{CLIENTPATH}
      or
      $logger->logdie( "Couldn't change directory to " . $self->{CLIENTPATH} );

    #-- Delete Harvest4x .hsig file

    if ( -f '.hsig' ) {
        chmod 0777, '.hsig';
        unlink '.hsig'
          or $logger->logwarn('Could not delete .hsig file from client path.');
    }

    my $command = $self->preCommand('hlr')

      . " -b "
      . $self->{BROKER}
      . " -rp \"$repository\""
      . " -cp \".\""
      . " -f '$pattern'"
      . " -cep -r"
      . " -o $ENV{HOME}/.hlr.log"
      . " -usr "
      . $self->{USER};

    $logger->debug("$command -pw XXXX");

    $command .= " -pw " . $self->{PASSWORD};

    my @output = `$command`;

    my $RC = $?;

    $self->_handleReturnCode( $RC, @output );

    return $RC;

}

#####################################################
#
#-- Add Users
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

sub AddUsers {

    my $self = shift;

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

    my $command = $self->preCommand('husrmgr')

      . " -b " . $self->{BROKER} . " -usr " . $self->{USER};

    $logger->debug("$command -pw XXXX");

    $command .= " -pw " . $self->{PASSWORD};

    my @output = `$command`;

    my $RC = $?;

    $self->_handleReturnCode( $RC, @output );

    return $RC;

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

sub _handleReturnCode {
    my $self       = shift;
    my $RC         = shift;
    my @cmd_output = @_;

    $logger = get_logger($self)
      or die "Couldn't get logger!";

    my $log = $self->_getLog( $self->{PROGRAM} . ".log" );
    open( HLOG, "<$log" );
    my @output = <HLOG>;
    close HLOG;

    if ( $RC > 0 ) {
        $logger->error( @cmd_output, @output )

    }
    else {
        $logger->info( @cmd_output, @output );
    }
}

sub _getLog {
    my $self = shift;
    my $log  = shift;

    # $logger = get_logger($self)
    #  or die "Couldn't get logger!";

    if ( $self->{LOGDIR} ) {
        $log = $self->{LOGDIR} . $DL . $log;
    }

    return $log;

}

#####################################################
# Synonyms

sub put { my $self = shift; return $self->CheckInAndRelease(@_) }

#sub put_and_keep_lock { my $self = shift; return $self->CheckInAndRelease(@_) }
#sub commit { my $self = shift; return $self->CheckInAndRelease(@_) }
sub get          { my $self = shift; return $self->CheckOutForBrowse(@_) }
sub get_and_lock { my $self = shift; return $self->CheckOutForUpdate(@_) }
sub update       { my $self = shift; return $self->hcoSynchRecursive(@_) }
sub lock         { my $self = shift; return $self->hcoReserve(@_) }
sub unlock       { my $self = shift; return $self->CheckInReleaseOnly(@_) }

#####################################################

1;

