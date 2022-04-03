#! /bin/bash
# Copyright (C) Juewuy

########################################################################################################
					echo "***********************************************"
					echo "**                 欢迎使用                  **"
					echo "**               	 ShellBox ！     	       **"
					echo "**                             by  Juewuy    **"
					echo "***********************************************"
########################################################################################################

#脚本工具
dir_avail(){
	df -h $1 | awk '{ for(i=1;i<=NF;i++){ if(NR==1){ arr[i]=$i; }else{ arr[i]=arr[i]" "$i; } } } END{ for(i=1;i<=NF;i++){ print arr[i]; } }' | grep Ava | awk '{print $2}'
}
webget(){
	#参数【$1】代表目标路径，【$2】代表在线路径
	#参数【$3】代表重试次数，【$4】代表输出显示
	[ -z "$3" ] && j=1 || j=$3
	for ((i=1;i<=j;i++));do
		if curl --version > /dev/null 2>&1;then
			[ "$4" = "echooff" ] && progress='-s' || progress='-#'
			result=$(curl -w %{http_code} --connect-timeout 5 $progress $redirect -ko $1 $2)
			[ -n "$(echo $result | grep -e ^2)" ] && return 0
		else
			if wget --version > /dev/null 2>&1;then
				[ "$4" = "echooff" ] && progress='-q' || progress='-q --show-progress'
				certificate='--no-check-certificate'
				timeout='--timeout=3'
			fi
			[ "$4" = "echoon" ] && progress=''
			[ "$4" = "echooff" ] && progress='-q'
			wget $progress $redirect $certificate $timeout -O $1 $2 
			[ $? -eq 0 ] && return 0
		fi
	done
	return 1
}
gettar(){
	tmp_dir=/tmp/ShellBox/ShellBox.tar.gz
	#下载
	webget $tmp_dir $tarurl 2
	[ "$?" != 0 ] && echo "文件下载失败,请尝试使用其他安装源！" && exit 1
	#解压
	echo -----------------------------------------------
	echo 开始解压文件！
	mkdir -p $SBOX_DIR > /dev/null
	tar -zxvf '$tmp_dir' -C $SBOX_DIR/
	[ "$?" != 0 ] && echo "文件解压失败,已退出！" && rm -rf $tmp_dir && exit 1
	rm -rf $tmp_dir
	#修饰文件
	sed -i "s#/bin/sh#/bin/$shtype#" $SBOX_DIR/sbox_ctl
	sed -i "s#/bin/sh#/bin/$shtype#" $SBOX_DIR/sbox_core
	chmod 755 $SBOX_DIR/sbox_ctl $SBOX_DIR/sbox_core
	#判断系统类型写入不同的启动文件
	if [ -f /etc/rc.common ];then
			#设为init.d方式启动
			ln -sf $SBOX_DIR/sbox_rc /etc/init.d/sbox
			chmod 755 /etc/init.d/sbox
			rm -rf $SBOX_DIR/sbox_systemd
	else
		[ -w /etc/systemd/system ] && sysdir=/etc/systemd/system
		[ -w /usr/lib/systemd/system ] && sysdir=/usr/lib/systemd/system
		if [ -n "$sysdir" ];then
			#设为systemd方式启动
			ln -sf $SBOX_DIR/sbox_systemd $sysdir/sbox.service
			sed -i "s#/etc/clash#${SBOX_DIR}#g" $SBOX_DIR/sbox_systemd
			systemctl daemon-reload 2>/dev/null
			rm -rf $SBOX_DIR/sbox_rc
		else
			$SBOX_DIR/sbox_ctl set sbox.boot=old #设为保守模式
			rm -rf $SBOX_DIR/sbox_systemd
			rm -rf $SBOX_DIR/sbox_rc
		fi
	fi
	#存档版本号和url地址
	$SBOX_DIR/sbox_ctl set sbox.version=$version
	$SBOX_DIR/sbox_ctl set sbox.update_url=$url
	$SBOX_DIR/sbox_ctl set sbox.systype=$systype
	#华硕/Padavan额外设置
	[ -n "$initdir" ] && sed -i '/SBox初始化/'d $initdir && touch $initdir && \
	echo "$SBOX_DIR/start.sh init #SBox初始化" >> $initdir
	#小米增强启动
	if [ "$systype" = "mi_snapshot" ];then
		chmod 755 $SBOX_DIR/mi_adv.sh
		uci set firewall.ShellBox=include
		uci set firewall.ShellBox.type='script'
		uci set firewall.ShellBox.path='/data/ShellBox/mi_adv.sh'
		uci set firewall.ShellBox.enabled='1'
		uci commit firewall
		$SBOX_DIR/sbox_ctl set sbox.boot=mi_adv
	fi
}
install(){
echo -----------------------------------------------
$echo "\033[33m开始从服务器获取安装文件！\033[0m"
echo -----------------------------------------------
gettar
$echo "\033[32m文件安装成功，正在初始化脚本！\033[0m"
$SBOX_DIR/sbox_ctl init
echo -----------------------------------------------
$echo "\033[32m ShellBox 安装成功!\033[0m"
[ "$profile" = "~/.bashrc" ] && echo "请执行【source ~/.bashrc &> /dev/null】命令以加载环境变量！"
echo -----------------------------------------------
$echo "\033[33m输入\033[30;47m sbox \033[0;33m命令即可管理工具箱！！！\033[0m"
echo -----------------------------------------------
}
setdir(){
if [ -n "$systype" ];then
	[ "$systype" = "Padavan" ] && dir=/etc/storage
	[ "$systype" = "asusrouter" ] && dir=/jffs
	[ "$systype" = "mi_snapshot" ] && dir=/data
else
	echo -----------------------------------------------
	$echo "\033[33m安装ShellBox至少需要预留约1MB的磁盘空间\033[0m"	
	$echo " 1 在\033[32m/etc目录\033[0m下安装(适合root用户)"
	$echo " 2 在\033[32m/usr/share目录\033[0m下安装(适合Linux设备)"
	$echo " 3 在\033[32m当前用户目录\033[0m下安装(适合非root用户)"
	$echo " 4 在\033[32m/data目录\033[0m下安装(适合小米路由设备)"
	$echo " 5 手动设置安装目录"
	$echo " 0 退出安装"
	echo -----------------------------------------------
	read -p "请输入相应数字 > " num
	#设置目录
	if [ -z $num ];then
		echo 安装已取消
		exit 1;
	elif [ "$num" = "1" ];then
		dir=/etc
	elif [ "$num" = "2" ];then
		dir=/usr/share
	elif [ "$num" = "3" ];then
		dir=~/.local/share
		mkdir -p ~/.config/systemd/user
	elif [ "$num" = "4" ];then
		dir=/etc
	elif [ "$num" = "5" ];then
		echo -----------------------------------------------
		echo '可用路径 剩余空间:'
		df -h | awk '{print $6,$4}'| sed 1d 
		echo '路径是必须带 / 的格式，注意写入虚拟内存(/tmp,/opt,/sys...)的文件会在重启后消失！！！'
		read -p "请输入自定义路径 > " dir
		if [ -z "$dir" ];then
			$echo "\033[31m路径错误！请重新设置！\033[0m"
			setdir
		fi
	else
		echo 安装已取消！！！
		exit 1;
	fi
fi

if [ ! -w $dir ];then
	$echo "\033[31m没有$dir目录写入权限！请重新设置！\033[0m" && sleep 1 && setdir
else
	$echo "目标目录\033[32m$dir\033[0m空间剩余：$(dir_avail $dir)"
	read -p "确认安装？(1/0) > " res
	[ "$res" = "1" ] && SBOX_DIR=$dir/ShellBox || setdir
fi
}

########################################################################################################
[ -n "$(echo -e|grep e)" ] && echo=echo || echo='echo -e'
[ -f "/etc/storage/started_script.sh" ] && systype=Padavan && initdir='/etc/storage/started_script.sh'
[ -d "/jffs/scripts" ] && systype=asusrouter && initdir='/jffs/scripts/net-start'
[ -f "/jffs/.asusrouter" ] && systype=asusrouter && initdir='/jffs/.asusrouter'
[ -f "/data/etc/config/firewall" -a "$(dir_avail /etc)" = 0 ] && systype=mi_snapshot
[ -z "$url" ] && url="https://cdn.jsdelivr.net/gh/juewuy/ShellBox@master"
########################################################################################################

#检查root权限
[ "$USER" != "root" -a -z "$systype" ] && {
	echo 当前用户:$USER
	$echo "\033[31m请尽量使用root用户(务必用sudo -i提权)执行安装!\033[0m"
	echo -----------------------------------------------
	read -p "仍要安装？可能会产生未知错误！(1/0) > " res
	[ "$res" != "1" ] && exit 1
}

#检查更新
mkdir /tmp/ShellBox
webget /tmp/ShellBox/version "$url/bin/version" echooff
[ "$?" = 0 ] && version=$(cat /tmp/ShellBox/version | grep "version" | awk -F "=" '{print $2}')
rm -rf /tmp/ShellBox/version
tarurl=$url/bin/ShellBox.tar.gz

#输出
$echo "最新版本：\033[32m$version\033[0m"
echo -----------------------------------------------
$echo "\033[44m如遇问题请加TG群反馈：\033[42;30m t.me/clashfm \033[0m"
$echo "\033[37m支持各种路由器设备"
$echo "\033[33m支持Debian、Centos等标准Linux系统\033[0m"

#安装
if [ -n "$SBOX_DIR" ];then
	echo -----------------------------------------------
	$echo "检测到旧的安装目录\033[36m$SBOX_DIR\033[0m，是否覆盖安装？"
	$echo "\033[32m覆盖安装时不会移除配置文件！\033[0m"
	read -p "覆盖安装/移除旧目录？(1/0) > " res
	if [ "$res" = "1" ];then
		install
	elif [ "$res" = "0" ];then
		rm -rf $SBOX_DIR
		echo -----------------------------------------------
		$echo "\033[31m 旧版本安装目录已移除！\033[0m"
		setdir
		install
	elif [ "$res" = "9" ];then
		echo 测试模式，变更安装位置
		setdir
		install
	else
		$echo "\033[31m输入错误！已取消安装！\033[0m"
		exit 1;
	fi
else
	setdir
	install
fi
