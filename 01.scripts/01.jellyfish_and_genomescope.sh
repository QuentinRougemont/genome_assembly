#!/bin/bash

input=$1 #fastq.gz read from HiFi
jellyfish count -C -m 21 -s 1000000000 -t 40 <(zcat $input) -o reads.jf

jellyfish histo -t 40 reads.jf > reads.histo

# Rscript genomescope.R histogram_file k-mer_length read_length output_dir [kmer_max] [verbose]

