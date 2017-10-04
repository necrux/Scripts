#!/bin/bash
# Show swap memory usage per-process.

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

usage=$(awk '/SwapCached/ {print $2}' /proc/meminfo)
swappiness=$(sysctl -n vm.swappiness)

function swap_per_process {
  echo 'PID Mem(kB) Binary'
  for PID in $(ls /proc/ | egrep '^[0-9]{1,9}$'); do
    local SWAP=$(awk '/VmSwap/ {print $2}' /proc/${PID}/status)
    local PROC=$(ps --no-headers -q ${PID} -o comm)
    if [ ! -z "${SWAP}" ] && [ ${SWAP} -ne 0 ]; then
      echo "${PID} ${SWAP} ${PROC}"
    fi
  done 2>/dev/null | sort -rnk 2
  #done | sort -nk 2
}

function swap_summary {
  if [[ ${usage} -eq 0 ]]; then
    echo 'Nothing in swap!'
    exit 0
  else
    echo -e "\n${YELLOW}~~~~~~ SWAP SUMMARY ~~~~~${NF}"
    echo "You currently have ${RED}${usage}${NF}kB of data in swap."
    echo "Your swappiness is set to ${RED}${swappiness}${NF}."
    echo -e "  You can read more about swappiness here: ${BLUE}https://en.wikipedia.org/wiki/Swappiness${NF}\n"
  fi
}

swap_summary
( swap_per_process ) | column -t
exit 0
