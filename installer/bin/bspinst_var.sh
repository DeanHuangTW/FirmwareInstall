# bspinst_var.sh
#
# Global variables for drawing API for WonderMedia ARM SoC.
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


#const value of mtdblock name in nand
BLK_NAND_LOGO="logo"
BLK_NAND_BOOT="boot"
BLK_NAND_RECOV="recovery"
BLK_NAND_MISC="misc"
BLK_NAND_SYS="system"
BLK_NAND_ANDROIDCACHE="cache"
BLK_NAND_ANDROIDDATA="data"
BLK_NAND_KEYDATA="keydata"


#for SD/UDisk boot
MOUNT_BOOT="/boot"



#############################
# set by FMaker or script program
#############################
# wload file name based on FirmwareInstall directory, such as firmware/wload-xxx.bin
instenv_wload=


# uboot  file name based on FirmwareInstall directory
# default is firmware/u-boot.bin
instenv_uboot=firmware/u-boot.bin


# LOGO files path based on FirmwareInstall directory
instenv_logo_path=


# uboot  LOGO file name based on FirmwareInstall directory
# default is $instenv_logo_path/u-boot-logo.data
instenv_uboot_logo=


# kernel file name based on FirmwareInstall directory
# default is firmware/uzImage.bin
instenv_kernel=firmware/uzImage.bin


#boot from device, either "NAND" (default) or "TF"
instenv_bootdev="NAND"
instenv_ddrsize=


#current top dir, will be set when starts up
instenv_top_dir=

#installation's mount point
instenv_fs_root="/android"
instenv_fs_system="/android/system"
instenv_fs_data="/android/data"
instenv_fs_localdisk="$instenv_fs_data/media"


#model_no, activated xxxxx.fwc 's base name
instenv_model_no=
