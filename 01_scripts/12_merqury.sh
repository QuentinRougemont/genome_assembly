#!/bin/bash
#===============================================================================
#          FILE: 12_merqury.sh
# 
#         USAGE: ./12_merqury.sh <genome> <fasta> <assembler>
# 
#   DESCRIPTION: compute QV/k-mer completeness draw k-mer multiplicity graph
# 
#       OPTIONS: ---
#  REQUIREMENTS: fasta assembly and mery database
#          BUGS: does not work with trios
#         NOTES: ---
#        AUTHOR: Q. Rougemont 
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:54:40
#      REVISION:  ---
#===============================================================================
set -o nounset                              # Treat unset variables as an error

#check that path to env exist
[[ -z $CONDA_PREFIX ]] && { echo "Error assembly_env path not found" ; exit 1 ; }
#===============================================================================
#------ External variable to be loaded from config file -----------#
if [ $# -lt 2  ]; then
    echo "USAGE: $0 : <genome> <fasta> <assembler>"
    echo -e "Expecting at least 2 arguments : \n 
      \t 1: <genome>: a name for the genomq\n
      \t 2: <fasta>: path to fasta assembly\n
      \t 3: <assembler> : optional: name of the assembler\n"
    exit 1
else
    genome=$1      #genome/species/whatever id
    fasta=$2       #path to fasta assembly file   
    assembler=$3   #assembleur name
fi
#===============================================================================
#--- create architecture ---- #
f1=$(readlink -f "$fasta" )
mkdir 08_meryl/"$genome"_"$assembler" 2>/dev/null
cd 08_meryl/"$genome"_"$assembler" || exit 

#===============================================================================
# -- run merqury -- 
if [ ! -s "$genome".qv ] ; then
    echo "running qv"
    rm results_"$genome".meryl 2>/dev/null
    ln -s ../results_"$genome".meryl . 
    merqury.sh results_"$genome".meryl "$f1" "$genome" > log_merqury_"$assembler"
else
   echo "qv score already computed"
fi
exit 
#===============================================================================
#step3 : -- make some plot --
"$CONDA_PREFIX"/share/merqury/eval/spectra-cn.sh \
    "$genome".meryl \
    "$f1" \
    "$genome".out

