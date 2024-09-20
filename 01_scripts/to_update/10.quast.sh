#!/bin/bash

fasta=$1 #fullpath
output=$2 #id of ind

quast --threads 4 --scaffolds --eukaryote -o ./$output $fasta

