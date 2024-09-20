# genome_assembly workflow  


## Purpose: 

Generate **genome assembly** +  **polishing** + 
several quality checks: **QV**, **K-mer multicplicity**, genome-scope plot, **busco/compleasm**, **CRAQ** evaluation  and plots with either : 

 * HiFi-only data 

 * ONT only (Q20) 

 * ONT + illumina 
 

# To Do:

* add contamination checks 



### Tested on linux, 

### Mamba

If you want to avoid potential conflicting versions or do not have root access on your device, you can use **conda** or **mamba** to install dependencies.

We recommend mamba for linux:

```
curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge-pypy3-Linux-x86_64.sh
bash Miniforge-pypy3-Linux-x86_64.sh
#note: see here for other verions of mamba: https://github.com/conda-forge/miniforge
```


# Full automated installation 

first clone this repository:

```sh
git clone https://github.com/QuentinRougemont/genome_assembly/ 
```

then run the following:
```sh
mamba env create assembly_env.yml  

#for busco:
mamba env create busco_env.yml

#and for non-conda dependencies
in a fixed folder in your /home: 
bash ./dependencies.sh
```

**Note:** this will create a folder call "softs" to install non conda dependencies (i.e. Jellyfish, Compleasm, Dorado, CRAQ)


## Manual installation:

if you don't want to use conda, then install all of this by hand according to your need:

* [pbtk](https://github.com/pacificbiosciences/pbtk/)

* [hifiasm](https://github.com/chhylp123/hifiasm)  

* [flye](https://github.com/mikolmogorov/Flye/blob/flye/docs/INSTALL.md)

* [minimap2](https://github.com/lh3/minimap2)  

* [jellyfish](http://www.genome.umd.edu/jellyfish.html#Release)  

* [genomescope](https://github.com/schatzlab/genomescope)  

* [busco](https://gitlab.com/ezlab/busco/-/releases#5.7.1) 

* [quast](https://sourceforge.net/projects/quast/)

* [mercury](https://github.com/marbl/merqury)

* [craq](https://github.com/JiaoLaboratory/CRAQ)


Contamination checks (optional): 
* [ncbi-genome-download](https://github.com/kblin/ncbi-genome-download)  

* [ncbi blast](https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/)  

* [bedtools](https://bedtools.readthedocs.io/en/latest/index.html) 

ONT-specific dependencies: 
* [dorado]()
* [chooper](https://github.com/wdecoster/chopper)
* [medaka]()

For short read corrections of ONT:
* [parallel](https://www.gnu.org/software/parallel/)

* [fastp](https://github.com/OpenGene/fastp)

* [bwa](https://sourceforge.net/projects/bio-bwa/files/)

* [samtools](http://www.htslib.org/)

* [fastp](https://github.com/OpenGene/fastp)

* [pilon](https://github.com/broadinstitute/pilon)

Visualisation (optional)
* [dgenies](http://dgenies.toulouse.inra.fr/install)  
* [R](https://www.r-project.org/)


# Quick start: 

after successfull installation provide your input data as arguments to the script `./assembly_flow.sh` 
option are as follows: 


see details by running the following command: 
```sh
./FlowAssembly.sh --help

#options are as follows:
	-g <genome>: path to genome file either as fastq.gz/bam/pod5
	-t <type> : data type: either hifi, "nano-raw", or "nano-hq"
	-a <assembler> : name of the assembler to be used either <hifiasm>,<canu>,<flye>
	-d <datatype> : database for busco analyses can be obtained through busco --list dataset)
	(optional:)
	-b <buscotype> (default : miniprot, else: miniprot, metaeuk, augustus)
	(ONT only parameters:) 
	-p <species_id/strain_id/whatever_id> : any species id for the genome
	-T <Trimm> :   wether to trimm ONT data or not
	-i <illumina> : path to illumina data folder for polishing
	-N <NCPU> : number of CPU to be used
	
```

# Concrete Example

**Assembling nano-raw (old chemistry + illumina):** 

``
./FlowAssembly.sh -g path/to/nano_data_folder -t nano-raw -s 400 -a flye -d insecta_odb10 -T YES -p Species1 -b miniprot -i /path/to/illumina_folder 2>&1 |tee logSpecies1
``

* **for nano-hq (no illumina needed):**

`./FlowAssembly.sh -g path/to/nano-hq -t nano-hq -s 40 -a flye -d basidiomycota_odb10 -T NO -p fungus1 -b miniprot | tee logFungus1 `

* **for HiFi:** 

`./FlowAssembly.sh -g path/to/raw_hifi/species.bam -s 400 -a hifiasm -d insecta_odb10 -T NO -p heliconius1 -p   2>&| tee logHeliconus1 `

#


# More details

## 1 - Assembly of HiFi data

run the scripts located in 01-scripts sequentially from scripts 01 to 11 to obtain an assembly and assess quality  

##	Step by Step guide :  

 * **1. look at kmer distribution, genome length, and heterozygosity with GenomeScope**
	
This step will help understand the data and optimize parameters for hifiasm assembly

see  `01.scripts/01.jellyfish_and_genomescope.sh`  

here are some details:     
 
	```sh
	1. conting k-mer frequencies:
	jellyfish count -C -m 21 -s 1000000000 -t 40 $input -o reads.jf 
	2. export kmer count histogram:
	jellyfish histo -t 40 reads.jf > reads.histo 
	3. Run GenomeScope:
	Rscript genomescope.R histogram_file k-mer_length read_length output_dir [kmer_max] [verbose]
	or use [online tools](http://qb.cshl.edu/genomescope/info.php) 
	```

Here is an example graph:
  ![example_graph](https://github.com/QuentinRougemont/genome_assembly/blob/main/pictures/example.png)  

	We see the two kmers peaks at a coverage of ~60 and ~120 representing heterozygous and homozyguous peak respectively  

	the genome length is ~266mb, with approximately 80% unique k-mer and an heterozygosity of 2.8%  

 * **2. look for potential contamination**

	* download data from bacteria, fungi, virus, archaea, protozoaires using ncbi [donwload](https://github.com/kblin/ncbi-genome-download)  
		exemple: 
		ncbi-genome-download --formats fasta --refseq-categories reference bacteria,viral,protozoa,arachaea  
		
	* download genome of several closely related species to your focal organsims on NCBI. This is important to use as a null as minimap will align many sequences to putative contaminant even with low mapping quality    
			see script:
   		*  `01.scripts/02.download_contaminant_human_and_focal_species.sh`

        	This script takes 1 single argument:
        
        		* 1 - "species" which is the name of the species/lineage/major group you want to download from NCBI (e.g. insect, fungi, etc...)

			* it will:
     * download the data
     * concatenate everything in a single fasta and insert an ID for your focal species, potential contaminant, and human  (`e.g. zcat RefSeq/\*/GCF\*/\*fna.gz |sed 's/^>/>contam-/g'  > contaminant.fasta`)  
	
	
 * then we perform minimap alignment and validate with blast.  
		see:
		`01.scripts/01.scripts/03.minimap_and_filtering.sh`

		this script takes 3 arguments:
		* 1 - the species name used for NCBI download  
 
 		* 2 - the name of the raw fastq file  
 
		* 3 - the type of data (a string: either "PB" or "ONT" with PB for pacbio-hifi and ONT for ONT)  
 
 * The script above should ultimately remove sequence that seems derived from putative contaminations. 



 * **3. perform assembly on the cleaned RAW data**
		simply use hifiasm. look at the [documentation](https://hifiasm.readthedocs.io/en/latest/index.html), [faq](https://hifiasm.readthedocs.io/en/latest/faq.html) and [github issues](https://github.com/chhylp123/hifiasm/issues) for optimisation as everything is well documented.  
		see example of script here: `01.scripts/07.hifiasm.sh`
  
			I've especially explored the use of different -s and -o parameters to optimize assembly size but default parameters already produced almost what we expected.
   
	*	-s parameter: decrease it to avoid missassembly, perform more purging and decrease assembly size 
	*	-O parameter: decrease it to avoid missassembly,  
	*	-D & -N can be increased to increased assembly contiguity.  
		Explore a combination of different parameter to see how it change the results!

 * **4. generate fasta** 
	Depending on your need you may want the primary assembly only, the two hap* approximately phased assembly, or anything else  

 * **5. look at quality.**  
	Use bash, busco, quast, merqury, etc to assess assembly quality, NG50, N50, length of contig...
	these scripts may be usefull:
	```
	sort_gfa_by_contig_length.sh
	sort_gfa_by_rd.sh
	get_total_length_of_gfa.sh
	``` 
	* **busco**
	busco is very simple to run on a genomic fasta file:
	```
	busco -c8 -o output_busco -i your_fasta  -l lepidoptera_odb10 -m geno
	```

In my case the busco score looks not to bad:  

```sh
--------------------------------------------------
|Results from dataset lepidoptera_odb10           |
--------------------------------------------------
|C:98.6%[S:98.2%,D:0.4%],F:0.2%,M:1.2%,n:5286     |
|5211   Complete BUSCOs (C)                       |
|5190   Complete and single-copy BUSCOs (S)       |
|21     Complete and duplicated BUSCOs (D)        |
|12     Fragmented BUSCOs (F)                     |
|63     Missing BUSCOs (M)                        |
|5286   Total BUSCO groups searched               |
--------------------------------------------------
```

We will get back to that later.


	
* **merqury**  

 I used merqury only to obtain QV scores as these are not from trios.  
  It requires some additional tools [betools](https://bedtools.readthedocs.io/en/latest/content/installation.html) and [samtools](http://www.htslib.org/)   

simply follow github: https://github.com/marbl/merqury/wiki :

```bash
1 prepare meryl dbs fille
1.1. find best kmer:
~/software/merqury-1.3/best_k.sh 262666002 #genome size in bp according to genome scope.
~/software/merqury-1.3/best_k.sh 319000002 #genome size in bp according to biology.
#best kmer is ~19

#1.2. Build k-mer dbs with meryl
#k=19
#read=/scratch/qrougemont/pacbio/filter_dataset/filter2/output.fastq.gz

#meryl k=$k count output read.meryl $read

#2. Overall assembly evalution:
#2.1. reference free QV estimate
cd test_HiFi
ln -s ../read.meryl
~/software/merqury-1.3/merqury.sh read.meryl test.p_ctg.fasta  test_HiFi > hifi.log

cd ../hap1.HiFi
ln -s ../read.meryl
~/software/merqury-1.3/merqury.sh read.meryl test.hap1.p_ctg.fasta  hap1.HiFi > hifi.hap1.log

cd ../hap2.HiFi
ln -s ../read.meryl
~/software/merqury-1.3/merqury.sh read.meryl test.hap2.p_ctg.fasta  hap2.HiFi > hifi.hap2.log

```

example results:
```
seq	UniqKmer KmerInBoth	QV	ErrorRate
hap1	1484	294577935	65.7652	2.65144e-07
hap2	1118	298221533	67.0485	1.9731e-07
Both	2602	592799468	66.3635	2.31019e-07
```

That seems rather good!

#we can look at the k-mer duplicity distribution to make sure everything is OK:
![example_graph](https://github.com/QuentinRougemont/genome_assembly/blob/main/pictures/Fig2.png)  


The graph look ok but we see an excess of k-mer with low read depth (i.e. we will remove them) later 


#when considering the busco score on each separate parental assembly the number of duplicated reads were (very sligthly) higher than in the primary assembly.
#therefore purged_dups could be used to reduce this:

* **purged_dups** (see https://github.com/dfguan/purge_dups)

```bash
ref=your_reference.p_ctg.fa.gz         
readcss=hifi.fastq.gz
minimap2 -xasm20 -t 20 $ref $readcss | gzip -c - > aln.paf.gz

./bin/pbcstat *.paf.gz #(produces PB.base.cov and PB.stat files)
./bin/calcuts PB.stat > cutoffs 2>calcults.log

#here I modify the cutoffs to remove the seq with k-mer depth below 20

bin/split_fa $ref > $ref.split
minimap2 -xasm5 -DP $ref.split $ref.split | gzip -c - > $ref.split.self.paf.gz

bin/purge_dups -2 -T cutoffs -c PB.base.cov $ref.split.self.paf.gz > dups.bed 2> purge_dups.log

bin/get_seqs -e dups.bed $ref

```


this was done for each parental assembly and the primary reference.

* **then run busco again**

on each assembly separately 

* **6 compare to other existing genomes :** 
		**dgenies** can be used for that purpose
  		**minimap** + pafr + SV detections methods

* **7 annotate TE with repeatmodeler**

* **8 perform prediction of gene with RNAseq**

For step 7 and 8 see our example pipeline here:https://github.com/QuentinRougemont/genome_annotation

# 2 - Hifi - Haploid assembly



# 3 - ONT assembly 

# 3.1 new chemistery 

# 3.2 old chemistery

