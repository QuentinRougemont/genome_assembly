#!/bin/bash
#SBATCH --job-name=BUSCO
#SBATCH --cpus-per-task=8
#SBATCH --mem=20G

source /local/env/envconda.sh
conda activate /groups/bipaa/env/busco_4.0.6
. /local/env/envaugustus.sh
input=$1   #fasta
output=$2  #folderoutput
busco -c8 -o $output -i $input  -l lepidoptera_odb10 -m geno
