mkdir -p statsperfresult
rm statsperfresult/aggregated_bc.log statsperfresult/aggregated_crpc.log statsperfresult/aggregated_summary.log

for subdir in statsperfresult/statsperf_bc_*/; do
  subfolder_name=$(basename "$subdir")
  leader_tid=$(awk '/tid of leader is [0-9]+/ {print $NF}' "$subdir/program_logs.txt")
  echo "$subfolder_name, leader tid : $leader_tid" >> statsperfresult/aggregated_bc.log
  cat "$subdir/summary.log" >> statsperfresult/aggregated_bc.log
  echo -e "\n" >> statsperfresult/aggregated_bc.log
done

for subdir in statsperfresult/statsperf_crpc_*/; do
  subfolder_name=$(basename "$subdir")
  leader_tid=$(awk '/tid of leader is [0-9]+/ {print $NF}' "$subdir/program_logs.txt")
  echo "$subfolder_name, leader tid : $leader_tid" >> statsperfresult/aggregated_crpc.log
  cat "$subdir/summary.log" >> statsperfresult/aggregated_crpc.log
  echo -e "\n" >> statsperfresult/aggregated_crpc.log
done

paste -d$'\t' statsperfresult/aggregated_crpc.log statsperfresult/aggregated_bc.log | column -s$'\t' -t > statsperfresult/aggregated_summary.log
sed -i 's/Running for duration, Throughput: [0-9.]*$/&\n/g' statsperfresult/aggregated_summary.log
