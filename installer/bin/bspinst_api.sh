# bspinst_api.sh
#
# Linux BSP installer drawing API for WonderMedia ARM SoC.
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


install_critical_error=0

wmt_mknod ()
{
    mknod $@
    if [ $? -ne 0 ] ; then
	info 0 "mknod $@ failed, retry once more!"
        sleep 1
        mknod $@
    fi
    
    if [ $? -ne 0 ] ; then
        install_critical_error=1
        return 1
    fi
}

# wmt_fdisk - fdisk TF/UDisk
# @patition_cfg in shell script
# @dev_name of TF/UDisk
wmt_fdisk ()
{
    local partition_cmd=$1
    local dev_name=$2

    local t=5
    while [ $t -gt 0 ]; do
        if [ -e $dev_name ]; then
            break;
        else
            info 0 "[WMT] waiting for root device($dev_name) ..."
            if [ $t -eq 1 ]; then
                info 1 "Error: Root device($dev_name) not found, upgrading stopped!"
                return 1
            else
                sleep 1
                let "t = t - 1"
            fi
        fi
    done
    
    info 1 "Fdisk root device($dev_name) ..."

    if [ $instenv_bootdev == "TF" ]; then
        #Jody: does it need 'p' here?
        umount ${dev_name}p*
        ${partition_cmd} | fdisk $dev_name
        sleep 5

        #Jody: if system don't create dev-nod for new MMC partition, we do it
        wmt_mknod "${dev_name}p1" b 179 9
        wmt_mknod "${dev_name}p2" b 179 10
        wmt_mknod "${dev_name}p3" b 179 11
        wmt_mknod "${dev_name}p5" b 179 12
        wmt_mknod "${dev_name}p6" b 179 13
        wmt_mknod "${dev_name}p7" b 179 14
    elif [ $instenv_bootdev == "UDISK" ]; then
        umount ${dev_name}*
        ${partition_cmd} | fdisk $dev_name
    fi
    
    return $install_critical_error
}

unmount_all ()
{
    cd /
    sync
    if [ $instenv_bootdev != "NAND" ]; then
        /bin/umount $MOUNT_BOOT
    fi
    
    /bin/umount $instenv_fs_data    2>/dev/null
    /bin/umount $instenv_fs_system    2>/dev/null

    cd $instenv_top_dir     #restore our current dir.
}

# Quiet - do command in silence
# @command
Quiet ()
{
    $@ 2>/dev/null >/dev/null

    return $?
}



# get_mtd - get mtd device by name
# @name
get_mtd ()
{
    desc=`echo $1 | sed 's/\ /\\\ /g'`
    cat /proc/mtd | grep "\"$desc\"" | cut -d: -f1 | sed 's/mtd/\/dev\/mtd/g'
}

# get_mtdblock - get mtdblock device by name
# @name
get_mtdblock ()
{
    get_mtd "$1" | sed 's/mtd/mtdblock/g'
}

# get_mtd_len - get mtd length by name
# @name
get_mtd_len ()
{
    tmp=`cat /proc/mtd |grep "\"$1\""| cut -d\  -f 2`
    len=`printf "0x%x" 0x$tmp`

    echo $len
}

# sf_inst - copy from a file onto SPI flash
# @name
# @file
#
# The default search path is the current folder
# if $src_dir is invalid.
sf_inst ()
{
    local name=$1
    local file=$2
    local mtd=

    mtd=`get_mtd "$name"`

    if [ -z "$mtd" ]; then
        info 1 "Error: No MTD partition called $name."
        return 1
    fi

    if [ -e "$file" ]; then
        printf "Update %s to %s ... " $file $mtd
        Quiet flash_erase $mtd 0 0
        if [ -e /usr/sbin/flashcp ]; then
            Quiet flashcp $file $mtd
        else
            cat $file > $mtd
        fi
        printf "done\n"
    else
        info 1 "Error: not found $file, skip update $name."
    fi
}

# nand_erase: erase nand partition
# @discription of nand partition
# 
nand_erase ()
{
    local name=$1
    local mtd=

    mtd=`get_mtd "$name"`

    if [ -z "$mtd" ]; then
        info 1 "No MTD partition called $name."
        return 1
    fi

    if [ ! -e "$mtd" ]; then
        return 2
    fi
    
    info 0 "flash eraseall $mtd ... "
    Quiet flash_erase $mtd 0 0
    info 0 "flash eraseall done, ret $?"
    return 0
}

# nand_inst - copy from a file onto Nand flash
# @name
# @file
#
# The default search path is the current folder
# if $src_dir is invalid.
nand_inst ()
{
    local name=$1
    local file=$2
    local mtd=`get_mtd "$name"`

    if [ -z "$mtd" ]; then
        info 1 "Error: No MTD partition called $name."
        return 1
    fi

    if [ ! -e "$file" ]; then
        return 2
    fi

    printf "Update %s to %s ... " $file $mtd
    nand_erase $name
    nandwrite -p $mtd $file
    printf "done\n"
    
    return 0
}



get_mtd_offset ()
{
    mtdlist=`cat /proc/wmt_mtd|cut -d\  -f2,3|tr \  @|sed 's/"//g'`

    flg_error="error"
    offset=$flg_error
    for i in $mtdlist; do
        mtd=`echo $i|cut -d@ -f2`
        if [ "$mtd" == "$1" ]; then
            offset=`echo $i|cut -d@ -f1`
            break;
        fi
    done
    
    if [ "$offset" == $flg_error ]; then
        echo "[WMT] *E* Failed to get offset of $1"
    else
        echo "0x$offset"
    fi
}


# get_mtd_num
# 
# get the mtd number by mtdblock's name
#
get_mtd_num()
{
    mtd_block=`get_mtdblock "$1"`
    mtd_num=`echo ${mtd_block##*mtdblock}`
    echo $mtd_num
}

# generate a random MAC address
# random_mac
#
# Usage:
#     random_mac
random_mac ()
{
    local name="ethaddr"
    local random=`head -200 /dev/urandom | sha1sum`

    local a1=`echo $random | cut -c1-2`
    local a2=`echo $random | cut -c3-4`
    local a3=`echo $random | cut -c5-6`
    
    setenv $name 00:40:63:$a1:$a2:$a3
    info 1 "Random Mac address : 00:40:63:$a1:$a2:$a3"
}

# generate a random SN
# random_sn
#
# Usage:
#     random_sn
random_sn ()
{
    local name="androidboot.serialno"
    local SN=`head -c 6 /dev/urandom | hexdump | cut -c9-23 | tr '\n' ' ' | sed 's/ //'g`
    
    setenv $name $SN
    info 1 "Random SN: $SN"
}

# restore_env
# @@ uboot environment variable name
# Restore some uboot environment variables
# Usage:
#     restore_env foo bar
restore_env()
{
    for name in $@; do 

        local value=`wmtenv get $name`
        local ret=`echo $value | grep failed`
    
        if [ "$value" = "" ] || [ -n "$ret" ]; then
            info 0 "restore $name not found."
        else 
            info 0  "restore_env: $name=$value"
            setenv $name $value
        fi
    done
}

# do_setenv
# @uboot_env    U-boot script in plain text format
# @mtd        MTD device used by U-Boot env.
# @flag        active flag
#
# Save uboot environment variables from u-boot plain text script
#
# Usage:
#     do_setenv /mnt/mmcblk0p1/env/uboot_env_sf /dev/mtd3 1
do_setenv ()
{
    local infile=$1
    local mtd=$2
    local flag=$3

    local crc32=installer/bin/crc32
    local outfile=/tmp/uboot_env.raw
    local tmpfile=/tmp/uboot_env.tmp

    dd if=/dev/zero of=${outfile} bs=1k count=64

    dos2unix -u ${infile}

    cat ${infile} | \
    tr '\n' '~' | sed 's/\\~//g' | tr '~' '\n' | \
    sed 's/\ \+/ /g' | \
    grep setenv | sed 's/setenv //' | sed 's/ /=/' | \
    sed 's/\\;/;/g' | tr "\n" "\0" > ${tmpfile}

    dd if=${tmpfile} of=${outfile} bs=1 seek=5 count=65531 conv=notrunc

    $crc32 -s 5 -x 1 ${outfile}
    $crc32 -s 5 -r ${outfile} > ${tmpfile}
    printf "\x${flag}" >> ${tmpfile}
    dd if=${tmpfile} of=${outfile} bs=1 seek=0 count=5 conv=notrunc

    flash_erase $mtd 0 0
    cat ${outfile} > $mtd

    #mv ${tmpfile} ${tmpfile}.${flag}
    #cp ${outfile} ${outfile}.${flag}
    rm ${tmpfile} ${outfile}
}



#
# Add additional uboot environment variables
#
# Usage:
#     env_addon outfile
env_addon()
{         
    info 0 "Adding additionl uboot env..."

    local value=`wmtenv get wmt.ethaddr.persist`
    if [ "$value" = "1" ]; then
        restore_env wmt.ethaddr.persist ethaddr
        info 1 "Don't change mac address"
    else 
        info 0 "No mac address customization"
        random_mac
    fi

    local SN=`wmtenv get androidboot.serialno`
    local ret=`echo $SN | grep failed`
    if [ "$SN" = "" ] || [ -n "$ret" ]; then
        info 1 " serialno not found, generate it by random."
        random_sn
    else
        info 1 " restore serialno."
        restore_env androidboot.serialno
    fi
    restore_env serialnum pcba.serialno uuid.ro
    restore_env wmt.btaddr.persist btaddr
}

#
# set uboot environment variables from u-boot plain text script
inst_env ()
{
    info 1 "Installing U-Boot env. cfg. to SF."

    #clean it to remove duplicated items
    wmtclean /tmp/setenv.out > /tmp/setenv.clean

    #DEBUG
    Quiet cp /tmp/setenv.out debug/setenv.out
    Quiet cp /tmp/setenv.clean debug/setenv.clean
    
    mtd_name="u-boot env. cfg. 1-SF"
    mtd=`get_mtd "${mtd_name}"`

    if [ ! -z "${mtd}" ]; then
        do_setenv /tmp/setenv.clean ${mtd} 1
    else
        info 1 "No MTD partition called ${mtd_name}."
        install_critical_error=1
        return 1
    fi

    mtd_name="u-boot env. cfg. 2-SF"
    mtd=`get_mtd "${mtd_name}"`

    if [ ! -z "${mtd}" ]; then
        do_setenv /tmp/setenv.clean ${mtd} 0
    else
        info 0 "No MTD partition called ${mtd_name}."
    fi
}


#
# PLEASE DON'T MODIFY FUNCTIONS ABOVE THIS LINE.
# THOSE FUNCTIONS ARE THE HEART OF BSPINST2.
#
inst_wload()
{
    local wload_name=$instenv_wload

    local mtd_wload=`get_mtd "w-load-SF"`
        
    if [ -z "$instenv_wload" ]; then
        local wload_updateid=`strings ${mtd_wload}  | grep "UPDATEID_"` 
        info 0 "Select w-load according to $wload_updateid ..."
        if [ -z "$wload_updateid" ]; then
            info 0 "Error: old w-load in board, please select a proper w-load in .fwc "
            install_critical_error=1
            return 1
        else
            if [ "$wload_updateid" == "UPDATEID_DDR3_800M_800M_32bit_4_512MB" ]; then
                wload_name="*_DDR3_5_3_2_4_512MB"
            elif [ "$wload_updateid" == "UPDATEID_DDR3_800M_800M_16bit_2_256MB" ]; then
                wload_name="*_DDR3_5_3_1_2_256MB"
            else
                wload_name=`echo $wload_updateid | sed 's/UPDATEID/*/g'`
            fi
    
            info 0 wload_wild_name=$wload_name    
            wload_name=`find firmware -name ${wload_name}.bin`
            info 1 "Auto probe wload_name=$wload_name"
        fi
    fi

    if [ -z "$wload_name" ]; then
        info 1 "Error: No wload file defined. Abort!"
        install_critical_error=1
        return 1
    fi

    if [ ! -f "$wload_name" ]; then
        info 1 "Error: can not find wload: $wload_name. Abort!"
        install_critical_error=1
        return 1
    fi
    
    local buildno_board=`strings ${mtd_wload} | grep "BUILDID_"` 
    local buildno_file=`strings ${wload_name} | grep "BUILDID_"` 

    if [ -z "$buildno_file" ]; then
        info 1 "Error: wload:$wload_name invalid, Abort!"
        install_critical_error=1
        return 1
    fi
    
    info 0 "wload BUILDID board: $buildno_board"
    info 0 "wload BUILDID file : $buildno_file"

    cat ${mtd_wload} > /tmp/board.wload
    local wsize=`stat -c%s $wload_name`

    dd if=/tmp/board.wload of=/tmp/board.wload2 bs=$wsize count=1

    if diff --brief /tmp/board.wload2 $wload_name; then
        info 1 "Skipped same $wload_name."
    else
        info 1 "Installing $wload_name..."
        sf_inst "w-load-SF" "$wload_name"
    fi

    Quiet cp /tmp/board.wload debug/board.wload
    Quiet cp /tmp/board.wload2 debug/board.wload2
    rm /tmp/board.wload /tmp/board.wload2
    return 0
}

inst_uboot()
{
    if [ ! -f "$instenv_uboot" ]; then
        info 1 "Uboot:$instenv_uboot not found, Abort!"
        install_critical_error=1
        return 1
    else
        info 0 "Uboot = $instenv_uboot"
    fi
    
    local mtd_uboot=`get_mtd "u-boot-SF"`
    cat ${mtd_uboot} > /tmp/board.uboot
    local usize=`stat -c%s $instenv_uboot`

    dd if=/tmp/board.uboot of=/tmp/board.uboot2 bs=$usize count=1

    if diff --brief /tmp/board.uboot2 $instenv_uboot; then
        info 1 "Skipped same $instenv_uboot."
    else
        info 1 "Installing $instenv_uboot..."
        sf_inst "u-boot-SF" "$instenv_uboot"
    fi
}


update_logo()
{
    info 1 "Installing u-boot logo to NAND..."
    
    local name="${BLK_NAND_LOGO}"
    local logo_dir="$instenv_logo_path"
    local mtd=
    
    mtd=`get_mtd "$name"`

    if [ -z "$mtd" ]; then
        info 1 "Error: No MTD partition named $name."
        install_critical_error=1
        return 1
    fi

    if [ ! -e "$mtd" ]; then
        info 1 "Error: not exist MTD partition($mtd)!"
        install_critical_error=1
        return 1
    fi

    info 1 "Erasing LOGO partition(Nand)..."
    nand_erase $name

    
    #use customize logo firstly
    local uboot_logo_file=$instenv_uboot_logo/u-boot-logo.bmp
    local uboot_logo2_file=$instenv_uboot_logo/u-boot-logo2.bmp
    local charge_logo_file=$instenv_uboot_logo/charge-logo.bmp
    #use default logo if no customize logo
    if [ ! -f $uboot_logo_file ]; then
        uboot_logo_file=$logo_dir/u-boot-logo.bmp
    fi
    
    if [ ! -f $charge_logo_file ]; then
        charge_logo_file=$logo_dir/charge-logo.bmp
    fi
    
    local out_logo="/tmp/logo.out"
    if [ -f $uboot_logo_file ] &&
       [ -f $charge_logo_file ] ; then
        #merge two logo into a single file
        cat $uboot_logo_file $charge_logo_file > $out_logo
        if [ $? -ne 0 ] ; then
            info 1 "Error: merge logo files failed!"
            install_critical_error=1
            return 1
        fi

        local logosize_logo2
        if [ -f $uboot_logo2_file ]; then
            #merge second logo
            cat $uboot_logo2_file >> $out_logo
            if [ $? -ne 0 ] ; then
                info 1 "Error: merge logo2 files failed!"
                install_critical_error=1
                return 1
            fi
            logosize_logo2=`ls $uboot_logo2_file -al | sed 's/ \+/ /g' | cut -d' ' -f5`
            setenv wmt.logosize.logo2 `printf "0x%x" $logosize_logo2`
            #uboot will show logo2 if setenv wmt.logo.index 1
        fi

        local logosize_uboot=`ls $uboot_logo_file -al | sed 's/ \+/ /g' | cut -d' ' -f5`
        local logosize_charge=`ls $charge_logo_file -al | sed 's/ \+/ /g' | cut -d' ' -f5`
        setenv wmt.logosize.uboot `printf "0x%x" $logosize_uboot`
        setenv wmt.logosize.charge `printf "0x%x" $logosize_charge`

        #cp logo data to system/.restore folder for OTA package's tool
        mkdir -p ${instenv_fs_system}/.restore
        Quiet cp $out_logo  ${instenv_fs_system}/.restore/  
        nandwrite -p $mtd $out_logo
        if [ $? -ne 0 ] ; then
            info 1 "Error: write logo failed!"
            install_critical_error=1
            return 1
        fi
    else
        info 1 "Error: missing $uboot_logo_file or $charge_logo_file!"
        install_critical_error=1
        return 1
    fi
        
    return 0
}


get_ramdisk_path()
{
    local ret_path="firmware/$1.img"
    
    if [ $instenv_bootdev == "TF" ] ; then        
                        
        if [ ! -f firmware/$1-$instenv_bootdev.img ]; then
            info 1 "Error: no firmware/$1-$instenv_bootdev.img found, your may need to run prepare_android_rootfs.sh again"
            install_critical_error=1
            return 1                        
        fi
        ret_path="firmware/$1-$instenv_bootdev.img"       
    fi

    echo "$ret_path"
}

inst_logo_bootimg()
{
    if [ ! -f "$instenv_kernel" ]; then
        info 1 "Error: can not find kernel: $instenv_kernel. Abort!"
        install_critical_error=1
        return 1
    fi

    #can't modify ramdisk.img/ramdisk-recovery.img during FW install, or checksum will failed when OTA
    local ramdisk_path=`get_ramdisk_path "ramdisk"`
    info 0 "ramdisk_path = $ramdisk_path, kernel = $instenv_kernel"
    mkbootimg --kernel $instenv_kernel --ramdisk $ramdisk_path -o /tmp/boot.img
    if [ $? -ne 0 ] ; then
        info 1  "Error: failed to make boot.img! Abort!"
        install_critical_error=1
        return 1
    fi
    local recovery_path=`get_ramdisk_path "ramdisk-recovery"`
    mkbootimg --kernel $instenv_kernel --ramdisk $recovery_path -o /tmp/recovery.img
    if [ $? -ne 0 ] ; then
        info 1  "Error: failed to make recovery.img! Abort!"
        install_critical_error=1
        return 1
    fi

    if [ $instenv_bootdev == "NAND" ]; then
        local mtd=`get_mtd "${BLK_NAND_LOGO}"`
        if [ "$mtd" == "" ] ; then
            info 1 "Error: Cannot find ${BLK_NAND_LOGO} partition in NAND, Abort!"
            install_critical_error=1
            return 1
        fi

        #disable garbage collection of yaffs2, or it will be too slow for ESLC(only for Hynix nand)
        sync
        echo 0 >  /sys/module/yaffs/parameters/yaffs_bg_enable
        info 1 "Installing boot.img to NAND..."
        nand_inst "${BLK_NAND_BOOT}" /tmp/boot.img
        setenv boot-img-len `ls /tmp/boot.img -al | sed 's/ \+/ /g' | cut -d' ' -f5`
        inc_ratio 5

        info 1 "Installing recovery.img to NAND..."
        nand_inst "${BLK_NAND_RECOV}" /tmp/recovery.img
        setenv recov-img-len `ls /tmp/recovery.img -al | sed 's/ \+/ /g' | cut -d' ' -f5`        
        inc_ratio 5

        update_logo
        #enable garbage collection of yaffs2
        echo 1 >  /sys/module/yaffs/parameters/yaffs_bg_enable
    elif [ $instenv_bootdev == "TF" ] || [ $instenv_bootdev == "UDISK" ]; then
        local mtd_kernel=
        if [ $instenv_bootdev == "TF" ]; then
            info 1 "Prepare kernel partition(TF)..."
            mtd_kernel=/dev/mmcblk1p1
        elif [ $instenv_bootdev == "UDISK" ]; then
            info 1 "Prepare kernel partition(UDISK)..."
            mtd_kernel=/dev/sda1
        fi

        umount ${mtd_kernel}
        mkdosfs ${mtd_kernel}
        if [ $? -ne 0 ] ; then
            info 1  "Error: failed to format kernel partition! Abort!"
            install_critical_error=1
            return 1
        fi

        /bin/mkdir -p $MOUNT_BOOT
        mount ${mtd_kernel} $MOUNT_BOOT
        if [ $? -ne 0 ] ; then
            info 1 "Error: failed to mount kernel partition. Abort!"
            install_critical_error=1
            return 1
        fi
        info 1 "Installing boot.img/recovery.img/logo ..."
        /bin/cp -af /tmp/boot.img $MOUNT_BOOT
        /bin/cp -af /tmp/recovery.img $MOUNT_BOOT
        /bin/cp -af $instenv_uboot_logo/u-boot-logo.bmp $MOUNT_BOOT
        if [ -f $instenv_uboot_logo/charge-logo.bmp ]; then
            #use customize logo first
            /bin/cp -af $instenv_uboot_logo/charge-logo.bmp $MOUNT_BOOT            
        else
            #use default logo
            /bin/cp -af $instenv_logo_path/charge-logo.bmp $MOUNT_BOOT            
        fi

    else
        info 1 "Error: unknown root device:$instenv_bootdev! Abort!"
        install_critical_error=1
        return 1
    fi
}


format_disk()
{
    if [ $instenv_bootdev == "TF" ]; then
        if [ -e "installer/bin/partition.sh" ]; then
            wmt_fdisk "installer/bin/partition.sh" "/dev/mmcblk1"
        else
            info 1 "Partition file not found, upgrading stopped!"
            return 1
        fi
    elif [ $instenv_bootdev == "UDISK" ]; then
        if [ -e "installer/bin/partition.sh" ]; then
            wmt_fdisk "installer/bin/partition.sh" "/dev/sda"
        else
            info 1 "Partition file not found, upgrading stopped!"
            return 1
        fi
    fi
    
    return $?
}


inst_systemdata()
{
    local mnt_system=$instenv_fs_system
    local mnt_data=$instenv_fs_data

    local mtd_system=
    local mtd_data=
    local mtd_cache=

    local prev_ratio=$CompleteRatio
    local _ratio=
    local ret=

    #mount /android/data , /android/system
    if [ $instenv_bootdev == "NAND" ]; then
        mtd_system=`get_mtdblock "${BLK_NAND_SYS}"`
        mtd_data=`get_mtdblock "${BLK_NAND_ANDROIDDATA}"`

        info 1 "Erasing System partition(Nand)..."
        umount ${mtd_system} 2>/dev/null
        nand_erase ${BLK_NAND_SYS}
        if [ $? -ne 0 ] ; then
            info 1 "Error: Failed to format FileSystem partition(NAND)..."
            install_critical_error=1
            return 1
        fi
        
        info 1 "Erasing Data partition(Nand)..."
        umount ${mtd_data} 2>/dev/null
        nand_erase "${BLK_NAND_ANDROIDDATA}"

        info 1 "Erasing Cache/misc/keydata partition(Nand)..."
        nand_erase "${BLK_NAND_MISC}"
        nand_erase "${BLK_NAND_ANDROIDCACHE}"
        #keydata is for widevine
        nand_erase "${BLK_NAND_KEYDATA}"
        
        mount -t yaffs2 -o rw $mtd_system $mnt_system
        mount -t yaffs2 -o rw $mtd_data $mnt_data
    elif [ $instenv_bootdev == "TF" ] || [ $instenv_bootdev == "UDISK" ]; then
        format_disk
        if [ $? -ne 0 ] ; then
            info 1 "Error: in format_disk($instenv_bootdev)"
            install_critical_error=1
            return 1
        fi
        if [ $instenv_bootdev == "TF" ]; then
            mtd_system=/dev/mmcblk1p2
            mtd_data=/dev/mmcblk1p7
            mtd_cache=/dev/mmcblk1p5
        elif [ $instenv_bootdev == "UDISK" ]; then
            mtd_system=/dev/sda2
            mtd_data=/dev/sda7
            mtd_cache=/dev/sda5
        fi

        info 1 "Erasing System partition..."
        umount ${mtd_system}
        mke2fs -T ext4 ${mtd_system}
        if [ $? -ne 0 ] ; then
            info 1 "Error: Failed to format System partition!"
            install_critical_error=1
            return 1
        fi

        info 1 "Erasing Data partition..."
        umount ${mtd_data}
        mke2fs -T ext4 ${mtd_data}
        if [ $? -ne 0 ] ; then
            info 1 "Error: Failed to format Data partition!"
            install_critical_error=1
            return 1
        fi

        info 1 "Erasing Cache partition..."
        umount ${mtd_cache}
        mke2fs -T ext4 ${mtd_cache}
        #TODO: why cache will be failed?
        #if [ $? -ne 0 ] ; then
        #    info 1 "Error: Failed to format Cache partition!"
        #    install_critical_error=1
        #    return 1
        #fi
        
        mount -t ext4 ${mtd_system} ${mnt_system}
        if [ $? -ne 0 ] ; then
            info 1 "Error: Failed to mount System partition!"
            install_critical_error=1
            return 1
        fi

        mount -t ext4 ${mtd_data} ${mnt_data}
    else
        info 1 "Error: Unknown root device!"
        install_critical_error=1
        return 1
    fi
    
    if [ $? -ne 0 ] ; then
        info 1 "Error: system/data partition init failed!"
        install_critical_error=1
        return 1
    fi

    export is_data_mounted=`mount | grep \/data`
    export is_sys_mounted=`mount | grep \/system`

    #install all *.tgz in firmware folder
    info 1 "Installing tgz packages..."
    pkgtotal=`ls -1 firmware/*.tgz | wc -l`
    pkgcount=0
    for f in `ls -1 firmware/*.tgz` ; do
        let 'pkgcount = pkgcount + 1'
        _ratio=`expr $prev_ratio + \( 45 - $prev_ratio \) \* $pkgcount / $pkgtotal`
        ratio $_ratio
        info 1 "    $f"
        info 0 "Install $f ($pkgcount / $pkgtotal)"
        tar zxf $f -C ${instenv_fs_root} >/dev/null
    done

    #install all *.tar in firmware folder
    info 1 "Installing tar packages..."
    pkgtotal=`ls -1 firmware/*.tar | wc -l`
    pkgcount=0
    for f in `ls -1 firmware/*.tar` ; do
        let 'pkgcount = pkgcount + 1'
        _ratio=`expr $prev_ratio + \( 45 - $prev_ratio \) \* $pkgcount / $pkgtotal`
        ratio $_ratio
        info 1 "    $f"
        info 0 "Install $f ($pkgcount / $pkgtotal)"
        tar xf $f -C ${instenv_fs_root} >/dev/null
    done
	
	
    # set all ko files as rw-r-r permission
    find ${instenv_fs_system}/modules -type f | xargs chmod 644

    #make backup dir for factory restore, all pre-install data/app will be backup in this folder
    mkdir -p ${instenv_fs_system}/.restore/data_app
    mkdir -p ${instenv_fs_data}/app

    #backup .fwc and modules.xml
    cp -v config/+*.fwc ${instenv_fs_system}/wmtapp/
    cp -v config/modules.xml ${instenv_fs_system}/wmtapp/
    
    sync
    
    return 0
}

# this function only format and mount localdisk
# demo file will be copied by hook in fs_patch
inst_localdisk()
{
    #no single partition for Local, it is only a folder named ""in Data partition
    return 0
}


#
# change special case after some installation steps are done.
# wload is updated so we can know ddr_size
# and uboot-env is not installed so we can setenv.
#
process_special()
{
   if [ $instenv_bootdev == "NAND" ]; then
        setenv boot-NAND_mtd `get_mtdblock ${BLK_NAND_BOOT}`
        setenv boot-NAND_ofs `get_mtd_offset ${BLK_NAND_BOOT}`
        setenv boot-NAND_len `get_mtd_len ${BLK_NAND_BOOT}`
    
        setenv recov-NAND_mtd `get_mtdblock ${BLK_NAND_RECOV}`
        setenv recov-NAND_ofs `get_mtd_offset ${BLK_NAND_RECOV}`
        setenv recov-NAND_len `get_mtd_len ${BLK_NAND_RECOV}`
    
        setenv misc-NAND_mtd `get_mtdblock ${BLK_NAND_MISC}`
        setenv misc-NAND_ofs `get_mtd_offset ${BLK_NAND_MISC}`
        setenv misc-NAND_len `get_mtd_len ${BLK_NAND_MISC}`
    
        setenv filesystem-NAND_mtd `get_mtdblock ${BLK_NAND_SYS}`
        setenv filesystem-NAND_ofs `get_mtd_offset ${BLK_NAND_SYS}`
        setenv filesystem-NAND_len `get_mtd_len ${BLK_NAND_SYS}`
    
        local uboot_logo_ofs=`get_mtd_offset ${BLK_NAND_LOGO}`
    
        setenv wmt.nfc.mtd.u-boot-logo `printf "0x%x" $uboot_logo_ofs`
    elif [ $instenv_bootdev == "TF" ]; then
        info 0 "Aready modified uboot env of logocmd/ota_normal/ota_recovery for TF in modules.xml"
        setenv misc-TF_part 1:6
    elif [ $instenv_bootdev == "UDISK" ]; then
        info 0 "Aready modified uboot env of logocmd/ota_normal/ota_recovery for UDISK in modules.xml"
    else
        info 1 "Error: unkown root device:$instenv_bootdev"
    fi

    setenv wmt.boot.dev $instenv_bootdev


    ##determine mem-size
    local mtd_wload=`get_mtd "w-load-SF"`
    local wload_updateid=`strings ${mtd_wload}  | grep "UPDATEID_"` 
    local ddr_size=`echo ${wload_updateid} | cut -d_ -f7`
    instenv_ddrsize=$ddr_size
    info 0 "[WMT] wload_updateid: $wload_updateid, ddr_size = $ddr_size"
    if [ "$ddr_size" == "512MB" ]; then
        if [ -n "$HDMI_only" ]; then
            info 0 "[WMT] set memtotal for HDMI&512M DDR."
            setenv wmt.ge.param 1:24:-1:8
            setenv memtotal 414M
            setenv mbsize 73M
        else
            info 0 "[WMT] set memtotal for MID&512M DDR."
            #use default wmt.ge.param
            setenv memtotal 426M
            setenv mbsize 73M
        fi
        setenv wmt.multi.vd.max 2
    elif [ "$ddr_size" == "1024MB" ]; then
        if [ -n "$HDMI_only" ]; then
            info 0 "[WMT] set memtotal for HDMI&1G DDR."
            setenv wmt.ge.param 1:24:-1:8
            setenv memtotal 886M
            setenv mbsize 113M
        else
            info 0 "[WMT] set memtotal for MID&1G DDR."
            #use default wmt.ge.param
            setenv memtotal 898M
            setenv mbsize 113M
        fi
        #use default wmt.multi.vd.max
    else
        info 1 "Error: can not determine ddrsize($ddr_size), Abort!"
        #comment following to ignore this mistake temp if need
        install_critical_error=1
        return 1
    fi

    if [ -n "$special_memtotal" ]; then
        info 1 "[WMT] set special memtotal for $instenv_model_no."
        setenv memtotal $special_memtotal
    fi

    if [ -n "$special_mbsize" ]; then
        info 1 "[WMT] set special mbsize for $instenv_model_no."
        setenv memtotal $special_mbsize
    fi
    
    if [ -n "$HDMI_only" ]; then
        setenv wmt.lcd.power 
    fi

    return 0
}


export_instenv()
{
    printf "\n\n=======export below instenv_ values to script=======\n"
    for i in $@; do
        export $i
        echo `export | grep $i=`
    done
}


#
# find the activated fwc file, set the basename to $instenv_model_no
# also get the $instenv_bootdev
#
find_activated_fwc()
{
    instenv_model_no=""
    local fwc=""
    active_file=`ls -1 config/+*.fwc | wc -l`
    if [ "$active_file" == "1" ]; then
        info 1 "use special(+) config"
        fwc=`ls config/+*.fwc | cut -d+ -f2 | sed 's/.fwc$//'`
    elif [ "$active_file" == "0" ]; then
        info 1 "try to use default config saved in uboot env"
        fwc=`wmtenv get wmt.model.no`
    else
        info 1 "Error: more than one .fwc marked as activated. Abort!"
        install_critical_error=1
        return 1
    fi

    if [ "$fwc" == "" ]; then
        info 1 "Error: no proper .fwc file. Abort!"
        install_critical_error=1
        return 1
    else
        instenv_model_no=$fwc

        local fwc_file="config/+"$instenv_model_no".fwc"
        if [ ! -f $fwc_file ]; then
            fwc_file="config/"$instenv_model_no".fwc"
        fi
        #search search like <BOOTDEV name="TF" />  or <BOOTDEV name="NAND" />
        local temp=`grep "<BOOTDEV" $fwc_file`
        if [ $? -ne 0 ]; then
            instenv_bootdev="NAND"
        else
            instenv_bootdev=`echo $temp | cut  -d\" -f2`
        fi

        if [ $instenv_bootdev == "TF" ]; then
            :
        elif [ $instenv_bootdev == "NAND" ]; then
            :
        else
            install_critical_error=1
            info 1 "Error: unknown boot device: $instenv_bootdev. Abort!"
            return 1
        fi

        return 0
    fi
}


process_fwc()
{
    local fwc_file=$1
    
    # parse fwc file and generate a sh script file then run it.
    if ! xml2sh config/modules.xml $fwc_file > /tmp/fwc.sh; then
        info 1 "File $fwc_file can not be parsed. Abort!"
        install_critical_error=1
        return 1
    fi

    chmod +x /tmp/fwc.sh
    #DEBUG
    Quiet cp /tmp/fwc.sh debug/fwc.sh

    export setprop_file=/tmp/setprop.out      #used by setprop 
    export setenv_file=/tmp/setenv.out        #used by setenv 
    rm -f /tmp/setprop.out /tmp/setenv.out

    #export below env for /tmp/fwc.sh script
    export_instenv instenv_fs_root instenv_fs_system instenv_fs_data instenv_fs_localdisk instenv_model_no

    printf "\n\n=======Execute fwc script file start...=======\n\n"
    . /tmp/fwc.sh
    printf "\n=======Execute fwc script file done,ret $?=======\n"

    setenv wmt.model.no $instenv_model_no
    
    cd $instenv_top_dir #cd to instenv_top_dir again to prevent /tmp/fwc.sh changed cur dir.

    #update prop file
    printf "\n\n####### below is from $instenv_fs_system/default.prop #######\n" > /tmp/setprop.tmp
    cat $instenv_fs_system/default.prop >> /tmp/setprop.tmp
    #append version info
    printf "\n\n####### from firmware/VERSION #######\n" >> /tmp/setprop.tmp
    cat firmware/VERSION >> /tmp/setprop.tmp
    if [ -f /tmp/setprop.out ]; then
        printf "\n\n####### below is from fwc.sh file #######\n" >> /tmp/setprop.tmp
        cat /tmp/setprop.out >> /tmp/setprop.tmp
    fi
    mv /tmp/setprop.tmp /tmp/setprop.out    # now /tmp/setprop.out contains all setprop result

    #update env file
    printf "\n\n####### below is from config/uboot_env #######\n" >> /tmp/setenv.tmp
    cat config/uboot_env >> /tmp/setenv.tmp
    printf "\n\n####### below is from fwc.sh file #######\n" >> /tmp/setenv.tmp
    cat /tmp/setenv.out >> /tmp/setenv.tmp
    mv /tmp/setenv.tmp /tmp/setenv.out      # now /tmp/setenv.out contains all setenv result

    
    printf "\n\n####### below is from env_addon #######\n" >> /tmp/setenv.out
    env_addon

    inc_ratio 5

    sync
    ### run wmtinst_??_* script to get more setenv/setprop command
    ### or even copy more files to device file system. we don't konw exactly.

    printf "\n\n####### below is from wmtinst_hook script files #######\n" >> /tmp/setenv.out
    printf "\n\n####### below is from wmtinst_hook script files #######\n" >> /tmp/setprop.out
    source $instenv_top_dir/installer/bin/bspinst_addons.sh
    inc_ratio 5

    #clean setprop result and replace /system/default.prop
    info 0 "clean /tmp/setprop.out to /tmp/cleanprop"

    wmtclean /tmp/setprop.out > /tmp/default.prop

    #DEBUG
    Quiet cp /tmp/setprop.out  debug/setprop.out
    Quiet cp /tmp/default.prop debug/setprop.clean

    cp /tmp/default.prop $instenv_fs_system/default.prop
    chmod g-w,o-w $instenv_fs_system/default.prop
    chmod g-w,o-w $instenv_fs_system/build.prop
    sync

    return 0
}


#
# $1: module name, for example "wload"
# $2: inc progress, for example 5
# if $install_modules contains $1, exec inst_$1 command, for example inst_wload
try_install()
{
    local module=$1             # 
    local progress=$2
    local run_cmd=inst_$1       # run "inst_wload" command

    if [ $install_critical_error -eq 1 ];then
        return 1
    fi

    for i in $install_modules; do
        if [ "$i" == "$module" ]; then
            inc_ratio $progress
            $run_cmd
            return $?
        fi
    done
    info 1 "Skipped $module installation."
    inc_ratio $progress
    return 0
}

# install_end
install_end ()
{
    if [ $install_critical_error -eq 1 ];then
        return 1
    fi

    #remove customer key information
    /bin/rm -rf ${instenv_fs_system}/.restore/wmtpref

    local sys_inst_end="${instenv_fs_system}/.restore/sys_partition_end.sh"
    if [  -f $sys_inst_end ]; then
        chmod +x ${sys_inst_end}
        ${sys_inst_end} ${instenv_fs_system} ${instenv_fs_data}
    fi

    inc_ratio 1
    return 0
}

#
# do_install
#
do_install ()
{
    if ! find_activated_fwc; then
        return 1
    fi
    
    info 1 "Model:$instenv_model_no,BootDev:$instenv_bootdev"

    mkdir -p $instenv_fs_system
    mkdir -p $instenv_fs_data
    mkdir -p $instenv_fs_localdisk
 
    # run inst_systemdata function if $install_modules contains "systemdata", 
    try_install "systemdata" 0

    if [ $install_critical_error -eq 1 ];then
        return 1
    fi

    local fwc_file="config/+"$instenv_model_no".fwc"
    if [ ! -f $fwc_file ]; then
        fwc_file="config/"$instenv_model_no".fwc"
    fi
    process_fwc "$fwc_file"
    
    try_install "wload" 5
    try_install "uboot" 5

    if [ $install_critical_error -eq 1 ];then
        return 1
    else
        process_special
    fi
    #Must do this after process_special
    try_install "logo_bootimg" 5

    #do some misc task at installer end
    install_end

    #Must install uboot-env at last
    try_install "env"   5
    ratio 98

    sync
    return 0
}

