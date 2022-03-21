#!/bin/sh
# Copyright (C) Juewuy

alias sbox="$SBOX_DIR/sbox_ctl"
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
setcpucore(){
	cpucore_list="armv5 armv7 armv8 386 amd64 mipsle-softfloat mipsle-hardfloat mips-softfloat"
	echo -----------------------------------------------
	echo -e "\033[31m仅适合脚本无法正确识别核心或核心无法正常运行时使用！\033[0m"
	echo -e "当前可供在线下载的处理器架构为："
	echo $cpucore_list | awk -F " " '{for(i=1;i<=NF;i++) {print i" "$i }}'
	echo -e "如果您的CPU架构未在以上列表中，请运行【uname -a】命令,并复制好返回信息"
	echo -e "之后前往 t.me/clashfm 群提交或 github.com/juewuy/ShellClash 提交issue"
	echo -----------------------------------------------
	read -p "请输入对应数字 > " num
	setcpucore=$(echo $cpucore_list | awk '{print $"'"$num"'"}' )
	if [ -z "$setcpucore" ];then
		echo -e "\033[31m请输入正确的处理器架构！\033[0m"
		sleep 1
		cpucore=""
	else
		cpucore=$setcpucore
		setconfig cpucore $cpucore
	fi
}
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
ShellBoxcfg(){
	set_redir_mod(){
		set_redir_config(){
			setconfig redir_mod $redir_mod
			setconfig dns_mod $dns_mod 
			echo -----------------------------------------------	
			secho "\033[36m已设为 $redir_mod ！！\033[0m"
		}
		echo -----------------------------------------------
		secho "当前代理模式为：\033[47;30m $redir_mod \033[0m；Clash核心为：\033[47;30m $ShellBoxcore \033[0m"
		secho "\033[33m切换模式后需要手动重启ShellBox服务以生效！\033[0m"
		secho "\033[36mTun及混合模式必须使用ShellBoxpre核心！\033[0m"
		echo -----------------------------------------------
		secho " 1 Redir模式：CPU以及内存\033[33m占用较低\033[0m"
		secho "              但\033[31m不支持UDP\033[0m"
		secho "              适合\033[32m非外服游戏用户\033[0m使用"
		secho " 2 混合模式： 使用redir转发TCP，Tun转发UDP流量"
		secho "              \033[33m速度较快\033[0m，\033[31m内存占用略高\033[0m"
		secho "              适合\033[32m游戏用户、综合用户\033[0m"
		secho " 3 Tun模式：  \033[33m支持UDP转发\033[0m且延迟最低"
		secho "              \033[31mCPU占用极高\033[0m，只支持fake-ip模式"
		secho "              \033[33m如非必要不推荐使用\033[0m"
		secho " 4 纯净模式： 不设置iptables静态路由"
		secho "              必须\033[33m手动配置\033[0mhttp/sock5代理"
		secho "              或使用内置的PAC文件配置代理"
		echo " 0 返回上级菜单"
		read -p "请输入对应数字 > " num	
		if [ -z "$num" ]; then
			errornum
		elif [ "$num" = 0 ]; then
			i=
		elif [ "$num" = 1 ]; then
			redir_mod=Redir模式
			dns_mod=redir_host
			set_redir_config
		elif [ "$num" = 3 ]; then
			ip tuntap >/dev/null 2>&1
			if [ "$?" != 0 ];then
				echo -----------------------------------------------
				secho "\033[31m当前设备内核可能不支持开启Tun/混合模式！\033[0m"
				read -p "是否强制开启？可能无法正常使用！(1/0) > " res
				if [ "$res" = 1 ];then
					redir_mod=Tun模式
					dns_mod=fake-ip
					set_redir_config
				else
					set_redir_mod
				fi
			else	
				redir_mod=Tun模式
				dns_mod=fake-ip
				set_redir_config
			fi
		elif [ "$num" = 2 ]; then
			ip tuntap >/dev/null 2>&1
			if [ "$?" != 0 ];then
				secho "\033[31m当前设备内核可能不支持开启Tun/混合模式！\033[0m"
				read -p "是否强制开启？可能无法正常使用！(1/0) > " res
				if [ "$res" = 1 ];then
					redir_mod=混合模式
					set_redir_config
				else
					set_redir_mod
				fi
			else	
				redir_mod=混合模式	
				set_redir_config
			fi
		elif [ "$num" = 4 ]; then
			redir_mod=纯净模式	
			set_redir_config		
			echo -----------------------------------------------
			secho "\033[33m当前模式需要手动在设备WiFi或应用中配置HTTP或sock5代理\033[0m"
			secho "HTTP/SOCK5代理服务器地址：\033[30;47m$host\033[0m;端口均为：\033[30;47m$mix_port\033[0m"
			secho "也可以使用更便捷的PAC自动代理，PAC代理链接为："
			secho "\033[30;47m http://$host:$db_port/ui/pac \033[0m"
			secho "PAC的使用教程请参考：\033[4;32mhttps://juewuy.github.io/ehRUeewcv\033[0m"
			sleep 2
		else
			errornum
		fi

	}
	set_dns_mod(){
		echo -----------------------------------------------
		secho "当前DNS运行模式为：\033[47;30m $dns_mod \033[0m"
		secho "\033[33m切换模式后需要手动重启ShellBox服务以生效！\033[0m"
		echo -----------------------------------------------
		secho " 1 fake-ip模式：   \033[32m响应速度更快\033[0m"
		secho "                   兼容性比较差，部分应用可能打不开"
		secho " 2 redir_host模式：\033[32m兼容性更好\033[0m"
		secho "                   不支持Tun模式，抗污染能力略差"
		echo " 0 返回上级菜单"
		read -p "请输入对应数字 > " num
		if [ -z "$num" ]; then
			errornum
		elif [ "$num" = 0 ]; then
			i=
		elif [ "$num" = 1 ]; then
			set_fake_ip(){
				dns_mod=fake-ip
				setconfig dns_mod $dns_mod 
				echo -----------------------------------------------	
				secho "\033[36m已设为 $dns_mod 模式！！\033[0m"
				}
			if [ "$redir_mod" = "Redir模式" ];then
				echo -----------------------------------------------	
				read -p "fake-ip与Redir模式兼容性较差，是否依然强制使用？(1/0) > "	res
				[ "$res" = 1 ] && set_fake_ip
			else
				set_fake_ip
			fi

		elif [ "$num" = 2 ]; then
			dns_mod=redir_host
			setconfig dns_mod $dns_mod 
			echo -----------------------------------------------	
			secho "\033[36m已设为 $dns_mod 模式！！\033[0m"
		else
			errornum
		fi
	}
	
	#获取设置默认显示
	[ -z "$skip_cert" ] && skip_cert=已开启
	[ -z "$common_ports" ] && common_ports=已开启
	[ -z "$dns_mod" ] && dns_mod=redir_host
	[ -z "$dns_over" ] && dns_over=已开启
	[ -z "$cn_ip_route" ] && cn_ip_route=未开启
	[ -z "$(cat $ShellBoxdir/mac)" ] && mac_return=未开启 || mac_return=已启用
	#
	echo -----------------------------------------------
	secho "\033[30;47m欢迎使用功能设置菜单：\033[0m"
	echo -----------------------------------------------
	secho " 1 切换Clash运行模式: 	\033[36m$redir_mod\033[0m"
	secho " 2 切换DNS运行模式：	\033[36m$dns_mod\033[0m"
	secho " 3 跳过本地证书验证：	\033[36m$skip_cert\033[0m   ————解决节点证书验证错误"
	secho " 4 只代理常用端口： 	\033[36m$common_ports\033[0m   ————用于过滤P2P流量"
	secho " 5 过滤局域网设备：	\033[36m$mac_return\033[0m   ————使用黑/白名单进行过滤"
	secho " 6 设置本机代理服务:	\033[36m$local_proxy\033[0m   ————使本机流量经过ShellBox内核"
	secho " 7 CN_IP绕过内核:	\033[36m$cn_ip_route\033[0m   ————优化性能，不兼容Fake-ip"
	echo -----------------------------------------------
	secho " 0 返回上级菜单 \033[0m"
	echo -----------------------------------------------
	read -p "请输入对应数字 > " num
	if [ -z "$num" ]; then
		errornum
	elif [ "$num" = 0 ]; then
		i=
	elif [ "$num" = 1 ]; then
		if [ "$USER" != "root" -a "$USER" != "admin" ];then
			echo -----------------------------------------------
			read -p "非root用户可能无法正确配置其他模式！依然尝试吗？(1/0) > " res
			[ "$res" = 1 ] && set_redir_mod
		else
			set_redir_mod
		fi
		ShellBoxcfg
	  
	elif [ "$num" = 2 ]; then
		set_dns_mod
		ShellBoxcfg
	
	elif [ "$num" = 3 ]; then	
		echo -----------------------------------------------
		if [ "$skip_cert" = "未开启" ] > /dev/null 2>&1; then 
			secho "\033[33m已设为开启跳过本地证书验证！！\033[0m"
			skip_cert=已开启
		else
			secho "\033[33m已设为禁止跳过本地证书验证！！\033[0m"
			skip_cert=未开启
		fi
		setconfig skip_cert $skip_cert 
		ShellBoxcfg
	
	elif [ "$num" = 4 ]; then	
		echo -----------------------------------------------	
		if [ "$common_ports" = "未开启" ] > /dev/null 2>&1; then 
			secho "\033[33m已设为仅代理【$multiport】等常用端口！！\033[0m"
			common_ports=已开启
		else
			secho "\033[33m已设为代理全部端口！！\033[0m"
			common_ports=未开启
		fi
		setconfig common_ports $common_ports
		ShellBoxcfg  

	elif [ "$num" = 5 ]; then	
		macfilter
		ShellBoxcfg
		
	elif [ "$num" = 6 ]; then	
		localproxy
		sleep 1
		ShellBoxcfg
		
	elif [ "$num" = 7 ]; then
		echo -----------------------------------------------
		if ! ipset -v >/dev/null 2>&1;then
			secho "\033[31m当前设备缺少ipset模块，无法启用绕过功能！！\033[0m"
			sleep 1
		elif [ "$dns_mod" = "fake-ip" ];then
			secho "\033[31m不支持fake-ip模式，请将DNS模式更换为Redir-host！！\033[0m"
			sleep 1
			ShellBoxcfg
		else
			if [ "$cn_ip_route" = "未开启" ]; then 
				secho "\033[32m已开启CN_IP绕过内核功能！！\033[0m"
				cn_ip_route=已开启
				sleep 1
			else
				secho "\033[33m已禁用CN_IP绕过内核功能！！\033[0m"
				cn_ip_route=未开启
			fi
			setconfig cn_ip_route $cn_ip_route
		fi
			ShellBoxcfg  	
		
	elif [ "$num" = 9 ]; then	
		ShellBoxstart
	else
		errornum
	fi
}
ShellBoxadv(){
	#获取设置默认显示
	[ -z "$modify_yaml" ] && modify_yaml=未开启
	[ -z "$ipv6_support" ] && ipv6_support=未开启
	[ -z "$start_old" ] && start_old=未开启
	[ -z "$tproxy_mod" ] && tproxy_mod=未开启
	[ -z "$public_support" ] && public_support=未开启
	[ "$bindir" = "/tmp/ShellBox_$USER" ] && mini_ShellBox=已开启 || mini_ShellBox=未开启
	#
	echo -----------------------------------------------
	secho "\033[30;47m欢迎使用进阶模式菜单：\033[0m"
	secho "\033[33m如您并不了解ShellBox的运行机制，请勿更改本页面功能！\033[0m"
	echo -----------------------------------------------
	secho " 1 使用保守模式启动:	\033[36m$start_old\033[0m	————切换时会停止ShellBox服务"
	secho " 2 启用ipv6支持:	\033[36m$ipv6_support\033[0m	————实验性功能，可能不稳定"
	secho " 3 Redir模式udp转发:	\033[36m$tproxy_mod\033[0m	————依赖iptables-mod-tproxy"
	secho " 4 启用小闪存模式:	\033[36m$mini_ShellBox\033[0m	————不保存核心及数据库文件"
	secho " 5 允许公网访问:	\033[36m$public_support\033[0m	————需要路由拨号+公网IP"
	secho " 6 配置内置DNS服务	\033[36m$dns_no\033[0m"
	secho " 7 使用自定义配置"
	secho " 8 手动指定相关端口、秘钥及本机host"
	echo -----------------------------------------------
	secho " 9 \033[31m重置/备份/还原\033[0m脚本设置"
	secho " 0 返回上级菜单 \033[0m"
	echo -----------------------------------------------
	read -p "请输入对应数字 > " num
	if [ -z "$num" ]; then
		errornum
	elif [ "$num" = 0 ]; then
		i=
	elif [ "$num" = 1 ]; then	
		echo -----------------------------------------------
		if [ "$start_old" = "未开启" ] > /dev/null 2>&1; then 
			secho "\033[33m改为使用保守模式启动ShellBox服务！！\033[0m"
			secho "\033[31m注意：部分设备保守模式可能无法禁用开机启动！！\033[0m"
			start_old=已开启
			setconfig start_old $start_old
			$ShellBoxdir/start.sh stop
		else
			if [ -f /etc/init.d/ShellBox -o -w /etc/systemd/system -o -w /usr/lib/systemd/system ];then
				secho "\033[32m改为使用默认方式启动ShellBox服务！！\033[0m"
				$ShellBoxdir/start.sh cronset "ShellClash初始化"
				start_old=未开启
				setconfig start_old $start_old
				$ShellBoxdir/start.sh stop
				
			else
				secho "\033[31m当前设备不支持以其他模式启动！！\033[0m"
			fi
		fi
		sleep 1
		ShellBoxadv 
		
	elif [ "$num" = 2 ]; then
		echo -----------------------------------------------
		if [ "$ipv6_support" = "未开启" ] > /dev/null 2>&1; then 
			secho "\033[33m已开启对ipv6协议的支持！！\033[0m"
			secho "Clash对ipv6的支持并不友好，如不能使用请静等修复！"
			ipv6_support=已开启
			sleep 2
		else
			secho "\033[32m已禁用对ipv6协议的支持！！\033[0m"
			ipv6_support=未开启
		fi
		setconfig ipv6_support $ipv6_support
		ShellBoxadv   
		
	elif [ "$num" = 3 ]; then	
		echo -----------------------------------------------
		if [ "$tproxy_mod" = "未开启" ]; then 
			if [ -n "$(iptables -j TPROXY 2>&1 | grep 'on-port')" ];then
				tproxy_mod=已开启
				secho "\033[32m已经为Redir模式启用udp转发功能！\033[0m"
			else
				tproxy_mod=未开启
				secho "\033[31m您的设备不支持tproxy模式，无法开启！\033[0m"
			fi
		else
			tproxy_mod=未开启
			secho "\033[33m已经停止使用tproxy转发udp流量！！\033[0m"
		fi
		setconfig tproxy_mod $tproxy_mod
		sleep 1
		ShellBoxadv 	
		
	elif [ "$num" = 4 ]; then	
		echo -----------------------------------------------
		dir_size=$(df $ShellBoxdir | awk '{print $4}' | sed 1d)
		if [ "$mini_ShellBox" = "未开启" ]; then 
			if [ "$dir_size" -gt 20480 ];then
				secho "\033[33m您的设备空间充足(>20M)，无需开启！\033[0m"
			elif pidof systemd >/dev/null 2>&1;then
				secho "\033[33m该设备不支持开启此模式！\033[0m"
			else
				bindir="/tmp/ShellBox_$USER"
				secho "\033[32m已经启用小闪存功能！\033[0m"
				secho "核心及数据库文件将存储在内存中执行，并在每次开机运行后自动下载\033[0m"
			fi
		else
			if [ "$dir_size" -lt 8192 ];then
				secho "\033[31m您的设备剩余空间不足8M，停用后可能无法正常运行！\033[0m"
				read -p "确认停用此功能？(1/0) > " res
				[ "$res" = 1 ] && bindir="$ShellBoxdir" && secho "\033[33m已经停用小闪存功能！\033[0m"
			else
				rm -rf /tmp/ShellBox_$USER
				bindir="$ShellBoxdir"
				secho "\033[33m已经停用小闪存功能！\033[0m"
			fi
		fi
		setconfig bindir $bindir
		sleep 1
		ShellBoxadv
		
	elif [ "$num" = 5 ]; then
		if [ "$public_support" = "未开启" ]; then 
			secho "\033[32m已开启公网访问Dashboard端口及Http/Sock5代理端口！！\033[0m"
			secho "\033[33m安全起见建议设置相关访问密码！！\033[0m"
			public_support=已开启
			setconfig public_support $public_support
			sleep 1
		else
			secho "\033[32m已禁止公网访问Dashboard端口及Http/Sock5代理端口！！\033[0m"
			secho "\033[33m如果你的防火墙默认放行公网流量，可能禁用失败！\033[0m"
			public_support=未开启
			setconfig public_support $public_support
			sleep 1
		fi
			ShellBoxadv
		
	elif [ "$num" = 6 ]; then
		source $ccfg
		if [ "$dns_no" = "已禁用" ];then
			read -p "检测到内置DNS已被禁用，是否启用内置DNS？(1/0) > " res
			if [ "$res" = "1" ];then
				setconfig dns_no
				setdns
			fi
		else
			setdns
		fi
		ShellBoxadv	
		
	elif [ "$num" = 8 ]; then
		source $ccfg
		if [ -n "$(pidof ShellBox)" ];then
			echo -----------------------------------------------
			secho "\033[33m检测到ShellBox服务正在运行，需要先停止ShellBox服务！\033[0m"
			read -p "是否停止ShellBox服务？(1/0) > " res
			if [ "$res" = "1" ];then
				$ShellBoxdir/start.sh stop
				setport
			fi
		else
			setport
		fi
		ShellBoxadv
		
	elif [ "$num" = 7 ]; then
		[ ! -f $ShellBoxdir/user.yaml ] && cat > $ShellBoxdir/user.yaml <<EOF
#用于编写自定义设定(可参考https://lancellc.gitbook.io/ShellBox)，例如
#新版已经支持直接读取系统hosts(/etc/hosts)并写入配置文件，无需在此处添加！
#port: 7890
EOF
		[ ! -f $ShellBoxdir/rules.yaml ] && cat > $ShellBoxdir/rules.yaml <<EOF
#用于编写自定义规则(此处规则将优先生效)，(可参考https://lancellc.gitbook.io/ShellBox/ShellBox-config-file/rules)：
#例如“🚀 节点选择”、“🎯 全球直连”这样的自定义规则组必须与config.yaml中的代理规则组相匹配，否则将无法运行
# - DOMAIN-SUFFIX,google.com,🚀 节点选择
# - DOMAIN-KEYWORD,baidu,🎯 全球直连
# - DOMAIN,ad.com,REJECT
# - SRC-IP-CIDR,192.168.1.201/32,DIRECT
# - IP-CIDR,127.0.0.0/8,DIRECT
# - IP-CIDR6,2620:0:2d0:200::7/32,🚀 节点选择
# - DST-PORT,80,DIRECT
# - SRC-PORT,7777,DIRECT
EOF
		secho "\033[32m已经启用自定义配置功能！\033[0m"
		secho "Windows下请\n使用\033[33mwinscp软件\033[0m进入$ShellBoxdir目录后手动编辑！\033[0m"
		secho "Shell下(\033[31m部分旧设备可能不显示中文\033[0m)可\n使用【\033[36mvi $ShellBoxdir/user.yaml\033[0m】编辑自定义设定文件;\n使用【\033[36mvi $ShellBoxdir/rules.yaml\033[0m】编辑自定义规则文件。"
		secho "如需自定义节点，可以在config.yaml文件中修改或者直接替换config.yaml文件！\033[0m"
		sleep 3
		ShellBoxadv
		
	elif [ "$num" = 9 ]; then	
		secho " 1 备份脚本设置"
		secho " 2 还原脚本设置"
		secho " 3 重置脚本设置"
		secho " 0 返回上级菜单"
		echo -----------------------------------------------
		read -p "请输入对应数字 > " num
		if [ -z "$num" ]; then
			errornum
		elif [ "$num" = 0 ]; then
			i=
		elif [ "$num" = 1 ]; then
			cp -f $ccfg $ccfg.bak
			secho "\033[32m脚本设置已备份！\033[0m"
		elif [ "$num" = 2 ]; then
			if [ -f "$ccfg.bak" ];then
				mv -f $ccfg $ccfg.bak2
				mv -f $ccfg.bak $ccfg
				mv -f $ccfg.bak2 $ccfg.bak
				secho "\033[32m脚本设置已还原！(被覆盖的配置已备份！)\033[0m"
			else
				secho "\033[31m找不到备份文件，请先备份脚本设置！\033[0m"
			fi
		elif [ "$num" = 3 ]; then
			mv -f $ccfg $ccfg.bak
			secho "\033[32m脚本设置已重置！(旧文件已备份！)\033[0m"
		fi
		secho "\033[33m请重新启动脚本！\033[0m"
		exit 0

	else
		errornum
	fi
}
tools(){
	ssh_tools(){
		stop_iptables(){
			iptables -t nat -D PREROUTING -p tcp -m multiport --dports $ssh_port -j REDIRECT --to-ports 22 >/dev/null 2>&1
			ip6tables -t nat -A PREROUTING -p tcp -m multiport --dports $ssh_port -j REDIRECT --to-ports 22 >/dev/null 2>&1
		}
		[ -n "$(cat /etc/firewall.user 2>&1 | grep '启用外网访问SSH服务')" ] && ssh_ol=禁止 || ssh_ol=开启
		[ -z "$ssh_port" ] && ssh_port=10022
		echo -----------------------------------------------
		secho "\033[33m此功能仅针对使用Openwrt系统的设备生效，且不依赖ShellBox服务\033[0m"
		secho "\033[31m本功能不支持红米AX6S等镜像化系统设备，请勿尝试！\033[0m"
		echo -----------------------------------------------
		secho " 1 \033[32m修改\033[0m外网访问端口：\033[36m$ssh_port\033[0m"
		secho " 2 \033[32m修改\033[0mSSH访问密码(请连续输入2次后回车)"
		secho " 3 \033[33m$ssh_ol\033[0m外网访问SSH"
		echo -----------------------------------------------
		secho " 0 返回上级菜单 \033[0m"
		echo -----------------------------------------------
		read -p "请输入对应数字 > " num
			if [ -z "$num" ]; then
				errornum
			elif [ "$num" = 0 ]; then
				i=
				
			elif [ "$num" = 1 ]; then
				read -p "请输入端口号(1000-65535) > " num
					if [ -z "$num" ]; then
						errornum
					elif [ $num -gt 65535 -o $num -le 999 ]; then
						secho "\033[31m输入错误！请输入正确的数值(1000-65535)！\033[0m"
					elif [ -n "$(netstat -ntul |grep :$num)" ];then
						secho "\033[31m当前端口已被其他进程占用，请重新输入！\033[0m"
					else
						ssh_port=$num
						setconfig ssh_port $ssh_port
						sed -i "/启用外网访问SSH服务/d" /etc/firewall.user
						stop_iptables
						secho "\033[32m设置成功，请重新开启外网访问SSH功能！！！\033[0m"
					fi
				sleep 1
				ssh_tools
				
			elif [ "$num" = 2 ]; then
				passwd
				sleep 1
				ssh_tools
				
			elif [ "$num" = 3 ]; then	 
				if [ "$ssh_ol" = "开启" ];then
					iptables -t nat -A PREROUTING -p tcp -m multiport --dports $ssh_port -j REDIRECT --to-ports 22
					[ -n "$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p tcp -m multiport --dports $ssh_port -j REDIRECT --to-ports 22
					echo "iptables -t nat -A PREROUTING -p tcp -m multiport --dports $ssh_port -j REDIRECT --to-ports 22 #启用外网访问SSH服务" >> /etc/firewall.user
					[ -n "$(command -v ip6tables)" ] && echo "ip6tables -t nat -A PREROUTING -p tcp -m multiport --dports $ssh_port -j REDIRECT --to-ports 22 #启用外网访问SSH服务" >> /etc/firewall.user
					echo -----------------------------------------------
					secho "已开启外网访问SSH功能！"
				else
					sed -i "/启用外网访问SSH服务/d" /etc/firewall.user
					stop_iptables
					echo -----------------------------------------------
					secho "已禁止外网访问SSH！"
				fi
			else
				errornum
			fi
			}
	#获取设置默认显示
	[ -n "$(cat /etc/crontabs/root 2>&1| grep otapredownload)" ] && mi_update=禁用 || mi_update=启用
	[ "$mi_autoSSH" = "已启用" ] && mi_autoSSH_type=32m已启用 || mi_autoSSH_type=31m未启用
	#
	echo -----------------------------------------------
	secho "\033[30;47m欢迎使用其他工具菜单：\033[0m"
	secho "\033[33m本页工具可能无法兼容全部Linux设备，请酌情使用！\033[0m"
	secho "磁盘占用/所在目录："
	du -sh $ShellBoxdir
	echo -----------------------------------------------
	secho " 1 ShellClash测试菜单"
	[ -f /etc/firewall.user ] && secho " 2 \033[32m配置\033[0m外网访问SSH"
	[ -f /etc/config/ddns -a -d "/etc/ddns" ] && secho " 3 配置DDNS服务(需下载相关脚本)"
	secho " 4 \033[32m流媒体预解析\033[0m————用于解决DNS解锁在TV应用上失效的问题"
	[ -x /usr/sbin/otapredownload ] && secho " 5 \033[33m$mi_update\033[0m小米系统自动更新"
	[ -f /usr/sbin/otapredownload ] && secho " 6 小米设备软固化SSH ———— \033[$mi_autoSSH_type \033[0m"
	echo -----------------------------------------------
	secho " 0 返回上级菜单"
	echo -----------------------------------------------
	read -p "请输入对应数字 > " num
	if [ -z "$num" ]; then
		errornum
	elif [ "$num" = 0 ]; then
		i=
		
	elif [ "$num" = 1 ]; then
		source $ShellBoxdir/getdate.sh && testcommand  
		
	elif [ "$num" = 2 ]; then
		ssh_tools
		sleep 1
		tools  
		
	elif [ "$num" = 3 ]; then
		echo -----------------------------------------------
		if [ ! -f $ShellBoxdir/ShellDDNS.sh ];then
			secho "正在获取在线脚本……"
			$ShellBoxdir/start.sh webget /tmp/ShellDDNS.sh $update_url/tools/ShellDDNS.sh
			if [ "$?" = "0" ];then
				mv -f /tmp/ShellDDNS.sh $ShellBoxdir/ShellDDNS.sh
				source $ShellBoxdir/ShellDDNS.sh
			else
				secho "\033[31m文件下载失败！\033[0m"
			fi
		else
			source $ShellBoxdir/ShellDDNS.sh
		fi
		sleep 1
		tools  
		
	elif [ "$num" = 4 ]; then
		if type nslookup > /dev/null 2>&1;then
			checkcfg=$(cat $ccfg)
			streaming
			if [ -n "$PID" ];then
				checkcfg_new=$(cat $ccfg)
				[ "$checkcfg" != "$checkcfg_new" ] && checkrestart
			fi
		else
			echo -----------------------------------------------
			echo "当前设备缺少nslookup命令，无法启用流媒体预解析功能！"
			echo "Centos请尝试使用以下命令安装【yum -y install bind-utils】"
			echo "Debian/Ubuntu等请尝试使用【sudo apt-get install dnsutils -y】"
			sleep 1
		fi
		tools
		
	elif [ -x /usr/sbin/otapredownload ] && [ "$num" = 5 ]; then	
		[ "$mi_update" = "禁用" ] && sed -i "/otapredownload/d" /etc/crontabs/root || echo "15 3,4,5 * * * /usr/sbin/otapredownload >/dev/null 2>&1" >> /etc/crontabs/root	
		echo -----------------------------------------------
		secho "已\033[33m$mi_update\033[0m小米路由器的自动启动，如未生效，请在官方APP中同步设置！"
		sleep 1
		tools	
		
	elif [ -f /usr/sbin/otapredownload ] && [ "$num" = 6 ]; then
		if [ "$mi_autoSSH" = "已启用" ];then
			mi_autoSSH=禁用
		else
			echo -----------------------------------------------
			secho "\033[33m本功能使用软件命令进行固化不保证100%成功！\033[0m"
			secho "本功能需依赖ShellBox服务，请确保ShellBox为开机启动状态！"
			secho "\033[33m如有问题请加群反馈：\033[36;4mhttps://t.me/ShellBoxfm\033[0m"
			read -p "请输入需要还原的SSH密码(不影响当前密码,回车可跳过) > " mi_autoSSH_pwd
			mi_autoSSH=已启用
			if [ "$systype" = "mi_snapshot" ];then
				cp -f /etc/dropbear/dropbear_rsa_host_key $ShellBoxdir/dropbear_rsa_host_key 2>/dev/null
				secho "\033[32m检测当前为小米镜像化系统，已将SSH秘钥备份到脚本安装目录！\033[0m"
				secho "\033[32mClash会在启动时自动还原已备份的秘钥文件！\033[0m"
			fi
			secho "\033[32m设置成功！\033[0m"
		fi
		setconfig mi_autoSSH $mi_autoSSH
		setconfig mi_autoSSH_pwd $mi_autoSSH_pwd
		tools		
	else
		errornum
	fi
}
ShellBoxcron(){
	croncmd(){
		if [ -n "$(crontab -h 2>&1 | grep '\-l')" ];then
			crontab $1
		else
			crondir="$(crond -h 2>&1 | grep -oE 'Default:.*' | awk -F ":" '{print $2}')"
			[ ! -w "$crondir" ] && crondir="/etc/storage/cron/crontabs"
			[ ! -w "$crondir" ] && crondir="/var/spool/cron/crontabs"
			[ ! -w "$crondir" ] && crondir="/var/spool/cron"
			[ ! -w "$crondir" ] && echo "你的设备不支持定时任务配置，脚本大量功能无法启用，请前往 https://t.me/ShellBoxfm 申请适配！"
			[ "$1" = "-l" ] && cat $crondir/$USER 2>/dev/null
			[ -f "$1" ] && cat $1 > $crondir/$USER
		fi
	}
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
	echo -----------------------------------------------
	secho "\033[30;46m$lang_welcome ShellBox！\033[0m			$version"
	[ -n "$(pidof sbox_core)" ] && secho "ShellBox$lang_has_run：\033[46;30m"$day"\033[44;37m"$time"\033[0m"
	secho "$lang_mem_free：${mem_free}M	$lang_disk_info：$disk_sbox/$disk_free"
	secho "Telgram：\033[36;4mhttps://t.me/ShellBox\033[0m"
	echo -----------------------------------------------	
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
	[ "$num" = 0 ] || menu
}
#子菜单_插件相关
tools_service(){
	list=$SBOX_DIR/config/service.list
	numbers=$(cat $list | wc -l)
	if [ "$numbers" -gt 0 ];then
		echo -----------------------------------
		secho "正在运行的服务：" 
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
					set_tools $app
				else
					errornum
				fi
				;;
			a)			tools_cron			;;
			b)			tools_local			;;
			c)			tools_online		;;
			*)			errornum			;;
		esac
		[ "$norl" = 0 ] || tools_service
	else
		secho "没有正在运行的服务，已帮你跳转到插件列表！"	31
		lang_tools_local
	fi
}
tools_local(){
	list=$SBOX_DIR/config/local.list
	numbers=$(cat $list | wc -l)
	if [ "$numbers" -gt 0 ];then
		echo -----------------------------------
		secho "已安装但未运行的插件：" 
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
					set_tools $tools
				else
					errornum
				fi
				;;
			a)			tools_service		;;
			b)			tools_cron			;;
			c)			tools_online		;;
			*)			errornum			;;
		esac
		[ "$norl" = 0 ] || tools_local
	else
		secho "没有找到已安装插件，已帮你跳转至在线插件列表！"	31
		tools_online
	fi
tools_online(){
	update_url=$(sbox get sbox.update_url)
	$SBOX_DIR/webget 
	list=$SBOX_DIR/config/local.list
	numbers=$(cat $list | wc -l)
	if [ "$numbers" -gt 0 ];then
		echo -----------------------------------
		secho "已安装但未运行的插件：" 
		cat $list | awk '{print " "NR" "$1}'
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
					set_tools $tools
				else
					errornum
				fi
				;;
			a)			tools_service		;;
			b)			tools_cron			;;
			c)			tools_local		;;
			*)			errornum			;;
		esac
		[ "$norl" = 0 ] || tools_online
	else
		secho "没有找到已安装插件，已帮你跳转至在线插件列表！"	31
		lang_tools_local
	fi
set_tools(){
	[ -n "$(pidof $1)" ] && start_stop=\033[31m$lang_stop || start_stop=\033[32m$lang_start
	########################################
	secho " 1 ${start_stop}$1\033[0m"  
	secho " 2 $修改启动方式"		
	secho " 3 $进阶功能设置"
	secho " 4 $配置备份还原"	
	secho " 5 $查看后台日志"
	secho " 6 $更新ShellBox"	
	secho " 9 $卸载ShellBox"
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
	[ "$num" = 0 ] || set_sbox
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
				set_crons $cron
			else
				errornum
			fi
			;;
		a)			set_crons			;;
		b)			tools_service		;;
		c)			tools_local			;;
		d)			tools_online		;;
		*)			errornum			;;
	esac
	[ "$norl" = 0 ] || tools_cron
}

#子菜单_sbox相关
set_sbox(){
	[ -n "$(pidof sbox_core)" ] && sbox_start=\033[31m$lang_stop || start_stop=\033[32m$lang_start
	########################################
	secho " 1 $sbox_startShellBox\033[0m"  
	secho " 2 $修改启动方式"		
	secho " 3 $进阶功能设置"
	secho " 4 $配置备份还原"	
	secho " 5 $查看后台日志"
	secho " 6 $更新ShellBox"	
	secho " 9 $卸载ShellBox"
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
	[ "$num" = 0 ] || set_sbox
}
set_boot(){
	boot=$(sbox get sbox.boot)
	
	echo -----------------------------------
	secho "当前启动状态：$boot" 
	echo -----------------------------------
	########################################
	secho " 1 $使用守护进程"  
	secho " 2 $使用定时任务"		
	secho " 3 $小米增强启动"
	secho " 4 $禁止开机启动"	
	secho " 0 $lang_return_menu"	
	echo -----------------------------------
	read -p "$lang_input_num > " num
	########################################	
	case "$num" in
		1)			set_boot			;;
		2)			set_boot			;;
		3)			advanced			;;
		4)			backup				;;
		*)			errornum			;;
	esac
	[ "$num" = 0 ] || set_boot
}
advanced(){
	echo -----------------------------------
	secho "当前启动状态：$boot" 
	echo -----------------------------------
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
	[ "$num" = 0 ] || advanced
}
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
	[ "$num" = 0 ] || advanced
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
	[ "$num" = 0 ] || advanced
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
	[ "$num" = 0 ] || advanced
}


about(){
	echo 111
}

case "$1" in

*)					menu				;;

esac
