#!/bin/bash                     
#===============================================================================
#          FILE: 08_medaka.sh
# 
#         USAGE: ./08_medaka.sh <genome> <OUTFOLDER> <READS> <busco database> <buscotype> <optional: NCPU>"
# 
#   DESCRIPTION: polishing nano-raw (ONT) with medaka 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. Rougemont 
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:58:16
#      REVISION:  Alexandra Jalaber Dupont de Dinechin + Q. Rougemont
#===============================================================================

#model (to be set manually for now):
#model="r941_min_high_g360" #set it according to your sequencing technology
model="dna_r10.4.1_e8.2_400bps_sup@v4.3.0"

# Global variables
# Check if the number of arguments is correct
if [ $# -lt 5  ]; then
    echo "USAGE: $0  : <genome> <READS> <OUTFOLDER> <busco database> <buscotype> <optional: NCPU>"
    echo -e "Expecting four arguments : \n 
      \t 1: <genome>: genome assembly with full path\n
      \t 2: <READS>: path to the READS for polishg\n
      \t 3: <OUTFOLDER> OUTFODLER name \n
      \t 4: <database>: For Busco\n
      \t 5: <buscotype>: type for busco : augustus metaeuk miniprot\n
      \n\t optionally: \n
      \t 5: <NCPU>: number of CPU"
    exit 1
else
    genome=$1
    READS=$2
    OUTFOLDER=$3
    database=$4
    buscotype=$5
    NCPU=$6
fi
#===============================================================================
# Test if user specified a number of CPUs, if not, default to 8
if [[ -z "$NCPU" ]]
then
    NCPU=12
fi

#===============================================================================
ulimit -Hn 10048
ulimit -Hs 10048

eval "$(conda shell.bash hook)"
conda activate medaka2.10

# Run medaka:
if [ ! -f "${OUTFOLDER}"/consensus.fasta ]; then
    medaka_consensus -i "${READS}" -d "${genome}" -o "${OUTFOLDER}" -t "${NCPU}" -m "${model}" 
else
    echo The file "${OUTFOLDER}"/consensus.fasta already exist
fi
samtools depth  "$OUTFOLDER"/calls_to_draft.bam |\
    pigz -p $NCPU > "$OUTFOLDER"/calls_to_draft.dp.gz
Rscript 01_scripts/Rscripts/plot_depth.R "$OUTFOLDER"/calls_to_draft.dp.gz

#===============================================================================
echo -e "\n-------------------------------"
echo -e "\trunning quast                  " 
echo -e "\n-------------------------------"
if [ ! -s "${OUTFOLDER}"/quast/report.pdf ]
then
    quast.py --threads 4 --eukaryote -o "${OUTFOLDER}"/quast/ "${OUTFOLDER}"/consensus.fasta 
else
    echo -e "\n-------------------------------"
    echo "quast already ok"
    echo -e "\n-------------------------------"
fi

#===============================================================================
compleasm.py download "${database}"
if [ ! -s "${OUTFOLDER}"/compleasm/summary.txt ]
then
    #run
    compleasm.py run -t$NCPU \
            -l "${database}" \
            -a "${OUTFOLDER}"/consensus.fasta \
            -o "${OUTFOLDER}"/compleasm
else
    echo -e "\n-------------------------------"
    echo "compleasm already ok "
    echo -e "\n-------------------------------"
fi
#===============================================================================
eval "$(conda shell.bash hook)"
conda activate busco6.0.0

# make command for busco gene finder:
genefinder=$(echo "--""$buscotype" )

#running busco:
for file in "${OUTFOLDER}"/BUSCO_consensus.fasta/short*txt  
do
    #run busco 
    if [ ! -s "${file}" ] 
    then
        busco -c "$NCPU" \
        --out_path "${OUTFOLDER}"/ \
        -i "${OUTFOLDER}"/consensus.fasta  \
        -l "$database" \
        -m genome \
        "$genefinder"
    else
	    echo "busco already ok"
    fi
done

