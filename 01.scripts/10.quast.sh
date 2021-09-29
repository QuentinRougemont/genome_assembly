#!/bin/bash
#SBATCH --job-name=QUAST
#SBATCH --cpus-per-task=4
#SBATCH --mem=10G

fasta=$1 #fullpath
output=$2 #id of ind
source /local/env/envquast-4.4.sh
quast --threads 4 --scaffolds --eukaryote -o ./$output $fasta

