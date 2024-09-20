#!/bin/bash
#===============================================================================
#          FILE: 01_dorado.sh
#         USAGE: ./01_dorado.sh <$INPUT> <$OUTPUTMODEL> <$MODEL> 
# 
#   DESCRIPTION:  microscript to run dorado and perform basecalling
# 
#       OPTIONS: ---
#  REQUIREMENTS: pod5 data must be located in 02_raw  - GPU only
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. Rougemont 
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:54:40
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#===============================================================================
#       External variable 
if [ $# -ne 3  ]; then
    echo "USAGE: $0 : <INPUT> <OUTPUTNAME> <MODEL> "
    echo -e "Expecting three arguments : \n 
      \t 1: <INPUT>: folder_name contain pod5 files\n
      \t 2: <OUTPUTNAME> : id to rename the fastq input \n
      \t 3: <MODEL>: model for dorado basecalling \n"
    exit 1
else
    INPUT=$1
    OUTPUTNAME=$2
    MODEL=$3   #ex: "dna_r10.4.1_e8.2_400bps_sup@v4.3.0"
fi

#===============================================================================
#       Command check
command='dorado' 
if ! command -v $command &> /dev/null
then
    echo "ERROR: $command could not be found"
    echo "please install it before doing anything else"
    exit 1
fi

#===============================================================================
#download model:
dorado download --model "$MODEL" 
#actual basecall:
mkdir 02_raw 2>/dev/null
dorado basecaller "$MODEL" "$INPUT" > 02_raw/nanohq.calls.bam

#kitname="SQK-NBD114-24"
#dorado basecaller --kit-name "kitname"  "$MODEL" pod5 > 02_raw/"$kitname".bam

samtools fastq 02_raw/nanohq.calls.bam |gzip >> 01_raw/"$OUTPUTNAME".fastq.gz

#===============================================================================
#TO DO eventually: implement herro for read correction
#Unfortunatelly takes for ever with huge amount of memory 
#dorado correct  02_raw/"$OUTPUTNAME".fastq.gz >  01_raw/"$OUTPUTNAME".corrected.fasta
