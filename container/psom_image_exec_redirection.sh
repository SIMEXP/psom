#!/bin/bash

echo ${PSOM_FIFO}

[[ -p ${PSOM_FIFO} ]] || echo No FIFO to redirect to ;

cmd=$@

echo $cmd 
echo "$cmd" > ${PSOM_FIFO};
