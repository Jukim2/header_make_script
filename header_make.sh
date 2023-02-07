# Change this var to set default exclude file
EXCLUDE="*bonus.c"
# Change this var to set default exclude path
# EXCLUDE_PATH="*libft*"
FILE=header.h;
START_DIR=.;
SPLIT=0;
while getopts n:d:e:sh opt
do
        case $opt in
        	n) 	FILE=$OPTARG;;
            d) 	START_DIR=$OPTARG;;
            s)	SPLIT=1;;
			e)	EXCLUDE_PATH="*$OPTARG*";;
			h) 	echo "ham [-n File] [-d Directory] [-s Split]"
				exit;;
            *) 	echo "ham [-n File] [-d Directory] [-s Split]"
				exit;;
        esac
done
# GET only FILE_NAME (includes/header.h => header.h)
FILE_NAME=$(echo $FILE | rev | cut -d '/' -f1 | rev)
H_GUARD=$(echo $FILE_NAME | tr 'a-z.' 'A-Z_' )


main()
{
	# Before thinking about function prototypes, check 42 Header and Header Guard first.
	# if there is pre-existing file, We will use that file.
	if [ -f $FILE ]
	then
		# Find if 42header exist or not
		HEADER_END=$(($(cat "$FILE" | grep -n "###   ########.fr" | tail -1 | cut -d ':' -f1) + 2))
		# if 42header doesn't exist, make and put it
		if [ "$HEADER_END" -eq 2 ]
		then
			# tmp_header_42 file is temporary file which will be header file later.
			make_42header >> tmp_header_42
			HEADER_END=0;
		else
			cat $FILE | head -$HEADER_END >> tmp_header_42
		fi
		# Find if header guard exist or not
		H_GUARD_END=$(cat $FILE | grep -n "$H_GUARD" | tail -1 | cut -d ':' -f1)
		# if header guard doesn't exist, make and put it
		if [ -z $H_GUARD_END ]
		then
			if [ $HEADER_END -ne 0 ] 
			then
				echo -ne '\n' >> tmp_header_42
			fi
			header_guard >> tmp_header_42
			H_GUARD_END=0;
		else
			cat $FILE | head -$H_GUARD_END | tail -$(($H_GUARD_END - $HEADER_END)) >> tmp_header_42
		fi
		# Update H_GUARD_END to use it in the next if part
		if [ $H_GUARD_END -lt $HEADER_END ]
		then
			H_GUARD_END=$HEADER_END
		fi
		# Find line number, before which contents should be conserved(includes, structs ...)
		COPY_END=$(grep -s -n '}\|define\|include' $FILE | tail -1 | cut -d ':' -f1)
		if [ ! -z $COPY_END ]
		then
			cat $FILE | head -$COPY_END | tail -$(($COPY_END - $H_GUARD_END)) >> tmp_header_42
		fi
	else
		# if there was no file named $FILE_NAME, put 42 header and h_guard to tmp file which will be header file later.
		make_42header >> tmp_header_42
		header_guard >> tmp_header_42
	fi

	# Search every c file and find function that has longest space before function name.
	# And calculate TAB_MAX, amount of tab need for function which has short return type like 'int'.
	L_LEN=0;
	TOTAL_SRC_FILES=0;
	for dir in $(find $START_DIR -type d -not -path "$EXCLUDE_PATH")
	do
		for file in $(find $dir -maxdepth 1 -type f -name '*.c' ! -name "$EXCLUDE")
		do
			FUNCS=$(cat $file | grep '(' | grep ')' | grep '\t' | grep -v ';\|+\|=\|-\|||\|&&' | sed 's/)$/);/g')
			if [ $(echo $FUNCS | wc -l) -eq 0 ]
			then
				continue ;
			fi
			TOTAL_SRC_FILES=$(($TOTAL_SRC_FILES + 1))
			for func in $(echo -e "$FUNCS" | tr ' ' '#' | tr '\t' '@')
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
				LEN=${#key}
				if [ $L_LEN -lt $LEN ]
				then
					L_LEN=$LEN
				fi
			done
		done
		TAB_MAX=$(expr $L_LEN / 4 + 1);
	done
	if [ $TOTAL_SRC_FILES -eq 0 ]
	then
		rm tmp_header_42
		echo -e "\033[31mNo valid functions. You have only main function?\033[0m"
		exit ;
	fi
	# For every directory from START_DIR
	for dir in $(find $START_DIR -type d -not -path "$EXCLUDE_PATH")
	do
		# count c files in 'dir'
		cnt_c_file=$(find $dir -maxdepth 1 -type f -name '*.c' ! -name "$EXCLUDE" | wc -l)
		# if no c files exist, move to next direction
		if [ $cnt_c_file -eq 0 ]
		then
			continue ;
		fi
		# if SPLIT option is 1, write dir
		if [ $SPLIT -eq 0 ]
		then
			echo -e '\n'"/* ===============$dir=============== */"'\n' >> tmp_header_42
		fi
		for file in $(find $dir -maxdepth 1 -type f -name '*.c' -and ! -name "$EXCLUDE")
		do
			# show process_bar
			process_bar
			# if SPLIT option is 0, write file name
			if [ $SPLIT -eq 1 ]
			then
				echo -e '\n'"/* $file */"'\n' >> tmp_header_42
			fi
			# Get function prototypes and conditional statement
			# (name like 'spotify' includes 'if')
			FUNCS=$(cat $file | grep -n '(' | grep '\t' | grep -v "==\|++\|return\|-\|=\|||\|&&\|>\|<\|;" | tr ' ' '#' | tr '\t' '@')
			for func in $(echo -e "$FUNCS")
			do
				if [ $(echo -e $func | cut -d ':' -f2 | cut -b 1) = '@' ]
				then
					continue ;
				fi
				START_LINE=$(echo -e $func | cut -d ':' -f1)
				END_LINE=$START_LINE;
				while [ $(awk -v var="$END_LINE" 'NR == var' $file | grep '{' | wc -l) -eq 0 ]
				do
					END_LINE=$(($END_LINE + 1))
					if [ $(($END_LINE - $START_LINE)) -gt 30 ]
					then
						echo -e "\033[31mFunction with no brace...?\033[0m"
						rm tmp_header_42
						exit ;
					fi
				done
				func=$(echo $func | cut -d ':' -f2)
				TAB='@';
				# Exclude conditional statement and static function
				if [ $(echo $func | cut -d '@' -f1 | grep 'static' | wc -l) -eq 1 ]
				then
					continue ;
				fi
				# Exclude main function
				if [ $(echo $func | cut -d '@' -f2 | cut -d '(' -f1) = "main" ]
				then
					continue ;
				fi
				# Calculate How many tabs this fucntion needs
				key=$(echo $func | cut -d '@' -f1)
				TAB_OCCUPIED=$(expr ${#key} / 4)
				TAB_REQUIRED=$(($TAB_MAX - $TAB_OCCUPIED))
				for ((i=1; i < $TAB_REQUIRED; i++))
				do
					TAB=$TAB'@'
				done
				# put all the tabs and spaces and write in tmp_header_42
				if [ $(($END_LINE - $START_LINE)) -eq 1 ]
				then
					awk -v var1=$START_LINE -v var2=$(($END_LINE - 1)) 'NR >= var1 && NR <= var2' $file | tr ' ' '#' | tr '\t' '@' | sed "s/@/$TAB/" | tr '@' '\t' | tr '#' ' ' >> tmp_header_42
				else
					awk -v var1=$START_LINE -v var2=$(($END_LINE - 2)) 'NR >= var1 && NR <= var2' $file | tr ' ' '#' | tr '\t' '@' | sed "s/@/$TAB/" | tr '@' '\t' | tr '#' ' ' >> tmp_header_42
					echo "$TAB)" | tr '@' '\t' >> tmp_header_42
				fi
			done
		done
	done

	# Close header guard
	echo -e '\n''#endif' >> tmp_header_42

	# Remove original file and replace it by tmp_header_42
	# rm -f $FILE
    touch $FILE
	cat tmp_header_42 > $FILE
    rm tmp_header_42
}

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
	if [ -z $PROCESSED_FILES ]
	then
		PROCESSED_FILES=0;
	fi
	# Increment the count of processed files
	PROCESSED_FILES=$((PROCESSED_FILES + 1))

	# Calculate the percentage of processed files
	PERCENTAGE=$((20 * PROCESSED_FILES / TOTAL_SRC_FILES))

	# Display the progress bar
	echo -n "["
	for i in $(seq 0 $PERCENTAGE); do
		echo -en "\033[33m=\033[0m"
	done
	for i in $(seq 0 $((19 - PERCENTAGE))); do
		if [ $PERCENTAGE -eq 20 ]
		then
			continue
		fi
		echo -n " "
	done
	echo -n "] $((5 * $PERCENTAGE))% ($PROCESSED_FILES/$TOTAL_SRC_FILES)"
	if [ $PROCESSED_FILES -ne $TOTAL_SRC_FILES ]
	then
		echo -ne "\r"
	else
		echo -e '\n'"\033[32m✅ '$FILE' updated ✅\033[0m"
	fi
}

main
