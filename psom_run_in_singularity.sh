#!/bin/bash
if [ $# != 2 ]
then
    echo "usage: $0 <output_dir> <worker_id>"
    exit 1
fi

OUTPUT_DIR=$1
WORKER_ID=$2



singularity exec  $PSOM_SINGULARITY_IMAGE  psom_worker.py -d $OUPUT_DIR -w $WORKER_ID
