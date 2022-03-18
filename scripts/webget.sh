#!/bin/bash
# Copyright (C) Juewuy

#参数【$1】代表目标路径，【$2】代表在线路径
#参数【$3】代表重试次数，【$4】代表输出显示
#参数【$5】不启用重定向，【$6】代表验证证书
[ -z "$3" ] && j=1 || j=$3
SERVER=$(sbox get core.server)

for ((i=1;i<=j;i++));do
	if type curl > /dev/null 2>&1;then
		[ "$4" = "echooff" ] && progress='-s' || progress='-#'
		[ "$5" = "rediroff" ] && redirect='' || redirect='-L'
		[ "$6" = "skipceroff" ] && certificate='' || certificate='-k'
		result=$(curl $agent -w %{http_code} --connect-timeout 3 $progress $redirect $certificate -o "$1" "${SERVER}$2")
		[ "$result" -ge 200 -a "$result" -lt 300 ] && exit 0
	else
		if wget --version > /dev/null 2>&1;then
			[ "$4" = "echooff" ] && progress='-q' || progress='-q --show-progress'
			[ "$5" = "rediroff" ] && redirect='--max-redirect=0' || redirect=''
			[ "$6" = "skipceroff" ] && certificate='' || certificate='--no-check-certificate'
			timeout='--timeout=3 -t 2'
		fi
		[ "$4" = "echoon" ] && progress=''
		[ "$4" = "echooff" ] && progress='-q'
		wget $agent $progress $redirect $certificate $timeout -O "$1" "${SERVER}$2"
		[ "$?" = 0 ] && exit 0
	fi
done
exit 1