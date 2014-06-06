#!/bin/sh

# runui.sh
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

COMMAND_ITEM=1
COMMAND_TITLE=2
COMMAND_PROGRESS=3
COMMAND_EXITUI=4
COMMAND_NOTEINFO=5

TYPE_QUICKTEST=6
TYPE_UPDATE=7 

UI_SOCK_NAME="/tmp/autorun_msg.dat"
CompleteRatio=0

#
#@exit string
exit_ui()
{
	local str=$@
	local cmd=$COMMAND_EXITUI
	unixmsg ${UI_SOCK_NAME} "${cmd}@${str}"	
}
 
# default print item msg
# @message string 
uimsg()
{	
	local str=$@	
	local cmd=$COMMAND_ITEM
	unixmsg ${UI_SOCK_NAME} "${cmd}@${str}"		
}

#
#@title string
msg_title()
{
	local str=$@
	local cmd=$COMMAND_TITLE
	unixmsg ${UI_SOCK_NAME} "${cmd}@${str}"	
}

#
#@warnning string in bottom
msg_info()
{
	local str=$@
	local cmd=$COMMAND_NOTEINFO
	unixmsg ${UI_SOCK_NAME} "${cmd}@${str}"	
}

#
#@number: [0~100]
ratio ()
{	
	CompleteRatio=$@
	local cmd=$COMMAND_PROGRESS
	unixmsg ${UI_SOCK_NAME} "${cmd}@${CompleteRatio}"	
}

inc_ratio()
{
	local progress
	let progress=$CompleteRatio+$1
	if [ $progress -gt 100 ]; then
		progress=100
	fi
	ratio $progress
}


# run shellui 
# @srcdir
# @startuptype TYPE_UPDATE or TYPE_QUICKTEST
run_ui()
{
 	local this_dir=$1/installer/shellui
	local startuptype=$2
	
	echo "[WMT] $this_dir UI is preparing depending files..."
	
	ln -s $this_dir/lib/libvgui.so /lib/libvgui.so
#	if [ ! -e /lib/libstdc++.so} ];then
#		ln -s $this_dir/lib/libstdc++.so.6.0.9 /lib/libstdc++.so.6
#		ln -s $this_dir/lib/libstdc++.so.6.0.9 /lib/libstdc++.so
#	fi
	    
	cd $this_dir
	cp -a unixmsg /bin/
	cp -a fb0tofb1 /bin/
	
	./shellui $startuptype  &
	
#disable it cause conflict with SMP(dual core), need to fix for TV product
#	/bin/fb0tofb1 &
                
	echo "[WMT] waitting for shell-UI ready... "	
	while [ ! -e ${UI_SOCK_NAME} ]; do
		usleep 10
	done
}



###################################################
#-----------example for test -----------	
#echo "run runui.sh"
#
#source runui.sh
#
#run_ui ${shell_ui_path} $TYPE_UPDATE

#send text/information to UI_SHELL
#msg_title "WonderMedia 自动升级程序 "
#msg_info  "正在升级，请勿断电！"		
#uimsg "update item 1"
#ratio 30
#sleep 5
#uimsg "update item 2"
#ratio 50
#sleep 5
#uimsg "update item 3"
#ratio 70
