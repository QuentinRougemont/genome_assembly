#!/bin/bash
#===============================================================================
#          FILE: 02_awk_fastq_length.sh
# 
#         USAGE: ./02_awk_fastq_length.sh <$fastq(.gz)> <BASE> <LENGTH> 
# 
#   DESCRIPTION: computing length of fastq files compressed or not 
# 
#       OPTIONS: 3 arguments : 1) the fast file 
#                              2) a base name (specie name for instance) 
#                              3) the expected length (computed from genomeScope)
#  REQUIREMENTS: awk
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. Rougemont 
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:54:40
#      REVISION: 25/11/2026 11:24:20
#===============================================================================
set -o nounset                              # Treat unset variables as an error
#===============================================================================
fastq=$1   #full path to the fastq.(gz)
BASE=$(basename "${fastq%%.*}" ) 
LENGTH=$2  #expected length -- parameter genomesize in base pairs


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
Rscript 01_scripts/Rscripts/plot_len_gc.R  "$OUTFOLDER"/"$BASE".len.gc.gz

awk '{s+=$2}END{print "mean read length:\t" s}' > reads.stats 
awk 'NR==1{min = $2 +0 ; next}{if ($2 < min) min=$2;} END{print "min read length :\t"min}' >> reads.stats.txt
awk 'NR==1{max = $2 +0 ; next}{if ($2 > max) max=$2;} END{print "max read length :\t"max}' >> reads.stats.txt


#get a sense of expected depth based on total length and expected length:
expdp=$(zcat  "$OUTFOLDER"/"$BASE".len.gc.gz|awk -v n="$BASE" -v l="$LENGTH" '{s+=$2}END{print s/l}' )

threshold=20.0 #minimal sequencing depth
#verify that the mean expected depth is above a given threshold
 if awk -v d="$expdp" -v t="$threshold" 'BEGIN{exit !(d < t)}' ; 
 then 
     echo "=================================================================="
     echo "!!!warning sequencing depth seems lower than 20.0 given the expected genome size" ; 
     echo "please verify that this is ok for you !!!!" 
     echo "=================================================================="
     exit 
 else 
     echo " " ; 
 fi


