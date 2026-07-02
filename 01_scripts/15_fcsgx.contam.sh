#!/bin/bash
#NOTE1: add #!/usr/bin/env python to the fsc.py code
#download the latest fcs.py code
#sed -i '1i #!\/usr\/bin\/env python3' fcs.py
#NOTE2: only tested with docker
#NOTE3: taxid is the sheety part that the user must know in advance
input=$1    #full path to genome
taxid=$2    #4751 #taxon id 4751 is for fungi 
gxdbpath=$3 #gxdbpath="/scratch/quentin/gxdb2/" #to be set after install 

outdir=FCS_CONTA/outputdir_$(basename ${input%.fa**} )
mkdir -p $outdir 2>/dev/null 

#1 - download db and md5sum checks

#2 - set db

#3 - screan the genome 
python3 ./01_scripts/fcs-gx/fcs.py screen genome --fasta "$input" \
    --out-dir "$outdir" \
    --gx-db "$gxdbpath" \
    --tax-id "$taxid"

echo "screening finished"
