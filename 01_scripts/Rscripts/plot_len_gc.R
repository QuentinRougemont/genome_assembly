
#plot read length and gc content and make a table from it
#--------------- check if library are installed -------------------------------#
packages <- c('ggplot2','cowplot','gtsummary','flextable','rsvg')
install.packages(setdiff(packages, rownames(installed.packages())), repos="https://cloud.r-project.org" )
#---------------- load libraries ---------------------------------------------#
invisible(lapply(packages, suppressWarnings(suppressMessages(suppressPackageStartupMessages(library))), character.only = TRUE))

argv <- commandArgs(T)
 
a <- read.table(argv[1])
dir <- dirname(argv[1])

means <- data.frame(t(colMeans(a[,c(2,4)])))
colnames(means) <- c("meanlen","meanGC")

a <- a[,-c(1,3)]

colnames(a)<-c("len","GC")

a$trt <- gsub('.len.gc.gz','', basename(argv[1]) )
species <-gsub('.len.gc.gz','', basename(argv[1]) )

#creata a small summary table
t <- tbl_summary(a, 
            by = trt, 
            label=list(len ~"read length (bp)", GC ~ "%GC") , 
            type = c(len, GC) ~ "continuous2",    
            statistic = all_continuous2() ~ c("{median} ({p25} - {p75}", "{mean} ({sd})", "{min} - {max}"), 
            digits = all_continuous() ~ 2 ) %>%
    modify_header(label ~ "**Genome**") %>%
            bold_labels() %>% 
            italicize_levels()

save_as_image(as_flex_table(t), paste0(dir,"/", species,"_read.summary.stats.svg"), res = 300)
rsvg_pdf(paste0(dir,"/", species,"_read.summary.stats.svg"), file = paste0(dir,"/", species,"_read.summary.stats.pdf"))

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
