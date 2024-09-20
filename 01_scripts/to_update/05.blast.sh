#!/bin/bash                                  
#perform blast 

# Global variables
INPUT_FASTA=$1 #a set of  hifi or ONT raw read in fasta format 
DATABASE=$2    #name of the big database of contaminant generate with script n°2

mkdir blasts 2>/dev/null

#check input compression
if file --mime-type "$INPUT_FASTA" | grep -q gzip$; then
   echo "$INPUT_FASTA is gzipped"
   gunzip "$INPUT_FASTA"
   INPUT_FASTA=${INPUT_FASTA%.gz}
else
   echo "$INPUT_FASTA is not gzipped"
fi

# Blast fasta file
cat "$INPUT_FASTA" |
    parallel -k \
    --block 1k \
    --recstart '>' \
    --pipe blastn \
    -db "$DATABASE" -query - \
    -evalue 1e-10 \
    -outfmt \"6 qseqid sseqid pident length mismatch qstat qend sstart send sstrand evalue bitscore qseq sseq\" \
    -max_target_seqs 20 > \
    blasts/"$(basename ${INPUT_FASTA%.fasta*})"."$(basename $DATABASE)"

