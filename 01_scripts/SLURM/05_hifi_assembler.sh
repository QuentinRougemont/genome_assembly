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
#activate any conda env if necessary
conda activate assembly_env

source config #a filer with genomesize, data type, fastq/pod5, basename etc ploidy
source cpu_mem
FASTQ=$1 #full path to the fastq(.gz) file

echo "assembler will be ${assembler}"
echo "busco database will be ${buscodatabase}"
echo "busco alginer will be ${buscotype}"

echo -e "\n--------------------\nrunnig hifiasm\n--------------\n"
if ! ./01_scripts/05_hifi_assembler.sh \
    "${FASTQ}" \
    "${assembler}" \
    "${buscodatabase}" \
    "${buscotype}" \
    "$NCPU"
then
    echo "error hifiasm failed"
    exit 1
else
    echo "Hifiasm done"
fi
