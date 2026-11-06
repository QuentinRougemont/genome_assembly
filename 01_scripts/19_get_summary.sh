#!/bin/bash - 
#===============================================================================
#
#          FILE: 19_get_summary.sh
# 
#         USAGE: ./19_get_summary.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 04/11/2026 14:41:23
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

source config

mkdir -p 10_results/"$assembler"/
#1 create stat in R
cp 03_length_distrib/*.len_GC.pdf 10_results/"$assembler"/01_"$SPECIES".histogramLenGC.pdf 
cp 03_length_distrib/"$SPECIES"_read.summary.stats.pdf 10_results/"$assembler"/01_"$SPECIES".readLenGCstats.pdf

cp $(find 04_jellyfish  -name "summary.txt"  ) 10_results/"$assembler"/02a_"$SPECIES".jellyfish_summary.txt
sed -i "1i Jellyfish report for :\t $SPECIES \n\n " 10_results/"$assembler"/02a_"$SPECIES".jellyfish_summary.txt

cp 04_jellyfish/linear_plot.png 10_results/"$assembler"/02b_jellyfish_"$SPECIES"_linear_plot.png
cp $(find . -name report.txt  ) 10_results/"$assembler"/03_"$SPECIES".quast.report.txt
sed -i "1i ****Quast report for :\t $SPECIES ****\n" 10_results/"$assembler"/03_"$SPECIES".quast.report.txt

cp $(find . -name "short_summary.txt" ) 10_results/"$assembler"/04_"$SPECIES_"BUSCO_short_summary.txt
sed -i "1i ****BUSCO SUMMARY RESULTS FOR: $SPECIES*****\n"

for i in $(find 08_meryl -name *qv ) ; do cp $i 10_results/"$assembler"/05_$(basename "$i") ; done 
cp $(find 08_meryl -name *spectra-cn.fl.png ) 10_results/"$assembler"/06_merqury.spectra-cn.fl.png

cp 07_minimap*/*summary_depth.txt 10_results/"$assembler"/07_$SPECIES.summary_depth.txt #create a nice pdf in R
for i in $(find 07_minimap_* -name "*page*.png" ) ; do cp $i 10_results/"$assembler"/08_$(basename $i ) ; done

cd 10_results/$assembler
for i in *png ; do convert $i ${i%.png}.pdf ; done 
cd ../../
#faire ça :
if [ $assembler = "flye" ] ; then
    for i in $(find . -name "assembly_info.txt" ) ;
    do
    cut -f 1-6 $i >  10_results/03_flye_"$SPECIES"_assembly_info.txt;
    done
elif [ $assembler =  "canu" ] ; then
    grep ">" 06_assembly_canu4KB/assembly.contigs.fasta|sed 's/>//' |column -t > 10_results/03_canu_"$SPECIES".info.txt

elif [ $assembler =  "hifiasm" ] ; then
    if [ ploidy == 1 ] ; then
        for i in $(find . -name "*bp.p_ctg.noseq.gfa") ;
        do
            awk '$1=="S" ' $i \
            |awk '{gsub("LN:i:","",$4);gsub("rd:i:","",$5)}{print $2"\t"$4"\t"$5}' >> 10_results/03_hifiasm_"$SPECIES".info.txt;
        done
    elif [ ploidy == 2 ] ; then
        for i in $(find . -name "*bp.hap*.p_ctg.noseq.gfa") ;
        do
            n=$(basename $i )
            awk '$1=="S" ' $i \
            |awk '{gsub("LN:i:","",$4);gsub("rd:i:","",$5)}{print $2"\t"$4"\t"$5}'  >> 10_results/hifiasm.${n%.p_ctg.noseq.gfa}.info.txt
        done
    fi
fi
