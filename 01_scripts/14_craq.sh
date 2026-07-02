#!/bin/bash - 
#===============================================================================
#          FILE: 14_craq.sh
# 
#         USAGE: ./14_craq.sh <ASSEMBLY> <SMS.bam> <NGS.bam>  
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. ROUGEMONT, 
#  ORGANIZATION: 
#       CREATED: 05/09/2024 12:43:31
#      REVISION:  ---
#===============================================================================
#       External variable 
ASSEMBLY=$1 #genome assembly 
SMSBAM=$2   #long read bam
#optional for ONT:
NGSBAM=$3   #NGS reads
#===============================================================================

#       check manually installed command:

command='craq' 
if ! command -v $command &> /dev/null
then
    echo "ERROR: $command could not be found"
    echo "please install it before doing anything else"
    exit 1
fi

#===============================================================================
if [ ! -s CRAQ_results/"${ASSEMBLY%.fa*}"/consensus/runAQI_out/out_final.Report ] 
then 
    if [ -v "$NGSBAM" ]
    then
        samtools index "$SMSBAM"
        samtools index "$NGSBAM"
        craq -g "$ASSEMBLY" -sms "$SMSBAM" -ngs "$NGSBAM" -o CRAQ_results/"${ASSEMBLY%.fa*}"
    else
        samtools index "$SMSBAM"
        craq -g "$ASSEMBLY" -sms "$SMSBAM" -o CRAQ_results/"${ASSEMBLY%.fa*}"
    fi
else
    echo "craq output already available"
fi
