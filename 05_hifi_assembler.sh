#!/bin/bash
#===============================================================================
#          FILE: 05_hifi_assembler.sh
#         USAGE: ./05_hifi_assembler.sh <FASTQ> <assembler> <database> <buscotype> <genomesize> 
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
    echo "USAGE: $0 : <genome> <assembler> <database> <buscotype> <genomesize>"
    echo -e "Expecting four arguments : \n 
      \t 1: <genome>: genome/folder_name with the fastq\n
      \t 2: <assembler>: type assembler : canu ou hifi\n
      \t 3: <database>: For Busco\n
      \t 4: <buscotype>: type for busco : augustus metaeuk miniprot\n
      \t 5: <genomesize> : in m
      \n\t optionally: \n"
    exit 1
else
    FASTQ=$1
    assembler=$2
    database=$3
    buscotype=$4
    genomesize=$5
fi

source cpu_mem
source config
#===============================================================================
BASE=$(basename "${FASTQ%%.*}" ) 
#extension="${genome##*.}"
OUTFOLDER=05_"${SPECIES}"_"${assembler}" 
if [ "$no_purge" = "YES" ] ;
then 
    echo "here"
    l='l0' ; 
    OUTFOLDER=05_"${SPECIES}"_"${assembler}"_"$l" 
fi
if [ "$keep_primary" = "YES" ] ; 
then 
    echo "here2"
    p='primary' 
    OUTFOLDER="$OUTFOLDER"_"$p" 
fi

echo -e "OUTFOLDER is $OUTFOLDER"

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
mkdir LOG 2>/dev/null

if [[ "${assembler,,}" == "hifiasm" ]]
then
    if [ ! -s "${OUTFOLDER}"/"${SPECIES}".p_ctg.fasta ] 
    then
        echo "zoulou"
        #running hifiasm
	if [ "$no_purge" = "YES" ] && [ "$keep_primary" = "YES" ] ; then
           hifiasm -o "${OUTFOLDER}"/"${SPECIES}" \
              -t "$NCPUS_HIFIASM" -l0 --primary \
              "${FASTQ}" 2>&1 \
           | tee LOG/log."${SPECIES}"_"${assembler}"
           # "$s" "$O" "$D" "$N" "$P" "$h" "$l" \
    	elif [ "$no_purge" = "NO" ] && [ "$keep_primary" = "YES" ] ; then
           hifiasm -o "${OUTFOLDER}"/"${SPECIES}" \
              -t "$NCPUS_HIFIASM" --primary \
              "${FASTQ}" 2>&1 \
           | tee LOG/log."${SPECIES}"_"${assembler}"
	fi
        #extract fasta:
        awk '/^S/{print ">"$2;print $3}' "${OUTFOLDER}"/"${SPECIES}".p_ctg.gfa \
              > "${OUTFOLDER}"/"${SPECIES}".p_ctg.fasta
    	assembly="${OUTFOLDER}"/"${SPECIES}".p_ctg.fasta 
    elif [ ! -s "${OUTFOLDER}"/"${SPECIES}".bp.p_ctg.fasta ] 
    then
	if [ "$no_purge" = "YES" ] && [ "$keep_primary" = "NO" ] ; then
           hifiasm -o "${OUTFOLDER}"/"${SPECIES}" \
              -t "$NCPUS_HIFIASM" -l0 \
              "${FASTQ}" 2>&1 \
            | tee LOG/log."${SPECIES}"_"${assembler}"
          awk '/^S/{print ">"$2;print $3}' "${OUTFOLDER}"/"${SPECIES}".bp.p_ctg.gfa \
               > "${OUTFOLDER}"/"${SPECIES}".bp.p_ctg.fasta
    	  assembly="${OUTFOLDER}"/"${SPECIES}".bp.p_ctg.fasta 

	elif [ "$no_purge" = "NO" ] && [ "$keep_primary" = "NO" ] ; then
           hifiasm -o "${OUTFOLDER}"/"${SPECIES}" \
              -t "$NCPUS_HIFIASM" \
              "${FASTQ}" 2>&1 \
            | tee LOG/log."${SPECIES}"_"${assembler}"
          awk '/^S/{print ">"$2;print $3}' "${OUTFOLDER}"/"${SPECIES}".bp.p_ctg.gfa \
               > "${OUTFOLDER}"/"${SPECIES}".bp.p_ctg.fasta
    	  assembly="${OUTFOLDER}"/"${SPECIES}".bp.p_ctg.fasta 
        else
            echo "hifiasm output already present"
            assembly="${OUTFOLDER}"/"${SPECIES}".p_ctg.fasta 
	fi
    fi 
elif [[ "${assembler,,}" == "canu" ]]; then
    size=$(echo $(( $genomesize / 1000000 |bc -l )) )
    if [ ! -s "${OUTFOLDER}"/"${BASE}".contigs.fasta ] 
    then
        #run canu 
        canu -p "assembly" \
            -d "${OUTFOLDER}" \
            genomeSize="$size"m \
            -pacbio-hifi \
            "${FASTQ}" 
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
       flye --pacbio-hifi "${FASTQ}" \
            -o "${OUTFOLDER}" \
            -t "$NCPUS_FLYE"
    else
        echo "flye output already present"
    fi

    #declare assembly for later:
    assembly="${OUTFOLDER}"/assembly.fasta 

else 
    echo "Invalid assembler Should be canu/flye/hifiasm."
    exit 1
fi
#run awk to get length 
awk '/^>/ {if (seqlen){print seqlen}
     printf(">%s\t",substr($0,2)) ;seqlen=0;next;} 
    { seqlen += length($0)}END{print seqlen}' "$assembly"  > assembly_length.txt  
    

#===============================================================================
#run quast directly here:
OUTFOLDER="${OUTFOLDER}"/quast
echo -e "\n-------------------------------"
echo -e "\trunning quast                  " 
echo -e "\n-------------------------------"
if [ ! -s "${OUTFOLDER}"/report.pdf ]
then
    quast.py --threads 4 --eukaryote -o "${OUTFOLDER}" "$assembly" 
else
    echo -e "\n-------------------------------"
    echo "quast already ok"
    echo -e "\n-------------------------------"
fi
   
#===============================================================================
#
#compleasm.py download "${database}"
#
#if [ ! -s "${OUTFOLDER}"/compleasm/summary.txt ]
#then
#    #run
#    compleasm.py run -t "$NCPUS_COMPLEASM" \
#            -l "${database}" \
#            -a "${assembly}" \
#            -o "${OUTFOLDER}"/compleasm
#else
#    echo -e "\n-------------------------------"
#    echo "compleasm already ok "
#    echo -e "\n-------------------------------"
#fi

#===============================================================================
eval "$(conda shell.bash hook)"
conda activate busco6.1.0
# Make command for busco gene finder:
genefinder=$(echo "--""$buscotype" )

#running busco:
for file in "${OUTFOLDER}"/BUSCO_*fasta/short*txt  
do
    if [ ! -s "${file}" ] 
    then
        busco -c "$NCPUS_BUSCO" \
            --out_path "${OUTFOLDER}"/ \
            -i "${assembly}" \
            -l "${database}" \
            -m genome -f\
            "$genefinder"
    else
        echo "busco already ok"
    fi
done 
#===============================================================================

