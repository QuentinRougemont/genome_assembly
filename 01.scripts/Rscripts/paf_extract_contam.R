#Purpose: nano-script to extract putative contaminant from the minimap paf alignments
#criteria: we keep only contaminant that have no corresponding overlapping sequence align on our set of closely related species
#Date: 2024
#Author: QR

if("dplyr" %in% rownames(installed.packages()) == FALSE)
{install.packages("dplyr", repos="https://cloud.r-project.org") }
if("magrittr" %in% rownames(installed.packages()) == FALSE)
{install.packages("magrittr", repos="https://cloud.r-project.org") }
if("data.table" %in% rownames(installed.packages()) == FALSE)
{install.packages("data.table", repos="https://cloud.r-project.org") }


library(magrittr)
library(dplyr)
library(data.table)

#load focal species data - set colnames - and filter to keep sequence id with highest start-end-MQ in case of duplicates:
species <- read.table("spe.tmp") %>%
    set_colnames(.,c("Qname","Qlen","Qstart","Qend","strand","id","MQ"))  %>%
    group_by(Qname, Qstart, Qend) %>%
    filter(MQ==max(MQ))  #for each unique sequence keep the one with the highest MQ


#we do exactly the same with putative contaminant:
contam <- read.table("contam.tmp") %>%
    set_colnames(.,c("Qname","contam.Qlen","Qstart","Qend","strand","id","contam.MQ")) %>%
    group_by(Qname, Qstart, Qend) %>%
    filter(contam.MQ==max(contam.MQ))


#next we want to only keep contaminant data with no overlapping match in our focal species dataset
#we will use foverlap to do that, this means we need to have same column id as key and data.table class
#prepare data for overlapping :
cont <- contam %>%
    filter(Qend - Qstart > 250 ) %>% #ignore short contaminant (this might be too stringeant?)
    select(Qname, Qstart, Qend) %>%
    data.table(.)

spe <- species %>%
        select(Qname, Qstart, Qend) %>%
        data.table(.)

setkey(spe, Qname, Qstart, Qend)

candidate_contam <- foverlaps(cont, spe, type = "any" ) %>% #on regarde ceux qui s'overlappent:
    #idéalement on veut les contam sans overlap in the target species:
    filter(is.na(Qstart)) %>% #these will be na in the Qstart/Qend column info of the target species
    select(Qname, i.Qstart, i.Qend)

len <- sum((candidate_contam$i.Qend - candidate_contam$i.Qstart))

print(paste0("total length of candidate contaminant is : ", len, " bp") )

#note: we could further consider removing those with mapq in species > mapq in contam, which I didn't implemented here.


#finally we export the data  - they will be used to create fasta to blast against contaminant and to remove the sequence from the raw ONT/Pacbio data:
write.table(candidate_contam, "putative_contaminant.withnospecies_overlap.bed", quote =F, row.names =F, col.names = F, sep ="\t")


