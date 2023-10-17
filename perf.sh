#! /usr/bin/env bash

set -e

mkdir -p stats
touch stats/.pid
touch stats/summary.log

# get 1/3 of duration
d=$(( $(grep "duration=" run.sh | cut -d = -f 2) / 3 ))
c=$(( d * 3 ))
while :; do
  sleep 2
  [[ $(( c-- )) -lt 0 ]] && kill $$
  title=$(head -n 1 stats/.pid)
  pid=$(grep "tid of leader is " stats/.pid | awk '{print $NF}')

  if [[ $(pgrep -c deptran) -gt 0 \
  && $pid -ne 0 && $pid -ne $prevpid ]]; then
    echo "(perf) leader tid : " $pid

    perf stat -d -t $pid -o stats/.perf
    ctx=$(grep "context-switches" stats/.perf | awk '{print $1}')

    python3 -c 'print("ctx_switch : '$ctx';",end=" ")' \
    >> stats/summary.log

    c=$(( d * 3 ))
    prevpid=$pid
  fi
done
