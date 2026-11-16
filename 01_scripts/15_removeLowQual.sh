#!/bin/bash - 
#===============================================================================
#          FILE: 15_removeLowQual.sh
#         USAGE: ./15_removeLowQual.sh genome.fasta 
# 
#   DESCRIPTION: 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: QUENTIN ROUGEMONT (CNRS)
#  ORGANIZATION: 
#       CREATED: 04/11/2026 15:00:11
#      REVISION:  ---
#===============================================================================
#set -o nounset                              # Treat unset variables as an error
#===============================================================================
source config
source cpu_mem
#===============================================================================

assembly=$1 #full path to the assembly  
name=$(basename $assembly)

if [ "$DORADO_CORRECT" = "YES" ] ; then 
    FOLDER="07_minimap"_"$assembler"_"corrected"
else
    FOLDER="07_minimap"_"$assembler"
fi
sequence="${FOLDER}"/"length_prop_read.0.above.0.9"
if [ ! -s "$sequence" ] ; then
        echo "no sequence to remove"
        echo "no sequences were removed from draft assembly" >> "$FOLDER"/removed_sequence.info
        exit
fi

if [ ! -d 13_cleaned_fasta ] ; 
then 
    mkdir 13_cleaned_fasta
fi

OUTFOLDER="13_cleaned_fasta"
#remove sequence marked as displaying low quality: 
awk '{ if ((NR>1)&&($0~/^>/)) { printf("\n%s", $0); } else if (NR==1) { printf("%s", $0); } else { printf("\t%s", $0); } }' "${assembly}" |\
    grep -w -v -Ff <(awk '{print $1}' "${sequence}" ) - |tr "\t" "\n" > "${OUTFOLDER}"/"${name}"
#===============================================================================
#redo quast: 
if [ ! -s "${OUTFOLDER}"/report.pdf ]
then
    quast.py --threads 4 --eukaryote -o "${OUTFOLDER}"  "${OUTFOLDER}"/"${name}"
else
    echo -e "\n-------------------------------"
    echo "quast already ok"
    echo -e "\n-------------------------------"
fi
#===============================================================================
#redo busco:
eval "$(conda shell.bash hook)"
conda activate busco6.1.0
# Make command for busco gene finder:
genefinder=$(echo "--""$buscotype" )
source config
source cpu_mem

#running busco:
for file in "${OUTFOLDER}"/BUSCO_*fasta/short*txt  
do
    if [ ! -s "${file}" ] 
    then
        busco -c "$NCPUS_BUSCO" \
            --out_path "${OUTFOLDER}"/ \
            -i "${OUTFOLDER}"/"${name}" \
            -l "${buscodatabase}" \
            -m genome -f \
            "$genefinder"
    else
        echo "busco already ok"
    fi
done 
