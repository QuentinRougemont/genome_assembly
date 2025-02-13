#!/bin/bash

#TO DO: 
#for all script: declare OUTPUT as external variable to each script, so we can recover them here
#so no script contain hardcoded path to folder/output
#TO DO FOR compleasm/busco: if failed: process the rest anyway!

#===============================================================================
#          FILE: flow_assembly.sh
#         USAGE: ./flow_assembly.sh opt1 ... optN
#   DESCRIPTION: assembling genome + quality check + etc
# 
#       OPTIONS: ---
#  REQUIREMENTS: Hifi only or nano-hq only or nano-raw + illumina
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. Rougemont +   Alexandra Jalaber Dupont de Dinechin
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:54:40
#      REVISION:  ---
#===============================================================================
# This script is responsible for assembling genomic data and evaluate its quality
# All associated scripts are located in the folder: 01_scripts

# ./FlowAssembly.sh -g <genome> -t <type> -s <genomesize(mbp)> -a <assembler> -d <busco_database> -T <trimm_ONT_(YES/NO)> #optional: -b <Busco_type> -N <NCPU>
# Exemple ONT  : ./FlowAssembly.sh   -g pod5folder/ -p myspecies -t nano-hq -s 30 -a flye -d basidiomycota_odb10 -T YES -b metaeuk -N 20 -m "model"
# Exemple HiFi : ./FlowAssembly.sh -g hifi.bam     -t hifi        -s 30 -a hifiasm -d basidiomycota_odb10 -T NO -b miniprot -N 10
# Exemple ONT :  ./FlowAssembly.sh -g ont.fq.gz    -t nano-raw    -s 30 -a flye    -d basidiomycota_odb10 -T YES -b miniprot -N 10 -i path/to/illumina_folder/

eval "$(conda shell.bash hook)"
conda activate assembly_env

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo -e "master script to: \n
        1 - check fastq \n
        2 - run jellyfish and plot (HiFi/nano-hq only), \n
        3 - perform genome assembly, \n
        4 - estimate genome quality (busco/compleasm, QV/completness, k-mer multiplicity, quast, CRAQ)\n
        5 - map back the reads "
   echo " "
   echo "Usage: $0 [-g|-t|-a|-d|-b|-T|-N|-h|]"
   echo "options:"
   echo " -h|--help: Print this Help."
   echo " -g|--genome: <fastq/bam/pod5> file name (full path) "
   echo " -t|--type: <data type>:  nano-hq/nano-raw/hifi "
   echo " -s|--genomesize : <genome size>: size of the genome in mbp" 
   echo " -a|--assembler: <assembler>: Assembler type : canu flye (shasta raven) => ONT or canu hifiasm => HIFI"
   echo " -d|--datatype: <database>: For Busco (can be obtained through busco --list-dataset)"
   echo " -b|--buscotype: <buscotype>: Type for Busco : augustus meteuk miniprot"
   echo "ONT specific OPTION:"
   echo " -T|--trimm: <trimm>: YES/NO for trimming raw ONT reads with chopper"
   echo " -i|--illumina: <illumina_path> : path to folder containing illumina file for polishing raw-ont data"
   echo "ONT HQ (nano-hq) specific option" :
   echo " -p|--species <species id> to be used after basecalling"
   echo " -m|--model <model> for Dorado basecalling" 
   echo "other optional variable:"
   echo " -N|--NCPU <NCPU> : number of CPU to be used "
   echo " "
}

############################################################
# Process the input options.                               #
############################################################
while [ $# -gt 0 ] ; do
  case $1 in
    -g  | --genome) genome="$2" ; 
        echo -e "full path to input reads is ***${genome}*** \n" >&2;;
    -t  | --type) type="$2" ; 
        echo -e "data is of type ***${type}*** \n" >&2;;
    -s  | --genomesize) genomesize="$2" ; 
        echo -e "genome size is ***${genomesize}*** \n" >&2;;
    -a  | --assembler) assembler="$2" ; 
        echo -e "the assembler to be used will be ***${assembler}*** \n" >&2;;
    -d  | --database) database="$2" ; 
        echo -e "lineage databse for busco is ***${database}*** \n" >&2;;
    -b  | --buscotype  ) buscotype="$2"   ; 
        echo -e "genome finder for busco will be ***${buscotype}*** \n" >&2;;
        #optional for ONT: 
    -i  | --illumina  ) illumina="$2"   ; 
        echo -e "illumina data for polishing will be ***${illumina}*** \n" >&2;;
    -T  | --Trimm ) trimm="$2" ; 
        echo -e "ONT data will be trim? ***${trimm}*** \n" >&2 ;;
        #optional for ONT (nano-hq):
    -p  | --species ) species="$2"  ;
        echo -e "species name for ont assembly will be ***${species}*** \n" >&2;;
    -m  | --model ) model="$2" ;
        echo -e "model for dorado basecalling will be ***${model}*** \n" >&2;;
        #optional for all : 
    -N  | --ncpu )  NCPU="$2"   ; 
        echo -e "number of CPU set to: ***${NCPU}*** \n" >&2 ;; 
    -h  | --help ) Help ; exit 2 ;;
   esac
   shift
done 

if [ -z "${genome}" ] || [ -z "${type}" ] || [ -z "${genomesize}" ] || 
    [ -z "${assembler}" ] || [ -z "${database}" ]  ; then
    Help
    exit 2
fi

#BASE=$(basename "${genome%%.*}" ) 
#BASE=$(basename "${genome%%.f*q*}" )
BASE=$(basename "${genome%%.*}" )
extension="${genome##*.}"

echo BASE name is "$BASE"

#set buscotype to miniprot by default:
if [ -z "$buscotype" ]
then
    buscotype="miniprot"
fi


# Verification of the data "type" 
if [[ "${type,,}" != "hifi" ]] && [[ "${type,,}" != "nano-hq" ]] && 
    [[ "${type,,}" != "nano-raw" ]]; then
  echo "Invalid read type. Should be nano-hq or nano-row or HIFI."
  exit 1
fi

if [[ "${type,,}" == "hifi" ]]; then
echo "Run scripts for Hifi type"
    if [[ "${assembler,,}" != "hifiasm" ]]  && 
        [[ "${assembler,,}" != "flye" ]] && [[ "${assembler,,}" != "canu" ]]; then
      echo "Invalid assembler type. Should be canu, flye or hifiasm."
      exit 1
    fi
    
    echo "Processing HIFI type"
    if [ "$extension" == "bam" ] ; then 
        chmod +x ./01_scripts/01_extractHifi.sh 
        if ! ./01_scripts/01_extractHifi.sh "${genome}" ; then 
        echo "HiFi Extraction failed" 
        exit 1
        else
            echo "Excract Hifi done"
            genome=02_FilteredHifi/"${BASE}".fastq.gz
        fi
    fi

    echo -e "\nplotting length of read and gc content\n" 
    chmod +x ./01_scripts/02_awk_fastq_length_GCcontent.sh
    ./01_scripts/02_awk_fastq_length_GCcontent.sh "${genome}"
    

    echo "running jellyfish and GenomeScope" 
    echo "assuming kmer_length of 21"
    kmer_length=21
    echo -e "genome is $genome" 
    chmod +x ./01_scripts/04_jellyfish
    if ! ./01_scripts/04_jellyfish "${genome}" "${kmer_length}" ; then
        echo "error Jellyfish failed"
        exit 1
    else 
        echo -e "jellfyish successfully run\n"
    fi
    
    if [[ "${assembler,,}" == "hifiasm" ]] ; then
        chmod +x ./01_scripts/05_hifi_assembler.sh 
        NCPU=20

        echo -e "\n--------------------\nrunnig hifiasm\n--------------\n"
        if ! ./01_scripts/05_hifi_assembler.sh \
            "${genome}" \
            "${assembler}" \
            "${database}" \
            "${buscotype}" \
            "$NCPU"
        then
            echo "error hifiasm failed"
            exit 1
        else
                echo "Hifiasm done"
        fi

        #declare assembly:
        assembly=05_"${BASE}"_"${assembler}"/"${BASE}".bp.p_ctg.fasta

   elif  [[ "${assembler,,}" == "flye" ]] ; then
        echo -e "\n--------------------\nrunnig flye \n----------------\n"
        chmod +x ./01_scripts/05_hifi_assembler.sh
        if ! ./01_scripts/05_hifi_assembler.sh \
            "${genome}" \
            "${assembler}" \
            "${database}" \
            "${buscotype}" \
            "${genomesize}"
        then
            echo "error flye failed"
            exit 1
        else
            echo "flye done"
        fi

        #declare assembly:
        assembly=05_"${BASE}"_"${assembler}"/assembly.fasta

    elif  [[ "${assembler,,}" == "canu" ]] ; then
        echo -e "\n--------------------\nrunnig canu\n -----------------\n"
        chmod +x ./01_scripts/05_hifi_assembler.sh
        if ! ./01_scripts/05_hifi_assembler.sh \
            "${genome}" \
            "${assembler}" \
            "${database}" \
            "${buscotype}" \
            "${genomesize}"
        then
            echo "error canu failed"
            exit 1
        else
            echo "canu done"
        fi

        #declare assembly:
        assembly=05_"${BASE}"_"${assembler}"/assembly.contigs.fasta

    fi

    #run minimap2 here
    echo -e "\n-------------------------------"
    echo -e "\tmapping long reads to assembly" 
    echo -e "\n-------------------------------"
    READS="$genome"
    OUTFOLDER=07_minimap_"$assembler"
    NCPU=10
    SPECIES="" #will be ignore
    chmod +x ./01_scripts/07_minimap.sh
    if ! ./01_scripts/07_minimap.sh "${assembly}" "${READS}" "${type}" "${OUTFOLDER}" "${SPECIES}" "${NCPU}"
    then
        echo "error minimap and samtools failed"
        echo "check your data"
        exit 1
    else
        echo -e "\n-------------------------------"
        echo -e "\tminimap and samtools dp done   " 
        echo -e "\n-------------------------------"
    fi


    #run awk to get length 
    awk '/^>/ {if (seqlen){print seqlen}
      printf(">%s\t",substr($0,2)) ;seqlen=0;next;} 
      { seqlen += length($0)}END{print seqlen}' "$assembly"  > "$BASE"_length.txt  
    
    total_len=$(awk '{sum+=$2}END{print sum}' "$BASE"_length.txt ) 

    

    #run merryl here
    if ! ./01_scripts/11_merryl.sh "$BASE" "$READS" "$total_len" 
    then
            echo "merryl failed"
            exit 1
    else
        echo -e "\n-------------------------------"
        echo -e "\tmerryl counting done   " 
        echo -e "\n-------------------------------"
    fi

    #run merqury here
    if ! ./01_scripts/12_merqury.sh "$BASE" "$assembly" "$assembler"
    then
            echo "merqury failed"
            exit 1
    else
        echo -e "\n----------------------------------"
        echo -e "\tmerqury QV/completness & plot done"
        echo -e "\n----------------------------------"
    fi

    
    echo -e "\n-------------------------------"
    echo -e "\trunning craq " 
    echo -e "\n-------------------------------"
    #for HiFi only no short reads are available:
    SMSBAM=07_minimap_"$assembler"/"$BASE".bam
    ./01_scripts/14.craq.sh "$assembly" "$SMSBAM" 



    ##TO DO: if ploidy == 2  run hapdup if assembler is flye 
    ##Run merqury on hap1/hap2 of hifiasm

    #run purge dup if necessary


# Run scripts for ONT type
elif [[ "${type,,}" == "nano-hq" ]] ||  [[ "${type,,}" == "nano-raw" ]] ; then
    # Verification assembler type
    if [[ "${assembler,,}" != "canu" ]] && [[ "${assembler,,}" != "flye" ]] && 
        [[ "${assembler,,}" != "shasta" ]] && [[ "${assembler,,}" != "raven" ]]; then
      echo "Invalid assembler type. Should be canu or flye or shasta or raven."
      exit 1
    fi

    echo "Processing ONT type"

    if [[ "${type,,}" == "nano-hq" ]]; then
        echo "data are nano-hq" 
        echo "will perform basecalling with dorado"
        
        INPUT="$genome"                 #check if this is a pod5 folder
        OUTPUTNAME="$species"   #

        if [[ -z "$model" ]]
        then
            model="dna_r10.4.1_e8.2_400bps_sup@v4.3.0"
        fi

        chmod +x ./01_scripts/00_dorado.sh
        bash 01_scripts/00_dorado.sh "$INPUT" "$OUTPUTNAME" $model 

        echo "runing jellyfish and genomescope now"
        kmer_length=21
        chmod +x ./01_scripts/04_jellyfish
        ./01_scripts/04_jellyfish "${genome}" "${kmer_length}"


        #declare READS here:
        READS="TODO"

    elif [[ "$trimm" = "YES" ]] ; then 
        echo -e "\n-------------------------------"
        echo "running chopper"
        echo "assuming nano-raw"
        echo -e "\n-------------------------------"
        
        OUTFOLDER=02_trimmed_ONT
        mkdir "$OUTFOLDER" 2>/dev/null
        INFOLDER="$genome"
        chmod +x ./01_scripts/03_chopper.sh 
        QUAL=10
        HEADCROP=10
        MINLEN=1000
        if ! bash 01_scripts/03_chopper.sh "${INFOLDER}" "${OUTFOLDER}" "$QUAL" "$HEADCROP" "$MINLEN" ; then
            echo "chopper failed"
            exit 1
        else
            echo "Chopper Done"
        fi
        READS="02_trimmed_ONT/*gz"
    fi
 
    chmod +x ./01_scripts/06_ONT_assembler.sh
    if [[ -z "$NCPU" ]]
    then
        NCPU=40
    fi
    if [[ -z "$genomesize" ]]
    then
        genomesize=30 #size must be in megabase here
    fi
    
    
    # Test if output directory exist:
    OUTFOLDER=05_"${species}"_"${assembler}" 
    if [ ! -d "${OUTFOLDER}" ];
    then
        mkdir "${OUTFOLDER}" 2>/dev/null
    else
        echo The folder "${OUTFOLDER}" is already created
    fi

    INFOLDER="$READS" 
    if ! bash  01_scripts/06_ONT_assembler.sh "$INFOLDER" \
            "${OUTFOLDER}" \
            "${genomesize}" \
            "${type}" \
            "${assembler}" \
            "${database}"  \
            "${buscotype}" \
            "${NCPU}" 
    then
        echo "erreur ONT assembly failed"
        exit 1
    else
        echo -e "\n-------------------------------"
        echo "Assembler Done"
        echo -e "\n-------------------------------"
    fi

    BASE=$species     
    #ici mettre un ifelse flye ou canu pour le nom du genome
    if [[ $assembler == "flye" ]] ; then
        assembly=05_"$BASE"_"$assembler"/assembly.fasta 
    elif [[ $assembler == "canu" ]] ; then
        assembly=05_"$BASE"_"$assembler"/assembly.contigs.fasta 
    elif [[ $assembler == "shasta" ]] ; then
        assembly=05_"$BASE"_"$assembler"/Assembly.fasta 
    else #assuming shasta
        assembly=05_"$BASE"_"$assembler"/assembly.fasta 
    fi

    echo -e "\n\n assembly is $assembly \n\n"

    if [[ "${type,,}" == "nano-raw" ]]
    then
        echo "data are nano-raw" 
        echo "will perform polishing with medaka"
      
        #variable for medaka
        BASE="$species"
        OUTFOLDER=06_medaka_"${BASE}"_"${assembler}"
        chmod +x ./01_scripts/08_medaka.sh

        if ! bash  01_scripts/08_medaka.sh "${assembly}" \
                "${READS}" \
                "${OUTFOLDER}" \
                "${database}" \
                "${buscotype}" \
                "${NCPU}" 
        then
            echo "erreur medaka polish failed"
            exit 1
        else
            echo -e "\n-------------------------------"
            echo " medaka Polish Done"
            assembly=06_medaka_"${BASE}"_"${assembler}"/consensus.fasta

            echo -e "\n-------------------------------"
        fi
        
        OUTFOLDER=03_TrimmedIllumina/"${BASE}" 
        chmod +x ./01_scripts/09_fastp.sh
        if ! bash  01_scripts/09_fastp.sh "${illumina}" "${OUTFOLDER}" 
        then
            echo "erreur fastp failed"
            exit 1
        else
            echo -e "\n-------------------------------"
            echo "fastp Done"
            echo -e "\n-------------------------------"
        fi
   
        #variable for bwa-mem
        INPUTGENOME="$assembly"
        ILLUMINATRIMMED=03_TrimmedIllumina/"${BASE}"	
        OUTFOLDER=04_aligned_"$BASE"_"$assembler"
        mkdir "$OUTFOLDER" 2>/dev/null
        chmod +x ./01_scripts/10_bwamem2.sh
        if ! bash  01_scripts/10_bwamem2.sh "${INPUTGENOME}" \
            "${ILLUMINATRIMMED}" \
            "${OUTFOLDER}" 
        then
            echo "erreur bwa-mem failed"
            exit 1
        else
            echo -e "\n-------------------------------"
            echo "BWA mem Done"
            echo -e "\n-------------------------------"
        fi

        #variable for pilon
        INPUTGENOME="$assembly"	
        BAMFOLDER=04_aligned_"${BASE}"_"${assembler}"
        OUTFOLDER=09_pilon_"${BASE}"_"${assembler}"	
        chmod +x ./01_scripts/13_pilon.sh
        if ! bash  01_scripts/13_pilon.sh "${INPUTGENOME}" \
            "${BAMFOLDER}" \
            "${OUTFOLDER}" \
            "${database}" \
            "${buscotype}" 
        then
            echo "erreur pilon polish failed"
            exit 1
        else
            echo -e "\n-------------------------------"
            echo "Pilon Done"
            echo -e "\n-------------------------------"
        fi
        assembly=09_pilon_"${BASE}"_"${assembler}"/pilon.fasta

    fi

    #run awk to get length 
    awk '/^>/ {if (seqlen){print seqlen}
      printf(">%s\t",substr($1,2)) ;seqlen=0;next;} 
      { seqlen += length($0)}END{print seqlen}' "$assembly"  > "$BASE"_length.txt  
    
    total_len=$(awk '{sum+=$2}END{print sum}' "$BASE"_length.txt ) 
    
    echo total genome length is "$total_len" 
    echo -e "\n-------------------------------"
    echo -e "\trunning merryl   " 
    echo -e "\n-------------------------------"
    if [[ $total_len == 0  ]] ; 
    then
        echo "error total length is 0" 
        echo "please check your data"
        exit 1
    fi

   if [[ "${type,,}" == "nano-hq" ]]
   then
       echo "data are nano-hq"
       echo "setting up path to file for meryl"
       READS="02_trimmed_ONT/*gz"
       BASE="$BASE"
   else
       echo "assuming reads are nano-raw"
       READS="$illumina"/*.gz
       BASE="$species"
   fi

    #run merryl here
    if ! ./01_scripts/11_merryl.sh "$BASE" "$READS" "$total_len" 
    then
            echo "merryl failed"
            exit 1
    else
        echo -e "\n-------------------------------"
        echo -e "\tmerryl counting done   " 
        echo -e "\n-------------------------------"
    fi


    #run merqury here
    if ! ./01_scripts/12_merqury.sh "$BASE" "$assembly" "$assembler"
    then
            echo "merqury failed"
            exit 1
    else
        echo -e "\n----------------------------------"
        echo -e "\tmerqury QV/completness & plot done"
        echo -e "\n----------------------------------"
    fi

    #run minimap2 here
    echo -e "\n-------------------------------"
    echo -e "\tmapping long reads to assembly" 
    echo -e "\n-------------------------------"

    
    #ONTREADS="02_trimmed_ONT/input.trimmed.fastq.gz"
    ONTREADS="02_trimmed_ONT/*.fastq.gz"

    OUTFOLDER=07_minimap_"$assembler"
    SPECIES=$species
    NCPU=10
    chmod +x ./01_scripts/07_minimap.sh
    if ! ./01_scripts/07_minimap.sh "${assembly}" "${ONTREADS}" "${type}" "${OUTFOLDER}" "${SPECIES}" "${NCPU}"
    then
        echo "error minimap and samtools failed"
        echo "check your data"
        exit 1
    else
        echo -e "\n-------------------------------"
        echo -e "\tminimap and samtools dp done   " 
        echo -e "\n-------------------------------"
    fi

    #run craq
    #for HiFi only no short reads are availabe:
    if [[ "${type,,}" == "nano-raw" ]]
    then
    
        echo -e "\n-------------------------------"
        echo -e "\trunning craq " 
        echo -e "\n-------------------------------"
    
        #first runn bwa-mem2 on pilon assembly:
        #variable for bwa-mem
        INPUTGENOME="$assembly"
        ILLUMINATRIMMED="03_TrimmedIllumina/${BASE}"	
        OUTFOLDER=10_aligned_after_pilon_"$BASE"_"$assembler"
        mkdir "$OUTFOLDER" 2>/dev/null
        chmod +x ./01_scripts/10_bwamem2.sh
        if ! bash  01_scripts/10_bwamem2.sh "${INPUTGENOME}" \
            "${ILLUMINATRIMMED}" \
            "${OUTFOLDER}" 
        then
            echo "erreur bwa-mem failed"
            exit 1
        else
            echo -e "\n-------------------------------"
            echo "BWA mem on pilon done"
            echo -e "\n-------------------------------"
        fi
       
        INFOLDER=10_aligned_after_pilon_"$BASE"_"$assembler"
        NGSBAM="$INFOLDER"/finalmerged.bam
    
        echo -e "\n-------------------------------"
        echo "merging file"
        samtools merge "$NGSBAM" "$INFOLDER"/*sorted.bam
        SMSBAM=07_minimap_"$assembler"/"$SPECIES".bam
        echo "indexing..."
        samtools index "$SMSBAM"
        echo "indexing..."
        samtools index "$NGSBAM"
    
        chmod +x 01_scripts/14_craq.sh
        if ! ./01_scripts/14_craq.sh "$assembly" "$SMSBAM" "$NGSBAM"
        then
            echo error craq failed !!
            exit 1
        else
            echo -e "\n-------------------------------"
            echo -e "\t craq done! " 
            echo -e "\n-------------------------------"
        fi 
    fi
    echo "Assemblage DONE"
fi
