#!/bin/bash
#NOTE1: add #!/usr/bin/env python to the fsc.py code
input=$1    #full path to genome
taxid=$2    #ex: 4751
indir=FCS_CONTA/outputdir_$(basename ${input%.fa**} )
outdir=09_fcs_clean/

mkidr "$outdir" 2>/dev/null

echo -e " "$indir"/"$(basename ${input%.fa**})"."$taxid".fcs_gx_report.txt"

#4 - clean the genome:
cat "$input" \
    | python3 ./01_scripts/fcs-gx/fcs.py clean genome \
    --action-report "$indir"/"$(basename ${input%.fa**})"."$taxid".fcs_gx_report.txt \
    --output 09_fcs_clean/cleaned.fasta \
    --contam-fasta-out 09_fcs_clean/contam.fasta

