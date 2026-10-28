#!/bin/bash - 
#SBATCH --account=youraccount
#SBATCH --time=08:00:00
#SBATCH --job-name=jellyfish
#SBATCH --output=log_jelly-%J.out
#SBATCH --mem=30G
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=24

# Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR
#===============================================================================
set -o nounset                              # Treat unset variables as an error
#===============================================================================

source config #a filer with genomesize, data type, fastq/pod5, basename etc ploidy
source .cpu_mem

#arguments from config file:
echo "data type is "${datatype}" "
echo "assembler is "${assembler}" "
READS="$fastq"     #from config file
SPECIES="$species" #only for ONT 

#external arguments
assembly=$1         #full path to the new genome assembly (fasta) file

OUTFOLDER=07_minimap_"$assembler"
NCPU=24
SPECIES="" #will be ignore

chmod +x ./01_scripts/07_minimap.sh
if ! ./01_scripts/07_minimap.sh "${assembly}" "${READS}" "${datatype}" "${OUTFOLDER}" "${SPECIES}" "${NCPU}"
then
    echo "error minimap and samtools failed"
    echo "check your data"
    exit 1
else
    echo -e "\n-------------------------------"
    echo -e "\tminimap and samtools dp done   "
    echo -e "\n-------------------------------"
fi
