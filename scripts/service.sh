#!/bin/sh 

APP=$2
CPU_TYPE=$(sbox get core.cpu_type)
CORE=$(sbox get $APP.core)
PARA=$(sbox get $APP.para)
APP_DIR=$SBOX_DIR/tools/apps/$APP
[ "$(sbox get core.lite)" = true ] && BIN_DIR=/tmp/ShellBox/bin/$APP || BIN_DIR=$APP_DIR

check_files(){
	#检查并下载内核
	if [ ! -f $BIN_DIR/$CORE ];then 
		tmp_dir=/tmp/ShellBox/tmp/${CORE}
		sbox log "Core of $APP is missing ! Downloading start !" 1
		.webget.sh ${tmp_dir} /tools/apps/${APP}/bin/${CORE}_${CPU_TYPE} 2
		if [ "$?" = 0 ];then
			mv -f ${tmp_dir} $BIN_DIR/${CORE}
		else
			rm -rf ${tmp_dir}
			sbox log "Core of $APP downloading failed ! Stop starting !" 1
			exit 1
		fi
	fi
	#检查并下载依赖文件
	FILE_LIST=$APP_DIR/file.list
	if [ -s "FILE_LIST" ];then
		for file in $FILE_LIST;do
			tmp_dir=/tmp/ShellBox/tmp/${file}
			sbox log "Files : $file of $APP is missing ! Downloading start !" 1
			.webget.sh ${tmp_dir} /tools/apps/${APP}/bin/${file} 2
			if [ "$?" = 0 ];then
				if [ -n "$(echo $file|grep tar)" ];then
					tar -zxvf ${tmp_dir} -C $BIN_DIR/
				elif [ -n "$(echo $file|grep lib)" ];then
					i=
				else
					mv -f ${tmp_dir} $BIN_DIR/${file}
				fi
			else
				rm -rf ${tmp_dir}
				sbox log "Files of $APP downloading failed ! Stop starting !" 1
				exit 1
			fi			
		done
	fi			
}

start(){
	[ -n "$(pidof "$CORE")" ] && sbox log "$APP is running !" && exit 1
	[ -f /tmp/ShellBox/config/$APP ] && retry=$(sbox get $APP.retry /tmp/ShellBox/config) 
	check_files
	#启动APP
	if [ retry -lt 5 ];then
		$APP_DIR/bin/$CORE $PARA > /dev/null &
		if [ $? != 0 ];then
			sbox log "Service $APP failed to start, retry: $retry"
			sbox set $APP.retry=$((retry+1)) /tmp/ShellBox/config
		else
			sbox del $APP.retry /tmp/ShellBox/config
		fi
	else
		sbox log "Stop retrying to start $APP !" 1
		sed -i "s/$APP/d" $SBOX_DIR/config/service.list
	fi
}

stop(){
	sed -i "s/$APP/d" $SBOX_DIR/config/service.list
	type killall >/dev/null 2>&1 && killall $CORE
    kill -9 "$(pidof "$CORE")" 2>/dev/null
}

status(){
    [ -n "$(pidof $CORE)" ] && return 0 || return 1
}

case "$1" in

start)		start			;;
stop)		stop			;;
restart)	stop&&start		;;
status) 	status			;;

esac

