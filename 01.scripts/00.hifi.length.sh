
#compute length of the raw hifi file and GC content
#file generated with extract hifi to get QV 20 (0.99) reads

input=$1
#zcat $input | awk '{if(NR%4==1) {printf(">%s\t",substr($0,2));} else if(NR%4==2) print length;}' |gzip > $input.len.gz
zcat $input | awk '{if(NR%4==1) {printf(">%s\t",substr($0,2));} else if(NR%4==2) print length "\t" gsub(/[GC]/, "")}' |awk '{print $0"\t"$3/$2}'  |gzip > $input.len.gc.gz 

#then plot histogram in R
Rscript 01.scripts/Rscripts/plot_len_gc.R $input.len.gc.gz
