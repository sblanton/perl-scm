
package SCM::Tool::VersionControl::Harvest::Lawson;

BEGIN {

    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    use SCM::Tool::VersionControl::Harvest;

    #-- Inherits exporter functions to export functions
    @ISA = qw( SCM::Tool::VersionControl::Harvest );

    $VERSION = 2.02;

}

use strict;    #-- helps to find syntax errors
use Carp;      #-- helps for debugging
use Log::Log4perl qw( get_logger );
use Cwd;

my $logger = get_logger('SCM.Tool.Harvest');

#####################################################
# PACKAGE FUNCTIONS
#####################################################

#####################################################
# OVERRIDDEN OBJECT METHODS
#####################################################

#####################################################
#
#-- Check in files found locally
#
# Inputs:
#  @filelist - a list of files found in $path to check in
#
# Outputs:
#  a log file.  always returns 0
#
#####################################################

sub new {

    my $proto = shift;

    my $class = ref($proto) || $proto;
    my $self = {};

    my %ctx = @_;

    foreach ( keys %ctx ) {
        $self->{$_} = $ctx{$_};

    }

    $self->{TOOL} = 'Harvest';

    $logger->debug("New instance created.");

    #-- instantiate
    bless( $self, $class );
    return $self;

}

sub hciList {

    my $self = shift;

    my $lawson_object = shift;

    my @filelist = @_;

    #-- next line for Lawson only
    $self->{CLIENTPATH} =
      $lawson_object->{LAWDIR} . '/' . $lawson_object->{LAWPL};

    $logger->logconfess("BROKER not specified.")
      unless $self->{BROKER};

    $logger->logconfess("PROJECT not specified.")
      unless $self->{PROJECT};

    $logger->logconfess("STATE not specified.")
      unless $self->{STATE};

    $logger->logconfess("VIEWPATH not specified.")
      unless $self->{VIEWPATH};

    $logger->logconfess("PACKAGE not specified.")
      unless $self->{PACKAGE};

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
      . $self->{STATE} . "\" "
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
    $logger->debug("$cmd -pw XXXX @filelist");

    $cmd .= " -pw " . $self->{PASSWORD} . " @filelist";

    my @output = `$cmd`;

    my $RC = $?;

    if ( $RC > 0 ) {
        dumpLogError($log);

    }

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

    my $self          = shift;
    my $lawson_object = shift;

    #-- next line for Lawson only
    $self->{CLIENTPATH} =
      $lawson_object->{LAWDIR} . '/' . $lawson_object->{LAWPL};

    chdir $self->{CLIENTPATH}
      or $logger->logconfess(
        "Couldn't change directory to " . $self->{CLIENTPATH} . ".\n" );

    #-- check required inputs

    $logger->logconfess("BROKER not defined.")
      unless $self->{BROKER} ne '';

    $logger->logconfess("PROJECT not defined.")
      unless $self->{PROJECT} ne '';

    $logger->logconfess("STATE not defined.")
      unless $self->{STATE} ne '';

    $logger->logconfess("VIEWPATH not defined.")
      unless $self->{VIEWPATH} ne '';

    $logger->logconfess("USER not defined.")
      unless $self->{USER} ne '';

    $logger->logconfess("PASSWORD not defined.")
      unless $self->{PASSWORD} ne '';

    $logger->logconfess("HARVESTHOME not defined.")
      unless $self->{HARVESTHOME} ne '';

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

    if ( $RC > 0 ) {
        $logger->error("hcoSynchRecursive failed with RC=$RC.");
        $logger->error("$publicCommand");

    }

    dumpLog(@output);

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

sub hcoUpdate {

    my $self          = shift;
    my $lawson_object = shift;
    my @files         = @_;

    foreach (@files) {    #-- quote all the files
        $_ = "\"$_\"";
    }

    #-- next line for Lawson only
    $self->{CLIENTPATH} =
      $lawson_object->{LAWDIR} . '/' . $lawson_object->{LAWPL};

    chdir $self->{CLIENTPATH}
      or $logger->logconfess(
        "Couldn't change directory to " . $self->{CLIENTPATH} . ".\n" );

    #-- check required inputs

    $logger->logconfess("BROKER not defined.")
      unless $self->{BROKER} ne '';

    $logger->logconfess("PROJECT not defined.")
      unless $self->{PROJECT} ne '';

    $logger->logconfess("STATE not defined.")
      unless $self->{STATE} ne '';

    $logger->logconfess("VIEWPATH not defined.")
      unless $self->{VIEWPATH} ne '';

    $logger->logconfess("USER not defined.")
      unless $self->{USER} ne '';

    $logger->logconfess("PASSWORD not defined.")
      unless $self->{PASSWORD} ne '';

    $logger->logconfess("HARVESTHOME not defined.")
      unless $self->{HARVESTHOME} ne '';

    my $command =
        $self->preCommand('hco') . " -b "
      . $self->{BROKER}
      . " -en \""
      . $self->{PROJECT} . "\""
      . " -st \""
      . $self->{STATE} . "\""
      . " -vp \""
      . $self->{VIEWPATH} . "\""
      . " -p \""
      . $self->{PACKAGE} . "\""
      . " -r -op pc -up ";

    #-- if a process name is specified, use that

    if ( $self->{PROCESSNAME} ne '' ) {
        $command .= " -pn \"" . $self->{PROCESSNAME} . "\" ";

    }

    $command .= " \"" . $self->{USER} . "\" -pw \"";

    my $publicCommand = $command;

    $command       .= $self->{PASSWORD} . "\"";
    $publicCommand .= "XXXX\" @files";

    my @output = `$command @files`;

    my $RC = $?;

    if ( $RC > 0 ) {
        $logger->error("hcoUpdate failed with RC=$RC.");
        $logger->error("$publicCommand");

    }

    dumpLog(@output);

    return $RC;

}

sub getProgramFileNamesFromHarvest {

    my $self          = shift;
    my $lawson_object = shift;

    my $program    = $lawson_object->{PROGRAM};
    my $systemcode = $lawson_object->{LAWSC};

    $logger->logconfess("BROKER not defined.")
      unless $self->{BROKER} ne '';

    $logger->logconfess("PROJECT not defined.")
      unless $self->{PROJECT} ne '';

    $logger->logconfess("STATE not defined.")
      unless $self->{STATE} ne '';

    $logger->logconfess("VIEWPATH not defined.")
      unless $self->{VIEWPATH} ne '';

    $logger->logconfess("USER not defined.")
      unless $self->{USER} ne '';

    $logger->logconfess("PASSWORD not defined.")
      unless $self->{PASSWORD} ne '';

    $logger->logconfess("HARVESTHOME not defined.")
      unless $self->{HARVESTHOME} ne '';

    $logger->info(
        "Querying Harvest for file names for " . $lawson_object->{PROGRAM} );

    my $command =
        $self->preCommand('hlv') . " -b "
      . $self->{BROKER}
      . " -en \""
      . $self->{PROJECT} . "\""
      . " -st \""
      . $self->{STATE} . "\""
      . " -vp \""
      . $self->{VIEWPATH} . "\""
      . " -s \"*$program*\"";

    $command .= " -usr \"" . $self->{USER} . "\" -pw \"";

    my $publicCommand = $command;

    $command       .= $self->{PASSWORD} . "\"";
    $publicCommand .= "XXXX\" ";

    my @output = `$command`;

    my $RC = $?;

    if ( $RC > 0 ) {
        $logger->error("getProgramFileNamesFromHarvest failed with RC=$RC.");
        $logger->error("$publicCommand");
    }

    my @pgmfiles;
    my @lines = `cat hlv.log`;
    @lines = grep /^\*\*\*/, @lines;

    foreach my $file (@lines) {
        $file =~ /^\*\*\* ([^\;]+)\;/;
        push @pgmfiles, $1;

    }

    $logger->info("Found files @pgmfiles for $program.");

    return $RC, @pgmfiles;

}

*put          = *hciList;
*synch        = *hcoSynchRecursive;
*get_and_lock = *hcoUpdateLawson;

1;
