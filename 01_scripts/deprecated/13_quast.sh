#!/bin/bash

# Author: Quentin Rougemont 
# Date: 2023 + update 01/2024 
# Update 03/2024 by Alexandra Jalaber Dupont de Dinechin

# Global variables
# Check if the number of arguments is correct
if [ $# -ne 4  ]; then
    echo "USAGE: $0 ONT : <type> <genome> <datasetBusco>"
    echo -e "Expecting either four or five arguments for ONT: \n 
      \t 1: <type>: ONT\n
      \t 2: <genome>: genome/folder_name with the fastq\n
      \t 3: <database>: For Busco\n
      \t 4: <assembler> : assembler type"
    exit 1
else
    type=$1
    genome=$2
    assembler=$3
fi

if [[ "${type,,}" != "hifi" ]] && [[ "${type,,}" != "ont" ]]; then
  echo "Invalid read type. Should be ONT or HIFI."
  exit 1
fi
######################  Quast  ######################

########### HIFI ###########
if [[ "${type,,}" == "hifi" ]]; then 
    #running quast on genome fasta
    quast --threads 4 --eukaryote -o Pilon"$genome"_"${assembler}"/ Pilon"$genome"_"${assembler}"/pilon.fasta

########### ONT ###########
elif [[ "${type,,}" == "ont" ]]; then
    #running quast on genome fasta
    quast --threads 4 --eukaryote -o Pilon"$genome"_"${assembler}"/ Pilon"$genome"_"${assembler}"/pilon.fasta
fi
