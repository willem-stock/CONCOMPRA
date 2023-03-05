source directory_list.txt

FASTQ_FILE=$1 #name of the fastq to process
neighbors=$2
clustersize=$3
minsamples=$4
epsilon=$5
CLEAN_NAME="${FASTQ_FILE%.*}"

mkdir temp_para
cp temporary/$CLEAN_NAME/$CLEAN_NAME.plus.fastq temp_para
cp temporary/$CLEAN_NAME/freqs.txt temp_para
cd temp_para

conda activate $CONDA_DIR/read_clustering
echo $neighbors $clustersize $minsamples $epsilon
$TEMPLATE_DIR/umap_hdbscan_manual_sensitive.beta.py freqs.txt $neighbors $clustersize $minsamples $epsilon

CLUSTERS_CNT=$(awk '($5 ~ /[0-9]/) {print $5}' freqs.txthdbscan.output.tsv | sort -nr | uniq | head -n1)
conda activate $CONDA_DIR/split_by_cluster
for ((i = 0 ; i <= $CLUSTERS_CNT ; i++));
do
    cluster_id=$i
    awk -v cluster="$cluster_id" '($5 == cluster) {print $1}' freqs.txthdbscan.output.tsv > $cluster_id\_ids.txt
    seqtk subseq $CLEAN_NAME.plus.fastq $cluster_id\_ids.txt > $cluster_id.fastq
    READ_COUNT=$(( $(awk '{print $1/4}' <(wc -l $cluster_id.fastq)) ))
    echo -n "$cluster_id;$READ_COUNT" > $cluster_id.log
done
echo 'split_by_cluster done'

conda activate $CONDA_DIR/consensus_align
for ((i = 0 ; i <= $CLUSTERS_CNT ; i++));
do
    cluster_id=$i
	head -160 $cluster_id.fastq > $cluster_id.crop.fastq
    lamassemble $RESOURCE_DIR/$lass_lasttrain $cluster_id.crop.fastq > $cluster_id.consensus.fasta
	rm $cluster_id.crop.fastq
done
echo 'read consensus created'

#$cluster_id.contigs.fasta

paste --delimiter=\\n --serial *.log > $CLEAN_NAME.readcount.txt

awk '/^>/ {gsub(/.consensus.fasta?$/,"",FILENAME);printf(">%s\n",FILENAME);next;} {print}' *.consensus.fasta > $CLEAN_NAME.$neighbors.$clustersize.$minsamples.$epsilon.all_consensus.fasta

mv $CLEAN_NAME.$neighbors.$clustersize.$minsamples.$epsilon.all_consensus.fasta ../results_para
mv freqs.txthdbscan.output.png ../results_para/$CLEAN_NAME.$neighbors.$clustersize.$minsamples.$epsilon.hdscan.png

rm -rf temp_para
