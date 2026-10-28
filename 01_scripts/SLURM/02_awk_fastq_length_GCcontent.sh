#!/bin/bash - 
#SBATCH --account=youraccount
#SBATCH --time=06:00:00
#SBATCH --job-name=dorado
#SBATCH --output=log_dorado-%J.out
#SBATCH --mem=20G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1

# Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR
#===============================================================================
set -o nounset                              # Treat unset variables as an error
#===============================================================================

#source config #a filer with genomesize, data type, fastq/pod5, basename etc 

#Purpose: 
#script to launch dorado in high accuracy mode
FASTQ=$1
GENOMESIZE=$2

./01_scripts/02_awk_fastq_length_GCcontent.sh "$FASTQ" "$GENOMESIZE" 
