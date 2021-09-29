#!/bin/bash                                  
#SBATCH -J "blast"                      
#SBATCH -o log_%j                            
#SBATCH -c 6                               
#SBATCH --mem=21G                             
                                             
# Move to directory where job was submitted  
cd $SLURM_SUBMIT_DIR                         

#perform blast on all insect genome, all contaminant, human genome separately, then compare mappings
source /local/env/envparallel-20190122.sh
source /local/env/envblast-2.9.0.sh
# Global variables
INPUT_FASTA=/groups/supergene/RAW/pacbio/m64244_210809_131705.hifi_reads.fasta
DATABASE=insect.fa #.fa #$1

# Blast fasta file
cat "$INPUT_FASTA" |
    parallel -k \
    --block 1k \
    --recstart '>' \
    --pipe blastn \
    -db "$DATABASE" -query - \
    -evalue 10e-6 \
    -outfmt \"6 qseqid sseqid pident length evalue bitscore qseq sseq\" \
    -max_target_seqs 1 > \
    04_blasts/"$(basename ${INPUT_FASTA%.fasta})"."$(basename $DATABASE)"

