#!/bin/bash                                  
##/!\/!\ WARNING: in the merqury.sh and other *sh file from merqury-1.3 I've add the path to merqury

#2. Overall assembly evalution:
#2.1. reference free QV estimate
mkdir hap1_hap2.HiFi
cd hap1_hap2.HiFi
ln -s ../hap1.HiFi/hap1.p_ctg.fasta
ln -s ../hap2.HiFi/hap2.p_ctg.fasta
ln -s ../read.meryl
~/software/merqury-1.3/merqury.sh read.meryl hap1.p_ctg.fasta hap2.p_ctg.fasta hap1_hap2.HiFi > hifi.hap1hap2.log

