#!/bin/bash
#===============================================================================
#          FILE: 02_awk_fastq_length.sh
# 
#         USAGE: ./02_awk_fastq_length.sh <$fastq(.gz)> 
# 
#   DESCRIPTION: computing length of fastq files compressed or not 
# 
#       OPTIONS: ---
#  REQUIREMENTS: awk
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. Rougemont 
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:54:40
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
#===============================================================================
fastq=$1   #full path to the fastq.(gz)
BASE=$(basename "${fastq%%.*}" ) 

OUTFOLDER=03_length_distrib/"$BASE"
mkdir -p "$OUTFOLDER"/ 2>/dev/null

if [ ! -s "$OUTFOLDER"/"$BASE".len.gc.gz ] 
then
    #output not found run the code:
    #check file  
    if file --mime-type "$fastq" | grep -q gzip$; then
       echo "$fastq is gzipped"
        zcat "$fastq" \
           | awk '{
              if(NR%4==1) 
                  {printf(">%s\t",substr($0,2));} 
              else if(NR%4==2) print length "\t" gsub(/[GC]/, "")
              }' |\
           awk '{print $0"\t"$3/$2}'  \
           |gzip > "$OUTFOLDER"/"$BASE".len.gc.gz
     else
        echo "$fastq is not gzipped"
        awk '{
              if(NR%4==1) 
                  {printf(">%s\t",substr($0,2));} 
              else if(NR%4==2) print length "\t" gsub(/[GC]/, "")
              }' "$fastq" |\
           awk '{print $0"\t"$3/$2}'  \
           |gzip > "$OUTFOLDER"/"$BASE".len.gc.gz
     fi

else
    echo -e "\n------------\ngc and len info already available\n------------\n\n"
fi

#then run Rscript to plot de length distributions
#then plot histogram in R
Rscript 01.scripts/Rscripts/plot_len_gc.R  "$OUTFOLDER"/"$BASE".len.gc.gz
#TO DO: add code if R fails

