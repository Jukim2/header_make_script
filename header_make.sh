EXCLUDE="*bonus*"
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
TAB='@';
TAB_MAX=0;
TAB_REQUIRED=0;
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
	PERCENTAGE=$((20 * PROCESSED_FILES / TOTAL_SRC_FILES))

	# Display the progress bar
	echo -n "["
	for i in $(seq 1 $PERCENTAGE); do
		echo -en "\033[33m=\033[0m"
	done
	for i in $(seq 1 $((20 - PERCENTAGE))); do
		echo -n " "
	done
	echo -n "] $((5 * $PERCENTAGE))% ($PROCESSED_FILES/$TOTAL_SRC_FILES)"
	if [ $PROCESSED_FILES -ne $TOTAL_SRC_FILES ]
	then
		echo -ne "\r"
	else
		echo -e '\n'"\033[32m✅ Header file created ✅\033[0m"
	fi
}

# Before thinking about function prototypes, check 42 Header and Header Guard first.
# tmp_header_42 file is temporary file which will be header file later.
# if there is pre-existing file, We will use that file.
if [ -f $FILE_NAME ]
then
	# Find if 42header exist or not
	HEADER_END=$(($(cat "$FILE_NAME" | grep -n "###   ########.fr" | tail -1 | cut -d ':' -f1) + 2))
	# if 42header doesn't exist, make and put it
	if [ "$HEADER_END" -eq 2 ]
	then
		make_42header >> tmp_header_42
		HEADER_END=0;
	else
		cat $FILE_NAME | head -$HEADER_END >> tmp_header_42
	fi
	# Find if header guard exist or not
	H_GUARD_END=$(cat $FILE_NAME | grep -n "$H_GUARD" | tail -1 | cut -d ':' -f1)
	# if header guard doesn't exist, make and put it
	if [ -z $H_GUARD_END ]
	then
		header_guard >> tmp_header_42
		H_GUARD_END=0;
	else
		cat $FILE_NAME | head -$H_GUARD_END | tail -$(($H_GUARD_END - $HEADER_END)) >> tmp_header_42
	fi
	# Update H_GUARD_END to use it in the next if part
	if [ $H_GUARD_END -lt $HEADER_END ]
	then
		H_GUARD_END=$HEADER_END
	fi
	# Find line number, before which contents should be conserved(includes, structs ...)
	COPY_END=$(grep -s -n '}\|define\|include' $FILE_NAME | tail -1 | cut -d ':' -f1)
	if [ ! -z $COPY_END ]
	then
		cat $FILE_NAME | head -$COPY_END | tail -$(($COPY_END - $H_GUARD_END)) >> tmp_header_42
	fi
else
	# if there was no file named $FILE_NAME, put 42 header and h_guard to tmp file which will be header file later.
	make_42header >> tmp_header_42
	header_guard >> tmp_header_42
fi

# Search every c file and find function that has longest space before function name.
# And calculate TAB_MAX, amount of tab need for function which has short return type like 'int'.
for dir in $(find $START_DIR -type d)
do
	for file in $(find $dir -maxdepth 1 -type f -name '*.c' ! -name "$EXCLUDE")
	do
		TOTAL_SRC_FILES=$(($TOTAL_SRC_FILES + 1))
		FUNCS=$(cat $file  | grep '(' | grep ')' | grep -v ';\|if\|while\|for\|switch\|+\|=\|-\|||\|&&\|main\|static' | sed 's/)$/);/g') 
		for key in $(echo -e "$FUNCS" | tr ' ' '#' | cut -d $'\t' -f1)
		do
			LEN=${#key}
			if [ $L_LEN -lt $LEN ]
			then
				L_LEN=$LEN
			fi
		done
	done
	TAB_MAX=$(expr $L_LEN / 4 + 1);
done

# For every directory from START_DIR
for dir in $(find $START_DIR -type d)
do
	# count c files in 'dir'
	cnt_c_file=$(find $dir -maxdepth 1 -type f -name '*.c' ! -name "$EXCLUDE" | wc -l)
	# if no c files exist, move to next direction
	if [ $cnt_c_file -eq 0 ]
	then
		continue ;
	fi
	# if SECTION option is 1, write dir
	if [ $SECTION -eq 1 ]
	then
		echo -e '\n'"/* ===============$dir=============== */"'\n' >> tmp_header_42
	fi
	for file in $(find $dir -maxdepth 1 -type f -name '*.c' -and ! -name "$EXCLUDE")
	do
		# show process_bar
		process_bar
		# if SECTION option is 0, write file name
		if [ $SECTION -eq 0 ]
		then
			echo -e '\n'"/* $file */"'\n' >> tmp_header_42
		fi
		# Get function prototypes and conditional statement
		# (name like 'spotify' includes 'if')
		funcs=$(cat $file | grep '(' | grep ')' | grep '\t' | grep -v ';\|+\|=\|-\|||\|&&' | sed 's/)$/);/g')
		for func in $(echo -e "$funcs" | tr ' ' '#' | tr '\t' '@')
		do
			# Exclude conditional statement and static function
			key=$(echo -e "$func" | cut -d '@' -f1)
			if [ ${#key} -lt 1 ] || [ $(echo $key | cut -d '#' -f1 | grep 'static' | wc -l) -eq 1 ]
			then
				continue ;
			fi
			# Exclude main function
			if [ $(echo -e "$func" | cut -d '@' -f2 | cut -d '(' -f1) = "main" ]
			then
				continue ;
			fi
			# Calculate How many tabs this fucntion needs
			TAB_OCCUPIED=$(expr ${#key} / 4)
			TAB_REQUIRED=$(($TAB_MAX - $TAB_OCCUPIED))
			for ((i=1; i < $TAB_REQUIRED; i++))
			do
				TAB=$TAB'@'
			done
			# put all the tabs and spaces and write in tmp_header_42
			echo $func | sed "s/@/$TAB/" | tr '@' '\t' | tr '#' ' ' >> tmp_header_42
			TAB='@';
		done
	done
done

# Close header guard
echo -e '\n''#endif' >> tmp_header_42

# Remove original file and replace by tmp_header_42
rm -f $FILE_NAME
mv tmp_header_42 $FILE_NAME
