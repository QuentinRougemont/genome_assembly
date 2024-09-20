#!/bin/bash
#===============================================================================
#          FILE: 06_ONT_assembler.sh
# 
#         USAGE: ./06_ONT_assembler.sh <genome> <genomesize> <nanotype> <assembler> <database> <buscotype> <NCPU>
# 
#   DESCRIPTION: script to run flye/canu/shasta for ONT data + run busco
# 
#       OPTIONS: 
#  REQUIREMENTS: fastq.gz input
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. Rougemont + Alexandra Jalaber Dupont de Dinechin
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:54:40
#      REVISION:  ---
#===============================================================================
# Check if the number of arguments is correct
if [ $# -lt 6  ]; then
    echo "USAGE: $0 : <genome> <genomesize> <nanotype> <assembler> <database> <buscotype>"
    echo -e "Expecting five arguments : \n 
      \t 1: <genome>: genome/folder_name with the fastq\n
      \t 2: <genomesize> : estimated genome size \n
      \t 3: <nanotype>  : ONT technology: nano-hq or nano-raw
      \t 4: <assembler>: type assembler : canu flye shasta raven\n
      \t 5: <database>: For Busco\n
      \t 6: <buscotype>: gene predictor for Busco : augustus metaeuk miniprot"
    exit 1
else
    INFOLDER=$1
    OUTFOLDER=$2
    genomesize=$3
    nanotype=$4
    assembler=$5
    database=$6
    buscotype=$7
    NCPU=$8
fi
#===============================================================================
INFOLDER=02_trimmed_ONT
# Test if user specified a number of CPUs, if not, default to 8
if [[ -z "$NCPU" ]]
then
    NCPU=8
fi

#BASE=$(basename "${genome%%.*}" )
#extension="${genome##*.}"

# Test if user specified a number of CPUs, if not, default to 8
if [[ -z "$NCPU" ]]
then
    NCPU=40
fi

if [[ -f "$INFOLDER/*fq.gz" ]] ; then
    trim="--trimmed"
    echo "data are trimmed"
fi

#===============================================================================

# Run different assemblers based on the provided assembler argument
if [[ "${assembler,,}" == "flye" ]]; then
    if [ ! -s "${OUTFOLDER}"/assembly.fasta ]; then
        # Run flye with the full path to input files
        if [[ "${nanotype}" == "nano-raw" ]] ; then
            echo "run flye on nano-raw: "
            flye --nano-raw "$INFOLDER"/*.fastq.gz \
                 --genome-size "$genomesize"m \
                 -o "${OUTFOLDER}" \
                 -t $NCPU
        elif [[ "${nanotype}" == 'nano-hq' ]] ; then
            echo "assuming nano-hq"
            flye --nano-hq  "$INFOLDER"/*.fastq.gz \
                --genome-size "$genomesize"m \
                -o "${OUTFOLDER}" \
                -t $NCPU
        else
            echo 
            "error unknown sequencing type"
            exit
        fi

    else
        echo The file "${OUTFOLDER}"/assembly.fasta already exist
    fi 

    #declare assembly for later:
    assembly="${OUTFOLDER}"/assembly.fasta

elif [[ "${assembler,,}" == "canu" ]];then
    for fasta in "${OUTFOLDER}"/assembly.contigs.fasta
    do
        if [ ! -e "$fasta"  ]; then
            # Run Canu with the genome size
            canu -p assembly \
                -d "${OUTFOLDER}" \
                genomeSize="${genomesize}"m \
                minReadLength=1200 \
               -nanopore "$INFOLDER"/*.fastq.gz
                #${trim} 
        else
            echo The file "${OUTFOLDER}"/assembly.*.fasta already exist
        fi 
    done

    assembly="${OUTFOLDER}"/assembly.contigs.fasta

elif [[ "${assembler,,}" == "shasta" ]];then
    
    if [ ! -f "${OUTFOLDER}"/Assembly.fasta  ]; then
        # Run Shasta with the config Nanopore-May2022
        shasta --input TMP/input.fq.gz \
            --assemblyDirectory \
            "${OUTFOLDER}" \
            --config Nanopore-May2022 \
            --thread $NCPU

    else
        echo -e "The file $OUTFOLDER/Assembly.fasta already exist"
    fi 

    assembly="${OUTFOLDER}"/Assembly.fasta

elif [[ "${assembler,,}" == "raven" ]];then
    if [ ! -f "${OUTFOLDER}"/assembly.fasta  ]; then
        raven -t $NCPU \
            $INFOLDER > "$OUTFOLDER"/assembly.fasta
     
        # Run BUSCO with different options based on the provided busco type argument
        busco -c $NCPU --out_path "${OUTFOLDER}"/ \
                -i "${OUTFOLDER}"/Assembly.fasta  \
                -l "$database" \
                -m genome \
                "$genefinder"
    else
        echo The file "${OUTFOLDER}"/assembly.fasta already exist
    fi
    assembly="${OUTFOLDER}"/assembly.fasta
fi

#===============================================================================
echo -e "\n-------------------------------"
echo -e "\trunning quast                  " 
echo -e "\n-------------------------------"
if [ ! -s "${OUTFOLDER}"/quast/quast/report.pdf ]
then
    quast.py --threads 4 --eukaryote -o "${OUTFOLDER}"/quast "$assembly" 
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
            -a "${assembly}" \
            -o "${OUTFOLDER}"/compleasm
else
    echo -e "\n-------------------------------"
    echo "compleasm already ok "
    echo -e "\n-------------------------------"
fi

#===============================================================================


#===============================================================================
# Run BUSCO with different options based on the provided busco type argument
echo -e "\n-------------\nrunning busco\n-------------\n"
#make command for busco gene finder:
genefinder=$(echo "--""$buscotype" )

#running busco:
for file in "${OUTFOLDER}"/BUSCO_*/short*txt  
do
    if [ ! -s "${file}" ] 
    then
        busco -c $NCPU \
            --out_path "${OUTFOLDER}"/ \
            -i "${assembly}" \
            -l "${database}" \
            -m genome \
            "$genefinder"
    else
        echo "busco already ok"
    fi
done 

#runbusco=$(echo "busco -c $NCPU --out_path 05_${BASE}_${assembler}/ \
#    -i "$assembly" -l "$database" -m genome  "$genefinder" " )

#$run_busco
