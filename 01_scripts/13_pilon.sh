#!/bin/bash
#===============================================================================
#          FILE: 13_pilon.sh
# 
#         USAGE: ./13_pilon.sh <INPUTGENOME> <BAMFOLDER> <OUTFOLDER> <database> <buscotype>
# 
#   DESCRIPTION: compute QV/k-mer completeness draw k-mer multiplicity graph
# 
#       OPTIONS: ---
#  REQUIREMENTS: fasta assembly and mery database
#          BUGS: does not work with trios
#         NOTES: ---
#        AUTHOR: Q. Rougemont + A. Jalaber 
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:54:40
#      REVISION:  ---
#===============================================================================
set -o nounset                              # Treat unset variables as an error
# Check if the number of arguments is correct
if [ $# -ne 5  ]; then
    echo "USAGE: $0 ONT : <INPUTGENOME> <BAMFOLDER> <OUTFOLDER> <database>  <buscotype>"
    echo -e "Expecting four arguments : \n 
      \t 1: <INPUTGENOME> : genome assembly from medaka\n
      \t 2: <BAMFOLDER>  : FOLDER containing bam file \n
      \t 3: <OUTFOLDER>: FOLDER for the results\n
      \t 4: <database>: For Busco\n
      \t 5: <buscotype>: type for busco : augustus metaeuk miniprot"
else
    INPUTGENOME=$1
    BAMFOLDER=$2
    OUTFOLDER=$3
    database=$4
    buscotype=$5
fi
#===============================================================================
if [ ! -e "$OUTFOLDER" ]; then
    # Create a directory for Pilon output
    mkdir -p "$OUTFOLDER"
else
    echo "The folder $OUTFOLDER is already created"
fi
#===============================================================================
if [ ! -s "$OUTFOLDER/pilon.fasta" ]; then
    # Run Pilon to improve the genome assembly
    bam=$(find "$BAMFOLDER"/*sorted.bam) 
    frag=$(while IFS= read -r LINE ; do echo -e " --frags "$LINE"" ; done <<< "$bam" |perl -pe 's/\n/\t/g' )
    #echo $frag
    runpilon=$(echo -e "pilon -Xms100g -Xmx210g \
	    --genome "$INPUTGENOME" \
	    "$frag" \
	    --outdir "$OUTFOLDER"   \
	    --changes  \
	    --tracks   \
	    --diploid  \
	    --fix all  \
	    --mindepth 8" )
    if ! $runpilon ; 
    then
	    echo -e "\n---------\n error with pilon \n--------"
	    exit 1
    fi
else
    echo "The file $OUTFOLDER/pilon.fasta already exist"
fi
#===============================================================================
echo -e "\n-------------------------------"
echo -e "\trunning quast                  " 
echo -e "\n-------------------------------"
if [ ! -s "${OUTFOLDER}"/report.pdf ]
then
    quast.py --threads 4 --eukaryote -o "${OUTFOLDER}" "$OUTFOLDER"/pilon.fasta 
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
            -a "${OUTFOLDER}"/pilon.fasta  \
            -o "${OUTFOLDER}"/compleasm
else
    echo -e "\n-------------------------------"
    echo "compleasm already ok "
    echo -e "\n-------------------------------"
fi

#===============================================================================
# make command for busco gene finder:
genefinder=$(echo "--""$buscotype" )

NCPU=12
# Running BUSCO on the polished genome assembly
for file in "${OUTFOLDER}"/BUSCO_pilon.fasta/short*txt  
do
    if [ ! -s "${file}" ] 
    then
        busco -c "$NCPU" \
            --out_path "${OUTFOLDER}"/ \
            -i "${OUTFOLDER}"/pilon.fasta  \
            -l "$database" \
            -m genome \
            "$genefinder"
    else 
        echo "busco already run on pilon assembly"
    fi
done
