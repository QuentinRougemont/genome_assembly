#!/bin/bash

$species=$1 

contam="$species"_human_contam.fa
fasta=your.hifi_reads.fasta

minimap2 -x map-pb -I 110G -t 24 -a -Q $contam $fasta > minimap2.sam

#use map-ont for ONT
#could also generate a paf file to have the coordinates

#deprecate lines here:
#/nimap2 -x map-pb -I 500G -t 24 -a -Q --multi-prefix tmp $contam $fasta > minimap2.sam
# --multi-prefix: enable mergine
# -I: split index for every ~500G input bases, this number is far more than the reference.
