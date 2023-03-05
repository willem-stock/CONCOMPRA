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


