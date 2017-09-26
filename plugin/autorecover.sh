#!/bin/bash

PINGRES=`ping -c 6 10.1.100.1`
PLOSS=`echo $PINGRES : | grep -oP '\d+(?=% packet loss)'`

if [ "100" -eq "$PLOSS" ];then
    /etc/init.d/openvpn restart
fi
