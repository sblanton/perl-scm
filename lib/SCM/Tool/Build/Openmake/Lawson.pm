
package SCM::Tool::Build::Openmake::Lawson;

BEGIN {

    use vars qw($VERSION @ISA );
    use SCM::Tool::Build::Openmake;

    #-- Inherits exporter functions to export functions
    @ISA = qw( SCM::Tool::Build::Openmake );

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

sub lgentgt {
    my $self          = shift;
    my $lawson_object = shift;

    my $program     = shift || $lawson_object->{PROGRAM};
    my $lawdir      = $lawson_object->{LAWDIR};
    my $productline = $lawson_object->{LAWPL};
    my $systemcode  = $lawson_object->{LAWSC};

    my $project = $self->{PROJECT};
    my $os      = $self->{OS};

    my @tgtlist = ();

    my $fullsrcdir = "$lawdir/$productline/$systemcode" . "src";
    my $srcdir     = $systemcode . "src";
    my $tgtdir     = "$lawdir/$productline/tgt";

    unless ( -d $tgtdir ) {
        mkfulldir $tgtdir . '/';

    }

    #-- Read the source directory for the program
    #   source

    opendir PGMDIR, $fullsrcdir
      or die "Couldn't open directory '$fullsrcdir'.";
    my @files = readdir PGMDIR;
    closedir PGMDIR;

    #-- Keep only the files from the specified program
    @files = grep
/^\Q$program\E\.rpt$|^\Q$program\E\.scr$|^\Q$program\EPD$|^\Q$program\EWS$|^\Q$program\E[BME]PD$|^\Q$program\E[BME]WS$/,
      @files;

    die "Couldn't find any program files!"
      if @files == ();

    my %exit_files;
    $exit_files{'BEGIN'} = [];

    if ( ( grep /^\Q$program\E[BME]PD$|^\Q$program\E[BME]WS$/, @files ) > 0 ) {

        push(
            @{ $exit_files{'B'} },
            grep ( /^\Q$program\EBPD$|^\Q$program\EBWS$/, @files )
        );
        push(
            @{ $exit_files{'M'} },
            grep ( /^\Q$program\EMPD$|^\Q$program\EMWS$/, @files )
        );
        push(
            @{ $exit_files{'E'} },
            grep ( /^\Q$program\EEPD$|^\Q$program\EEWS$/, @files )
        );

        my @regular_files = grep
/^\Q$program\E\.rpt$|^\Q$program\E\.scr$|^\Q$program\EPD$|^\Q$program\EWS$/,
          @files;

        foreach my $exit_type ( keys %exit_files ) {
            unless ( @{ $exit_files{$exit_type} } == () ) {
                my $target = "usrobj/${program}${exit_type}.gnt";
                my @user_exit_files =
                  ( @{ $exit_files{$exit_type} }, @regular_files );

                genTGT( $target, $project, $srcdir, $tgtdir, $os,
                    @user_exit_files );
                push @tgtlist, $target;

                #-- add this target to the dependency list of the regular
                #   target
                push @regular_files, $target;
            }
        }

        @files = @regular_files;
    }

    genTGT( "obj/${program}.gnt", $project, $srcdir, $tgtdir, $os, @files );
    push @tgtlist, "obj/${program}.gnt";

    return @tgtlist;

}

#-- loop through files to get dependency elements

sub genTGT {

    #-- Get arguments
    my $target  = shift;
    my $project = shift;
    my $srcdir  = shift;
    my $tgtdir  = shift;
    my $os      = shift;
    my @files   = @_;

    my @dependencies = ();

    $target =~ m|obj/([^\.]+).gnt$|;
    my $tgtfile = "${1}.tgt";

    foreach my $file (@files) {
        if ( $file =~ /^usrobj/ ) {
            push @dependencies, depTemplate($file);

        }
        else {
            push @dependencies, depTemplate( $srcdir . '/' . $file );

        }
    }

    #-- Set build type and output dir for the normal program
    my $buildtype;

    if ( $target =~ /^usrobj/ ) {
        $buildtype = 'Lawson User Exit Compile';

    }
    else {
        $buildtype = 'Lawson Compile';

    }

    my $tgt =
      tgtTemplate( $target, $project, $tgtfile, $buildtype, $os,
        \@dependencies );

    #-- Write out to file
    chmod 0777, "$tgtdir/$tgtfile";

    open TGT, ">$tgtdir/$tgtfile"
      or die "couldn't write";

    print TGT $tgt;
    close TGT;

    print "\nWrote $tgtdir/$tgtfile.\n\n";

}

sub tgtTemplate {

    my ( $target, $project, $tgtfile, $buildtype, $os, $dependencies ) = @_;

    return <<ENDTGTTEMPL;
<?xml version="1.0"?>
<OMTarget>
 <Version>6.3</Version>
 <Name>$target</Name>
 <Project>$project</Project>
 <TargetDefinitionFile>$tgtfile</TargetDefinitionFile>
 <OSPlatform>$os</OSPlatform>
 <BuildType>$buildtype</BuildType>
 <IntDirectory></IntDirectory>
 <PhoneyTarget>false</PhoneyTarget>
 <BuildTask>
 <Name>Compile</Name>
 <OptionGroup>
  <GroupName>Build Task Options</GroupName>
  <Type>0</Type>
 </OptionGroup>
 </BuildTask>
 @$dependencies</OMTarget>
ENDTGTTEMPL

}

sub depTemplate {

    my $dep = shift;

    return <<ENDDEPTEMPL;
 <Dependency>
  <Name>$dep</Name>
  <Type>5</Type>
  <ParentBuildTask>Compile</ParentBuildTask>
  <ParentOptionGroup>Build Task Options</ParentOptionGroup>
 </Dependency>
ENDDEPTEMPL

}

