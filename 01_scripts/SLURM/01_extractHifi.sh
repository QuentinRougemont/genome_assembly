#!/bin/bash - 
#SBATCH --account=youraccount
#SBATCH --time=06:00:00
#SBATCH --job-name=extractHiFi
#SBATCH --output=log_dorado-%J.out
#SBATCH --mem=20G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1

# Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR
#===============================================================================
set -o nounset                              # Treat unset variables as an error
#===============================================================================
#activate any conda env if necessary
conda activate assembly_env

#Purpose: 
#script to launch dorado in high accuracy mode
INPUT=$1        #the bam file (can be the whole path in any folder)

./01_scripts/01_extractHifi.sh "${INPUT}"
