FILE_NAME=$1;
START_DIR=$2;
SECTION=$3;
if [ -z $1 ]
then
	FILE_NAME=header.h;
fi
if [ -z $2 ]
then
	START_DIR=.;
fi
if [ -z $3 ]
then
	SECTION=1;
fi
L_LEN=0;
TAB_TOTAL=0;
TAB_REQUIRED=0;
TAB='!';
COPY_END=0;
COPY_START=0;
TOTAL_SRC_FILES=0;
PROCESSED_FILES=0;
H_GUARD=$(echo $FILE_NAME | tr 'a-z.' 'A-Z_' )

make_42header()
{
	SPACES="                                                            "

	# Calculate FILE_SPACE
	FILE_SPACE=$((51 - ${#FILE_NAME}))

	# Calculate NAME_SPACE1
	NAME_SPACE1=$((47 - 21 - ${#USER} * 2))

	# Calculate NAME_SPACE2
	NAME_SPACE2=$((18 - ${#USER}))

	echo "/* ************************************************************************** */"
	echo "/*                                                                            */"
	echo "/*                                                        :::      ::::::::   */"
	printf "/*   "$FILE_NAME"%."$FILE_SPACE"s:+:      :+:    :+:   */\n" "$SPACES"
	echo "/*                                                    +:+ +:+         +:+     */"
	printf "/*   By: $USER <$USER@student.42.fr>%."$NAME_SPACE1"s+#+  +:+       +#+        */\n" "$SPACES"
	echo "/*                                                +#+#+#+#+#+   +#+           */"
	printf "/*   Created: %s by $USER%."$NAME_SPACE2"s#+#    #+#             */\n" "$(date +"%Y/%m/%d %T")" "$SPACES"
	printf "/*   Updated: %s by $USER%."$(($NAME_SPACE2 - 1))"s###   ########.fr       */\n" "$(date +"%Y/%m/%d %T")" "$SPACES"
	echo "/*                                                                            */"
	echo -e "/* ************************************************************************** */"'\n'
}

header_guard()
{
	echo "#ifndef $H_GUARD"
	echo "# define $H_GUARD"
}

process_bar()
{
	# Increment the count of processed files
	PROCESSED_FILES=$((PROCESSED_FILES + 1))
	# Calculate the percentage of processed files
	PERCENTAGE=$((100 * PROCESSED_FILES / TOTAL_SRC_FILES))
	# Display the progress bar
	echo -n "["
	for i in $(seq 1 $PERCENTAGE); do
		echo -en "\033[33m=\033[0m"
	done
	for i in $(seq 1 $((100 - PERCENTAGE))); do
		echo -n " "
	done
	echo -n "] $PERCENTAGE% ($PROCESSED_FILES/$TOTAL_SRC_FILES)"
	if [ $PROCESSED_FILES -ne $TOTAL_SRC_FILES ]
	then
		echo -ne "\r"
	else
		echo -e '\n'"\033[32m✅ Header file created successfully ✅\033[0m"
	fi
}

if [ -f $FILE_NAME ]
then
	HEADER_END=$(($(cat "$FILE_NAME" | grep -n "###   ########.fr" | tail -1 | cut -d ':' -f1) + 2))
	if [ "$HEADER_END" -eq 2 ]
	then
		make_42header >> tmp_header_42
		echo -e '\n'
		HEADER_END=0;
	else
		cat $FILE_NAME | head -$HEADER_END >> tmp_header_42
		echo -e '\n'
	fi
	H_GUARD_END=$(cat $FILE_NAME | grep -n "$H_GUARD" | tail -1 | cut -d ':' -f1)
	if [ -z $H_GUARD_END ]
	then
		header_guard >> tmp_header_42
		H_GUARD_END=0;
	else
		cat $FILE_NAME | head -$H_GUARD_END | tail -$(($H_GUARD_END - $HEADER_END)) >> tmp_header_42
	fi
	if [ $H_GUARD_END -lt $HEADER_END ]
	then
		H_GUARD_END=$HEADER_END
	fi
	COPY_END=$(grep -s -n '}\|define\|include' $FILE_NAME | tail -1 | cut -d ':' -f1)
	if [ ! -z $COPY_END ]
	then
		cat $FILE_NAME | head -$COPY_END | tail -$(($COPY_END - $H_GUARD_END)) >> tmp_header_42
	fi
else
	make_42header >> tmp_header_42
	echo -e >> '\n'
	header_guard >> tmp_header_42
fi

for dir in $(find $START_DIR -type d)
do
	for file in $(find $dir -maxdepth 1 -type f -name '*.c' ! -name '*bonus*')
	do
		TOTAL_SRC_FILES=$(($TOTAL_SRC_FILES + 1))
		funcs=$(cat $file  | grep '(' | grep ')' | grep -v ';\|if\|while\|for\|switch\|+\|=\|-\|||\|&&\|main\|static' | sed 's/)$/);/g') 
		for key in $(echo -e "$funcs" | tr ' ' '#' | cut -d $'\t' -f1)
		do
			len=${#key}
			if [ $L_LEN -lt $len ]
			then
				L_LEN=$len
			fi
		done
	done
	TAB_TOTAL=$(expr $L_LEN / 4 + 1);
done
for dir in $(find $START_DIR -type d)
do
	cnt_c_file=$(find $dir  -type f -name '*.c' ! -name '*bonus*' | wc -l)
	if [ $cnt_c_file -lt 1 ]
	then
		continue ;
	fi
	if [ $SECTION -eq 1 ]
	then
		echo -e '\n'"/* ===============$dir=============== */"'\n' >> tmp_header_42
	fi
	for file in $(find $dir -maxdepth 1 -type f -name '*.c' -and ! -name '*bonus*')
	do
		process_bar
		if [ $SECTION -eq 0 ]
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
			TAB_REQUIRED=$(($TAB_TOTAL - $tab_occupied))
			for ((i=1; i < $TAB_REQUIRED; i++))
			do
				TAB=$TAB'!'
			done
			echo $func | sed "s/!/$TAB/" | tr '!' '\t' | tr '#' ' ' >> tmp_header_42
			TAB='!';
		done
	done
done


echo -e '\n''#endif' >> tmp_header_42

rm -f $FILE_NAME
mv tmp_header_42 $FILE_NAME
rm -f tmp_header_42

echo "manual : ham [FILE_NAME] [START_DIR] [SECTION]"

# FILE_NAME : string
# 	You can decide your name of header file.
# 	Default is 'header.h'

# START_DIR : dir
# 	You can specify directory to start searching.
# 	Write based on current directory.
# 	Default is current directory.
	
# section : 0 or 1
# 	This option is about choosing which way to make header file.
# 	if you choose 0, prototypes will be divded by files.
# 	if you choose 1, prototypes will be divided by only directories.
# 	Default is 1
# "

