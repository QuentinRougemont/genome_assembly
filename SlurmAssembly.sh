#!/bin/bash
#===============================================================================
#          FILE: flow_assembly.sh
#         USAGE: ./flow_assembly.sh opt1 ... optN
#   DESCRIPTION: assembling genome + quality check + etc
#       OPTIONS: ---
#  REQUIREMENTS: Hifi only or nano-hq only or nano-raw + illumina
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. Rougemont 
#  ORGANIZATION: 
#       CREATED: 20/11/2026 11:54:40
#      REVISION:  ---
#===============================================================================
# This script is responsible for assembling genomic data and evaluate its quality
# All associated scripts are located in the folder: 01_scripts

source config
# Global variables
DEPENDS="--dependency=afterok:"
SCRIPTPATH="./01_scripts/SLURM/"
 
#set buscotype to miniprot by default:
if [ -z "$buscotype" ]
then
    buscotype="miniprot"
fi
# Verification of the data "type" 
if [[ "${datatype,,}" != "hifi" ]] && [[ "${datatype,,}" != "nano-hq" ]] && 
    [[ "${datatype,,}" != "nano-raw" ]]; then
  echo "Invalid read type. Should be nano-hq or nano-row or HIFI."
  exit 1
fi
if [[ "${datatype,,}" == "hifi" ]]; then
    if [[ "${assembler,,}" != "hifiasm" ]]  && 
        [[ "${assembler,,}" != "flye" ]] && [[ "${assembler,,}" != "canu" ]]; then
      echo "Invalid assembler type. Should be canu, flye or hifiasm."
      exit 1
    fi
    if [ -e "$BAM" ] ; then 
        p0=$(sbatch  "$SCRIPTPATH"01_extractHifi.sh "${BAM}"    |awk '{print $4}' )
        FASTQ=02_FilteredHifi/hifi.fastq.gz
        p1=$(sbatch "$DEPENDS"$p0 "$SCRIPTPATH"/02_awk_fastq_length_GCcontent.sh "${FASTQ}" "${genomesize}"  | awk '{print $4}' )
    else 
       p1=$(sbatch "$SCRIPTPATH"/02_awk_fastq_length_GCcontent.sh ${FASTQ} "${genomesize}"  | awk '{print $4}' )
    fi
    
    p2=$(sbatch "$DEPENDS"$p1 "$SCRIPTPATH"/04_jellyfish ${FASTQ}         |awk '{print $4}' )
    p3=$(sbatch "$DEPENDS"$p2 "$SCRIPTPATH"/05_hifi_assembler.sh "${FASTQ}" |awk '{print $4}' )

    if [[ "${assembler,,}" == "hifiasm" ]] ; then
        assembly=05_"${BASE}"_"${assembler}"/hifi.bp.p_ctg.fasta
    elif  [[ "${assembler,,}" == "flye" ]] ; then
        assembly=05_"${BASE}"_"${assembler}"/assembly.fasta
    elif  [[ "${assembler,,}" == "canu" ]] ; then
        assembly=05_"${BASE}"_"${assembler}"/assembly.contigs.fasta
    fi
fi
if [[ "${datatype,,}" == "nano-hq" ]]; then
    if [[ "${assembler,,}" != "flye" ]] && [[ "${assembler,,}" != "canu" ]]; then
      echo "Invalid assembler type. Should be canu, flye "
      exit 1
    fi
    if [[ -z "${SPECIES}" ]] ; then SPECIES="sample0001" ; fi
    if [ -e "$pod5" ] ; then 
        p0=$(sbatch  "$SCRIPTPATH"/00_dorado.sh "$INPUT" "$SPECIES" "$MODEL"   |awk '{print $4}' )
        FASTQ=02_raw/"${SPECIES}".fastq.gz
        p1=$(sbatch "$DEPENDS"$p0 "$SCRIPTPATH"/02_awk_fastq_length_GCcontent.sh "${FASTQ}" "${genomesize}"  | awk '{print $4}' )
    else 
       p1=$(sbatch "$SCRIPTPATH"/02_awk_fastq_length_GCcontent.sh "${FASTQ}" "${genomesize}"  | awk '{print $4}' )
    fi

    p2=$(sbatch "$DEPENDS"$p1 "$SCRIPTPATH"/04_jellyfish ${FASTQ}         |awk '{print $4}' )
    p3=$(sbatch "$DEPENDS"$p2 "$SCRIPTPATH"/06_ONT_assembler.sh "${FASTQ}" |awk '{print $4}' )
    if [[ "${assembler,,}" == "hifiasm" ]] ; then
        assembly=05_"${BASE}"_"${assembler}"/hifi.bp.p_ctg.fasta
    elif  [[ "${assembler,,}" == "flye" ]] ; then
        assembly=05_"${BASE}"_"${assembler}"/assembly.fasta
    elif  [[ "${assembler,,}" == "canu" ]] ; then
        assembly=05_"${BASE}"_"${assembler}"/assembly.contigs.fasta
    fi
fi

#generic stuff -- Common to HiFi/ONT 
p4=$(sbatch "$DEPENDS"$p3 "$SCRIPTPATH"/07_minimap.sh "${assembly}"  |awk '{print $4}' )

#run merryl here
p5=$(sbatch "$DEPENDS"$p4 "$SCRIPTPATH"/11_merryl.sh  "$BASE" "$FASTQ" "$total_len" | awk '{print $4}' ) 
p6=$(sbatch "$DEPENDS"$p5 "$SCRIPTPATH"/12_merqury.sh "$BASE" "$assembly" "$assembler" )
exit     

#then copy data to final folder and make a synthetic table

# TO IMPLEMENT:
##for HiFi only no short reads are available:
#SMSBAM=07_minimap_"$assembler"/"$BASE".bam
#./01_scripts/14_craq.sh "$assembly" "$SMSBAM" 
#
###TO DO: if ploidy == 2  run hapdup if assembler is flye 
###Run merqury on hap1/hap2 of hifiasm
##run purge dup if necessary
##finaly run fcs.gx for contamination and adaptors:
#if [ -v '$taxid' ] && [ -v '$gxdbpath' ]
#then
#        ./01_scripts/15_fcsgx.contam.sh "${assembly}" "${taxid}"  "$gxdbpath"
#        ./01_scripts/16_fcsgx.adapt.sh "${assembly}"
#        ./01_scripts/17_clean_genome.sh "${assembly}" "${taxid}" "${gxdbpath}"
#fi
#
