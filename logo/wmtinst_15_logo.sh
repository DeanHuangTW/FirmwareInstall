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

#$1 is current path, don't use pwd
local_path="$1"

export instenv_logo_path=$1
if [ -d "$local_path/$instenv_model_no" ]; then
    export instenv_uboot_logo=$1/$instenv_model_no
else
    local model_GT7301=`echo $instenv_model_no | grep GT7301`
    local model_GT7305=`echo $instenv_model_no | grep GT7305`
    local model_GT7320=`echo $instenv_model_no | grep GT7320`
    local model_GT8320=`echo $instenv_model_no | grep GT8320`
    local model_WonderTV=`echo $instenv_model_no | grep WonderTV`
    if [ -n "$model_GT7301" ] || \
       [ -n "$model_GT7305" ] || \
       [ -n "$model_GT7320" ] || \
       [ -n "$model_GT8320" ]; then
        if [ -d "$local_path/GT_LOGO" ]; then
            export instenv_uboot_logo=$1/GT_LOGO
        fi
    elif [ -n "$model_WonderTV" ]; then
        if [ -d "$local_path/WonderTV" ]; then
            export instenv_uboot_logo=$1/WonderTV
        fi
    else
        export instenv_uboot_logo=$1
    fi
fi


info 1 "    u-boot-logo path is: $instenv_uboot_logo"

