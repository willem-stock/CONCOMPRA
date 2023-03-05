#5jul22 phylogeny and usearch tax
source directory_list.txt
FASTA_FILE=$1 #name of the fastq to process

conda activate $CONDA_DIR/ssu-align

ssu-prep -x $FASTA_FILE phylo_results 4
bash phylo_results.ssu-align.sh

ssu-mask phylo_results
ssu-mask --stk2afa phylo_results
ssu-draw phylo_results

FastTree -nt < phylo_results/phylo_results.bacteria.afa > tree.nwk

vsearch --sintax $FASTA_FILE --db $RESOURCE_DIR/$REF_SEQ --tabbedout reads.sintax

bash $TEMPLATE_DIR/transform_sintax.sh reads.sintax

mv tree.nwk results/
mv reads.sintax results/
