if("ggplot2" %in% rownames(installed.packages()) == FALSE)
{install.packages("ggplot2", repos="https://cloud.r-project.org") }
if("dplyr" %in% rownames(installed.packages()) == FALSE)
{install.packages("dplyr", repos="https://cloud.r-project.org") }
#if("svglite" %in% rownames(installed.packages()) == FALSE)
#{install.packages("svglite", repos="https://cloud.r-project.org") }



library(ggplot2)
library(dplyr)

read_len <- read.table("all.length.txt.gz")
colnames(read_len) <- c("assembly","len")

#compute mean by group
p <- read_len %>%
  group_by(assembly) %>%
  mutate(mean_x = mean(len)) %>%
  ggplot(., aes(len, fill = assembly, colour = assembly)) + geom_histogram(alpha = 0.5) +
       geom_vline(aes(xintercept = mean_x), col = "red") +
        facet_wrap(~assembly, scales='free') +
        labs(title='Lenght Plot', x='Length', y='frequencies') +
        theme_classic()


ggsave("plot.length.pdf", p , dpi = 400, units = "cm", width = 30, height = 25)

p_trimm <- p +  xlim(c(0,2e4))

ggsave("plot.length_trimmed.pdf", p_trimm , dpi = 400, units = "cm", width = 30, height = 25)

#ggsave("plot.length2.svg", p + theme_classic() , dpi = 400, units = "cm", width = 30, height = 25)


### stats:
read_len %>%
  group_by(assembly) %>%
  summarise(mean = mean(len), med = median(len), quantiles = quantile(len))

#export quantile for eventual use in chopper
write.table(quantile(assembly$len,0.15), "quantile.len0.15", quote = F, sep="\t",col.names=F)
