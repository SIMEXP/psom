#!/bin/bash

if [ $# != 1 ]
then
    echo "usage: $0 <singularity_image>"
    exit 1
fi


IMAGE_PATH=$(realpath ${1})

export PSOM_FIFO=$(mktemp -d /tmp/psom-fifo.XXXXXX)/pipe
#
psom_host_exec_loop.sh ${PSOM_FIFO} & 
LOOP_ID=$!

singularity shell ${IMAGE_PATH} -c "export PSOM_FIFO=${PSOM_FIFO};octave"


function finish {
  # Your cleanup code here
  kill ${LOOP_ID}
  rm ${PSOM_FIFO}
}
trap finish EXIT



