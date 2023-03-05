#!/usr/bin/env Rscript

library(DECIPHER)
library(tidyr)

args = commandArgs(trailingOnly=TRUE)

print(args[1])
setwd(args[1]) #from pwd
temp_fas = list.files(pattern="*.all_consensus.fasta")
sample.names <- sapply(strsplit(basename(temp_fas), ".", fixed=T), `[`, 1) #original

a=c()
#load files
for (i in 1:length(sample.names)) assign(paste(sample.names[i],'.seq', sep=''), readDNAStringSet(temp_fas[i]))
for (i in 1:length(sample.names))  {    
  tryCatch({
    assign(paste(sample.names[i],'.OTU', sep=''),
           read.table(paste(sample.names[i],'.readcount.txt', sep=''), sep=';', 
                      col.names=c("OTU_id","abundance"), nrow=nrow(read.table(paste(sample.names[i],'.readcount.txt', sep=''), sep=';'))-1))                                 
  }, error=function(e) {
    print(paste(as.character(sample.names[i]),'is empty'))
    a<<-c(a,sample.names[i])})
}

sample.names=sample.names[!sample.names %in% a];rm(a)

joined_table=data.frame(OTU_id=-1,sequence='',abundance=-1,sample_id='')
for (i in 1:length(sample.names)) {
  print(sample.names[i])
    joined_table=rbind(joined_table,data.frame(OTU_id=get(paste(sample.names[i],'.OTU', sep=''))['OTU_id'],
                                               sequence=as.vector(get(paste(sample.names[i],'.seq', sep=''))),
                                               abundance=get(paste(sample.names[i],'.OTU', sep=''))['abundance'],
                                               sample_id=sample.names[i]))
}

write.table(sample.names,file='sample_names.txt',sep='\t')


#to wide
joined_table<-joined_table[-which(joined_table$sequence==''),]

joined_table_long=joined_table %>%
  pivot_wider(names_from = sample_id, values_from = abundance, values_fill = 0)

joined_table_long=data.frame(joined_table_long)
row.names(joined_table_long)=paste('OTU',1:nrow(joined_table_long), sep='_')
dna_obj=DNAStringSet(joined_table_long$sequence)
names(dna_obj)=paste('OTU',1:nrow(joined_table_long), sep='_')
Biostrings::writeXStringSet(dna_obj,'joined_seq.fa')


rm(list=setdiff(ls(), c('joined_table_long')))
save.image("Rworkspace_sampleintegration.RData")
