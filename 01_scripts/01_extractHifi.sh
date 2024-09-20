#!/bin/bash
#===============================================================================
#          FILE: 01_extractHifi.sh
# 
#         USAGE: ./01_extractHifi.sh <INPUT.bam>  
# 
#   DESCRIPTION: extracthifi is used to extract PacBio HiFi reads (>= Q20) from full CCS output (reads.bam).

# 
#       OPTIONS: ---
#  REQUIREMENTS: bam file must be located in 01_raw  
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. Rougemont 
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:54:40
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#===============================================================================
# Global variables
if [ $# -ne 1  ]; then
    echo "USAGE: $0 : <INPUT> "
    echo -e "Expecting two arguments : \n 
      \t 1: <INPUT>: raw reads.bam from pacbio\n"
    exit 1
else
    INPUT=$1
fi
#===============================================================================
BASE=$(basename "${INPUT%%.*}" ) 
#extension="${INPUT##*.}"

if [ ! -d 02_FilteredHifi ]; then

    mkdir 02_FilteredHifi 2>/dev/null 
    if [ ! -s 02_FilteredHifi/"${BASE}".fastq.gz ] 
    then
        echo "running extract hifi"
        extracthifi "$INPUT" 02_FilteredHifi/"$BASE"_extractHifi.bam
        pbindex 02_FilteredHifi/"$BASE"_extractHifi.bam
        bam2fastq -o 02_FilteredHifi/"${BASE}" 02_FilteredHifi"${BASE}"/"$BASE"_extractHifi.bam
    else
        echo "hifi bam aleary extracted"
    fi
fi
