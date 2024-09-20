#!/bin/bash
#===============================================================================
#          FILE: 05_hifi_assembler.sh
#         USAGE: ./05_hifi_assembler.sh <genome> <assembler> <database> <buscotype> <genomesize> <NCPU>
#   DESCRIPTION:  microscript to extract hifi data from bam
# 
#       OPTIONS: ---
#  REQUIREMENTS: bam file must be located in 01_raw  
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. Rougemont 
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:54:40
#      REVISION:  Update 03/2024 by Alexandra Jalaber Dupont de Dinechin 
#===============================================================================
# Global variables
if [ $# -ne 5 ]; then
    echo "USAGE: $0 : <genome> <assembler> <database> <buscotype> <genomesize> (optional: <NCPU>)"
    echo -e "Expecting four arguments : \n 
      \t 1: <genome>: genome/folder_name with the fastq\n
      \t 2: <assembler>: type assembler : canu ou hifi\n
      \t 3: <database>: For Busco\n
      \t 4: <buscotype>: type for busco : augustus metaeuk miniprot\n
      \t 5: <genomesize> : in m
      \n\t optionally: \n
      \t 6: <NCPU> : optional: number of cpu to use \n"
    exit 1
else
    genome=$1
    assembler=$2
    database=$3
    buscotype=$4
    genomesize=$5
    NCPU=$6
fi

#===============================================================================
BASE=$(basename "${genome%%.*}" ) 
#extension="${genome##*.}"

# Test if user specified a number of CPUs, if not, default to 8
if [[ -z "$NCPU" ]]
then
    NCPU=40
fi

OUTFOLDER=05_"${BASE}"_"${assembler}" 
if [ ! -d "${OUTFOLDER}" ]; 
then
    mkdir "${OUTFOLDER}" 2>/dev/null 
else
    echo The folder "${OUTFOLDER}" is already created
fi 

#===============================================================================

#  --- HiFiasm option ----
# uncomment to use one of them
# default option are run alternatively
#s="-s 0.1"  #s value 
#O="-O 1"  #o value
#D="-D 10" 
#N="-N 120"
#P="--purge-max 100"
#h="--hom-cov 1"
#l="l--l0" # can be used for low het genome 


if [[ "${assembler,,}" == "hifiasm" ]]
then
    if [ ! -s "${OUTFOLDER}"/"${BASE}".bp.p_ctg.fasta ] 
    then
        #running hifiasm
        hifiasm -o "${OUTFOLDER}"/"${BASE}" \
            -t $NCPU \
            "${genome}" 2>&1 \
            | tee LOG/log."${BASE}"_"${assembler}"
           # "$s" "$O" "$D" "$N" "$P" "$h" "$l" \
    
        #extract fasta:
        awk '/^S/{print ">"$2;print $3}' "${OUTFOLDER}"/"${BASE}".bp.p_ctg.gfa \
            > "${OUTFOLDER}"/"${BASE}".bp.p_ctg.fasta
    else
       echo "hifiasm output already present"
    fi 

    #declare assembly for later:
    assembly="${OUTFOLDER}"/"${BASE}".bp.p_ctg.fasta 

elif [[ "${assembler,,}" == "canu" ]]; then
    if [ ! -s "${OUTFOLDER}"/"${BASE}".contigs.fasta ] 
    then
        #run canu 
        canu -p "assembly" \
            -d "${OUTFOLDER}" \
            genomeSize="$genomesize"m \
            -pacbio-hifi \
            "${genome}" 
    else
       echo "canu output already present"
    fi 

    #declare assembly for later:
    assembly="${OUTFOLDER}"/"${BASE}".contigs.fasta 
 
elif [[ "${assembler,,}" == "flye" ]]
then
    if [ ! -s "${OUTFOLDER}"/assembly.fasta ] 
    then
       #running flye
       flye --pacbio-hifi "${genome}" \
            --genome-size "$genomesize"m \
            -o "${OUTFOLDER}" \
            -t $NCPU
    else
        echo "flye output already present"
    fi

    #declare assembly for later:
    assembly="${OUTFOLDER}"/assembly.fasta 

else 
    echo "Invalid assembler Should be canu/flye/hifiasm."
    exit 1
fi

#===============================================================================
#run quast directly here:
OUTFOLDER="${OUTFOLDER}"/quast
echo -e "\n-------------------------------"
echo -e "\trunning quast                  " 
echo -e "\n-------------------------------"
if [ ! -s "${OUTFOLDER}"/quast/quast/report.pdf ]
then
    quast.py --threads 4 --eukaryote -o "${OUTFOLDER}" "$assembly" 
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
# Make command for busco gene finder:
genefinder=$(echo "--""$buscotype" )

#running busco:
for file in "${OUTFOLDER}"/BUSCO_*fasta/short*txt  
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
#===============================================================================

