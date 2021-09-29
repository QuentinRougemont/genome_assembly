#!/bin/bash
##SBATCH --account=def-blouis #ihv-653-aa
#SBATCH --time=05:00:00
#SBATCH --job-name=jelly
#SBATCH --output=jelly-%J.out
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=80

# Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR

module load gcc/8.3.0
module load jellyfish/2.3.0

input=$1 #fastq.gz read from HiFi
jellyfish count -C -m 21 -s 1000000000 -t 40 $input -o reads.jf


jellyfish histo -t 40 reads.jf > reads.histo

# Rscript genomescope.R histogram_file k-mer_length read_length output_dir [kmer_max] [verbose]

