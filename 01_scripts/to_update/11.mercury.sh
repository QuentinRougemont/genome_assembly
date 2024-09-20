#!/bin/bash                                  

#Global Variables
source ~/.bashrc

# Global variables
if [ $# -ne 3  ]; then
    echo "USAGE: $0 <fasta <fastq> <genome_size>"
    echo -e "Expecting the three following arguments: \n 
    	\t 1: <fasta> : fasta assembly from HiFiasm\n
	\t 2: <fastq>   : the fastq file of HiFi reads\n
	\t 3: <genome_size>  : estimated genome size for merqury best_k\n"
    exit 1
else
    fasta=$1 #genome assembly
    fastq=$2 #set of long reads to be mapped - ideally compressed.
    genome_size=$3  
    echo "assembly name : ${fasta}"
    echo -e "\n"
    echo fastq file is $fastq 
    echo genome size is $genome_size
    echo -e "\n"
fi

#source /local/env/envigv-2.4.9.sh 
#source /local/env/envsamtools-1.6.sh 
#source /local/env/envbedtools-2.27.1.sh 
#source /local/env/envjava-1.8.0.sh 
#source /local/env/envr-4.0.3.sh 

#/!\/!\ WARNING: in the merqury.sh and other *sh file from merqury-1.3 I've add the path to merqury

#1 prepare meryl dbs fille
#1.1. find best kmer:
bestK=$(~/software/merqury/best_k.sh $genome_size |tail -n1 )


#1.2. Build k-mer dbs with meryl
meryl k=$bestK count output read.meryl $fastq

#2. Overall assembly evalution:
#2.1. reference free QV estimate
~/software/merqury/merqury.sh read.meryl $genome  meryl.HiFi > hifi.log

#step3 -- make some plot:
~/software/merqury/eval/spectra-cn.sh read.meryl/ $genome "$genome".out

#2.2. https://github.com/marbl/merqury/wiki/2.-Overall-k-mer-evaluation#2-copy-number-spectrum-analysis
#follow: https://github.com/marbl/merqury/wiki/2.-Overall-k-mer-evaluation

#2.3. 3. k-mer completeness (recovery rate)
#k-mer completeness = found solid k-mers in an assembly / solid k-mers in a read set
