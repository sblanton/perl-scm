#!/usr/bin/ksh

pod=<<=cut

=head1 Name

m_qa_deploy.ksh <Harvest project using 'mpscm' repository>

=head1 Synopsis

Synchronizes the qa UDP script area with the qa state working view of the specified Harvest project.

=head1 Description

Runs a simple hsync command and write the log to /tmp/m_qa_deploy.ksh

Cleans out the $SHARED_HARUDP/UNIT folder before running hsync.

hsync is not smart enough to manage differences between parallel projects

=cut

log=/tmp/m_qa_deploy.log
vista=/var/opt/harvest/mpscm-qa/ca/udp

#-- Clean out old unit scripts because they may test code
#   that is not there anymore

rm -fr $vista/UNIT/*

hsync -b harprod -en "$1" -st qa -vp \\mpscm\\common\\var\\opt\\harvest\\ca\\udp -cp $vista -sy -o $log -eh $HARVESTHOME/harvest.dfo

grep -e "^E" $log

