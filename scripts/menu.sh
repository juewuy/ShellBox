#!/bin/bash
# Copyright (C) Juewuy

alias sbox="$SBOX_DIR/sbox_ctl"
[ -n "$(ls -l /bin/sh|grep -oE 'dash|show|bash')" ] && SH=bash || SH=sh

#脚本内置工具
secho(){
	[ -z "$2" ] && echo -e "$1" || echo -e "\033["$2"m"$1"\033[0m"
}
lang_select(){
	echo -----------------------------------------------
	secho "Welcome to ShellBox !" 32
	secho "Please select your language first!" 33
	echo -----------------------------------------------
	i=1
	for lang in $SBOX_DIR/lang/* ;do
		lang_name=$(grep lang_name= $lang | awk -F "'" '{print $2}')
		echo $i $lang_name
		lang_all="$lang_all $lang"
		i=$((i+1))
	done
	echo -----------------------------------------------
	read -p "Iput the num : > " num
	if [ -z "$num" ];then
		lang_select
	elif [ "$num" -ge 1 -a "$num" -lt "$i" ];then
		LANG=$(echo $lang_all|awk '{print $"'$num'"}')
		sbox set sbox.lang=$LANG
	else
		echo -----------------------------------------------
		secho "Error Number ! Try again !" 31
		lang_select
	fi
}
dir_avail(){
	df -h $1 | awk '{ for(i=1;i<=NF;i++){ if(NR==1){ arr[i]=$i; }else{ arr[i]=arr[i]" "$i; } } } END{ for(i=1;i<=NF;i++){ print arr[i]; } }' | grep Ava | awk '{print $2}'
}
getconfig(){
	source $SBOX_DIR/config/sbox
	#开机自启检测
	if [ -f /etc/rc.common -a "$boot" != "mi_adv" ];then
		[ -n "$(find /etc/rc.d -name '*ShellBox')" ] && auto_start=true || auto_start=false
	elif [ -w /etc/systemd/system -o -w /usr/lib/systemd/system ];then
		[ -n "$(systemctl is-enabled ShellBox.service 2>&1 | grep enable)" ] && auto_start=true || auto_start=false
	fi
}
errornum(){
	echo -----------------------------------------------
	secho $lang_errornum 31
}
#功能相关
setport(){
	source $ccfg
	[ -z "$secret" ] && secret=未设置
	[ -z "$authentication" ] && authentication=未设置
	inputport(){
		read -p "请输入端口号(1-65535) > " portx
		if [ -z "$portx" ]; then
			setport
		elif [ $portx -gt 65535 -o $portx -le 1 ]; then
			secho "\033[31m输入错误！请输入正确的数值(1-65535)！\033[0m"
			inputport
		elif [ -n "$(echo $mix_port$redir_port$dns_port$db_port|grep $portx)" ]; then
			secho "\033[31m输入错误！请不要输入重复的端口！\033[0m"
			inputport
		elif [ -n "$(netstat -ntul |grep :$portx)" ];then
			secho "\033[31m当前端口已被其他进程占用，请重新输入！\033[0m"
			inputport
		else
			setconfig $xport $portx 
			secho "\033[32m设置成功！！！\033[0m"
			setport
		fi
	}
	echo -----------------------------------------------
	secho " 1 修改Http/Sock5端口：	\033[36m$mix_port\033[0m"
	secho " 2 设置Http/Sock5密码：	\033[36m$authentication\033[0m"
	secho " 3 修改静态路由端口：	\033[36m$redir_port\033[0m"
	secho " 4 修改DNS监听端口：	\033[36m$dns_port\033[0m"
	secho " 5 修改面板访问端口：	\033[36m$db_port\033[0m"
	secho " 6 设置面板访问密码：	\033[36m$secret\033[0m"
	secho " 7 修改默认端口过滤：	\033[36m$multiport\033[0m"
	secho " 8 指定本机host地址：	\033[36m$host\033[0m"
	secho " 0 返回上级菜单"
	read -p "请输入对应数字 > " num
	if [ -z "$num" ]; then 
		errornum
	elif [ "$num" = 1 ]; then
		xport=mix_port
		inputport
	elif [ "$num" = 2 ]; then
		echo -----------------------------------------------
		secho "格式必须是\033[32m 用户名:密码 \033[0m的形式，注意用小写冒号分隔！"
		secho "请尽量不要使用特殊符号！可能会产生未知错误！"
		secho "\033[31m需要使用本机代理功能时，请勿设置密码！\033[0m"
		echo "输入 0 删除密码"
		echo -----------------------------------------------
		read -p "请输入Http/Sock5用户名及密码 > " input
		if [ "$input" = "0" ];then
			authentication=""
			setconfig authentication
			echo 密码已移除！
		else
			if [ "$local_proxy" = "已开启" -a "$local_type" = "环境变量" ];then
				echo -----------------------------------------------
				secho "\033[33m请先禁用本机代理功能或使用增强模式！\033[0m"
				sleep 1
			else
				authentication=$(echo $input | grep :)
				if [ -n "$authentication" ]; then
					setconfig authentication \'$authentication\'
					secho "\033[32m设置成功！！！\033[0m"
				else
					secho "\033[31m输入有误，请重新输入！\033[0m"
				fi
			fi
		fi
		setport
	elif [ "$num" = 3 ]; then
		xport=redir_port
		inputport
	elif [ "$num" = 4 ]; then
		xport=dns_port
		inputport
	elif [ "$num" = 5 ]; then
		xport=db_port
		inputport
	elif [ "$num" = 6 ]; then
		read -p "请输入面板访问密码(输入0删除密码) > " secret
		if [ -n "$secret" ]; then
			[ "$secret" = "0" ] && secret=""
			setconfig secret $secret
			secho "\033[32m设置成功！！！\033[0m"
		fi
		setport
	elif [ "$num" = 7 ]; then
		echo -----------------------------------------------
		secho "需配合\033[32m仅代理常用端口\033[0m功能使用"
		secho "多个端口请用小写逗号分隔，例如：\033[33m143,80,443\033[0m"
		secho "输入 0 重置为默认端口"
		echo -----------------------------------------------
		read -p "请输入需要指定代理的端口 > " multiport
		if [ -n "$multiport" ]; then
			[ "$multiport" = "0" ] && multiport=""
			common_ports=已开启
			setconfig multiport $multiport
			setconfig common_ports $common_ports
			secho "\033[32m设置成功！！！\033[0m"
		fi
		setport
	elif [ "$num" = 8 ]; then
		echo -----------------------------------------------
		secho "\033[33m此处可以更改脚本内置的host地址\033[0m"
		secho "\033[31m设置后如本机host地址有变动，请务必手动修改！\033[0m"
		echo -----------------------------------------------
		read -p "请输入自定义host地址(输入0移除自定义host) > " host
		if [ "$host" = "0" ];then
			host=""
			setconfig host $host
			secho "\033[32m已经移除自定义host地址，请重新运行脚本以自动获取host！！！\033[0m"
			exit 0
		elif [ -n "$(echo $host |grep -E -o '\<([1-9]|[1-9][0-9]|1[0-9]{2}|2[01][0-9]|22[0-3])\>(\.\<([0-9]|[0-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\>){2}\.\<([1-9]|[0-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-4])\>' )" ]; then
			setconfig host $host
			secho "\033[32m设置成功！！！\033[0m"
		else
			host=""
			secho "\033[31m输入错误，请仔细核对！！！\033[0m"
		fi
		sleep 1
		setport
	fi	
}
checkport(){
	for portx in $dns_port $mix_port $redir_port $db_port ;do
		if [ -n "$(netstat -ntul 2>&1 |grep \:$portx\ )" ];then
			echo -----------------------------------------------
			secho "检测到端口【$portx】被以下进程占用！ShellBox可能无法正常启动！\033[33m"
			echo $(netstat -ntul | grep :$portx | head -n 1)
			secho "\033[0m-----------------------------------------------"
			secho "\033[36m请修改默认端口配置！\033[0m"
			setport
			source $ccfg
			checkport
		fi
	done
}
cron(){
	setcron(){
		setcrontab(){
			#设置具体时间
			echo -----------------------------------------------
			read -p "请输入小时（0-23） > " num
			if [ -z "$num" ]; then 
				errornum
				setcron
			elif [ $num -gt 23 ] || [ $num -lt 0 ]; then 
				errornum
				setcron
			else	
				hour=$num
				echo -----------------------------------------------
				read -p "请输入分钟（0-59） > " num
				if [ -z "$num" ]; then 
					errornum
					setcron
				elif [ $num -gt 59 ] || [ $num -lt 0 ]; then 
					errornum
					setcron
				else	
					min=$num
						echo -----------------------------------------------
						echo 将在$week1的$hour点$min分$cronname（旧的任务会被覆盖）
						read -p  "是否确认添加定时任务？(1/0) > " res
						if [ "$res" = '1' ]; then
							cronwords="$min $hour * * $week $cronset >/dev/null 2>&1 #$week1的$hour点$min分$cronname"
							tmpcron=/tmp/cron_$USER
							croncmd -l > $tmpcron
							sed -i "/$cronname/d" $tmpcron
							sed -i '/^$/d' $tmpcron
							echo "$cronwords" >> $tmpcron
							croncmd $tmpcron
							#华硕/Padavan固件存档在本地,其他则删除
							[ "$ShellBoxdir" = "/jffs/ShellBox" -o "$ShellBoxdir" = "/etc/storage/ShellBox" ] && mv -f $tmpcron $ShellBoxdir/cron || rm -f $tmpcron
							echo -----------------------------------------------
							secho "\033[31m定时任务已添加！！！\033[0m"
						fi
				fi			
			fi
		}
		echo -----------------------------------------------
		secho " 正在设置：\033[32m$cronname\033[0m定时任务"
		secho " 输入  1~7  对应\033[33m每周的指定某天\033[0m运行"
		secho " 输入   8   设为\033[33m每天\033[0m定时运行"
		secho " 输入 1,3,6 代表\033[36m指定每周1,3,6\033[0m运行(小写逗号分隔)"
		secho " 输入 a,b,c 代表\033[36m指定每周a,b,c\033[0m运行(1<=abc<=7)"
		echo -----------------------------------------------
		secho " 输入   9   \033[31m删除定时任务\033[0m"
		secho " 输入   0   返回上级菜单"
		echo -----------------------------------------------
		read -p "请输入对应数字 > " num
		if [ -z "$num" ]; then 
			errornum
		elif [ "$num" = 0 ]; then
			i=
		elif [ "$num" = 9 ]; then
			croncmd -l > /tmp/conf && sed -i "/$cronname/d" /tmp/conf && croncmd /tmp/conf
			sed -i "/$cronname/d" $ShellBoxdir/cron 2>/dev/null
			rm -f /tmp/conf
			echo -----------------------------------------------
			secho "\033[31m定时任务：$cronname已删除！\033[0m"
		elif [ "$num" = 8 ]; then	
			week='*'
			week1=每天
			echo 已设为每天定时运行！
			setcrontab
		else
			week=$num	
			week1=每周$week
			echo 已设为每周 $num 运行！
			setcrontab
		fi
	}
	#定时任务菜单
	echo -----------------------------------------------
	secho "\033[30;47m欢迎使用定时任务功能：\033[0m"
	secho "\033[44m 实验性功能，遇问题请加TG群反馈：\033[42;30m t.me/ShellBoxfm \033[0m"
	echo -----------------------------------------------
	echo  -e "\033[33m已添加的定时任务：\033[36m"
	croncmd -l | grep -oE ' #.*' 
	secho "\033[0m"-----------------------------------------------
	secho " 1 设置\033[33m定时重启\033[0mShellBox服务"
	secho " 2 设置\033[31m定时停止\033[0mShellBox服务"
	secho " 3 设置\033[32m定时开启\033[0mShellBox服务"
	secho " 4 设置\033[33m定时更新\033[0m订阅并重启服务"
	echo -----------------------------------------------
	secho " 0 返回上级菜单" 
	read -p "请输入对应数字 > " num
	if [ -z "$num" ]; then 
		errornum
	elif [ "$num" = 0 ]; then
		i=
	elif [ "$num" = 1 ]; then
		cronname=重启ShellBox服务
		cronset="$ShellBoxdir/start.sh restart"
		setcron
		ShellBoxcron
	elif [ "$num" = 2 ]; then
		cronname=停止ShellBox服务
		cronset="$ShellBoxdir/start.sh stop"
		setcron
		ShellBoxcron
	elif [ "$num" = 3 ]; then
		cronname=开启ShellBox服务
		cronset="$ShellBoxdir/start.sh start"
		setcron
		ShellBoxcron
	elif [ "$num" = 4 ]; then	
		cronname=更新订阅链接
		cronset="$ShellBoxdir/start.sh updateyaml"
		setcron	
		ShellBoxcron
	else
		errornum
	fi
}

#主菜单
welcome(){
	mem_free=$((`free | grep Mem | awk '{print $4}'`/1000))
	disk_sbox=$(du -sh $SBOX_DIR | awk '{print $1}')
	disk_free=$(dir_avail $SBOX_DIR)
	version=$(sbox get sbox.version)
	start_time=$(sbox get sbox.start_time)
	time=$((`date +%s`-start_time))
	day=$((time/86400))
	[ "$day" = "0" ] && day='' || day="$day $lang_day"
	time=`date -u -d @${time} +%H-%M-%S`
	#欢迎使用
	echo -----------------------------------
	secho "\033[30;46m$lang_welcome ShellBox！\033[0m	  v1.2.$version"
	[ -n "$(pidof sbox_core)" ] && secho "ShellBox$lang_has_run：\033[46;30m"$day"\033[44;37m"$time"\033[0m"
	secho "$lang_mem_free：${mem_free}M	$lang_disk_info：$disk_sbox/$disk_free"
	secho "Telgram：\033[36;4mhttps://t.me/ShellBox\033[0m"
	echo -----------------------------------	
}
menu(){
	########################################
	LANG=$(sbox get sbox.lang)
	[ "$LANG" = 0 ] && lang_select
	source $LANG
	welcome
	########################################
	secho " 1 $lang_tools_service"  
	secho " 2 $lang_tools_cron"		
	secho " 3 $lang_tools_local"	
	secho " 4 $lang_tools_online"	
	secho " 5 $lang_set_sbox"		
	secho " 6 $lang_about"
	secho " 0 $lang_close_menu"	
	echo -----------------------------------
	read -p "$lang_input_num > " num
	########################################
	case "$num" in
		0)			exit				;;
		1)			tools_service		;;
		2)			tools_cron			;;
		3)			tools_local			;;
		4)			tools_online		;;
		5)			set_sbox			;;
		6)			about				;;
		*)			errornum			;;
	esac
	[ -z "$num" -o "$num" = 0 ] || menu
}
#子菜单_插件相关
tools_service(){
	list=$SBOX_DIR/config/service.list
	numbers=$(cat $list | wc -l)
	if [ "$numbers" -gt 0 ];then
		echo -----------------------------------
		secho "$lang_running_service" 
		cat $list | awk '{print " "NR" "$1}'
		echo -----------------------------------
		secho " a $lang_tools_cron"  
		secho " b $lang_tools_local"		
		secho " c $lang_tools_online"
		secho " 0 $lang_return_menu"	
		echo -----------------------------------
		read -p "$lang_input_norl > " norl
		########################################	
		case "$norl" in
			[0-9])
				if [ "$norl" -ge 1 -a "$norl" -le "$numbers" ];then
					app=$(cat $list| sed -n "$norl"p)
					ck_tools $app
				else
					errornum
				fi
				;;
			a)			tools_cron			;;
			b)			tools_local			;;
			c)			tools_online		;;
			*)			errornum			;;
		esac
		[ -z "$norl" -o "$norl" = 0 ] || tools_service
	else
		if [ "$(cat $SBOX_DIR/config/local.list | wc -l)" = 0 ];then
			secho "$lang_none_plugins"	33
			tools_online
		else
			secho "lang_none_service"	31
			tools_local
		fi
	fi
}
tools_local(){
	list=$SBOX_DIR/config/local.list
	numbers=$(cat $list | wc -l)
	if [ "$numbers" -gt 0 ];then
		echo -----------------------------------
		secho "$lang_local_plugins" 
		cat $list | awk '{print " "NR" "$1}'
		echo -----------------------------------
		secho " a $lang_tools_service" 
		secho " b $lang_tools_cron"		
		secho " c $lang_tools_online"
		secho " 0 $lang_return_menu"	
		echo -----------------------------------
		read -p "$lang_input_norl > " norl
		########################################	
		case "$norl" in
			[0-9])
				if [ "$norl" -ge 1 -a "$norl" -le "$numbers" ];then
					tools=$(cat $list| sed -n "$norl"p)
					ck_tools $tools
				else
					errornum
				fi
				;;
			a)			tools_service		;;
			b)			tools_cron			;;
			c)			tools_online		;;
			*)			errornum			;;
		esac
		[ -z "$norl" -o "$norl" = 0 ] || tools_local
	else
		if [ "$(cat $SBOX_DIR/config/service.list | wc -l)" = 0 ];then
			secho "$lang_none_plugins"	33
			tools_online
		else
			secho "$lang_none_local"	31
			tools_service
		fi
	fi
}
tools_online(){
	update_url=$(sbox get sbox.update_url)
	list_ol=/tmp/ShellBox_$USER/online.list
	list_lo=$SBOX_DIR/config/local.list
	list_run=$SBOX_DIR/config/service.list
	secho "$lang_online_list"
	sbox webget ${list_ol} ${update_url}/bin/tools_${LANG}.list 2
	if [ "$?" = 0 ];then
		echo -----------------------------------
		secho "$lang_online_select" 
		cat $list_ol | grep -v -f $list_lo | grep -v -f $list_run | awk '{print " "NR" "$1" ——"$2}'
		echo -----------------------------------
		secho " a $lang_tools_service"  
		secho " b $lang_tools_cron"		
		secho " c $lang_tools_local"
		secho " 0 $lang_return_menu"	
		echo -----------------------------------
		read -p "$lang_input_norl > " norl
		########################################	
		case "$norl" in
			[0-9])
				if [ "$norl" -ge 1 -a "$norl" -le "$numbers" ];then
					tools=$(cat $list| sed -n "$norl"p)
					get_tools $tools
				else
					errornum
				fi
				;;
			a)			tools_service		;;
			b)			tools_cron			;;
			c)			tools_local		;;
			*)			errornum			;;
		esac
		[ -z "$norl" -o "$norl" = 0 ] || tools_online
	else
		secho "$lang_online_error"	31
		update
	fi
}
ck_tools(){
	APP_DIR=$SBOX_DIR/tools/$1
	source $APP_DIR/sbox.config
	[ "$type" = "stand" ] && $SH $APP_DIR/$1.sh || set_tools $1
}
set_tools(){
	if [ -n "$(pidof $1)" ];then
		start_stop=\033[31m$lang_stop
	else
		[ "$type" = "app" ] && start_stop=\033[32m$lang_start || start_stop=\033[32m$lang_run
	fi
	########################################
	echo -----------------------------------
	secho "欢迎使用 \033[46;30m$1\033[0m !"	
	eval echo '$'"desc_$LANG"
	echo -----------------------------------
	secho " 1 ${start_stop}\033[0m $1"  
	[ -n "$im_var1" ] && secho " 2 $基础功能设置"		
	[ -n "$gen_var1" ] && secho " 3 $lang_advanced_set"
	[ -n "$cron_para1" ] && secho " 4 $计划任务配置"	
	$config_online && secho " 5 $在线配置生成"
	secho " 8 ${lang_update} $1"	
	secho " 9 ${lang_uninstall} $1"
	secho " 0 $lang_return_menu"	
	echo -----------------------------------
	read -p "$lang_input_num > " num
	########################################	
	case "$num" in
		0)			exit				;;
		1)			
			[ -z "$(pidof sbox_core)" ] && sbox start || sbox stop
			;;
		2)			basic_set			;;
		3)			advanced			;;
		4)			tools_cron			;;
		5)			get_config_ol		;;
		8)			update	$1			;;
		9)			uninstall $1		;;
		*)			errornum			;;
	esac
	[ -z "$num" -o "$num" = 0 ] || set_sbox
}
get_tools(){
echo
}
#子菜单_定时任务相关
tools_cron(){
	numbers=$(sbox croncmd -l | grep -i sbox | wc -l)
	########################################
	echo -----------------------------------
	if [ "$numbers" -gt 0 ];then
		secho "已添加的定时任务：" 33
		sbox croncmd -l | grep -i sbox | awk -F '#' '{print " "NR" "$2}'
	else
		secho "你还没有添加ShellBox相关定时任务！" 	31
	fi
	echo -----------------------------------
	secho " a $添加定时任务" 
	secho " b $lang_tools_service"  
	secho " c $lang_tools_local"		
	secho " d $lang_tools_online"
	secho " 0 $lang_return_menu"	
	echo -----------------------------------
	read -p "$lang_input_norl > " norl
	########################################	
	case "$norl" in
		[0-9])
			if [ "$norl" -ge 1 -a "$norl" -le "$numbers" ];then
				cron=$(cat $list| sed -n "$norl"p)
				set_cron $cron
			else
				errornum
			fi
			;;
		a)			set_cron			;;
		b)			tools_service		;;
		c)			tools_local			;;
		d)			tools_online		;;
		*)			errornum			;;
	esac
	[ "$norl" = 0 ] || tools_cron
}
#施工中
set_cron(){
	echo
}
#子菜单_sbox相关
set_sbox(){
	[ -n "$(pidof sbox_core)" ] && start_stop='\033[31m'$lang_stop || start_stop='\033[32m'$lang_start
	########################################
	secho " 1 ${start_stop}ShellBox\033[0m"  
	secho " 2 $lang_boot_type"		
	secho " 3 $lang_advanced_set"
	secho " 4 $lang_backup"	
	secho " 5 $lang_view_logs"
	secho " 6 ${lang_update}ShellBox"	
	secho " 9 ${lang_uninstall}ShellBox"
	secho " 0 $lang_return_menu"	
	echo -----------------------------------
	read -p "$lang_input_num > " num
	########################################	
	case "$num" in
		0)			exit				;;
		1)			
			[ -z "$(pidof sbox_core)" ] && sbox start || sbox stop
			;;
		2)			set_boot			;;
		3)			advanced			;;
		4)			backup				;;
		5)			update				;;
		6)			ck_log				;;
		9)			sbox -u				;;
		*)			errornum			;;
	esac
	[ -z "$num" -o "$num" = 0 ] || set_sbox
}
set_boot(){
	unsupported(){
		echo -----------------------------------
		secho "$lang_boot_unsupport" 31
	}
	boot=$(sbox get sbox.boot)
	
	echo -----------------------------------
	secho "$lang_boot_state $boot" 
	echo -----------------------------------
	########################################
	secho " 1 $lang_boot_system"  
	secho " 2 $lang_boot_cron"		
	secho " 3 $lang_boot_mi_adv"
	secho " 4 $lang_boot_disable"
	secho " 0 $lang_return_menu"	
	echo -----------------------------------
	read -p "$lang_input_num > " num
	########################################	
	case "$num" in
		1)	
			if [ -f /etc/rc.common -o -w /etc/systemd/system -o -w /usr/lib/systemd/system ] && [ "$(dir_avail /etc)" != 0 ];then
				boot=system
				[ -f /etc/rc.common ] && /etc/init.d/sbox enable
				type systemctl >/dev/null && systemctl enable sbox.service
				sbox cronset '#SBox守护进程'
				type uci >/dev/null && { 
				uci del firewall.ShellBox
				uci commit firewall
				}
			else
				unsupported
			fi
			;;
		2)				
			if [ "$(dir_avail /etc)" != 0 ];then
				boot=old
				sbox cronset '#SBox守护进程' "*/1 * * * * $SBOX_DIR/sbox_core 1 #SBox守护进程"
				[ -f /etc/rc.common ] && /etc/init.d/sbox disable
				type systemctl >/dev/null && systemctl disable sbox.service
			else
				unsupported
			fi			
			;;
		3)
			if [ -f /data/etc/config/firewall ];then
				boot=mi_adv
				chmod 755 $SBOX_DIR/mi_adv.sh
				uci set firewall.ShellBox=include
				uci set firewall.ShellBox.type='script'
				uci set firewall.ShellBox.path='/data/ShellBox/mi_adv.sh'
				uci set firewall.ShellBox.enabled='1'
				uci commit firewall	
				sbox cronset '#SBox守护进程'
			else
				unsupported
			fi			
			;;
		4)	
			boot=disable
			sbox cronset '#SBox守护进程'
			[ -f /etc/rc.common ] && /etc/init.d/sbox disable
			type systemctl >/dev/null && systemctl disable sbox.service		
			;;
		*)			errornum			;;
	esac
	sbox set sbox.boot=$boot
	[ -z "$num" -o "$num" = 0 ] || set_boot
}
advanced(){
	echo -----------------------------------
	########################################
	secho " 1 启用小闪存模式"  
	secho " 2 指定处理器架构" 
	#secho " 3 获取非兼容插件"
	#secho " 4 添加第三方插件" 
	secho " 0 $lang_return_menu"	
	echo -----------------------------------
	read -p "$lang_input_num > " num
	########################################	
	case "$num" in
		1)			set_bindir			;;
		2)			set_arch			;;
		3)			
			sbox set sbox.app_test=true
			;;
		4)			add_other_tools		;;
		*)			errornum			;;
	esac
	[ -z "$num" -o "$num" = 0 ] || advanced
}
set_bindir(){
	input_dir(){
		df -h
		read -p "$lang_input_fold > " dir
		if [ ! -w $dir -o "$(dir_avail $dir)" = 0 ];then
			secho "没有目标目录写入权限！请重新输入！" 31
			input_dir
		else
			bin_dir=$dir/sbox/tools/app
		fi
	}
	echo -----------------------------------
	secho "注意：插件核心文件加载到内存后，重启设备后将自动重新下载相关文件" 33
	echo -----------------------------------
	########################################
	secho " 1 将核心文件下载到内存/tmp"  
	secho " 2 将核心文件下载到指定目录" 
	secho " 3 将核心文件下载到安装目录"
	secho " 0 $lang_return_menu"	
	echo -----------------------------------
	read -p "$lang_input_num > " num
	########################################	
	case "$num" in
		1)		bindir=/tmp/ShellBox_$USER/tools/app	;;
		2)		input_dir					;;
		3)		bindir=$SBOX_DIR			;;
		*)		errornum					;;
	esac
	#移动文件
	if [ "$bindir" != "$SBOX_DIR" ];then
		secho "$正在移动相关核心文件！"	
		for dir in "$(ls $SBOX_DIR/tools)";do
			[ -f $SBOX_DIR/tools/$dir/bin ] && mv -rf $SBOX_DIR/tools/$dir/bin $tmp_dir/tools/$dir
		done
	fi
	sbox set sbox.bin_dir=bindir
	[ -z "$num" -o "$num" = 0 ] || set_bindir	
}
set_arch(){
	arch=$(sbox get sbox.arch)
	arch_compa=$(sbox get sbox.arch_compa)
	[ "$arch_compa" =0 ] && arch_compa=$arch
	echo -----------------------------------
	secho "当前核心架构为：$arch;兼容架构为：$arch_compa"
	secho "兼容架构取决于当前核心架构，无法手动更改！"
	secho "错误的架构可能导致应用无法运行，请谨慎更改！"	31
	secho "适配请前往 https://github.com/juewuy/ShellBox/issues"	32
	echo -----------------------------------
	########################################
	secho " 1 armv5" 
	secho " 2 armv7(also armv5)" 
	secho " 3 armv8(also armv5)" 
	secho " 4 386"
	secho " 5 x86_64(also 386)"
	secho " 6 mips"
	secho " 7 mipsle(also mips)"
	secho " 0 $lang_return_menu"	
	echo -----------------------------------
	read -p "$lang_input_num > " num
	########################################	
	case "$num" in
		1)		arch=armv5;arch_compa=armv5		;;
		2)		arch=armv7;arch_compa=armv5		;;
		3)		arch=armv8;arch_compa=armv5		;;
		4)		arch=386;arch_compa=386			;;
		5)		arch=x86_64;arch_compa=386		;;
		6)		arch=mips;arch_compa=mips		;;
		7)		arch=mipsle;arch_compa=mips		;;
		*)		errornum						;;
	esac
	read -p "$确认更改？将移除已下载的内核文件！(1/0) > " res
	if [ "$res" = 1 ];then 
		bin_dir=get sbox.bin_dir
		[ "$bin_dir" = 0 ] && bin_dir=$SBOX_DIR/tools/app
		sbox set sbox.arch=arch
		sbox set sbox.arch_compa=arch_compa
		rm -rf /$bin_dir/*/bin
	fi
	[ -z "$num" -o "$num" = 0 ] || set_bindir	
}
#子菜单_其他功能	施工中
backup(){
	########################################
	secho " 1 施工中"  
	secho " 0 $lang_return_menu"	
	echo -----------------------------------
	read -p "$lang_input_num > " num
	########################################	
	case "$num" in
		1)			errornum			;;
		*)			errornum			;;
	esac
	[ -z "$num" -o "$num" = 0 ] || advanced
}
update(){
	########################################
	secho " 1 施工中"  
	secho " 0 $lang_return_menu"	
	echo -----------------------------------
	read -p "$lang_input_num > " num
	########################################	
	case "$num" in
		1)			errornum			;;
		*)			errornum			;;
	esac
	[ -z "$num" -o "$num" = 0 ] || advanced
}
ck_log(){
	########################################
	secho " 1 施工中"  
	secho " 0 $lang_return_menu"	
	echo -----------------------------------
	read -p "$lang_input_num > " num
	########################################	
	case "$num" in
		1)			errornum			;;
		*)			errornum			;;
	esac
	[ -z "$num" -o "$num" = 0 ] || advanced
}
about(){
	echo 111
}

case "$1" in

*)					menu				;;

esac
