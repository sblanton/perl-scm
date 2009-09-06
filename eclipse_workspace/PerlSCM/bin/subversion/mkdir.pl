#!/bin/env perl

#-- Load modules
use Log::Log4perl "get_logger";
use SCM::Tool::VersionControl::Subversion;

#-- Initialize log4perl
my $HOME= $ENV{HOME} || "$ENV{HOMEDRIVE}$ENV{HOMEPATH}";

Log::Log4perl::init("$HOME/perl-scm/scm-log4perl.conf");
#my $logger = get_logger("SCM");

#-- Instantiate the lawson context
$svnctx = SCM::Tool::VersionControl::Subversion->new();

$svnctx->load( "$HOME/perl-scm/svn.ctx");
$svnctx->set( MESSAGE => 'test');


$svnctx->print();

$svnctx->mkdir("SCM/Tool");
$svnctx->mkdir("bin/subversion");
$svnctx->mkdir("SCM/Tool/VersionControl");

