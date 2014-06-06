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

info 0 "    Processing in $local_path..."

if [ "$touch_panel" == "disable" ]; then
    info 0 "    Touch panel is disable"
else
    info 1 "    Copying CTP_FW to system folder.."
    /bin/cp -aR $local_path/CTP_FW/* ${instenv_fs_system}/etc/firmware/
fi

