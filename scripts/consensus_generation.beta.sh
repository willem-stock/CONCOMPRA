source directory_list.txt

FASTQ_FILE=$1 #name of the fastq to process
CLEAN_NAME="${FASTQ_FILE%.*}"

cd temporary
echo $CLEAN_NAME
mkdir $CLEAN_NAME
cp $FASTQ_FILE $CLEAN_NAME/.
cd $CLEAN_NAME

if [ -f $CLEAN_NAME.all_consensus.fasta ]
then
    if [ -s $CLEAN_NAME.all_consensus.fasta ]
    then
        echo "File exists and not empty"
		exit
    else
        echo "File exists but empty"
    fi
else
    echo "File not exists"
fi
     echo "File empty"


READ_COUNT=$(( $(awk '{print $1/4}' <(wc -l $FASTQ_FILE)) ))
echo -n "total;$READ_COUNT" > total.log

#keep only first 20,000 reads
head -80000 $FASTQ_FILE >temp.fastq

#optional step to reorient reads
conda activate $CONDA_DIR/ssu-align
vsearch --orient temp.fastq --db $RESOURCE_DIR/$REF_SEQ --fastqout $CLEAN_NAME.plus.fastq

rm temp.fastq

conda activate $CONDA_DIR/kmer_freq
$TEMPLATE_DIR/kmer_freq_manual.py $CLEAN_NAME.plus.fastq > freqs.txt # process read_clustering
conda activate $CONDA_DIR/read_clustering
$TEMPLATE_DIR/umap_hdbscan_manual_sensitive.beta.py freqs.txt  #replacing umap_hdbscan_manual.py for more clusters


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

awk '/^>/ {gsub(/.consensus.fasta?$/,"",FILENAME);printf(">%s\n",FILENAME);next;} {print}' *.consensus.fasta > $CLEAN_NAME.all_consensus.fasta


