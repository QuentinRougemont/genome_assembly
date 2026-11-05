#!/bin/bash - 
#===============================================================================
#
#          FILE: 18_get_summary.sh
# 
#         USAGE: ./18_get_summary.sh 
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

mkdir 10_results
cp $(find 04_jellyfish  -name "summary.txt"  ) 10_results/jellyfish_summary.txt
cp $(find . -name report.txt  ) 10_results/quast.report.txt
cp 03_length_distrib/*.len_GC.pdf 10_results/
cp 04_jellyfish/linear_plot.png 10_results/jellyfish_linear_plot.png
cp $(find . -name "short_summary.txt" ) 10_results/BUSCO_short_summary.txt
cp $(find 08_meryl -name *qv ) 10_results/
cp $(find 08_meryl -name *spectra-cn.fl.png ) 10_results/merqury.spectra-cn.fl.png
cp 07_minimap*/*summary_depth.txt 10_results/

#faire ça :
if [ $assembler = "flye" ] ; then
    for i in $(find . -name "assembly_info.txt" ) ;
    do
    cut -f 1-6 $i >  10_results/flye_assembly_info.txt;
    done
elif [ $assembler =  "canu" ] ; then
    grep ">" 06_assembly_canu4KB/assembly.contigs.fasta|sed 's/>//' |column -t > 10_results/canu.info.txt

elif [ $assembler =  "hifiasm" ] ; then
    if [ ploidy == 1 ] ; then
        for i in $(find . -name "*bp.p_ctg.noseq.gfa") ;
        do
            awk '$1=="S" ' $i \
            |awk '{gsub("LN:i:","",$4);gsub("rd:i:","",$5)}{print $2"\t"$4"\t"$5}' >> 10_results/hifiasm.info.txt;
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
