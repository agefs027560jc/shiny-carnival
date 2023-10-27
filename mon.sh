#! /usr/bin/env bash

set -e

# get 1/3 of duration
d=$(( $(grep "duration=" run.sh | cut -d = -f 2) / 3 ))
c=120
while :; do
  sleep 2
  [[ $(( c-- )) -lt 0 ]] && kill $$
  title=$(head -n 1 stats/.pid)
  pid=$(grep  --line-buffered "tid of leader is " stats/.pid \
  | sed --unbuffered 's/.*leader is \([0-9]\+\).*/\1/')

  if [[ $(pgrep -c deptran) -gt 0 && $pid -ne 0 && $pid -ne $prevpid ]]; then
    echo "(mon) leader tid : " $pid
    taskset -c -p $pid
    for i in $(grep  --line-buffered "tid of non-leader is " stats/.pid \
    | sed --unbuffered 's/.*non-leader is \([0-9]\+\).*/\1/')
    do taskset -c -p $i; done

    sleep $d
    top -H -b -n $d -d 1 -p $pid > stats/top.log
    grep "$pid" stats/top.log > stats/.avg
    line=$(grep -c "$pid" stats/.avg)
    calc="((0"
    for ((i=1; i <= $line; i++)); do
      x=$(awk 'NR=='$i'{print $9}' stats/.avg)
      calc="${calc}+${x}"
    done
    calc="${calc}))/${line}"

    python3 -c 'print("%cpu_utils : {0:.2f};".format('$calc'),end=" ")' \
    >> stats/summary.log

    c=$(( d * 3 ))
    prevpid=$pid
  fi
done
