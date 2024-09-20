#!/bin/bash

input=$1 #protein database stored in 02_data/ folder
title=$2 #title for the blast db
input_type="fasta"
dbtype="nucl"


makeblastdb -in "$input" \
            -input_type "$input_type" \
            -dbtype "$dbtype"\
            -title "$title"


