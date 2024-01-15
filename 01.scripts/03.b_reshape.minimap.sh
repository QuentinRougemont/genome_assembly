

#separate minimap alignment based on matching pattern:
species=$1

zgrep -v "SQ" minimap2.sam.gz |awk -v spe=species '$3 ~ spe && $2!=4 {print $1"\t"$2"\t"$3"\t"$4"\t"$5}' |gzip > "$species".txt.gz

zgrep -v "SQ" minimap2.sam.gz |awk '$3 ~/contam/ && $2!=4 {print $1"\t"$2"\t"$3"\t"$4"\t"$5}' |gzip > contam.txt.gz

zgrep -v "SQ" minimap2.sam.gz |awk '$3 ~/human/ && $2!=4 {print $1"\t"$2"\t"$3"\t"$4"\t"$5}' |gzip > human.txt.gz


#Also take time to look at the mapping code ($6) and look at the blast results
