#!/bin/bash
#SBATCH --job-name=minimap
#SBATCH --cpus-per-task=24
#SBATCH --mem=480G

source /local/env/envgcc-9.3.0.sh
source /local/env/envminimap2-2.15.sh 
contam=/scratch/qrougemont/pacbio/blast/insect_human_contam.fa
fasta=/groups/supergene/RAW/pacbio/m64244_210809_131705.hifi_reads.fasta

minimap2 -x map-pb -I 110G -t 24 -a -Q $contam $fasta > minimap2.sam
exit
/scratch/qrougemont/pacbio/minimap2-arm/minimap2 -x map-pb -I 500G -t 24 -a -Q --multi-prefix tmp $contam $fasta > minimap2.sam
# --multi-prefix: enable mergine
# -I: split index for every ~500G input bases, this number is far more than the reference.
