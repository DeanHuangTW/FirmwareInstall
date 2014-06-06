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

#### Warn: don't change this script file name as export_data.wmt!sh depends on it.
#$1 is current path, don't use pwd

local_path="$1"

info 1 "    Processing customization in $local_path..."

# Display resolution
video_mode=`fbset | grep - | cut -d\  -f2 | sed 's/\"//g' | cut -d- -f1`

xres=`echo ${video_mode} | cut -dx -f1`
yres=`echo ${video_mode} | cut -dx -f2`

# such as 800x480_data.tar
file_name="${xres}x${yres}_data.tar"
datatar_file=$local_path/$file_name
if [ -f "$local_path/$instenv_model_no/$file_name" ]; then
    datatar_file=$local_path/$instenv_model_no/$file_name
fi

info 1 "    custmization package is: $datatar_file"

if [ -f $datatar_file ] && [ -n "$is_data_mounted" ]; then
    info 1 "    Restoring $datatar_file..."
    /bin/tar xf $datatar_file -C ${instenv_fs_data}
    #creat Download folder or GTS will failed
    dl_path=${instenv_fs_data}/media/0/Download
    mkdir -p ${dl_path}
    chmod 775 -R  ${dl_path}
    chown 1023:1023 -R ${dl_path}

    #backup data.tar to /system/.restore/ folder.
    cp $datatar_file $instenv_fs_system/.restore/data.tar
else
    info 1 "    Not found $datatar_file file."
fi

#pre-copy demo files to LocalDisk(data/media/ or data/media/0)
if [ -d $local_path/localdisk ] && [ -n "$is_data_mounted" ]; then
    #no single partition for Local, it is only a folder named "media" in Data partition
    dest_path=${instenv_fs_localdisk}
    if [ -f $datatar_file ]; then
        dest_path=${dest_path}/0
    fi
    mkdir -p ${dest_path}
    info 1 "    Copying localdisk to ${dest_path}..."
    /bin/cp -aR $local_path/localdisk/. ${dest_path}/

    chmod 770 ${instenv_fs_localdisk}
    chmod 775 -R ${instenv_fs_localdisk}/*
    chown 1023:1023 -R ${instenv_fs_localdisk}
fi

