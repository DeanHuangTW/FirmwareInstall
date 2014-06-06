#!/bin/sh
#
# Add-ons for user-defined installation
#
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


printf "\n\n=======Execute bspinst_addons.sh start...=======\n\n"
info 1 "Executing subdir wmtinst_##_ script files..."

#exec inst hook script, sort by basename, good choice?
local index=1
local shdir
for f in `find . -name wmtinst_??_*.sh -maxdepth 2 -type f | sort -t / -k 3`; do
    info 0 "  #$index: run $f..."

    shdir=$(dirname "$f")
    shdir=${shdir:2}        #remove ./ prefix

    cd $instenv_top_dir

    #before run it copy this file to tmp folder and dos2unix ([VicYuan] not work? )
    #cp $f /tmp/tmp.sh
    #dos2unix /tmp/tmp.sh

    # source run to make msg/inc_ratio function works on hook script.
    # $1 is the shell script's path
    info 0 "    script cur dir: $instenv_top_dir/$shdir"
    source $f $instenv_top_dir/$shdir

    info 1 "  #$index: run $f ret $?"
    let index++
done

printf "\n=======Execute wmtinst_##_ script file done.=======\n"


