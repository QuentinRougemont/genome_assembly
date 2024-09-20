#!/bin/bash - 
#===============================================================================
#
#          FILE: 10_bwamem2.sh
# 
#         USAGE: ./10_bwamem2.sh <INPUTGENOME> <ILLUMINAFOLDER> <OUTFOLDER> (optional : <NCPU>) 
# 
#   DESCRIPTION: running bwa-mem2 + samtools 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. Rougemont +  Alexandra Jalaber Dupont de Dinechin
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:54:40
#      REVISION:  ---
#===============================================================================
#set -o nounset                              # Treat unset variables as an error
# Global variables
# Check if the number of arguments is correct
if [ $# -lt 3  ]; then
    echo "USAGE: $0 <genome> <assembler> (optional: <NCPU>)"
    echo -e "Expecting at least 3 arguments : \n 
      \t 1: <INPUTGENOME>: full path to genome assembly\n
      \t 2: <ILLUMINAFOLDER>: path to folder containing trimmed illumina data\n
      \t 3: <OUTFOLDER>: name of output folder \n
      \n\t optionally: \n
      \t 4: <NCPU> : optional: number of cpu to use \n"
      exit 
else
    INPUTGENOME=$1
    ILLUMINAFOLDER=$2
    OUTFOLDER=$3
    NCPU=$4
fi
#===============================================================================

# Define paths and files
# Test if user specified a number of CPUs, if not, default to 8
if [[ -z "$NCPU" ]]
then
    NCPU=8
fi

if [[ ! -d "$OUTFOLDER" ]]
then
    mkdir "$OUTFOLDER"
fi

cmd=$(command -v bwa-mem2) #I used it to fix the "prefix too long error"

#===============================================================================
# Test if genome index already exists, if not, index it
if [ ! -e "${INPUTGENOME}".bwt.2bit.64 ]; then
    echo "BWA.mem : Indexing genome..."
    $cmd index "${INPUTGENOME}"
    echo "BWA.mem : Genome indexed successfully."
else
    echo "BWA.mem : Genome index already exists."
fi

#===============================================================================
#Loop through each trimmed Illumina fastq file
for file in "$ILLUMINAFOLDER"/*trimmed_1.fq.gz ; 
do
    #[ -f $file ] || echo "no illumina data" 
    # Name of corresponding second read file
    file2="${file/_1.fq.gz/_2.fq.gz}"

    name=$(basename "$file")
    name2=$(basename "$file2")
    ID="@RG\tID:ind\tSM:ind\tPL:Illumina"

    if [ ! -s "$OUTFOLDER/${name%.fq.gz}.sorted.bam" ]; then
        echo "BWA.mem : Aligning file $file $file2" 

        $cmd mem -t "$NCPU" -R "$ID" "$INPUTGENOME" "$ILLUMINAFOLDER"/"$name" "$ILLUMINAFOLDER"/"$name2" 2> /dev/null |\
            samtools view -Sb -q 10 - |\
            samtools sort --threads "$NCPU" -o "$OUTFOLDER"/"${name%.fq.gz}".sorted.bam -
        samtools index "$OUTFOLDER"/"${name%.fq.gz}".sorted.bam
    else
	    echo The file "$OUTFOLDER/${name%.fq.gz}.sorted.bam" already exist
    fi	
done
