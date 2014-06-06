#!/bin/sh
# autorun.sh
#
# WonderMedia Linux BSP auto installatopn script 
#
# This script is derived from VT8430 Linux BSP installation script.
#
# This shell script is for ash in busybox. Ash is not as smart as bash.
# Therefore, only the basic shell syntax can be used in ash.
# Please note that a bash shell script may not work in ash.
#
# Written by Vincent Chen <vincentchen@wondermedia.com.tw>
#
# Copyright 2008-2009 WonderMedia Corporation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY WONDERMEDIA CORPORATION ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL WONDERMEDIA CORPORATION OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.

# get_dir - get file location
# @top_dir
# @filename
# @search_dirs

top_dir=

get_dir ()
{
    for d in $@ ; do
        if [ -e "$d/$2" ]; then
            eval "$1=$d"
            break
        fi
    done
}

info()
{
    local ui="$1"
    shift

    if [ "$ui" == "0" ]; then
        echo "$@" > /dev/console 
    else
        uimsg "$@"
        echo "$@" > /dev/console     #out to console also for debug.
    fi
    
    # if have a debug folder, output to debug/log.txt file also.
    if [ -d $top_dir/debug ]; then
        echo "$@" >> $top_dir/debug/log.txt    
    fi
}

mount tmpfs /tmp/ -t tmpfs

#find the instenv_top_dir, for example /mnt/mmcblk0p1/FirmwareInstall
#get_dir top_dir installer/bin/bspinst_api.sh `find /mnt -maxdepth 2 -type d`
top_dir=`readlink -f $0 | xargs dirname | sed 's/\/installer//g'`

if [ -z $top_dir ]; then
    info 1 "Error: can not find install source. Abort!"
    exit 1
fi

#stop kernel animation, add usleep for kernel log
usleep 10
echo "0" > /proc/kernel_animation
usleep 10

#use low level cpu frequency
echo powersave  > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

rm -f $top_dir/debug/log.txt    
info 0 "top_dir is $top_dir"


#include other files
source $top_dir/installer/bin/bspinst_var.sh
source $top_dir/installer/bin/bspinst_api.sh
source $top_dir/installer/shellui/runui.sh

### update instenv_top_dir
instenv_top_dir=$top_dir

ln -s ${top_dir}/installer/bin/setenv "/bin/+setenv"

killall shellui 2>/dev/null
killall fb0tofb1 2>/dev/null
run_ui ${instenv_top_dir} $TYPE_UPDATE



# change current directory to the top dir after run_ui
cd $instenv_top_dir
export PATH=$instenv_top_dir/installer/bin:$PATH

#mdev -s
Quiet mount -t proc none /proc

#add_missing_files if it is not included in ramdisk
#tar zxf $src_dir/tools/mtd-utils*.tgz -C / >/dev/null 
#tar zxf $src_dir/tools/zlib*.tgz -C / >/dev/null 

local disp_para=`wmtenv get wmt.display.param`
disp_para0=`echo $disp_para | cut -d: -f1`
if [ "$disp_para0" == "8" ]; then
    info 1 "HDMI only product(TV Box/Dongle)"
    export HDMI_only=1
fi

if [ -n "$HDMI_only" ]; then
    #kill all LED Flash script
    killall TV_addon.sh 2>/dev/null
    #LED Flash indicate begin...
    TV/TV_addon.sh 2 &
fi

msg_title "WMT Android4.2 FW Upgrading ..."
msg_info "DON'T REMOVE INSTALLATION MEDIA..."

# install_modules: a string like "filesystem wload uboot env logo bootimg "
# if want to update few moduels such as wload and uboot, set install_modules as
# install_modules="wload uboot"
# Note: bootimg means both kernel and init ramdisk such as ramdisk.img/ramdisk_recovery.img
install_modules="systemdata wload uboot env logo_bootimg"

info 0 "Install below modules:"
info 0 "  $install_modules"

### start installation now...
do_install


## check any critical error during installation.
if [ $install_critical_error -eq 1 ]; then
    info 1 "WonderMedia Android FW installation ERROR!!!"
    unmount_all
    if [ -n "$HDMI_only" ]; then
        #LED ON indicate error
        killall TV_addon.sh 2>/dev/null
        TV/TV_addon.sh 1
    fi
    exit 1
fi

if [ $ROOT_DEV -eq $DEV_TF ] || [ $ROOT_DEV -eq $DEV_UDISK ]; then
     info 0 "restart udevd daemon"
     udevd --daemon
fi

sync
unmount_all

ratio 100
msg_info "PLEASE REMOVE INSTALLATION MEDIA..."
info 0 "PLEASE REMOVE INSTALLATION MEDIA..."

if [ ! -z "$instenv_endscript" ]; then
    info 1 "    Checking $instenv_endscript..."
    if [ -e "$instenv_endscript" ]; then
        source $instenv_endscript $instenv_endscript
        #. $instenv_endscript  $instenv_endscript
    fi
fi

if [ -n "$HDMI_only" ]; then
    #LED OFF indicate OK
    killall TV_addon.sh 2>/dev/null
    sleep 2
    TV/TV_addon.sh 0
fi
# check $0 (this file) to know when installation media is removed.
while [ -e $0 ]; do
    read -t 1 key
    if [ $? -eq 0 ]; then
        break
    fi
done

msg_info "System will reboot now..."
exit_ui "OK"
reboot

