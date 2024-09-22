source directory_list.txt

FASTQ_FILE=$1 #name of the fastq to process
CLEAN_NAME="${FASTQ_FILE%.*}"

cd temporary
echo $CLEAN_NAME
mkdir $CLEAN_NAME
cp $FASTQ_FILE $CLEAN_NAME/.
cd $CLEAN_NAME

#skip fastq if the consensus fasta has already been created
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
    :
fi
     :

#total nr of reads/fastq
READ_COUNT=$(( $(awk '{print $1/4}' <(wc -l $FASTQ_FILE)) ))
echo -n "total;$READ_COUNT" > total.log

#searches and trims primers
$TEMPLATE_DIR/primer-chop/bin/primer-chop -q $PRIMER_SET $FASTQ_FILE primerchop_out

#retain only the highest quality reads
filtlong --keep_percent 80 primerchop_out/good-fwd.fq > primerchop_out/good-fwd.filt.fq

vsearch -fastq_filter primerchop_out/good-fwd.filt.fq --fastaout primerchop_out/good-fwd.filt.fa --fastq_qmax 90

#kmer count in the forward oriented reads with forward and reverse primers detected
python $TEMPLATE_DIR/kmer_umap_OPTICS.py primerchop_out/good-fwd.filt.fa $THREADS
CLUSTERS_CNT=$(awk '($2 ~ /[0-9]/) {print $2}' freqs.txthdbscan.output.tsv | sort -nr | uniq | head -n1)

echo "drafting consensus sequences for $CLEAN_NAME"

for ((i = 0 ; i <= $CLUSTERS_CNT ; i++));
do
    cluster_id=$i
    awk -v cluster="$cluster_id" '($2 == cluster) {print $1}' freqs.txthdbscan.output.tsv > $cluster_id\_ids.txt
done

process_cluster() {
    cluster_id=$1
    seqtk subseq primerchop_out/good-fwd.filt.fa "${cluster_id}_ids.txt" > "${cluster_id}.fas"
    READ_COUNT=$(( $(awk '{print $1/2}' <(wc -l "${cluster_id}.fas")) ))
    seqtk sample "${cluster_id}.fas" "${READS_CONSENSUS}"| lamassemble primerchop_out/train.txt - > "${CLEAN_NAME}${cluster_id}@size=${READ_COUNT}@.consensus.fasta"
}

for ((i = 0 ; i <= $CLUSTERS_CNT ; i++)); do
    process_cluster "$i" &
    ((j=j%THREADS)); ((j++==0)) && wait
done
wait


echo "consensus sequences generated for $CLEAN_NAME"

awk '/^>/ {gsub(/.consensus.fasta?$/,"",FILENAME);printf(">%s\n",FILENAME);next;} {print}' *.consensus.fasta > $CLEAN_NAME.all_consensus.fasta
sed -i 's/@/;/g' $CLEAN_NAME.all_consensus.fasta

vsearch --uchime_denovo $CLEAN_NAME.all_consensus.fasta --nonchimeras $CLEAN_NAME.nochim.consensus.fasta --chimeras $CLEAN_NAME.chim.consensus.fasta --xsize



