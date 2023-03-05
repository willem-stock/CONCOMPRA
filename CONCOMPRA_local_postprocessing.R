#CONCOMPRA postprocessing script WStock 5march23


install.packages('ape')
#align with ssu-align & tree construction with FastTree2 #library(ape)
tree16S<-ape::read.tree('tree.nwk')
#plot(tree16S)

#taxonomic assignment-vsearch
vsearch_sintax_out <- read.delim("reads.sintax", header=T,fill=T, row.names = 1)
vsearch_sintax_out<-as.matrix(vsearch_sintax_out)

# -> to phyloseq -> merge
#https://joey711.github.io/phyloseq/install.html
library(phyloseq) #version?

OTU = otu_table(seqs_nochim_long[3:ncol(seqs_nochim_long)], taxa_are_rows = TRUE)
TAX=tax_table(vsearch_sintax_out)
sample_data=read.table("sample_meta_Loes16S4jul22.txt",sep='\t', header=T, row.names = 1)
which(!rownames(sample_data)%in%colnames(seqs_nochim_long)[3:ncol(seqs_nochim_long)])

phylo=phyloseq(OTU,TAX, sample_data(sample_data),tree16S) 

phylo_merge=tax_glom(phylo,taxrank='genus') #merge OTUs based on taxonomic identification
phylo_merge=tip_glom(phylo,h = 0.05) #merge OTUs based on phylogenetic tree 
