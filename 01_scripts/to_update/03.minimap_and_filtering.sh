#!/bin/bash
#Author: QR
#date: 2022
#update: 2024
#purpose: 
# 1 - align long read against a reference set of sequence to search for putative contaminant.
# 2 - remove the contaminant if there is not a better overlapping match with known sequence closely related to the focal species of interest
# 3 - mask the contaminant in the fasta (insert NNNN) (a new fasta is created) 
# 4 - prepare the data for launching blast 

#-------- input data -----------------------#
# Global variables
if [ $# -ne 3  ]; then
    echo "USAGE: $0 <species> <fastq> <type>"
    echo -e "Expecting the three following arguments: \n 
    	\t 1: <species> : a name corresponding to the genome of your study species\n
	\t 2: <fastq>   : the fastq file of read to align\n
	\t 3: <type>    : PB or ONT a string stating wether data are frome pacbio-hifi (pb) or ONT (ONT)\n"
    exit 1
else
    species=$1
    fastq=$2 #set of long reads to be mapped - ideally compressed.
    type=$3  #either PB or ONT
    echo "species name : ${species}"
    echo -e "\n"
    echo fastq file is $fastq 
    echo data type is $type
    echo -e "\n"
fi

contam="$species"_human_contam.fa

#--------- step 1 -- run minimap ----------#
if [[ $type = "PB" ]]
then
	minimap2 -c -x map-pb  -t 24 -Q $contam $fastq |gzip  > minimap2.paf.gz

else 
	echo "assuming reads are ONT" 
	minimap2 -c -x map-ont -t 24 -Q $contam $fastq |gzip > minimap2.paf.gz
fi

#--------- step 2 -- reshape data----------#

#print only wanted columns:
zcat minimap2.paf.gz |awk '$12 > 29 && $6 ~/contam/ {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$12}' > contam.tmp
zcat minimap2.paf.gz |awk -v spe=$species '$12 > 29 && $6 ~ spe {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$12}' > spe.tmp 

#run Rscript to extract contaminant: 
Rscript 01.scripts/Rscripts/paf_extract_contam.R

#check input compression :
echo -e "\n\n"

if file --mime-type "$fastq" | grep -q gzip$; then
   echo "$fastq is gzipped"
   echo "converting fastq in fasta "
   zcat "$fastq" |sed -n '1~4s/^@/>@/p;2~4p'  |sed 's/ runid.*//' > "${fastq%.f*q*}".fasta
else
   echo "$fastq is not gzipped"
   echo "converting fastq in fasta "
   cat "$fastq" |sed -n '1~4s/^@/>@/p;2~4p'  |sed 's/ runid.*//' > "${fastq%.f*q*}".fasta
fi

#--------- step 3 -- insert NNNNN----------#
fasta="${fastq%.f*q*}".fasta
masked_fasta="${fastq%.f*q*}".masked.fasta

#use bedtools maskfasta for our purpose: 
#the file putative_contaminant.withnospecies_overlap.bed is generate from the above Rscript 
bedtools maskfasta -fi $fasta -bed putative_contaminant.withnospecies_overlap.bed -fo "$masked_fasta"

#----- step 4 -- run blast ---------------#
#grep also the sequence from within the fasta to blast them:
grep -A1 -Ff <(cut -f1 putative_contaminant.withnospecies_overlap.bed ) $fasta  > putative_contaminant.withnospecies_overlap.toblast.fa

./01.scripts/04.makeblastdb.sh $contam $contam
./01.scripts/05.blast.sh  $fasta $contam 

#keep high quality blasts:
grep -v "$species" blasts/putative_contaminant.withnospecies_overlap.toblast.fa."$species"_human_contam.fa |\
	awk '$3>80 && $4>300 && $10<1e-20 {print $1"\t"$5"\t"$6}' |\
	sort -k1  |uniq > putative_contaminant_from_blast.bed

#use bedtools to re-insert additional NNNN :
masked_fasta2="${fastq%.f*q*}".maskedfull.fasta

bedtools maskfasta -fi $masked_fasta -bed putative_contaminant_from_blast.bed -fo "$masked_fasta2"

# ---- step 5 --- create a stringeant filtration by removing all putativate contaminant from minimap

awk '{ if ((NR>1)&&($0~/^>/)) { printf("\n%s", $0); } else if (NR==1) { printf("%s", $0); } else { printf("\t%s", $0); } }' "$fasta" |\
     grep -vFf <(cut -f1 putative_contaminant.withnospecies_overlap.bed ) - | tr "\t" "\n" > ${fasta﻿%.fasta}.nocomtam.fasta


#- Now run the assembler for the different cleaned output and look at the differences

exit


##########################################################################################
#deprecate lines here:
#/nimap2 -x map-pb -I 500G -t 24 -a -Q --multi-prefix tmp $contam $fasta > minimap2.sam
# --multi-prefix: enable mergine
# -I: split index for every ~500G input bases, this number is far more than the reference.
