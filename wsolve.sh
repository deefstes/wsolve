#!/bin/bash

debug=false
ARGS=$(getopt -a --options di: --long "debug,input:" -- "$@")
eval set -- "$ARGS"

while true; do
  case "$1" in
    -d|--debug)
      debug="true"
      shift;;
    -i|--input)
      input="$2"
      shift 2;;
    --)
      break;;
     *)
      printf "Unknown option %s\n" "$1"
      exit 1;;
  esac
done

echo "debug=$debug"
echo "input=$input"

# If no input file is specified, use file called wordlewords.txt
if [ -z $input ]
then
	input="wordlewords.txt"
fi

# whittle input file down to only 5 letter words
cat $input | grep -E '^.{5}$' > tmp

echo "Let's solve a Wordle"

lastword='adieu'
wordindex=1
done=0
posincorrect=('0' '0' '0' '0' '0') # this has a longer lifespan than results remembered inside the scope of the loop below as we want it to be remembered for subsequent guesses

while [ $done = 0 ]
do
	echo ""
	echo "Try \"$lastword\" and let me know the result (? for help, q to quit, d for different word)"

	read -r rslt
	if [ $rslt = '?' ]
	then
		echo "Use 5 characters to give me the result:"
		echo "- for a correct letter in the wrong position"
		echo "+ for a correct letter in the correct position"
		echo "x for an incorrect letter"
		echo ""
		echo "Example:"
		echo "xx-+- = First two letters incorrect (x)"
		echo "        Second and last letter correct but in wrong position (-)"
		echo "        Fourth letter correct and in correct position (+)"
		echo ""
	fi
	
	if [ $rslt = 'q' ]
	then
		done=1
		break
	fi
	
	if [ $rslt = '+++++' ]
	then
		done=1
		echo 'Yay! We solved the wordle: '$lastword
		break
	fi
	
	if [ $rslt = 'd' ]
	then
		echo "I agree, '$lastword' is a dumb choice. Let's pick another word."
		wordindex=$((wordindex+1))
		lastword=$(head -n $wordindex tmp | tail -n 1)
		continue
	fi

	# check if rslt is in correct format
	rslt=$(echo $rslt | grep -E '^[\+-x]{5}$')
	if [ -z $rslt ]
	then
		echo "Sorry, that result makes no sense"
		echo "Please try again or press ? for help"
		echo ""
		continue
	fi
	
	# obtain result for each individual position
	p=(\
		$(echo $rslt | head -c 1 | tail -c 1)\
		$(echo $rslt | head -c 2 | tail -c 1)\
		$(echo $rslt | head -c 3 | tail -c 1)\
		$(echo $rslt | head -c 4 | tail -c 1)\
		$(echo $rslt | head -c 5 | tail -c 1)\
	)
	
	poscorrect=''
	valid=''
	for i in ${!p[@]}; do
		# build up list of invalid characters
		if [ ${p[$i]} = 'x' ]
		then
			invalid=$(echo $invalid$(echo $lastword | head -c $((i+1)) | tail -c 1))
		fi
		
		# build up list of valid characters and populate positionally incorrect character array
		if [ ${p[$i]} = '-' ]
		then
			valid="$valid$(echo $lastword | head -c $((i+1)) | tail -c 1)"
			posincorrect[$i]="${posincorrect[$i]}$(echo $lastword | head -c $((i+1)) | tail -c 1)"
		fi
		
		# build up string for positionally correct characters
		if [ ${p[$i]} = '+' ]
		then
			poscorrect=$(echo $poscorrect$(echo $lastword | head -c $((i+1)) | tail -c 1))
			valid="$valid$(echo $lastword | head -c $((i+1)) | tail -c 1)"
		else
			poscorrect=$(echo $poscorrect'.')
		fi
	done
	
	# sort characters in $valid string and remove duplicates
	valid=$(echo $valid | grep -o . | sort |tr -d "\n" | sed 's/\(.\)\1*/\1/g')
	
	# sort characters in $invalid string and remove duplicates
	invalid=$(echo $invalid | grep -o . | sort |tr -d "\n" | sed 's/\(.\)\1*/\1/g')
	
	# remove any characters from $invalid string which also occurs in $valid string (might occur if characters appear multiple times in word)
	if [ -n "$valid" ]
	then
		invalid=$(echo $invalid | sed "s/[$valid]//g")
	fi
	
	# flesh out regexes
	regex_valid="^$(echo $valid | sed 's/\(.\)/\(?=.*\1\)/g').*$"
	regex_invalid="^[^$invalid]+$"
	regex_poscorrect="^$poscorrect$"
	regex_posincorrect="^"
	for i in ${!p[@]}; do
		if [ ${posincorrect[$i]} = '0' ]
		then
			regex_posincorrect="$regex_posincorrect."
		else
			regex_posincorrect="$regex_posincorrect[^${posincorrect[$i]}]"
		fi
	done
	regex_posincorrect="$regex_posincorrect$"
	regex_posincorrect=$(echo $regex_posincorrect | sed 's/0//g')
	
	if [ $debug = 'true' ]
	then
		echo '          lastword: '$lastword
		echo '              rslt: '$rslt
		echo '           invalid: '$invalid
		echo '             valid: '$valid
		echo '        poscorrect: '$poscorrect
		echo '       regex_valid: '$regex_valid
		echo '     regex_invalid: '$regex_invalid
		echo '  regex_poscorrect: '$regex_poscorrect
		echo 'regex_posincorrect: '$regex_posincorrect
	fi
	
	cat tmp | grep -E "$regex_invalid" | grep -Po "$regex_valid" | grep -E "$regex_poscorrect" | grep -E "$regex_posincorrect$" > tmp2 # $regex_valid is a Perl style regex, hence the -Po
	cp tmp2 tmp
	
	wordindex=1
	lastword=$(head -n $wordindex tmp | tail -n 1)
	
	if [ -z $lastword ]
	then
		echo "I'm so sorry I failed you but, at this point, I got nothing :-("
		done=1
		break;
	fi
done

rm tmp
rm tmp2

echo "All done"