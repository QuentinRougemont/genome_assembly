#!/bin/bash - 
#SBATCH --account=youraccount
#SBATCH --time=46:00:00
#SBATCH --job-name=dorado
#SBATCH --output=log_dorado-%J.out
#SBATCH --nodes=1
#SBATCH --gpus=1
#SBATCH -p gpu
#SBATCH --mem-per-gpu=180G

# Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR
#===============================================================================
set -o nounset                              # Treat unset variables as an error
#===============================================================================

#Purpose: 
#script to launch dorado in high accuracy mode

#external variable (passed from config file or main scipt)
INPUT=$1        #pod5 folder in general data are located in folder 'pod5/' 
OUTPUTNAME=$2   #a name for the species/strain/etc
MODEL=$3        #model from ONT R10 : ex: "dna_r10.4.1_e8.2_400bps_sup@v4.3.0"

./01_scripts/00_dorado.sh "$INPUT" "$OUTPUTNAME" "$MODEL"
