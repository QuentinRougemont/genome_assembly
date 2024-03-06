#!/bin/bash
##SBATCH --job-name=BUSCO
##SBATCH --cpus-per-task=8
##SBATCH --mem=20G

#script to remove contaminant
source /local/env/envconda.sh
#source /local/env/envqiime2-2019.10.sh
conda activate qiime1

sequences=contaminant.to.remove.txt
input=/groups/supergene/RAW/pacbio/m64244_210809_131705.hifi_reads.fastq
gunzip "$input".gz
output=output.fastq
filter_fasta.py -f $input -o $output -s $sequences -n
