#! /usr/bin/env bash

set -e

dir=$(dirname $1)
i=0
k=$(grep run -n $1 | cut -d : -f 1)
k+=" "
k+=$(cat $1 | wc -l)
echo > $dir/med.log
for j in $k; do
cat $1 | awk 'NR == '$i' {print}' >> $dir/med.log
for cc in {1..1}; do
for c in {1,10,20}; do
for r in {2,3,5,7}; do
for v in {"broadcast","crpc-ring"}; do

if [[ $(cat $1 | awk 'NR >= '$i' && NR <= '$j' {print}' | grep "${c}c1s${r}r1p_${cc}-con_${v}") ]]; then
  cat $1 | awk 'NR >= '$i' && NR <= '$j' {print $NF,$0}' | grep "${c}c1s${r}r1p_${cc}-con_${v}" | sort -n | awk 'NR % 2 == 0 {print}' | cut -d' ' -f2- >> $dir/med.log
fi

done; done; done; done;
i=$j
done
