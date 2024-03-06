#!/bin/bash
#conda activate hifiasm

input=$1 #hifi reads can be filtered from contaminant or not
s=$2  #s value 
O=$3  #o value

#tested parameters #no improvement
#see manual for details of what they do
#-D 10 
#-N 120
#--purge-max 100
#--hom-cov 1 
#--l0 can be used for low het genome 

mkdir LOG/ 2>/dev/null 

#running hifiasm
hifiasm -o ${input%.fa**} \
	-s "$s" \
	-O $O \
	-t 40 \
	$input 2>&1 |tee LOG/log.${input%.fa**}.s"$s".O$O 
 

exit
#old assembly with primary only:
#hifiasm -o m64244_210809_131705.hifi_reads.no_contam.asm --primary -t 40 output.fastq 
