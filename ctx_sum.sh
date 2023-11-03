mkdir -p statsperf

duration="$1"
for file in statsperf/perf_sched_results_*.data; do
  tid=$(echo "$file" | sed 's/statsperf\/perf_sched_results_\([0-9]*\).data/\1/')
  if [ -f "$file" ]; then
    # cpus_utilized=$(grep "CPUs utilized" "$file" | awk '{print $1}')
    context_switches=$(grep "context-switches" "$file" | awk '{print $1}')
    echo "perf_sched_results_$tid.data: context switches = $context_switches" >> statsperf/summary.log
  fi
done

total_throughput=0

while IFS= read -r line; do
  if [[ $line =~ Throughput:\ ([0-9.]+) ]]; then
    throughput="${BASH_REMATCH[1]}"
    total_throughput=$(bc -l <<< "$total_throughput + $throughput")
  fi
done < statsperf/program_logs.txt

echo "Running for ${duration}, Throughput: $total_throughput" >> statsperf/summary.log