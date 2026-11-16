#!/bin/bash - 
#===============================================================================
set -o nounset                              # Treat unset variables as an error
#===============================================================================

source config #a filer with genomesize, data type, fastq/pod5, basename etc ploidy
source cpu_mem
echo "assembler is "${assembler}" "

assembly=$1         #full path to the new genome assembly (fasta) file
BASE="${SPECIES}"
 #run merqury here
 if ! ./01_scripts/12_merqury.sh "$BASE" "$assembly" "$assembler"
 then
         echo "merqury failed"
         exit 1
 else
     echo -e "\n----------------------------------"
     echo -e "\tmerqury QV/completness & plot done"
     echo -e "\n----------------------------------"
 fi
