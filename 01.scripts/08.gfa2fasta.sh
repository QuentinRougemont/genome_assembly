
input=$1
awk '/^S/{print ">"$2;print $3}' $input > ${input%.gfa}.fasta
