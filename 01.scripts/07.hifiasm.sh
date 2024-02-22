#!/bin/bash
#SBATCH --job-name=assembly
#SBATCH --output=ass-%J.out
#SBATCH --cpus-per-task=40
#SBATCH --mem=140G

# Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR

source /local/env/envconda3.sh 

conda activate hifiasm

input=filtered.hififile.fastq.gz
s=$1  #s value 
O=$2  #o value

#tested parameters #no improvement
#see manual for details of what they do
#-D 10 
#-N 120
#--purge-max 100
#--hom-cov 1 
#--l0 can be used for low het genome 

mkdir LOG/ 2>/dev/null 

#running hifiasm
hifiasm -o ${input%.fa**}.no_contam.asm.s"$s".O$O \
	-s "$s" \
	-O $O \
	-t 40 \
	$input 2>&1 |tee LOG/log.${input%.fa**}.no_contam.asm.s"$s".O$O 
 

exit
#old assembly with primary only:
#hifiasm -o m64244_210809_131705.hifi_reads.no_contam.asm --primary -t 40 output.fastq 

