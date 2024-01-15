#puprose: 
#script to download many genome with ncbi-genome-download tools on the ncbi database usign refseq categories
#Author: QR
#date 2022
#update: 2024

species=$1 #name of a focal species (major lineage) of interest to be download on ncbi


#use ncbi dowload to dowload the data: https://github.com/kblin/ncbi-genome-download
#ncbi-genome-download --formats fasta --refseq-categories reference bacteria,viral,fungi,protozoa,archaea  
ncbi-genome-download --formats fasta bacteria,viral,fungi,protozoa,archaea  

cd refseq

zcat \*/GCF\*/\*fna.gz |sed 's/^>/>contam-/g'  > contaminant.fasta
cd ../

#also download human reference genome
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.28_GRCh38.p13/GCA_000001405.28_GRCh38.p13_genomic.fna.gz
zcat GCA_000001405.28_GRCh38.p13_genomic.fna.gz |sed 's/^>/>human-/g' > human.fasta

#repeat the same with $species genome and insert id:
ncbi-genome-download --formats fasta $speices

zcat $species/*/*fna.gz  |sed "s/^>/>$species/g" > "species".fasta 

#concatenate all:
cat contaminant.fasta $species.fasta human.fasta  |gzip > "$species"_human_contam.fa.gz

#data should be ready for alignment with minimap
