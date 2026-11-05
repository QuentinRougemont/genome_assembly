#!/bin/bash - 
##SBATCH --account=youraccount
#SBATCH --time=01:00:00
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
#script to clean genome
ASSEMBLY=$1        #the fasta (can be the whole path in any folder)

./01_scripts/15_removeLowQual.sh "${ASSEMBLY}"
