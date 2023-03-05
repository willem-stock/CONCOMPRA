source directory_list.txt #set to file containing directories


mkdir temporary
conda activate $CONDA_DIR/preprocess
for file in *.fastq; do NanoFilt  -l 1200 --maxlength 1700 "$file" > temporary/"$file" ; done
for file in *.fastq; do bash $TEMPLATE_DIR/consensus_generation.sh "$file" directory_list.txt ; done

mkdir results

find ./temporary -name *.readcount.txt -exec cp {} results \;
find ./temporary -name *.all_consensus.fasta -exec cp {} results \;


#r exported fasta file -> create alignment file
conda activate $CONDA_DIR/R_phylo
Rscript $TEMPLATE_DIR/sample_integration.R $(pwd)/results
	# pass results to working directory: OTUtable; dna_seqs
	# packages DECIPHER; tidyr; Biostrings


bash $TEMPLATE_DIR/phylogeny_usearchtax.sh results/joined_seq.fa

bash $TEMPLATE_DIR/cluster_pictures.sh

#r import to phyloseq object
