mkdir -p statsperfresult

for subdir in statsperfresult/statsperf_bc_*/; do
  subfolder_name=$(basename "$subdir")
  echo "$subfolder_name :" >> statsperfresult/aggregate_bc.log
  cat "$subdir/summary.log" >> statsperfresult/aggregate_bc.log
  echo -e "\n" >> statsperfresult/aggregate_bc.log
done

for subdir in statsperfresult/statsperf_crpc_*/; do
  subfolder_name=$(basename "$subdir")
  echo "$subfolder_name :" >> statsperfresult/aggregate_crpc.log
  cat "$subdir/summary.log" >> statsperfresult/aggregate_crpc.log
  echo -e "\n" >> statsperfresult/aggregate_crpc.log
done

paste -d$'\t' statsperfresult/aggregate_crpc.log statsperfresult/aggregate_bc.log | column -s$'\t' -t > statsperfresult/aggregated_summary.log
sed -i 's/Running for duration, Throughput: [0-9.]*$/&\n/g' statsperfresult/aggregated_summary.log
