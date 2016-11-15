#!/bin/bash
# Starts a NIAK instance inside a singularity container 
# and a process to execute code on the host, typically qsub

# load config file
CONFIG_FILE=psom.conf
source /etc/${CONFIG_FILE} > /dev/null 2>&1
source ${HOME}/.config/psom/${CONFIG_FILE} > /dev/null 2>&1
#PSOM_SINGULARITY_IMAGES_PATH=~/simexp/singularity/:.

list_all_image () {
#ls ${PSOM_SINGULARITY_IMAGES}

    while IFS= read -r -d $'\0' line; do
        if head -n1 $line | grep -q run-singularity ; then
          ALL_IMAGES=${line}:${ALL_IMAGES%:}
        fi
    done  < <(find ${PSOM_SINGULARITY_IMAGES_PATH//:/ } -maxdepth 1 -type f -print0)

    # Available images
    while read -r line ; do
      ONE_IMAGE=
      bidon=${line##*/}
      echo ${bidon%.img}
    done < <(echo ${ALL_IMAGES}| tr ':' '\n')
    if [[ ! ${ONE_IMAGE+x} ]]; then
       echo No Image installed
       echo "try running with the -p <path_to_image> option"
    fi
}

usage (){

    echo "Starts octave in psom/singulrity mode"
    echo
    echo "Usage: $(basename $0) -l"
    echo "   or: $(basename $0) -i image_from_list"
    echo "   or: $(basename $0) -p path_to_singularity_image"
    echo

    echo "   -l                 list locally installed images "
    echo "   -i <image_name>    run an installed images"
    echo "   -p <path_to_image> run from an arbitrary singularity image path"
}

finish () {
  # Your cleanup code here
  kill ${LOOP_ID} > /dev/null 2>&1
  rm -r ${PSOM_FIFO_DIR} > /dev/null 2>&1
}
trap finish EXIT

host_exec_loop () {
  while true
  do
    if read line; then
        eval $line
    fi
  done <"$PSOM_FIFO"
}


while getopts ":li:p:" opt; do

  case $opt in
    l)
      list_all_image
      exit 0
      ;;
    p)
      echo "-p was triggered, Parameter: $OPTARG" >&2
      IMAGE_PATH=$OPTARG
      if [ ! -f "${IMAGE_PATH}" ]; then
        echo ${IMAGE_PATH} not found
      fi
      ;;
    i)
      IMAGE_PATH=$(find ${PSOM_SINGULARITY_IMAGES_PATH//:/ } \
                    -maxdepth 1 -type f -name "${OPTARG%.img}.img" -print -quit)
      if [[ -z "${IMAGE_PATH// }" ]]; then
        echo image ${OPTARG} not found
        echo
        usage
        exit 1
      fi
      ;;
    \?)
      usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      exit 1
      ;;
  esac
done
if [ $OPTIND -eq 1 ]; then
  usage
  exit 1
fi

IMAGE_PATH=$(realpath ${IMAGE_PATH})

CONSOLE_ID=$$

export PSOM_FIFO_DIR=$(mktemp -d /tmp/psom-${CONSOLE_ID}-fifo.XXXXXX)
export PSOM_FIFO=${PSOM_FIFO_DIR}/pipe

[ -p $PSOM_FIFO ] || mkfifo $PSOM_FIFO;

# Start the communication loop
host_exec_loop  & 
LOOP_ID=$!

# Start singularity-psom
singularity shell ${IMAGE_PATH} -c "export PSOM_FIFO=${PSOM_FIFO};octave"