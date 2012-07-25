#!/usr/bin/ksh

hsync -b harprod -en "$1" -st local -vp \\mpscm\\common\\var\\opt\\harvest\\ca\\udp -cp
/var/opt/harvest/mpscm-dev/ca/udp -sy -o /tmp/m_dev_deploy.log -eh $HARVESTHOME/harvest.dfo

