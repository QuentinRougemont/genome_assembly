
#use ncbi dowload to dowload the data: https://github.com/kblin/ncbi-genome-download
#ncbi-genome-download --formats fasta --refseq-categories reference bacteria,viral,fungi,protozoa,archaea  
ncbi-genome-download --formats fasta bacteria,viral,fungi,protozoa,archaea  

cd refseq

zcat \*/GCF\*/\*fna.gz |sed 's/^>/>contam-/g'  > contaminant.fasta
cd ../

#also download human reference genome
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.28_GRCh38.p13/GCA_000001405.28_GRCh38.p13_genomic.fna.gz
zcat GCA_000001405.28_GRCh38.p13_genomic.fna.gz |sed 's/^>/>human-/g' > human.fasta

#repeat the same with insect genome and insert id:
cd insect/
zcat */*fna.gz  |sed 's/^>/>insect/g' > insect.fasta 
#/!\ warning: change according to your model organisms outgroups genomes

#concatenate all:
cat contaminant.fasta insect.fasta human.fasta > insect_human_contam.fa

#data should be ready for alignment with minimap
