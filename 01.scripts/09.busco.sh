#!/bin/bash

input=$1   #fasta
database=$2   #dataset name for busco from the focal species (can be obtained through busco --list-dataset)
output=busco_results

busco -c8 -o $output -i $input  -l $database -m geno
