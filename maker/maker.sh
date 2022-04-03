#!/bin/bash
# Copyright (C) Juewuy

DIR=$(dirname $(pwd))
XLSX=config.xlsx
CSV=config.csv

win2linux(){
	encod=$(file -i $CSV | sed 's/.*charset=//g')
	if [ "$encod" != utf-8 ];then
		echo "Fixing file encoding! 正在修复文件编码!"
		iconv -f GBK -t UTF-8 $1 -o win2linux.tmp
		mv -f win2linux.tmp $1
	fi
	sed -i 's/\r//g' $1
}

make_config(){
	if [ ! -f $CSV ];then
		if [ -f $XLSX ];then
			if !(type xlsx2csv >/dev/null);then
				echo "install xlsx2csv now! 正在安装xlsx2csv转换工具！"
				if type apt-get >/dev/null;then
					sudo apt-get update
					sudo apt-get install -y xls2csv
				else
					echo "Could not install xlsx2csv! Please manually save config.xlsx as config.csv file!"
					echo "无法安装xlsx2csv应用！ 请手动将config.xlsx另存为config.csv文件！"
					exit 1
				fi
			fi
			xlsx2csv $XLSX $CSV
		else
			echo "$XLSX file is missing! exit! 找不到$XLSX文件！已退出！"
			exit 1
		fi
	fi
	if [ "$?" != 0 ];then
		echo "file $CSV conversion failed! Please manually save config.xlsx as config.csv file!"
		echo "config.csv文件生成失败！请手动将config.xlsx另存为config.csv文件！"
		exit 1
	else
		win2linux $CSV
	fi
	cat $CSV | awk -F ',' '{print $2"=""\""$3"\""}' | sed '1d' | sed '/=""/d' | sed 's/"yes"/true/g'  | sed 's/"no"/false/g' > scripts/sbox.config
	rm -rf $CSV
}
upx_cores(){
	echo "UPX compressing！ 正在使用UPX压缩！"
	type upx >/dev/null || sudo apt-get install -y upx
	for cpu in armv5 armv7 armv8 386 amd64;do
		upx ${tool_dir}/bin/${core}_${cpu}
	done
	for cpu in mipsle mips;do
		chmod 755 $DIR/bin/upx_3.93
		$DIR/bin/upx_3.93 ${tool_dir}/bin/${core}_${cpu}
	done
	echo "UPX compress complete！ 压缩成功！"
}
make_files(){
	dir=$(pwd)
	source $dir/scripts/sbox.config
	tool_dir=$DIR/tools/${type}s/$name
	mkdir $tool_dir 2>/dev/null
	[ "$dir" != "$tool_dir" ] && cp -rf $dir/* $tool_dir
	#打包scripts目录
	type tar >/dev/null || sudo apt-get install -y tar
	tar -zcvPf $tool_dir/bin/${name}.tar.gz $tool_dir/scripts
	$upx && upx_cores
}
make_list(){
	list=$DIR/bin/list.csv
	if [ -f $list ];then
		win2linux $list
		sed -i "/$name,/d" $list
		echo "$name","type","version","compa","desc_chs","desc_en" >> $list
	fi
}

make_config
make_files
make_list


