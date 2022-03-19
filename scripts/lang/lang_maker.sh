#!/bin/sh
# Copyright (C) Juewuy

CSV=lang.csv
[ ! -f $CSV ] && echo 语言基础配置文件丢失，已退出！ && exit 1
sed -i 's/\\r//g' $CSV
encod=$(file -i $CSV | sed 's/.*charset=//g')
if [ "$encod" != utf-8 ];then
	iconv  -f $encod -t UTF-8 $CSV -o lang.tmp
	mv -f lang.tmp $CSV
fi

files=$(head -n +1 $CSV | sed 's/.*文件名,//g' | sed 's/\,/\ /g')
i=1

for lang in $files;do
	i=$((i+1))
	echo 清理旧的翻译文件$lang
	rm -rf $lang
	
	while read line;do
		lang_a=$(echo $line | awk -F "," '{print $1}')
		lang_b=$(echo $line | awk -F "," '{print $'"$i"'}')
		[ -z "$lang_b" ] && lang_b=$(echo $line | awk -F "," '{print $2}')
		echo "$lang_a=$lang_b" >> $lang
	done < $CSV
	sed -i '1d' $lang
	sed -i 's/语言描述=#/#/g' $lang
	echo 已经生成了新的$lang翻译文件！
done
