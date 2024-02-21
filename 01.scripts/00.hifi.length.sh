
#compute length of the raw hifi file 
#file generate with extract hifi to get QV 20 (0.99) reads

input=$1
zcat $input | awk '{if(NR%4==1) {printf(">%s\t",substr($0,2));} else if(NR%4==2) print length;}' |gzip > $input.len.gz


#then plot histogram in R

argv <- commandArgs(T)
 
a <- read.table(argv[1])

mean = data.frame(mean(a$V2))
colnames(mean) = "mean"


library(ggplot2)

pdf(file = "hist.len.pdf", 8,8)
ggplot(a, aes(x = V2, color="z") ) + geom_histogram(fill = "white")  + 
   theme_classic() + 
   geom_vline(data = mean, aes(xintercept = mean) , linetype = "dashed") + 
   xlab("read len") + 
   ylab("count") + 
   scale_color_brewer(palette="Dark2") + theme(legend.position="none")
dev.off()
