#!/bin/bash

# This script is used to compare the contents of 2 directories.
# The intended purpse is to compare the second listed directory
# (DIR2) to the first listed directory (DIR1) to see if there are
# either missing files or discrepancies between the files.
#
# Possible exit codes:
# 0   = Successful
# 1   = Catchall for general errors
# 128 = Invalid argument
# 129 = Directory does not exist
# 130 = Script terminated by Control-C

# Font color.
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
DEFAULT=$(tput setaf 9)
NF=$(tput sgr0) #No Formatting.

# Print usage statement.
function usage {
	cat <<- EOF

		This script can be used to compare the contents of two directories.
	  The intended purpse is to compare the second listed directory (DIR2)
	    to the first listed directory (DIR1) to see if there are either
	    missing files or discrepancies between the files.

		SYNTAX
		  compare_dirs.sh [ DIR1 DIR2 ]

	EOF
}

# Validate user input.
if [ "$#" != "2" ]; then
  usage
  exit 128
elif [ ! -d "$1" ]; then
  usage
  echo -e "${RED} Directoy '$1' does not exist.${NF}"
  exit 129
elif [ ! -d "$2" ]; then
  usage
  echo -e "${RED} Directoy '$2' does not exist.${NF}"
  exit 129
fi

# Sanitize user input. This cleans up the final output.
if [ "$(echo $1 | grep -o ".$")" != "/"  ]; then
  DIR1=$1
else
  DIR1=$(echo $1 | sed 's@/$@@')
fi

if [ "$(echo $2 | grep -o ".$")" != "/"  ]; then
  DIR2=$2
else
  DIR2=$(echo $2 | sed 's@/$@@')
fi

# Initialize arrays.
NO_MATCH=()
NOT_FOUND=()

for FILES in $(find ${DIR1} -type f); do
  # Perform comparison.
  PATH2=$(echo ${FILES} | awk -F"${DIR1}" '{print $2}')
  FIRST_HASH=$(md5sum ${FILES} | cut -d ' ' -f1)
  if [ -e ${DIR2}${PATH2} ]; then
    SECOND_HASH=$(md5sum ${DIR2}${PATH2} | cut -d ' ' -f1)
  fi

  # Append results to their respective arrays.
  if [ ! -e ${DIR2}${PATH2} ]; then
    NOT_FOUND+=("${DIR2}${PATH2}")
  elif [ "${FIRST_HASH}" != "${SECOND_HASH}" ];then
    NO_MATCH+=("${FILES} ${DIR2}${PATH2}")
  fi
done

# Print files that do not match.
echo -e "\n${RED}     ****THESE FILES DO NOT MATCH****${NC}\n"
( for i in "${NO_MATCH[@]}"; do
  echo $i
done ) | column -t

# Print list of missing files.
echo -e "\n${RED}     ****THESE FILES DO NOT EXIST****${NC}\n"
for i in "${NOT_FOUND[@]}"; do
  echo $i
done

exit 0
