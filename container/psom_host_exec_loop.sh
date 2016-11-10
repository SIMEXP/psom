#!/bin/bash

if [ $# != 1 ]
then
    echo "usage: $0 <fifo_name>"
    exit 1
fi

fifo_name=$1

[ -p $fifo_name ] || mkfifo $fifo_name;

while true
do
    if read line; then
        echo $line
        eval $line
    fi
done <"$fifo_name"
