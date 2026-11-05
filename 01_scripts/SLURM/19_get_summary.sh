#!/bin/bash - 
#SBATCH --account=youraccount
#SBATCH --time=00:05:00
#SBATCH --job-name=summarize
#SBATCH --output=log_summarize-%J.out
#SBATCH --mem=4G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1

# Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR
#===============================================================================
#set -o nounset                              # Treat unset variables as an error
#===============================================================================
#activate any conda env if necessary
conda activate assembly_env

./01_scripts/19_get_summary.sh
