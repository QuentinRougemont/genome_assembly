#!/bin/bash - 
#===============================================================================
#set -o nounset                              # Treat unset variables as an error
#===============================================================================
#activate any conda env if necessary
conda activate assembly_env

#source config #a filer with genomesize, data type, fastq/pod5, basename etc 

#Purpose: 
#script to launch dorado in high accuracy mode
FASTQ=$1
GENOMESIZE=$2

./01_scripts/02_awk_fastq_length_GCcontent.sh "$FASTQ" "$GENOMESIZE" 
