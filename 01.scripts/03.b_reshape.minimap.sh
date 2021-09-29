

#separate minimap alignment based on matching pattern:
grep -v "SQ" minimap2.sam.gz |awk '$3=="insect" {print $1"\t"$2"\t"$3"\t"$4"\t"$5}' |gzip > insect.txt.gz

grep -v "SQ" minimap2.sam.gz |awk '$3=="contam" {print $1"\t"$2"\t"$3"\t"$4"\t"$5}' |gzip > contam.txt.gz

grep -v "SQ" minimap2.sam.gz |awk '$3=="human" {print $1"\t"$2"\t"$3"\t"$4"\t"$5}' |gzip > human.txt.gz


#Also take time to look at the mapping code ($6) and look at the blast results
