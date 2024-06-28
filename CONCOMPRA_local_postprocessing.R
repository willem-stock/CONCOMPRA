#this script proves an example on how to process the output from CONCOMPRA from a single run and from multiple runs
#IdTaxa from the Decipher package is used for taxonomic identification; Trained classifiers for this tool can be downloaded here:http://www2.decipher.codes/Downloads.html
library(DECIPHER); packageVersion("DECIPHER")
library(phyloseq) packageVersion('phyloseq')
library(tibble);library(tidyr) 
setwd("") #set to the directory containing the CONCOMPRA output

load("")# load train classifier Rdata file load(".../SILVA_SSU_r138_2019.RData") 

tax_assign = function(seqs) {
  ids_CONCOMPRA <- IdTaxa(seqs, trainingSet, strand="both", processors=4, verbose=T, threshold=40) 
  ranks <- c("domain", "phylum", "class", "order", "family", "genus", "species") # ranks of interest
  # Convert the output object of class "Taxa" to a matrix analogous to the output from assignTaxonomy
  taxid_CONCOMPRA <- t(sapply(ids_CONCOMPRA, function(x) {
    m <- match(ranks, x$rank)
    taxa <- x$taxon[m]
    taxa[startsWith(taxa, "unclassified_")] <- NA
    taxa
  }))
  colnames(taxid_CONCOMPRA) <- ranks
  return (taxid_CONCOMPRA)
}

#for a single run (having a single consensus sequence file and otu_table, which can contain multiple samples)
OTU =  read.csv('ill.otu_table.csv', header = TRUE, sep=',')
OTU =  column_to_rownames(OTU,'X.OTU.ID') %>% as.matrix
consensus_seq = readDNAStringSet("ill.noglobal_nolocalchim.consensus.sequences.fas")
consensus_tax = tax_assign(consensus_seq)
#in case taxonomy was assigned with vsearch:
concompra_physeq = phyloseq(tax_table(consensus_tax),otu_table(OTU,taxa_are_rows=T), refseq(consensus_seq))
# add/adjust sample data as required (optional)
sample_data(concompra_physeq)=data.frame(sample_id=unlist(strsplit(sample_names(concompra_physeq),split='.CONCOMPRA')),
                                         analysis='CONCOMPRA',row.names = sample_names(concompra_physeq) )



#for multiple runs (having multiple consensus sequence files and otu_table files) ####
#this script assumes that all otu tables are named SAMPLEID.otu_table.csv and that the matching consensus sequence file is called SAMPLEID.noglobal_nolocalchim.consensus.sequences.fas 
#this will load and process all files in the current working directory
temp = list.files(pattern="*.otu_table.csv") #this should find all otu tables (adjust if you have named the otu tables differently)
for (i in 1:length(temp)) { #merge all CONCOMPRA output files with tax info
  id = unlist(strsplit(temp[i],split='.otu_table.'))[1]
  assign(paste(id,'_OTU',sep=""), read.csv(temp[i], header = TRUE, sep=','))
  assign(paste(id,'_OTU',sep=""), column_to_rownames(get(paste(id,'_OTU',sep="")),'X.OTU.ID') %>% as.matrix)
  assign(paste(id,'_seq',sep=""),readDNAStringSet(paste(id,".noglobal_nolocalchim.consensus.sequences.fas", sep="")))
  assign(paste(id,'_seq',sep=""),tax_assign(get(paste(id,'_seq',sep=""))))
  assign(paste("CONCOMPRA_",id,sep=""),phyloseq(tax_table(get(paste(id,'_seq',sep=""))),otu_table(get(paste(id,'_OTU',sep="")),taxa_are_rows=T)))
}

phyloseqlist_concompra=ls(pattern="CONCOMPRA_")
physeq_list <- lapply(phyloseqlist_concompra, get)

for (i in seq_along(physeq_list)) { #this creates unique taxon names
  taxa_names(physeq_list[[i]])<-paste(taxa_names(physeq_list[[i]]),'uni',as.character(i))
}
combined_concompra_physeq <- do.call(merge_phyloseq, physeq_list) #create a single phyloseq object with all the data
# add/adjust sample data as required (optional)
sample_data(combined_concompra)=data.frame(sample_id=unlist(strsplit(sample_names(combined_concompra_physeq),split='.CONCOMPRA')),analysis='CONCOMPRA',row.names = sample_names(combined_concompra_physeq) )

#all data are now in a single phyloseq object

#optional processing steps ####
combined_concompra_physeq_genus = tax_glom(combined_concompra_physeq,'genus') #merges OTUs that have the same taxonomy at a certain taxonomic rank
combined_concompra_physeq_genus = transform_sample_counts(combined_concompra_physeq_genus, function(x) 100 * x/sum(x)) #transform the reads counts to % [0-100] relative abundances
