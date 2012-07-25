#!/usr/bin/ksh

hsync -b harprod -en "$1" -st prod -vp \\mpscm\\common\\var\\opt\\harvest\\ca\\udp -cp /var/opt/harvest/ca/udp -sy -o /tmp/m_prod_deploy.log -eh $HARVESTHOME/harvest.dfo

