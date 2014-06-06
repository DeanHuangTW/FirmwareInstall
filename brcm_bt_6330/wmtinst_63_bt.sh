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
if [ "$BT_model" != "BRCM6330" ]; then
    return 0
fi

info 1 "    Processing fs_patch for $instenv_model_no in $local_path..."

/bin/rm -rf ${instenv_fs_system}/lib/libbluetooth_em.so
/bin/rm -rf ${instenv_fs_system}/lib/libbluetooth_mtk_pure.so
/bin/rm -rf ${instenv_fs_system}/lib/libbt-vendor_6620.so
/bin/rm -rf ${instenv_fs_system}/lib/libbluetooth_mtk_6620.so
/bin/rm -rf ${instenv_fs_system}/lib/hw/bluetooth.mtk6620.so

if [ -d $local_path/system ] && [ -n "$is_sys_mounted" ]; then
    info 1 "    Copying system folder.."
    /bin/cp -aR $local_path/system/. ${instenv_fs_system}
fi
