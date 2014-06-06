#!/bin/sh
#
# Copyright 2012 WonderMedia Technologies, Inc. All Rights Reserved. 
#  
# This PROPRIETARY SOFTWARE is the property of WonderMedia Technologies, Inc. 
# and may contain trade secrets and/or other confidential information of 
# WonderMedia Technologies, Inc. This file shall not be disclosed to any third party, 
# in whole or in part, without prior written consent of WonderMedia. 
#  
# THIS PROPRIETARY SOFTWARE AND ANY RELATED DOCUMENTATION ARE PROVIDED AS IS, 
# WITH ALL FAULTS, AND WITHOUT WARRANTY OF ANY KIND EITHER EXPRESS OR IMPLIED, 
# AND WonderMedia TECHNOLOGIES, INC. DISCLAIMS ALL EXPRESS OR IMPLIED WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.  
#

local LOG_FILE=/dev/console 
#local LOG_FILE=/dev/null

init_led()
{
    #enable GPIO 1
    mu s d8110040 0x02
    #set GPIO 1 to output
    mu s d8110080 0x02
}

# $1: 1, led on; 0 or other, led off
led_ctrl()
{
    if [ "$1" = "1" ]; then
        #LED ON
        mu s d81100c0 0x02
    else
        #LED OFF
        mu s d81100c0 0x0
    fi
}

led_flash()
{
    while [ 1 ]; do
        led_ctrl 1
        usleep 400000
        led_ctrl 0
        usleep 500000
    done
}

#if [ "$instenv_model_no" != "Soyea_OTT" ]; then
#    return 0
#fi

init_led
case $1 in
        0)
        echo "    Excute LED OFF..." > $LOG_FILE
        led_ctrl 0
        ;;
        1)
        echo "    Excute LED ON..." > $LOG_FILE
        led_ctrl 1
        ;;
        2)
        echo "    Excute LED Flash..." > $LOG_FILE
        led_flash
        ;;
        *)
        echo "    Excute Nothing..." > $LOG_FILE
        ;;
esac
