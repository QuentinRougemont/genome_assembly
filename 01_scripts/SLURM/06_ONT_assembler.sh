#!/bin/bash - 
#SBATCH --account=youraccount
#SBATCH --time=48:00:00
#SBATCH --job-name=assembly
#SBATCH --output=log_assembly-%J.out
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

#parameter as argument:
INFOLDER=$1 #full path to folder containing fastq.gz

#parameter from config file: 
echo "assembler will be ${assembler}"
echo "busco database will be "${buscodatabase}" "
echo "busco alginer will be "${buscotype}" "
echo "species/strain/sample id will be "${SPECIES} " "
echo "genomesize will be "$genomesize" bp "
echo "data type will be "$datatype" "

# Test if output directory exist:
OUTFOLDER=05_"${SPECIES}"_"${assembler}"
if [ ! -d "${OUTFOLDER}" ];
then
    mkdir "${OUTFOLDER}" 2>/dev/null
else
    echo The folder "${OUTFOLDER}" is already created
fi
if ! bash  ./01_scripts/06_ONT_assembler.sh "$INFOLDER" \
        "${OUTFOLDER}" \
        "${genomesize}" \
        "${datatype}" \
        "${assembler}" \
        "${buscodatabase}"  \
        "${buscotype}" \
        "${NCPU}"
then
    echo "erreur ONT assembly failed"
    exit 1
else
    echo -e "\n-------------------------------"
    echo "Assembler Done"
    echo -e "\n-------------------------------"
fi
