#date = 25.08.2021
#author QR
#purpose: compare alignement of hifi read from minimap on insect/human/contaminant fasta


##check packages
if("dplyr" %in% rownames(installed.packages()) == FALSE)
{install.packages("dplyr", repos="https://cloud.r-project.org") }
if("data.table" %in% rownames(installed.packages()) == FALSE)
{install.packages("data.table", repos="https://cloud.r-project.org") }
if("magrittr" %in% rownames(installed.packages()) == FALSE)
{install.packages("magrittr", repos="https://cloud.r-project.org") }

#load libs
library(magrittr)
library(dplyr)
library(data.table)

#download data
insect <- fread("zcat insect.txt.gz") %>% 
	select( -V3,-V4) %>% 
	set_colnames(.,c("seqid","insect_flag","insect_MAPQ"))
contam <- fread("zcat contam.txt.gz") %>% 
	select(-V3,-V4) %>% 
	set_colnames(.,c("seqid","contam_flag","contam_MAPQ"))

hum <- fread("zcat human.txt.gz")%>% 
	select(-V3,-V4) %>% 
	set_colnames(.,c("seqid","human_flag","human_MAPQ"))

#filter
human <- hum %>% group_by(seqid) %>% filter(human_MAPQ==max(human_MAPQ)) #%>% filter(human_flag!="256" & !="2064" & !="272"))
conta <- contam %>% group_by(seqid) %>% filter(contam_MAPQ==max(contam_MAPQ)) #%>% filter(human_flag!="256" & !="2064" & !="272"))

insec <- insect %>% group_by(seqid) %>% filter(insect_MAPQ==max(insect_MAPQ)) #%>% filter(human_flag!="256" & !="2064" & !="272"))


all2 = full_join(human,insec)
human_mq30 <- all2 %>% filter(human_MAPQ>30)
unique(human_mq30$seqid) #13 sequences only! 
length(unique(conta_mq30$seqid))
#yet also mapped onto insect with mapq 60
#only one not mapped on insect

write.table(unique(human_mq30$seqid),"putative_human_conta_to_blast",quote=F,row.names=F,col.names=F)

#contam:
all2 = full_join(conta,insec)
conta_mq30 <- all2 %>% filter(contam_MAPQ>30)
unique(conta_mq30$seqid)
length(unique(conta_mq30$seqid))
#131 sequences with putative contamination #yet 30 sequences also mapped onto insect
conta_mq30_no_insect <- conta_mq30 %>% filter(insect_MAPQ<50)
conta_mq30insect <- conta_mq30 %>% filter(insect_MAPQ>1)

write.table(unique(conta_mq30$seqid),"putative_contamconta_to_blast",quote=F,row.names=F,col.names=F)
 write.table(conta_mq30,"contaminant_significant.txt",quote=F,row.names=F,sep="\t")

awk '$5=="NA" {print $0}' contaminant_significant.txt  |cut -f 1 |uniq > contaminant.to.remove.txt

