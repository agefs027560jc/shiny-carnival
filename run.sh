#! /usr/bin/env bash

set -e

mkdir -p stats
touch stats/.avg
touch stats/.tp
# check mode "top"|"perf"
bash mon.sh top &
pid=$!
echo $pid
# change below values
duration=60
for nrun in {1..1}; do echo -e "#run_${nrun}" >> stats/summary.log;
for cc in {1,10}; do
for c in {1,5,10,15,20}; do
for r in {2,3,5,7}; do
for v in {0,2}; do
  # cpuset setup
  sudo cgdelete -g cpuset:/cpulimitf
  sudo cgcreate -t $USER:$USER -a $USER:$USER -g cpuset:/cpulimitf
  sudo cgset -r cpuset.mems=0 cpulimitf
  sudo cgset -r cpuset.cpus=0 cpulimitf

  date
  title="${c}c1s${r}r1p_${cc}-con"

  if [[ $v -eq 0 ]]; then
    title="${title}_broadcast"
  elif [[ $v -eq 2 ]]; then
    title="${title}_crpc-ring"
  fi
  echo -e "$title\n" > stats/.pid
  time ./build/deptran_server -f config/sample_crpc.yml -f config/${c}c1s${r}r1p.yml -f config/rw.yml -f config/concurrent_${cc}.yml -P localhost -v $v -d $duration | tee -a stats/.pid | grep  --line-buffered "tid of leader is " | sed --unbuffered 's/.*leader is \([0-9]\+\).*/\1/' | sudo tee /sys/fs/cgroup/cpuset/cpulimitf/tasks
  grep "all clients have shut down" stats/.pid
  while [[ $(tail -n 1 stats/summary.log | grep $title | wc -l) -eq 0 ]]; do sleep 2; done

  grep Throughput stats/.pid > stats/.tp
  line=$c
  calc="((0"
  for ((i=1; i <= $line; i++)); do
    x=$(head -n $i stats/.tp | tail -n 1 | awk '{print $11}')
    calc="${calc}+${x}"
  done
  calc="${calc}))"
  python3 -c 'print("throughput : {0:.2f}".format('$calc'))' >> stats/summary.log
  tail -n 1 stats/summary.log

  echo -e "\n\n#run_${nrun}\n" >> stats/$title.log
  cat stats/.pid >> stats/$title.log
  cat stats/.avg >> stats/$title.log
  cat /dev/null > stats/.pid
  cat /dev/null > stats/.avg
  cat /dev/null > stats/.tp

done; done; done; done;
column -t stats/summary.log > stats/.tmp && mv stats/.tmp stats/summary.log
done

sleep 2
kill $pid
