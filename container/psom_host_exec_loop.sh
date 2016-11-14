#!/bin/bash

if [ $# != 1 ]
then
    echo "usage: $0 <fifo_name>"
    exit 1
fi

fifo_name=$1

PARENT_ID=$(echo $a  | sed "s/.*psom\-\(.*\)\-fifo.*/\1/")
CURRENT_PROCESS=$$

[ -p $fifo_name ] || mkfifo $fifo_name;

while true
do
    if read line; then
        echo $line
        eval $line
    fi
done <"$fifo_name"





kill_clock {
# Make sure I do not hang if parent process is gone
while ps --pid ${PARENT_ID}
do
  sleep 5

done

# clean mess!
kill $CURRENT_PROCESS
rm $fifo_name


}