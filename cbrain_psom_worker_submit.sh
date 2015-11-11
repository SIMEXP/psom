#!/bin/bash

if [ $# != 2 ]
then
    echo "usage: $0 <output_dir> <worker_id>"
    exit 1
fi

OUTPUT_DIR=$1
WORKER_ID=$2

FILE=`mktemp cbrain-psom-worker-XXXX.submit`
echo ${OUTPUT_DIR},${WORKER_ID} > ${FILE}