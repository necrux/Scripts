#!/bin/bash

# compare_dirs v1.0
# Written on: Tue Nov 29 2016
#
# This script is used to compare the contents of 2 directories.
#
# Possible exit codes:
# 0   = Successful
# 1   = Catchall for general errors
# 128 = Invalid argument
# 129 = Directory does not exist
# 130 = Script terminated by Control-C

#Set Bash colors to variables.
black='\e[0;30m'
darkgray='\e[1;30m'
blue='\e[0;34m'
lightblue='\e[1;34m'
green='\e[0;32m'
lightgreen='\e[1;32m'
cyan='\e[0;36m'
lightcyan='\e[1;36m'
red='\e[0;31m'
lightred='\e[1;31m'
purple='\e[0;35m'
lightpurple='\e[1;35m'
brownorange='\e[0;33m'
yellow='\e[1;33m'
lightgray='\e[0;37m'
white='\e[1;37m'
NC='\e[0m' # No Color

#Function to print usage statement.
function usage {
	cat <<- EOF

		This script can be used to compare the contents of two directories.
		Currently the script does not check for files that exist in the second list directory, but not the first. 

		SYNTAX
		  compare_dirs.sh [ DIR1 DIR2 ]

	EOF
}

#Validate user input.
if [ "$#" != "2" ];then
  usage
  exit 128
elif [ ! -d "$1" ]; then
  usage
  echo -e "$red Directoy '$1' does not exist.$NC"
  exit 129
elif [ ! -d "$2" ]; then
  usage
  echo -e "$red Directoy '$2' does not exist.$NC"
  exit 129
fi

#Sanitize user input. This cleans up the final output.
if [ "$(echo $1 | grep -o ".$")" != "/"  ];then
  DIR1=$1
else
  DIR1=$(echo $1 | sed 's@/$@@')
fi

if [ "$(echo $2 | grep -o ".$")" != "/"  ];then
  DIR2=$2
else
  DIR2=$(echo $2 | sed 's@/$@@')
fi

#Initialize arrays.
NO_MATCH=()
NOT_FOUND=()

usage

for FILES in $(find $DIR1 -type f); do
  #Perform comparison.
  PATH2=$(echo $FILES | awk -F"$DIR1" '{print $2}')
  FIRST_HASH=$(md5sum $FILES | cut -d ' ' -f1)
  if [ -e $DIR2$PATH2 ];then
    SECOND_HASH=$(md5sum $DIR2$PATH2 | cut -d ' ' -f1)
  fi

  #Append results to their respective arrays.
  if [ ! -e $DIR2$PATH2 ];then
    NOT_FOUND+=("$DIR2$PATH2")
  elif [ "$FIRST_HASH" != "$SECOND_HASH" ];then
    NO_MATCH+=("$FILES $DIR2$PATH2")
  fi
done

#Print files that do not match.
echo -e "\n$red     ****THESE FILES DO NOT MATCH****$NC\n"
( for i in "${NO_MATCH[@]}";do
  echo $i
done ) | column -t

#Print list of missing files.
echo -e "\n$red     ****THESE FILES DO NOT EXIST****$NC\n"
for i in "${NOT_FOUND[@]}";do
  echo $i
done

exit 0
