#!/bin/bash

if [[ $# -ne 2 ]]
then
    echo "usage: $0 path_to_the_input_folder path_and_name_of_the_profile" 1>&2
    exit 1
fi

if [ ! -d $1 ]
then
    echo "$1 is not a directory!" 1>&2
    exit 1
fi

if [ ! -s $2 ]
then
    echo "$2 file not found!" 1>&2
    exit 1
fi

export dir="$1"

export hmm_profile_name="$2"

files=( $(find "$dir" -name "*.fasta" -print) )

numfiles="${#files[@]}"
zbnumfiles="$(($numfiles-1))"

if [ $zbnumfiles -ge 0 ]; then
    sbatch --array=0-$zbnumfiles hmmer-array.slurm
    sleep 1
fi
