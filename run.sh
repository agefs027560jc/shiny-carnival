#! /usr/bin/env bash

set -e

mkdir -p stats
touch stats/.avg
touch stats/.perf
touch stats/.tp

# at least one is enabled
enable_top=1
enable_perf=1
if [[ $enable_top -eq 1 ]]; then
  bash mon.sh &
  pida=$!
  echo pid of mon : $pida;
fi
if [[ $enable_perf -eq 1 ]]; then
  bash perf.sh &
  pidb=$!
  echo pid of perf : $pidb;
fi

# change below values
duration=60
i=0
for cc in {1..1}; do echo -e "#run_$(( i++ ))" >> stats/summary.log;
for c in {1,10,20,30}; do
for r in {2,3,5,7}; do
for v in {1,2}; do
for nrun in {1..3}; do
  # cpuset setup
  if [[ $1 -eq 1 ]]; then
    sudo cgdelete -g cpuset:/cpulimitf
    sudo cgcreate -t $USER:$USER -a $USER:$USER -g cpuset:/cpulimitf
    cgset -r cpuset.mems=0 -r cpuset.cpus=0 /cpulimitf
  fi

  title="${c}c1s${r}r1p_${cc}-con"

  [[ $v -eq 1 ]] && title="${title}_broadcast"
  [[ $v -eq 2 ]] && title="${title}_crpc-ring"
  echo $title started at : $(date)
  echo -e "$title\n" > stats/.pid
  python3 -c 'print("'$title'" ,end=" ")' >> stats/summary.log
  if [[ $1 -eq 0 ]]; then
    echo "not using cgroup"
    time ./build/deptran_server \
    -f config/sample_crpc.yml \
    -f config/${c}c1s${r}r1p.yml \
    -f config/rw.yml \
    -f config/concurrent_${cc}.yml \
    -P localhost \
    -v $v \
    -d $duration >> stats/.pid
  elif [[ $1 -eq 1 ]]; then
    echo "using cgroup"
    time ./build/deptran_server \
    -f config/sample_crpc.yml \
    -f config/${c}c1s${r}r1p.yml \
    -f config/rw.yml \
    -f config/concurrent_${cc}.yml \
    -P localhost \
    -v $v \
    -d $duration \
    | tee -a stats/.pid \
    | grep  --line-buffered "tid of leader is " \
    | sed --unbuffered 's/.*leader is \([0-9]\+\).*/\1/' \
    | cgclassify -g cpuset:/cpulimitf
  fi
  grep "all clients have shut down" stats/.pid

  cnt=0
  line=$(tail -n 1 stats/summary.log)
  while [[
    ($enable_top -eq 1 && $(echo $line | grep %cpu_utils | wc -l) -eq 0) \
    || ($enable_perf -eq 1 && $(echo $line | grep ctx_switch | wc -l) -eq 0)
  ]]; do
    if [[ $(( ++cnt )) -gt $duration ]]; then
      [[ $enable_top -eq 1 ]] && kill $pida
      [[ $enable_perf -eq 1 ]] && kill $pidb
      kill $$
    fi
    sleep 2
    line=$(tail -n 1 stats/summary.log)
  done

  grep Throughput stats/.pid > stats/.tp
  line=$c
  calc="((0"
  for ((j=1; j <= $line; j++)); do
    x=$(head -n $j stats/.tp | tail -n 1 | awk '{print $11}')
    calc="${calc}+${x}"
  done
  calc="${calc}))"
  python3 -c 'print("throughput : {0:.2f}".format('$calc'))' \
  >> stats/summary.log
  tail -n 1 stats/summary.log

  echo -e "\n\n#run_${nrun}\n" >> stats/$title.log
  cat stats/.pid >> stats/$title.log
  cat stats/.avg >> stats/$title.log
  cat stats/.perf >> stats/$title.log
  cat /dev/null > stats/.pid
  cat /dev/null > stats/.avg
  cat /dev/null > stats/.perf
  cat /dev/null > stats/.tp

done; done; done; done;
column -t stats/summary.log > stats/.tmp
mv stats/.tmp stats/summary.log
done

sleep 2
[[ $enable_top -eq 1 ]] && kill $pida
[[ $enable_perf -eq 1 ]] && kill $pidb

cat stats/summary.log
