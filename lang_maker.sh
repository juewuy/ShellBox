#!/bin/sh
# Copyright (C) Juewuy

CSV=lang.csv
TMP=lang.tmp
[ ! -f $CSV ] && echo 语言基础配置文件丢失，已退出！ && exit 1
#修正编码及换行符

encod=$(file -i $CSV | sed 's/.*charset=//g')
if [ "$encod" != utf-8 ];then
	echo 正在修复文件编码
	iconv -f GBK -t UTF-8 $CSV -o $TMP
else
	cp -f $CSV $TMP
fi
sed -i 's/\r//g' $TMP
#exit
files=$(head -n +1 $TMP | sed 's/.*文件名,//g' | sed 's/\,/\ /g')
i=1

for lang in $files;do
	lang_dir=$(pwd)/scripts/lang/$lang
	i=$((i+1))
	echo 清理旧的【$lang】翻译文件
	rm -rf $lang_dir
	echo 开始生成新的【$lang】翻译文件
	while read line;do
		lang_a=$(echo $line | awk -F "," '{print $1}')
		lang_b=$(echo $line | awk -F "," '{print $'"$i"'}')
		[ -z "$lang_b" ] && lang_b=$(echo $line | awk -F "," '{print $2}')
		echo "$lang_a='$lang_b'" >> $lang_dir
	done < $TMP
	sed -i '1d' $lang_dir
	echo 已经生成了新的【$lang】翻译文件
done

rm -rf $TMP