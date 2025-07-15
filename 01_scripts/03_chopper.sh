#!/bin/bash
#===============================================================================
#          FILE: 03_chopper.sh
# 
#         USAGE: ./03_chopper.sh <genome> <qual> <headcrop> <len> 
# 
#   DESCRIPTION: nanoscript to run chopper on ONT data  
# 
#       OPTIONS: quality, headcrop and minimal length of read must be set
#  REQUIREMENTS: fastq.gz input + chopper
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. Rougemont 
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:54:40
#      REVISION:  ---
#===============================================================================

##  ------------------------ general parameters --------------------------------  ##
if [ $# -lt 2  ]; then
    echo "USAGE: $0 : <INFOLDER> <OUTFOLDER> <qual> <headcrop> <len>"
    echo -e "Expecting at least 2 arguments in that order : \n 
      \t 1: <INFOLDER>: path to the folder containing one or several fastq\n
      \t 2: <OUTFOLDER>: name of the output folder \n
      \t optional arguments in this order: 
      \t 3: <QUAL> : minimum quality score <default: 10>\n
      \t 4: <HEADCROP> : minimal length for headcrop <default: 10>\n
      \t 5: <MINLEN> : miniam length for trimming <default: 1000>\n"
    exit 1
else
    INFOLDER=$1
    OUTFOLDER=$2
    QUAL=$3
    HEADCROP=$4
    MINLEN=$5
fi
#===============================================================================

if [ -z "$QUAL" ] ;
then
    QUAL=10
fi

if [ -z "$HEADCROP" ] ;
then
    HEADCROP=10
fi

if [ -z "$MINLEN" ] ;
then
    MINLEN=1000
fi

#TO DO: handling case with multiple fastq/fastq.gz fastqs

#"--- trimming with chopper ---"

#iterate over all input in the raw folder 
#their can be several file

minsize=900000
outsize="$OUTFOLDER"/input.trimmed.fastq.gz
if [ -s "$outsize" ] 
then
    filesize=$(wc -c <"$outsize" )
else
    filesize=0
fi
#
#---------  run minimap ----------#

if [ "$filesize" -lt "$minsize" ]
then
    echo "running chopper"
    for fastq in "$INFOLDER"/*f*q.gz 
    do
       name=$(basename "${fastq}" )
       echo "$name"  
       if file --mime-type "$fastq" | grep -q gzip$; then
           echo processing "$name"   ; 
           zcat "$fastq" | \
           chopper -q "$QUAL" -l "$MINLEN" --headcrop "$HEADCROP" |  \
                gzip >> "$OUTFOLDER"/input.trimmed.fastq.gz ;
                #gzip > "$OUTFOLDER"/"${name%.fastq.gz}".trimmed.fastq.gz ;
       else
           echo processing "$name"   ; 
           chopper -q "$QUAL" -l "$MINLEN" --headcrop "$HEADCROP" "$fastq" |  \
                 gzip >> "$OUTFOLDER"/input.trimmed.fastq.gz ; 
          
       fi
    done
else
    echo "output file $OUTFOLDER/input.trimmed.fastq.gz already exist"
    echo "this file will be use for genome assembly"
    #exit 1
fi


