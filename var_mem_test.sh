#!/bin/sh

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 test_duration_in_secs"
	exit 1
fi

FREE_MEM=$(expr $(free | awk '/^Mem:/{print $4}') / 1024)
ITERS=$(expr $(expr $FREE_MEM - 300) / 150)
echo There is $FREE_MEM MBytes of free RAM
echo Running $ITERS threads of memory test, 150 MBytes each one, for $1 seconds

for i in `seq 1 $ITERS`;
do
	memtester 150m | grep FAIL &
done

sleep $1

killall memtester
