#!/bin/bash
#===============================================================================
#          FILE: flow_assembly.sh
#         USAGE: ./flow_assembly.sh opt1 ... optN
#   DESCRIPTION: assembling genome + quality check + etc
# 
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

#check if config file variables are properly set:
#if  [ -z "${datatype}" ]  || [ -z "${genomesize}" ] || 
 #   [ -z "${assembler}" ] || [ -z "${buscodatabase}" ]  ; then
 #   Help
 #   exit 2
#fi

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
	    echo "species is $SPECIES"
        p0=$(sbatch  "$SCRIPTPATH"01_extractHifi.sh "${BAM}"    |awk '{print $4}' )
        FASTQ=02_FilteredHifi/"${SPECIES}".fastq.gz
        p1=$(sbatch "$DEPENDS"$p0 "$SCRIPTPATH"/02_awk_fastq_length_GCcontent.sh "${FASTQ}" "${genomesize}"  | awk '{print $4}' )
    else 
       echo "species is $SPECIES"
       echo "submitting GC content and plot code"
       p1=$(sbatch "$SCRIPTPATH"/02_awk_fastq_length_GCcontent.sh ${FASTQ} "${genomesize}"  | awk '{print $4}' )
    fi
       p2=$(sbatch "$DEPENDS"$p1 "$SCRIPTPATH"/04_jellyfish ${FASTQ} 	   |awk '{print $4}' ) 
	   echo "submitting genome assemly code"	
       p3=$(sbatch "$DEPENDS"$p2 "$SCRIPTPATH"/05_hifi_assembler.sh "${FASTQ}" |awk '{print $4}' )
fi
if [[ "${datatype,,}" == "nano-hq" ]]; then
    if [[ "${assembler,,}" != "flye" ]] && [[ "${assembler,,}" != "canu" ]]; then
      echo "Invalid assembler type. Should be canu, flye "
      exit 1
    fi
    if [[ -z "${SPECIES}" ]] ; then SPECIES="sample0001" ; fi
    if [ -e "$pod5" ] ; then 
        echo -e "  "$SCRIPTPATH"/00_dorado.sh "$pod5" "$SPECIES" "$MODEL"   " 
        p0=$(sbatch  "$SCRIPTPATH"/00_dorado.sh "$pod5" "$SPECIES" "$MODEL"   |awk '{print $4}' )
        if [ "$DORADO_CORRECT" = "NO" ] ; then
            FASTQ=02_raw/"${SPECIES}".fastq.gz
        else
            FASTQ=02_raw/"${SPECIES}".corrected.fasta
        fi

        p1=$(sbatch "$DEPENDS"$p0 "$SCRIPTPATH"/02_awk_fastq_length_GCcontent.sh "${FASTQ}" "${genomesize}"  | awk '{print $4}' )
    else 
        p1=$(sbatch "$SCRIPTPATH"/02_awk_fastq_length_GCcontent.sh "${FASTQ}" "${genomesize}"  | awk '{print $4}' )
    fi
    p2=$(sbatch "$DEPENDS"$p1 "$SCRIPTPATH"/04_jellyfish ${FASTQ} 	   |awk '{print $4}' ) 
    p3=$(sbatch "$DEPENDS"$p2 "$SCRIPTPATH"/06_ONT_assembler.sh "${FASTQ}" |awk '{print $4}' )
fi
   if [[ "${assembler,,}" == "hifiasm" ]] && [ "$DORADO_CORRECT" = "NO" ]  ; then
       assembly=05_"${SPECIES}"_"${assembler}"/"${SPECIES}".bp.p_ctg.fasta
   elif  [[ "${assembler,,}" == "flye" ]]  && [ "$DORADO_CORRECT" = "NO" ] ; then
       assembly=05_"${SPECIES}"_"${assembler}"/assembly.fasta
   elif  [[ "${assembler,,}" == "canu" ]]  && [ "$DORADO_CORRECT" = "NO" ] ; then
       assembly=05_"${SPECIES}"_"${assembler}"/assembly.contigs.fasta
   elif [[ "${assembler,,}" == "hifiasm" ]] && [ "$DORADO_CORRECT" = "YES" ]  ; then
       assembly=05_"${SPECIES}"_"${assembler}"_corrected/"${SPECIES}".bp.p_ctg.fasta
   elif  [[ "${assembler,,}" == "flye" ]]  && [ "$DORADO_CORRECT" = "YES" ] ; then
       assembly=05_"${SPECIES}"_"${assembler}"_corrected/assembly.fasta
   elif  [[ "${assembler,,}" == "canu" ]]  && [ "$DORADO_CORRECT" = "YES" ] ; then
       assembly=05_"${SPECIES}"_"${assembler}"_corrected/assembly.contigs.fasta
    fi

#generic stuff -- Common to HiFi/ONT 
echo fastq are $FASTQ
echo assembly is $assembly

echo "submitting minimap and depth/mapq code"
p4=$(sbatch "$DEPENDS"$p3 "$SCRIPTPATH"/07_minimap.sh "${assembly}" "$FASTQ" |awk '{print $4}' )

#run merryl here
echo "submtting merryl" 
p5=$(sbatch "$DEPENDS"$p4 "$SCRIPTPATH"/11_merryl.sh  "$BASE" "$FASTQ" "$total_len" | awk '{print $4}' ) 
echo "submitting merqury"
p6=$(sbatch "$DEPENDS"$p5 "$SCRIPTPATH"/12_merqury.sh "$assembly" "$FASTQ"  "$assembler" |awk '{print $4}' )

if [ "${removeLowQualContigs}" = "YES" ] ; then
   echo "cleaning removing low quality scaffold" 
   echo " "
   p7=$(sbatch "$DEPENDS"$p6 "$SCRIPTPATH"/15_removeLowQual.sh "$assembly" |awk '{print $4}' )
   if [ -z "$taxid" ] && [ -z "$gxdb" ] ; then 
       p11=$(sbatch "$DEPENDS"$p7 "$SCRIPTPATH"/19_get_summary.sh  "${assembly}" "${taxid}" "${gxdbpath}" |awk '{print $4}' )
   else
       echo "running fcs-gx" 
       p8=$(sbatch "$DEPENDS"$p7 "$SCRIPTPATH"/16_fcsgx.contam.sh  "${assembly}" "${taxid}"  "${gxdbpath}" |awk '{print $4}' )
       p9=$(sbatch "$DEPENDS"$p8 "$SCRIPTPATH"/17_fcsgx.adapt.sh   "${assembly}" | awk '{print $4}' )
       p10=$(sbatch "$DEPENDS"$p9 "$SCRIPTPATH"/18_clean_genome.sh "${assembly}" "${taxid}" "${gxdbpath}" |awk '{print $4}' )
       p11=$(sbatch "$DEPENDS"$p10 "$SCRIPTPATH"/19_get_summary.sh "${assembly}" "${taxid}" "${gxdbpath}" |awk '{print $4}' )
   fi
else
   if [ -z "$taxid" ] && [ -z "$gxdb" ] ; then 
   #if [ -v '$taxid' ] || [ -v '$gxdbpath' ]
       p11=$(sbatch "$DEPENDS"$p6 "$SCRIPTPATH"/19_get_summary.sh "${assembly}" "${taxid}" "${gxdbpath}" |awk '{print $4}' )
   else
       echo "running fcs-gx" 
       p7=$(sbatch "$DEPENDS"$p6 "$SCRIPTPATH"/16_fcsgx.contam.sh "${assembly}" "${taxid}"  "$gxdbpath" |awk '{print $4}' )
       p8=$(sbatch "$DEPENDS"$p7 "$SCRIPTPATH"/17_fcsgx.adapt.sh  "${assembly}" | awk '{print $4}' )
       p9=$(sbatch "$DEPENDS"$p8 "$SCRIPTPATH"/18_clean_genome.sh "${assembly}" "${taxid}" "${gxdbpath}" |awk '{print $4}' )
       p11=$(sbatch "$DEPENDS"$p9 "$SCRIPTPATH"/19_get_summary.sh "${assembly}" "${taxid}" "${gxdbpath}" |awk '{print $4}' )
   fi
fi

exit     










#for HiFi only no short reads are available:
SMSBAM=07_minimap_"$assembler"/"$BASE".bam
./01_scripts/14_craq.sh "$assembly" "$SMSBAM" 

    ##TO DO: if ploidy == 2  run hapdup if assembler is flye 
    ##Run merqury on hap1/hap2 of hifiasm
    #run purge dup if necessary

