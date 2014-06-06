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

local tvShell="TVShell.apk"
if [ -f $instenv_fs_data/app/$tvShell ] || \
   [ -f $instenv_fs_system/vendor/app/$tvShell ] || \
   [ -f $instenv_fs_system/app/$tvShell ]; then
    info 1 "    Copying resource for $tvShell..."
    tar zxf $local_path/Res_TVShell.tgz -C ${instenv_fs_root} >/dev/null
fi

if [ -n "$HDMI_only" ]; then
    rm -rf $instenv_fs_system/app/WmtLauncher.apk
    rm -rf $instenv_fs_system/app/Calculator.apk
    rm -rf $instenv_fs_system/app/Calendar.apk
    rm -rf $instenv_fs_system/app/Contacts.apk
    rm -rf $instenv_fs_system/app/DeskClock.apk
    rm -rf $instenv_fs_system/app/Email.apk
    rm -rf $instenv_fs_system/app/Exchange2.apk
    rm -rf $instenv_fs_system/app/Galaxy4.apk
    rm -rf $instenv_fs_system/app/HoloSpiralWallpaper.apk
    rm -rf $instenv_fs_system/app/LiveWallpapers.apk
    rm -rf $instenv_fs_system/app/LiveWallpapersPicker.apk
    rm -rf $instenv_fs_system/app/MagicSmokeWallpapers.apk
    rm -rf $instenv_fs_system/app/VisualizationWallpapers.apk
    rm -rf $instenv_fs_system/app/OpenWnn.apk
    rm -rf $instenv_fs_system/app/LatinIME.apk
    rm -rf $instenv_fs_system/app/Phone.apk

    rm -rf $instenv_fs_system/vendor/app/MyRecorder.apk

    cp optional/wmt_cursor.png ${instenv_fs_system}/wmtapp/
    cp optional/PinyinIME.apk ${instenv_fs_system}/app/

    #enable miracast sink for TV box/dongle
    setprop ro.wmt.miracast.enable true
fi

