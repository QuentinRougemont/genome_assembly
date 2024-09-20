#!/bin/bash
#===============================================================================
#          FILE: 09_fastp.sh
# 
#         USAGE: ./09_fastp.sh <ILLUMINA_FOLDER> <OUTFOLDER> 
# 
#   DESCRIPTION: polishing nano-raw (ONT) with fastp 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. Rougemont 
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:58:16
#      REVISION:  Alexandra Jalaber Dupont de Dinechin + Q. Rougemont
#===============================================================================
# Global variables
# Check if the number of arguments is correct
if [ $# -ne 2  ]; then
    echo "USAGE: $0 <ILLUMINA_FOLDER> <OUTFOLDER> "
    echo -e "Expecting the following argument: \n 
    	\t 1: <ILLUMINA_FOLDER> : path to the folder containing ILLUMINA_FOLDER data for the species\n
	    \t 2: <OUTFOLDER>       : OUTPUT FOLDER\n"
    exit 1
else
    ILLUMINA_FOLDER=$1
    OUTFOLDER=$2
fi

#expected form of out-folder:
#OUTFOLDER="03_TrimmedIllumina/${genome}"

for file in "${OUTFOLDER}"/*gz 
do
    if [ ! -s "${file}" ] 
    then
       qual=30     #by default we set it to 30 #TO DO: remove hardcoded variable and pass it as argument
       length=120  #by default we set it to 120 #TO DO: remove hardcoded variable and pass it as argument
   
       # Create OUTFOLDER directories
       mkdir -p "$OUTFOLDER" 2>/dev/null
       mkdir -p "$OUTFOLDER"/01_report 2>/dev/null
   
       # number of threads
       NCPU=8
       # Trim reads with fastp 
       find "$ILLUMINA_FOLDER"/*1.f*q.gz | perl -pe 's/[12]\.f.*q\.gz//g' |
               parallel -j "$NCPU" \
                   fastp -i {}1.f*q.gz -I {}2.f*q.gz \
                       -o "$OUTFOLDER"/{/}trimmed_1.fq.gz \
                       -O "$OUTFOLDER"/{/}trimmed_2.fq.gz  \
                       --length_required="$length" \
                       --qualified_quality_phred="$qual" \
                       --correction \
                       --trim_tail1=1 \
                       --trim_tail2=1 \
                       --json "$OUTFOLDER"/01_report/{/}.json \
                       --html "$OUTFOLDER"/01_report/{/}.html  \
                       --report_title={/}.html
    else
        echo The folder "$OUTFOLDER" is already created
    fi
done
