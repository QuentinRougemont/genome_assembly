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

#1 prepare meryl dbs fille
#1.1. find best kmer:
#~/software/merqury-1.3/best_k.sh 262666002 #genome size in bp according to genome scope.
#~/software/merqury-1.3/best_k.sh 319000002 #genome size in bp according to biology.
#best kmer is ~19

#1.2. Build k-mer dbs with meryl
#k=19
#read=/scratch/qrougemont/pacbio/filter_dataset/filter2/output.fastq.gz

#meryl k=$k count output read.meryl $read

#2. Overall assembly evalution:
#2.1. reference free QV estimate
cd test_HiFi
ln -s ../read.meryl
~/software/merqury-1.3/merqury.sh read.meryl test.p_ctg.fasta  test_HiFi > hifi.log

cd ../hap1.HiFi
ln -s ../read.meryl
~/software/merqury-1.3/merqury.sh read.meryl test.hap1.p_ctg.fasta  hap1.HiFi > hifi.hap1.log

cd ../hap2.HiFi
ln -s ../read.meryl
~/software/merqury-1.3/merqury.sh read.meryl test.hap2.p_ctg.fasta  hap2.HiFi > hifi.hap2.log



#2.2. https://github.com/marbl/merqury/wiki/2.-Overall-k-mer-evaluation#2-copy-number-spectrum-analysis
#follow: https://github.com/marbl/merqury/wiki/2.-Overall-k-mer-evaluation

#2.3. 3. k-mer completeness (recovery rate)
#k-mer completeness = found solid k-mers in an assembly / solid k-mers in a read set


