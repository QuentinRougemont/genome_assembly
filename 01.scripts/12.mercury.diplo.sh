#!/bin/bash                                  
#SBATCH --job-name=mercury                
#SBATCH --output=QV-%J.out                  
#SBATCH --cpus-per-task=24                   
#SBATCH --mem=40G                           
                                             
# Move to directory where job was submitted  
cd $SLURM_SUBMIT_DIR                         

source ~/.bashrc

#source /local/env/envigv-2.4.9.sh 
source /local/env/envsamtools-1.6.sh 
source /local/env/envbedtools-2.27.1.sh 
source /local/env/envjava-1.8.0.sh 
source /local/env/envr-4.0.3.sh 


#/!\/!\ WARNING: in the merqury.sh and other *sh file from merqury-1.3 I've add the path to merqury

#2. Overall assembly evalution:
#2.1. reference free QV estimate
mkdir hap1_hap2.HiFi
cd hap1_hap2.HiFi
ln -s ../hap1.HiFi/test.hap1.p_ctg.fasta
ln -s ../hap2.HiFi/test.hap2.p_ctg.fasta
ln -s ../read.meryl
~/software/merqury-1.3/merqury.sh read.meryl test.hap1.p_ctg.fasta test.hap2.p_ctg.fasta hap1_hap2.HiFi > hifi.hap1hap2.log

