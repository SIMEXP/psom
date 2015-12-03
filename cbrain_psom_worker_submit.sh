#!/bin/bash

if [ $# != 2 ]
then
    echo "usage: $0 <output_dir> <worker_id>"
    exit 1
fi

OUTPUT_DIR=$1
WORKER_ID=$2

FILE=`mktemp new-task-XXXX.json`

cat << NEWTASK > ${FILE}
{
  "tool-class": "PSOMWorker",
  "description": "A PSOM worker submitted by PSOM through cbrain-psom-worker-submit.",
  "parameters": [
      {
          "name": "output_dir",
          "value" : "${OUTPUT_DIR}"
      },
      {
          "name": "worker_id",
          "value" : "${WORKER_ID}"
      }
  ]
}

NEWTASK
