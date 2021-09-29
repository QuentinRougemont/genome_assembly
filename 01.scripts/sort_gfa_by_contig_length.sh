input=$1 #gfa file
awk '$1=="S" {print $4"\t"$5}' $input|sed -e 's/rd:i://g' -e 's/LN:i://g' |LC_ALL=C sort -k 1 -nr > contig.length.rd.txt

