#!/bin/env perl

#-- Load modules
use Log::Log4perl "get_logger";
use SCM::Tool::VersionControl::Harvest;

#-- Initialize log4perl
my $HOME= $ENV{HOME} || "$ENV{HOMEDRIVE}$ENV{HOMEPATH}";

Log::Log4perl::init("scm-log4perl.conf");
#Log::Log4perl::init("$HOME/perl-scm/scm-log4perl.conf");
my $logger = get_logger("SCM");

#-- Instantiate the lawson context
$harctx = SCM::Tool::VersionControl::Harvest->new();

$harctx->load( "$HOME/perl-scm/harvest.ctx");

$harctx->setParm( PROCESSNAME => "Check Out for Browse" );

$harctx->print();

$harctx->get("application.xml");
