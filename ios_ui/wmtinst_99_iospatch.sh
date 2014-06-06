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

if [ -z "$enable_iosUI" ]; then
    return 0
fi

info 1 "    Processing patch in $local_path..."

if [ -d $local_path/system ] && [ -n "$is_sys_mounted" ]; then
    info 1 "    Copying system folder.."
    /bin/cp -aR $local_path/system/. ${instenv_fs_system}
    setprop persist.wmt.uistyle ios
    setprop ro.wmt.bootanim.args 0,400,400,0

    info 1 "    Delete some Android apks\n"
    rm $instenv_fs_system/app/Launcher2.apk
    rm $instenv_fs_system/app/WmtLauncher.apk
    rm $instenv_fs_system/app/SystemUI.apk
    rm $instenv_fs_system/app/Settings.apk
    rm $instenv_fs_system/app/LatinIME.apk
    rm $instenv_fs_system/app/Gallery2.apk
    rm $instenv_fs_system/vendor/app/WmtMusic.apk
fi
