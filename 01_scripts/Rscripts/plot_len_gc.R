
argv <- commandArgs(T)
 
a <- read.table(argv[1])
dir <- dirname(argv[1])

means <- data.frame(t(colMeans(a[,c(2,4)])))
colnames(means) <- c("meanlen","meanGC")

a <- a[,-c(1,3)]

colnames(a)<-c("len","GC")

if("ggplot2" %in% rownames(installed.packages()) == FALSE)
{install.packages("ggplot2", repos="https://cloud.r-project.org") }
if("cowplot" %in% rownames(installed.packages()) == FALSE)
{install.packages("cowplot", repos="https://cloud.r-project.org") }
library(ggplot2)
library(cowplot)

p1 <- ggplot(a, aes(x = len, color="z") ) + geom_histogram(fill = "white")  + 
   theme_classic() + 
   geom_vline(data = means, aes(xintercept = meanlen) , linetype = "dashed") + 
   xlab("read len") + 
   ylab("count") + 
   scale_color_brewer(palette="Dark2") + theme(legend.position="none")


p2 <- ggplot(a, aes(x = GC, color = "a") ) + geom_histogram(fill = "white")  + 
   theme_classic() + 
   geom_vline(data = means, aes(xintercept = meanGC) , linetype = "dashed") + 
   xlab("GC percent") + 
   ylab("count") + 
   scale_color_brewer(palette="Spectral") + theme(legend.position="none")


pdf(file = paste0(dir, "hist.len_GC.pdf"), 10,8)
plot_grid(p1,p2)
dev.off()

#add a check in case this fail 
