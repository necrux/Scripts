#!/bin/bash
#Written by Wes on 5/19/2016
#Show swap memory usage per-process

if [ $(awk '/SwapCached/ {print $2}' /proc/meminfo) -eq 0 ]; then
  echo 'Nothing to report!'
  exit 0
fi

(
  echo "PID Mem(kB) Binary"
  for PID in $(ls /proc/ | egrep '^[0-9]{1,9}$'); do
    SWAP=$(awk '/VmSwap/ {print $2}' /proc/$PID/status)
    PROC=$(ps --no-headers -q $PID -o comm)
  if [ ! -z "$SWAP" -a $SWAP -ne 0]; then
    echo "$PID $SWAP $PROC"
  fi
  done 2>/dev/null | sort -nk 2
) | column -t
exit 0
