#!/bin/bash
#===============================================================================
#          FILE: 11_merryl.sh
# 
#         USAGE: ./11_merryl.sh <genome> <reads> <genome_size> 
#   DESCRIPTION: run merryl 
# 
#       OPTIONS: ---
#  REQUIREMENTS: Illumina WGS or HiFi or NanoHQ (Q20)
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. Rougemont 
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:54:40
#      REVISION:  ---
#===============================================================================
set -o nounset                              # Treat unset variables as an error

#check that path to env exist
[[ -z $CONDA_PREFIX ]] && { echo "Error assembly_env path not found" ; exit 1 ; }

#------ External variable to be loaded from config file -----------#
if [ $# -lt 3  ]; then
    echo "USAGE: $0 : <genome> <reads> <assembler>"
    echo -e "Expecting at least 2 arguments : \n 
      \t 1: <genome>: a name for the genomq\n
      \t 2: <reads>: path to reads to buld db\n
      \t 3: <genome_size> : optional: name of the assembler\n"
    exit 1
else
    genome=$1       #genome/species/whatever id
    reads=$2        #path to HiFi/nano-hq or illumina WGS reads
    genome_size=$3  #genome size of the assembly (computed with awk)
fi

r1=$(readlink -f "$reads" )

#===============================================================================
#preliminary step: -- get K -- 
K=$( "$CONDA_PREFIX"/share/merqury/best_k.sh "$genome_size" \
	| tail -n 1 )

#--- create architecture ---- #
mkdir -p 08_meryl/ 2>/dev/null

#===============================================================================
if [ ! -s 08_meryl/results_"$genome".meryl/0x000000.merylData ] ;then 
	# -- build k-mer dbs --
	meryl k="$K" count $r1 output 08_meryl/results_"$genome".meryl
else
	echo "meryl k-mer count already done"
fi
