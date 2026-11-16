#!/bin/bash - 
#===============================================================================
set -o nounset                              # Treat unset variables as an error
#===============================================================================
#activate any conda env if necessary
conda activate assembly_env

#Purpose: 
#script to launch dorado in high accuracy mode
INPUT=$1        #the bam file (can be the whole path in any folder)

./01_scripts/01_extractHifi.sh "${INPUT}"
