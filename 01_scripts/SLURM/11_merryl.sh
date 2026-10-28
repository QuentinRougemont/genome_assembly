#!/bin/bash - 
#SBATCH --account=youraccount
#SBATCH --time=48:00:00
#SBATCH --job-name=jellyfish
#SBATCH --output=log_jelly-%J.out
#SBATCH --mem=30G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=48

# Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR
#===============================================================================
set -o nounset                              # Treat unset variables as an error
#===============================================================================

source config #a filer with genomesize, data type, fastq/pod5, basename etc ploidy
source .cpu_mem

assembly=$1         #full path to the new genome assembly (fasta) file
READS="$fastq"      #from config file file

if [[ "${datatype,,}" == "hifi" ]]; then
   BASE0=$(basename "${READS}" )
   BASE="${BASE0%%.*}"
fi
if [[ "${datatype,,}" == "nano-hq" ]]; then
   BASE="${species}"
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
