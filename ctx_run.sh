#!/bin/bash

mkdir -p statsperfresult
duration=60
for cc in {1..1}; do
for c in {1,10,20}; do
for r in {2,3,5,7}; do
for v in {1,2}; do
  echo ${c}c${r}r${v}v
  mkdir -p statsperf

  ./build/deptran_server \
    -f config/sample_crpc.yml \
    -f config/${c}c1s${r}r1p.yml \
    -f config/rw.yml \
    -f config/concurrent_${cc}.yml \
    -P localhost \
    -v $v \
    -d $duration >> stats/.pid > statsperf/program_logs.txt &

  program_pid=$!
  # (taskset -c 19 perf stat -d -t $program_pid -o statsperf/perf_pid_total_$program_pid.data) &
  # echo "Matched whole pid: $program_pid"

  declare -A seen_tids
  counter=0

  tail -f statsperf/program_logs.txt | while read line && [ $counter -lt $((r + 1)) ]; do
    if [[ $line =~ poll\ thread\ tid:\ ([0-9]+) ]]; then
      ((counter++))
      tid="${BASH_REMATCH[1]}"
      echo "Matched: $line"

      if [[ -z "${seen_tids[$tid]}" ]]; then
        seen_tids[$tid]=1
        perf stat -d -e cpu-cycles,context-switches -t $tid -o statsperf/perf_sched_results_$tid.data &
      fi
    fi
  done

  wait $program_pid

  if [ "$v" -eq 1 ]; then
    v_name="bc"
  elif [ "$v" -eq 2 ]; then
    v_name="crpc"
  fi

  outdir="statsperf_${v_name}_${c}c${r}r"

  bash ctx_sum.sh duration &
  wait

  mv statsperf statsperfresult/$outdir
  
done; done; done; done;

bash ctx_aggregate.sh &
wait