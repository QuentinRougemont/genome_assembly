#!/bin/bash - 
#===============================================================================
set -o nounset                              # Treat unset variables as an error
#===============================================================================
#activate any conda env if necessary
conda activate assembly_env

#Purpose: 
#script to clean genome
ASSEMBLY=$1        #the fasta (can be the whole path in any folder)

./01_scripts/15_removeLowQual.sh "${ASSEMBLY}"
