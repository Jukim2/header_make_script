file_name=$1;
start_dir=$2;
section_by_dir=$3;
if [ -z $1 ]
then
	file_name=header.h;
fi
if [ -z $2 ]
then
	start_dir=.;
fi
if [ -z $3 ]
then
	section_by_dir=1;
fi
l_len=0;
tab_total=0;
tab_required=0;
tab='!';
rewrite_line=0;

rewrite_line=$(grep -s -n '}\|define\|include' $file_name | tail -1 | cut -d ':' -f1)
cat $file_name | head -$rewrite_line > tmp_header_42
# 전체 프로토타입들의 Indentation을 맞추기 위해 대상 경로(현재, 하위)에 있는 c 파일들을 탐색하면서 함수명 앞부분(명칭을 모르겠네요)이 가장 긴 함수를 찾아
# 길이가 얼마나 되는 지 탐색하여 int를 기준으로 최대로 필요한 tab이 몇개나 되는 지 tab_total에 저장합니다.
for dir in $(find $start_dir -type d)
do
	for file in $(find $dir  -type f -name '*.c')
	do
		funcs=$(cat $file  | grep '(' | grep ')' | grep -v ';\|if\|while\|for\|switch\|+\|=\|-\|||\|&&\|main\|static' | sed 's/)$/);/g') 
		# 각각의 함수를 탭을 기준으로 잘라서 첫번째 필드만 가져옵니다
		# 모든 첫번쨰 필드의 길이를 재서 가장 긴 길이를 l_len에 저장합니다.
		for key in $(echo -e "$funcs" | tr ' ' '#' | cut -d $'\t' -f1)
		do
			len=${#key}
			if [ $l_len -lt $len ]
			then
				l_len=$len
			fi
		done
	done
	tab_total=$(expr $l_len / 4 + 1);
done

for dir in $(find $start_dir -type d)
do
	cnt_c_file=$(find $dir  -type f -name '*.c' ! -name '*bonus*' | wc -l)
	if [ $cnt_c_file -lt 1 ]
	then
		continue ;
	fi
	if [ $section_by_dir -eq 1 ]
	then
		echo -e '\n'"/* ===============$dir=============== */"'\n' >> tmp_header_42
	fi
	for file in $(find $dir -maxdepth 1 -type f -name '*.c' -and ! -name '*bonus*')
	do
		if [ $section_by_dir -eq 0 ]
		then
			echo -e '\n'"/* $file */"'\n' >> tmp_header_42
		fi
		funcs=$(cat $file | grep '(' | grep ')' | grep '\t' | grep -v ';\|+\|=\|-\|||\|&&\|main\|static' | sed 's/)$/);/g')
		for func in $(echo -e "$funcs" | tr ' ' '#' | tr '\t' '!')
		do
			key=$(echo -e "$func" | cut -d '!' -f1)
			if [ ${#key} -lt 1 ]
			then
				continue ;
			fi
			tab_occupied=$(expr ${#key} / 4)
			tab_required=$(($tab_total - $tab_occupied))
			for ((i=1; i < $tab_required; i++))
			do
				tab=$tab'!'
			done
			echo $func | sed "s/!/$tab/" | tr '!' '\t' | tr '#' ' ' >> tmp_header_42
			tab='!';
		done
	done
done
echo -e '\n''#endif' >> tmp_header_42

rm -f $file_name
mv tmp_header_42 $file_name
rm -f tmp_header_42

# tmp_header_42의 내용을 전부다 옮겨적는다.
# mv tmp_header_42 header.h
# rm -f tmp_header_42
# echo "manual : bash header_make.sh [file_name] [start_dir] [section]

# file_name : string
# 	You can decide your name of header file.
# 	Default is 'header.h'

# start_dir : dir
# 	You can specify directory to start searching.
# 	Write based on current directory.
# 	Default is current directory.
	
# section : 0 or 1
# 	This option is about choosing which way to make header file.
# 	if you choose 0, prototypes will be divded by files.
# 	if you choose 1, prototypes will be divided by only directories.
# 	Default is 1
# "

