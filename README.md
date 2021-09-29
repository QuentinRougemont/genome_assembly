# genome_assembly
generate genome assembly with hifi-only data  

Stuff I used with HiFi only, no HiC, trio, ONT, linked or short reads were available

## Dependancies

### tested on linux, depends on gcc, python, R, java. Conda is usefull to ease software installations  

**hifiasm** software avialble [here](https://github.com/chhylp123/hifiasm)  

**minimap** software availalbe [here](https://github.com/lh3/minimap2)  

**jellyfish** software available [here](http://www.genome.umd.edu/jellyfish.html#Release)  

**genomescope** tools avaible [here for the online version](http://qb.cshl.edu/genomescope/info.php) and [here for running it from the command-line;](https://github.com/schatzlab/genomescope)  

**ncbi-genome-download** software available [here](https://github.com/kblin/ncbi-genome-download)  

**ncbi blast** available [here](https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/)  

**dgenies** software available [here](http://dgenies.toulouse.inra.fr/install)  

**busco** [software](https://gitlab.com/ezlab/busco/-/releases#5.2.1) also available from [conda](https://anaconda.org/bioconda/busco)

**quast** [software](https://sourceforge.net/projects/quast/)

**qiime** [software](http://qiime.org/install/install.html) which can be installed with conda

**mercury**[software](https://github.com/marbl/merqury)


# Assembly of HiFi data

run the scripts located in 01-scripts sequentially from scripts 01 to 11 to obtain an assembly and assess quality  

##	Details:  

 * **1. look at kmer distribution, genome length, and heterozygosity with GenomeScope**
	
This step will help understand the data and optimize parameters for hifiasm assembly

see  `01.scripts/01.jellyfish_and_genomescope.sh`  

here are some details:     
	```
	1. conting k-mer frequencies
	jellyfish count -C -m 21 -s 1000000000 -t 40 $input -o reads.jf
	2. export kmer count histogram:
	jellyfish histo -t 40 reads.jf > reads.histo 
	3. Run GenomeScope:
	Rscript genomescope.R histogram_file k-mer_length read_length output_dir [kmer_max] [verbose] 
	#or use the [online tools](http://qb.cshl.edu/genomescope/info.php)
	```
		
Here is an example graph:
  ![example_graph](https://github.com/QuentinRougemont/genome_assembly/blob/master/pictures/example.png)  

	We see the two kmers peaks at a coverage of ~60 and ~120 representing heterozygous and homozyguous peak respectively  

	the genome length is ~266mb, with approximately 80% unique k-mer and an heterozygosity of 2.8%  

 * **2. look for potential contamination**

 * download data from bacteria, fungi, virus, archaea, protozoaires using ncbi [donwload](https://github.com/kblin/ncbi-genome-download)  
		exemple: 
		ncbi-genome-download --formats fasta --refseq-categories reference bacteria,viral,fungi,protozoa,arachaea  
		
* download insect genome (or other closely related species) on NCBI. This is important to use as a null as minimap will align many sequences to putative contaminant even with low mapping quality    
			see scripts `01.scripts/02.download_contaminant_human_and_insect.sh` 

* concatenate every contaminant in a single fasta and insert an ID for contaminant, insect, and human  (e.g. zcat RefSeq/\*/GCF\*/\*fna.gz |sed 's/^>/>contam-/g'  > contaminant.fasta)  
	
* then perform minimap alignment and validate with blast.  
		see: `01.scripts/03.a_run_minimap.sh`  
		for blast :  
			`01.scripts/04.makeblastdb.sh` and `01.scripts/05.blast.sh`  

 
* ultimately remove sequence that you feel derived from putative contaminations.   
			these scripts may help: `01.scripts/03.b_reshape.minimap.sh 01.scripts/03.c_compare.minimap.results.R`  
			then I use [qiime](https://github.com/QuentinRougemont/genome_assembly/blob/master/01.scripts/06.filter_raw_input.sh) to remove blacklisted sequences  

 * **3. perform assembly on the cleaned assembly**
		simply use hifiasm. look at the [documentation](https://hifiasm.readthedocs.io/en/latest/index.html), [faq](https://hifiasm.readthedocs.io/en/latest/faq.html) and [github issues](https://github.com/chhylp123/hifiasm/issues) for optimisation as everything is well documented.  
		see example of script here: `01.scripts/07.hifiasm.sh`  
			I've especially explored the use of different -s and -o parameters to optimize assembly size but default parameters already produced almost what we expected.   

 * **4. generate fasta** 
	Depending on your need you may want the primary assembly only, the two hap* approximately phased assembly, or anything else  

 * **5. look at quality.**  
		Use bash busco, quast, merqury, etc to assess assembly quality, NG50, N50, length of contig...  
 
		I used merqury only to obtain QV scores as these are not from trios. It requires some additional tools [betools](https://bedtools.readthedocs.io/en/latest/content/installation.html) and [samtools](http://www.htslib.org/)   

 * **6 compare to other genome :** 
		dgenies can be used for that purpose  
