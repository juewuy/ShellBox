#!/bin/sh
# Copyright (C) Juewuy

SBOX_DIR=$(cd $(dirname $0);pwd)
PROFILE=/etc/profile
INIT_DIR=/etc/init.d/sbox

#h初始化环境变量
echo "export SBOX_DIR=\"$SBOX_DIR\"" >> $PROFILE
echo "alias sbox=\"$SBOX_DIR\"/sbox_ctl" >> $PROFILE 

#设置init.d服务并启动ShellBox服务
ln -sf $SBOX_DIR/sbox_rc $INIT_DIR
chmod 755 $INIT_DIR

if [ "$($0 get core.auto_start)" != false ];then
	log_file=`uci get system.@system[0].log_file`
	while [ "$i" -lt 10 ];do
		sleep 3
		[ -n "$(grep 'init complete' $log_file)" ] && i=10 || i=$((i+1))
	done
	$INIT_DIR start
	$INIT_DIR enable
fi
