#!/bin/bash


genome=$1 #full path to genome

folder=FCS_ADPAT/outputdir_$(basename ${genome%.fa**} )

mkdir -p $folder 2>/dev/null 
./01_scripts/run_fcsadaptor.sh --fasta-input "$genome" \
    --output-dir $folder \
    --euk \
    --container-engine singularity \
    --image ./01_scripts/fcs-adaptor.sif


