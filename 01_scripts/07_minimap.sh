#!/bin/bash
#===============================================================================
#          FILE: 07_minimap.sh
# 
#         USAGE: ./07_minimap.sh <ASSEMBLY> <READS> <TYPE> <OUTFOLDER> <SPECIES> 
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
source cpu_mem
source config
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
    if [[ $TYPE = "hifi" ]]
    then
        echo "reads are hifi"
        #to create paf file for inspection
        #minimap2 -c -x map-pb  -t "$NCPU" "$ASSEMBLY" "$READS" |gzip  > minimap2.paf.gz
        minimap2 -ax map-pb -t "$NCPU" "$ASSEMBLY" "$READS" > "$OUTFOLDER"/"$BASE".sam
        samtools view -Sb "$OUTFOLDER"/"$BASE".sam \
            |samtools sort --threads $NCPU > "$OUTFOLDER"/"$BASE".bam
    
        samtools depth  "$OUTFOLDER"/"$BASE".bam |\
            gzip > "$OUTFOLDER"/"$BASE".dp.gz
        Rscript 01_scripts/Rscripts/plot_depth.R "$OUTFOLDER"/"$BASE".dp.gz
        zcat "$OUTFOLDER"/"$BASE".dp.gz \
            |sort -k2,2n \
            |awk -f 01_scripts/median_col3.awk \
            > "$OUTFOLDER"/"$BASE".median.dp.txt 
        rm "$OUTFOLDER"/"$SPECIES".sam 
        samtools view "$OUTFOLDER"/"$SPECIES".bam |cut -f 1-5 > column1.5.tmp
    else
        echo "assuming reads are ONT"
        echo -e "
        minimap2 -ax map-ont -t "$NCPU" "$ASSEMBLY" "$READS" > "$OUTFOLDER"/"$SPECIES".sam " >  runme
        bash runme 
        samtools view -Sb "$OUTFOLDER"/"$SPECIES".sam \
            | samtools sort --threads "$NCPU" > "$OUTFOLDER"/"$SPECIES".bam
        
        samtools depth  "$OUTFOLDER"/"$SPECIES".bam |\
            pigz -p $NCPU > "$OUTFOLDER"/"$SPECIES".dp.gz
        rm runme
        Rscript 01_scripts/Rscripts/plot_depth.R "$OUTFOLDER"/"$SPECIES".dp.gz
        
        #verify median depth
        zcat "$OUTFOLDER"/"$SPECIES".dp.gz \
            |sort -k2,2n \
            |awk -f 01_scripts/median_col3.awk \
                > "$OUTFOLDER"/"$SPECIES".median.dp.txt 
        rm "$OUTFOLDER"/"$SPECIES".sam 
        samtools view "$OUTFOLDER"/"$SPECIES".bam |cut -f 1-5 > column1.5.tmp
    fi
else
    echo "minimap output already here"
fi
if [ ! -e "$OUTFOLDER"/column1.5.tmp.gz ] ; then
    samtools view "$OUTFOLDER"/"$SPECIES".bam |cut -f 1-5 > column1.5.tmp
elif LC_ALL=C gzip -l  "$OUTFOLDER"/column1.5.tmp.gz | awk 'NR==2 {exit($2!=0)}' ; then
    samtools view "$OUTFOLDER"/"$SPECIES".bam |cut -f 1-5 > column1.5.tmp
fi

file=column1.5.tmp
if [ -s "$file"  ] ; then
   #some post-proccessing:
   samtools faidx "${ASSEMBLY}"
   fai="${ASSEMBLY}".fai
   cut -f 3 $file |sort |uniq -c > ReadsCount
   grep -v "*" ReadsCount > tmp ; mv tmp ReadsCount
   
   rm test 2>/dev/null
   
   for i in $(awk '{print $2}' ReadsCount ) ; do
           grep -w $i "$file" \
           |cut -f 5 \
           |sort \
           |uniq -c \
           |awk -v var=$i '{print var"\t"$0}' >> test
   done
   
   join -1 2 -2 1 ReadsCount <(awk '$3=="0" ' test )  \
           |awk '{print $0"\t"$3/$2}'  > read.0
   
   source config
   awk -v var="$threshold" '$5 > var' read.0 > prop_read.0.above."$threshold"
   grep -w -Ff <(awk '{print $1 }' prop_read.0.above."$threshold"  prop_read.0.above."$threshold") <(cut -f 1-2 $fai) > length_prop_read.0.above."$threshold"
   
   #depth:
   grep -w -Ff <(awk '{print $1 }' prop_read.0.above."$threshold"  prop_read.0.above."$threshold") "$OUTFOLDER"/*summary_depth.txt > depth_prop_read.0.above."$threshold"
   gzip column1.5.tmp
   mv column1.5.tmp.gz "$OUTFOLDER"
   mv ReadsCount "$OUTFOLDER"
   mv length_prop_read.0.above."$threshold" "$OUTFOLDER"
   mv depth_prop_read.0.above."$threshold" "$OUTFOLDER"
   mv test "$OUTFOLDER"
fi
