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

#eval "$(conda shell.bash hook)"
#mamba activate assembly_env

source config
# Global variables
SCRIPTPATH="./01_scripts/NOSLURM/"
 
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
         "$SCRIPTPATH"01_extractHifi.sh "${BAM}"     
        FASTQ=02_FilteredHifi/"${SPECIES}".fastq.gz
        "$SCRIPTPATH"/02_awk_fastq_length_GCcontent.sh "${FASTQ}" "${genomesize}"   
        if [[  "${PIPESTATUS[0]}" -ne 0 ]] ; then
            printf "GC and len computation error"
            exit   1
        fi
    else 
       echo "species is $SPECIES"
       echo "submitting GC content and plot code"
       "$SCRIPTPATH"/02_awk_fastq_length_GCcontent.sh ${FASTQ} "${genomesize}"   
        if [[  "${PIPESTATUS[0]}" -ne 0 ]] ; then
            printf "GC and len computation error"
            exit   1
        fi
    fi
       echo "submitting Jellyfish"
        "$SCRIPTPATH"/04_jellyfish ${FASTQ} 	     
        if [[  "${PIPESTATUS[0]}" -ne 0 ]] ; then
            printf "jellyfish/genome scope error"
            exit   1
        fi
	   echo "submitting genome assemly code"	
        "$SCRIPTPATH"/05_hifi_assembler.sh "${FASTQ}"  
fi
if [[ "${datatype,,}" == "nano-hq" ]]; then
    if [[ "${assembler,,}" != "flye" ]] && [[ "${assembler,,}" != "canu" ]]; then
      echo "Invalid assembler type. Should be canu, flye "
      exit 1
    fi
    if [[ -z "${SPECIES}" ]] ; then SPECIES="sample0001" ; fi
    if [ ! -z "$(ls -A "$pod5" )" ] ; then 
        echo -e "  "$SCRIPTPATH"/00_dorado.sh "$pod5" "$SPECIES" "$MODEL"   " 
        "$SCRIPTPATH"/00_dorado.sh "$pod5" "$SPECIES" "$MODEL"    
        if [[  "${PIPESTATUS[0]}" -ne 0 ]] ; then
            printf "dorado error check your data path and config file"
            exit   1
        fi

        if [ "$DORADO_CORRECT" = "NO" ] ; then
            FASTQ=02_raw/"${SPECIES}".fastq.gz
        else
            FASTQ=02_raw/"${SPECIES}".corrected.fasta
        fi

        "$SCRIPTPATH"/02_awk_fastq_length_GCcontent.sh "${FASTQ}" "${genomesize}"   
        if [[  "${PIPESTATUS[0]}" -ne 0 ]] ; then
            printf "GC and len computation error"
            exit   1
        fi

    else 
        "$SCRIPTPATH"/02_awk_fastq_length_GCcontent.sh "${FASTQ}" "${genomesize}"   
        if [[  "${PIPESTATUS[0]}" -ne 0 ]] ; then
            printf "GC and len computation error"
            exit   1
        fi

    fi
    "$SCRIPTPATH"/04_jellyfish ${FASTQ}
     if [[  "${PIPESTATUS[0]}" -ne 0 ]] ; then
        printf "jellyfish/genome scope error"
        exit   1
     fi

    "$SCRIPTPATH"/06_ONT_assembler.sh "${FASTQ}" 
fi
   if [[ "${assembler,,}" == "hifiasm" ]] && [ "$DORADO_CORRECT" = "NO" ]  ; then
       #if [[ "$keep_primary" = "YES"  ]] && [[ "$no_purge" = "YES" ]] ; then
	if [ "$no_purge" = "YES" ] && [ "$keep_primary" = "YES" ] ; then
       p="primary"
	   l="l0"
           assembly=05_"${SPECIES}"_"${assembler}"_"$l"_"$p"/"${SPECIES}".p_ctg.fasta
       elif [ "$keep_primary" = "YES"  ] && [ "$no_purge" = "NO" ] ; then
           p="primary"
           assembly=05_"${SPECIES}"_"${assembler}"_"$p"/"${SPECIES}".p_ctg.fasta
       elif [ "$keep_primary" = "NO"  ] && [ "$no_purge" = "YES" ] ; then
	   l="l0"
           assembly=05_"${SPECIES}"_"${assembler}"_"$l"/"${SPECIES}".bp.p_ctg.fasta
       elif [ "$keep_primary" = "NO"  ] && [ "$no_purge" = "NO" ] ; then
           assembly=05_"${SPECIES}"_"${assembler}"/"${SPECIES}".bp.p_ctg.fasta
       fi
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
echo -e "\n\n"
printf '~%.0s' {1..70}
echo fastq are $FASTQ
echo assembly is $assembly

echo "submitting minimap and depth/mapq code"
"$SCRIPTPATH"/07_minimap.sh "${assembly}" "$FASTQ"  
printf '~%.0s' {1..70}
#run merryl here
echo -e "\nsubmtting merryl" 
"$SCRIPTPATH"/11_merryl.sh "$SPECIES" "$FASTQ" "$total_len"  
echo -e "\nsubmitting merqury"
"$SCRIPTPATH"/12_merqury.sh "$assembly" "$FASTQ"  "$assembler"  

if [ "${removeLowQualContigs}" = "YES" ] ; then
   echo "cleaning removing low quality scaffold" 
   echo " "
    "$SCRIPTPATH"/15_removeLowQual.sh "$assembly"  
   if [ -z "$taxid" ] && [ -z "$gxdb" ] ; then 
       "$SCRIPTPATH"/19_get_summary.sh  "${assembly}" "${taxid}" "${gxdbpath}"  
   else
       echo "running fcs-gx" 
        "$SCRIPTPATH"/16_fcsgx.contam.sh  "${assembly}" "${taxid}"  "${gxdbpath}"  
        "$SCRIPTPATH"/17_fcsgx.adapt.sh   "${assembly}"  
        "$SCRIPTPATH"/18_clean_genome.sh "${assembly}" "${taxid}" "${gxdbpath}"  
        "$SCRIPTPATH"/19_get_summary.sh "${assembly}" "${taxid}" "${gxdbpath}"  
   fi
else
   if [ -z "$taxid" ] && [ -z "$gxdb" ] ; then 
   #if [ -v '$taxid' ] || [ -v '$gxdbpath' ]
        "$SCRIPTPATH"/19_get_summary.sh "${assembly}" "${taxid}" "${gxdbpath}"  
   else
       echo "running fcs-gx" 
        "$SCRIPTPATH"/16_fcsgx.contam.sh "${assembly}" "${taxid}"  "$gxdbpath"  
        "$SCRIPTPATH"/17_fcsgx.adapt.sh  "${assembly}"  
        "$SCRIPTPATH"/18_clean_genome.sh "${assembly}" "${taxid}" "${gxdbpath}"  
        "$SCRIPTPATH"/19_get_summary.sh "${assembly}" "${taxid}" "${gxdbpath}"  
   fi
fi

exit     










#for HiFi only no short reads are available:
SMSBAM=07_minimap_"$assembler"/"$BASE".bam
./01_scripts/14_craq.sh "$assembly" "$SMSBAM" 

    ##TO DO: if ploidy == 2  run hapdup if assembler is flye 
    ##Run merqury on hap1/hap2 of hifiasm
    #run purge dup if necessary

