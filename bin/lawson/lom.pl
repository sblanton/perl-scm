#!/bin/env perl

#-- Load modules
use Log::Log4perl "get_logger";
use SCM::System::Lawson;

#-- Initialize log4perl
Log::Log4perl::init("$ENV{HOME}/scm-log4perl.conf");
my $logger = get_logger("SCM");

#-- Instantiate the lawson context
$lawctx = SCM::Platform::Lawson->new();

my @args = $lawctx->readArgs( @ARGV );
$lawctx->validateCommonArgs();

$lawctx->print();

$lawctx->setTool('BUILD', 'SCM::Tool::Build::Openmake::Lawson');

$lawctx->{BUILD}->load("$ENV{HOME}/openmake.ctx");

unless (-d "$ENV{HOME}/.scm") {
 mkdir "$ENV{HOME}/.scm"
  or die "Couldn't make directory $ENV{HOME}/.scm!";
}

my $makefile = $lawctx->{BUILD}->getMakefile();

$lawctx->{BUILD}->bldmake(qw(-s -l -ov), "-m $ENV{HOME}/.scm" );
$lawctx->{BUILD}->om( qw( -ov -l ), "-f $ENV{HOME}/.scm/$makefile", @args );

