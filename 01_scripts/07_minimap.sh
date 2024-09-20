#!/bin/bash
#===============================================================================
#          FILE: 07_minimap.sh
# 
#         USAGE: ./07_minimap.sh <ASSEMBLY> <READS> <assembler> (optional: <NCPU>) 
# 
#   DESCRIPTION: align raw read to ASSEMBLY to find problems and other use
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Q. Rougemont 
#  ORGANIZATION: 
#       CREATED: 07/08/2024 11:54:40
#      REVISION:  ---
#===============================================================================
#global variable #
if [ $# -lt 4  ]; then
    echo "USAGE: $0 <ASSEMBLY> <READS> <TYPE> <assembler> (optional: <NCPU>)"
    echo -e "Expecting a least the first four following arguments: \n
        \t 1: <ASSEMBLY> : the path to the genome ASSEMBLY\n
        \t 2: <READS>    : the fastq/fasta of SMS read to align\n
        \t 3: <TYPE>     : Hifi or ONT a string stating wether data are frome pacbio-hifi (Hifi) or ONT (ONT)\n
        \t 4: <OUTFOLDER>: Output Folder for minimap \n
        \n\t optionally: \n
        \t 5: <species> : a species name in cases of nano-raw/nano-hq \n
        \t 6: <NCPU>    : optional: number of cpu to use \n"
    exit 1
else
    ASSEMBLY=$1  #full path to the ASSEMBLY
    READS=$2     #set of long reads to be mapped - ideally compressed.
    TYPE=$3      #either PB or ONT
    OUTFOLDER=$4 #output folder
    SPECIES=$5
    NCPU=$6
    echo -e "\nASSEMBLY file $ASSEMBLY\n"
    echo -e "READS file is : $READS\n"
    echo -e "data TYPE is : $TYPE\n"
    echo -e "output folder is $OUTFOLDER\n"
    echo -e "\n"
fi
#===============================================================================
# create architecture and checks 
BASE=$(basename "${READS%%.*}" ) 

mkdir "$OUTFOLDER" 2>/dev/null

# Test if user specified a number of CPUs, if not, default to 8
if [ -z "$NCPU" ]
then
    NCPU=20
fi

minsize=900000
bamfile="$OUTFOLDER"/*.bam
if [ -s $bamfile ] 
then
    filesize=$(wc -c <$bamfile )
else
    filesize=0
fi

#---------  run minimap ----------#

if [ "$filesize" -lt "$minsize" ]
then
    echo "running minimap"
    if [[ $TYPE = "Hifi" ]]
    then
        #to create paf file for inspection
        #minimap2 -c -x map-pb  -t "$NCPU" "$ASSEMBLY" "$READS" |gzip  > minimap2.paf.gz
        #to create same file for depth plot :
        minimap2 -ax map-pb -t "$NCPU" "$ASSEMBLY" "$READS" > "$OUTFOLDER"/"$BASE".sam
        samtools view -Sb "$OUTFOLDER"/"$BASE".sam \
            |samtools sort --threads $NCPU > "$OUTFOLDER"/"$BASE".bam
    
        samtools depth  "$OUTFOLDER"/"$BASE".bam |\
            gzip > "$OUTFOLDER"/"$BASE".dp.gz
    else
        echo "assuming reads are ONT"
        minimap2 -ax map-ont -t "$NCPU" "$ASSEMBLY" "$READS" > "$OUTFOLDER"/"$SPECIES".sam
        samtools view -Sb "$OUTFOLDER"/"$SPECIES".sam \
            | samtools sort --threads "$NCPU" > "$OUTFOLDER"/"$SPECIES".bam
    
        samtools depth  "$OUTFOLDER"/"$SPECIES".bam |\
            gzip > "$OUTFOLDER"/"$SPECIES".dp.gz
    fi
else
    echo "minimap output already here"
fi
