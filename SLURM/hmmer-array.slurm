#!/bin/bash

#SBATCH --partition=queue
#SBATCH --time=12:00:00
#SBATCH --output=slurm-%A-%a.out
#SBATCH --error=slurm-%A-%a.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --exclude=n[4-6]

#SBATCH --job-name=hmmer

set -o pipefail
set -o errexit

module purge

source /data/software/exports

module load coreutils/8.21
module load HMMER
module load bedops

scratchdir="/scratch/$SLURM_JOB_USER/$SLURM_JOB_ID-$SLURM_JOB_NAME"

files=( $(find "$dir" -name "*.fasta" -print) )

filename="${files[$SLURM_ARRAY_TASK_ID]}"

p="$(basename "$hmm_profile_name")"
bp="${p%.*}"

n="$(basename "$filename")"
bn="${n%.*}"

mkdir -p "$scratchdir"

cd "$scratchdir"

proc() {

    echo "$filename"

#   HMMER analysis
    nhmmer --notextw --noali --tblout nhmmer-$bp-vs-$bn-tbl.out -o /dev/null $hmm_profile_name $filename

#   Converting HMM table output to the BED format with filtering by threshold score to length
#   https://github.com/enigene/hmmertblout2bed
    awk -v th=0.7 -f ~/git/enigene/hmmertblout2bed/hmmertblout2bed.awk nhmmer-$bp-vs-$bn-tbl.out > nhmmer-$bp-vs-$bn-tbl.bed

#   Sorting by name and coordinates
    sort -k 1.4,1 -k 2,2n nhmmer-$bp-vs-$bn-tbl.bed > _nhmmer-t0-$bn.bed

#   Filter by score in each region
    bedmap --max-element --fraction-either 0.1 _nhmmer-t0-$bn.bed > _nhmmer-t1-$bn.bed

#   Filter unique elements
    awk "{if(!(\$0 in a)){a[\$0];if(length(\$4)==2){next}print}}" _nhmmer-t1-$bn.bed > nhmmer-$bp-vs-$bn-tbl.bed

#   Delete temporary files
    rm _nhmmer-t1-$bn.bed
    rm _nhmmer-t0-$bn.bed

    cp -pr "$scratchdir" "$dir"
}

export -f proc

time proc 2>&1

rm -rf "$scratchdir"
