source directory_list.txt #set to file containing directories

echo 'This is CONCOMPRA 0.0.1'

mkdir -p temporary/filteredPAFs
for file in *.fastq; do awk -v min=$MIN -v max=$MAX 'BEGIN {FS = "\t" ; OFS = "\n"} {header = $0 ; getline seq ; getline qheader ; getline qseq ; if (length(seq) >= min && length(seq) <= max) {print header, seq, qheader, qseq}}' < $file |tr -d " " > temporary/"$file" ; done
for file in *.fastq; do
    ((i=i%THREADS)); ((i++==0)) && wait
    bash $TEMPLATE_DIR/consensus_generation.sh "$file" directory_list.txt &
done
#find . -name "*.fastq" | parallel -j $THREADS bash $TEMPLATE_DIR/consensus_generation.sh {} $directory_list
wait

mkdir -p results

find ./temporary -name *.all_consensus.fasta -exec cat {} + > results/all_consensus.fasta


#join consensus sequences across samples
vsearch -cluster_fast results/all_consensus.fasta -id $MERGE_CONSENSUS --relabel_keep -consout results/clustered_consensus.fasta
awk -i inplace '/^>/ {
    split($0, a, ";");
    split(a[1], b, "=");
    print ">" b[2];
    next;
}
{print}' results/clustered_consensus.fasta #return headers of the fasta to the original format, remove additional info from cluster_fast


minimap2 -d temporary/across_sample_consensus_sequences.mmi results/clustered_consensus.fasta
mkdir -p unmapped # folder for any unmapped reads

#map reads to the consensus sequences
for file in *.fastq;
do
	cd temporary
	CLEAN_NAME="${file%.*}" 
	NO_DIR_NAME="${file##*/}"
	minimap2 -x map-ont -t $THREADS --secondary=no -K 20M across_sample_consensus_sequences.mmi $CLEAN_NAME/$file > $CLEAN_NAME.paf
	RES=$(echo "scale=4; $MIN*0.9" | bc)
	$TEMPLATE_DIR/filterPAF_strict.py -i $CLEAN_NAME.paf -b $RES -m 10 > $CLEAN_NAME.CONCOMPRA.paf

	#split of the unmapped reads
	cut  -f1 $CLEAN_NAME.CONCOMPRA.paf |uniq > $CLEAN_NAME.CONCOMPRA.ls
	awk '{if(NR%4==1) print $1, $5}' $CLEAN_NAME/$file | sed -e "s/^@//" | awk '{$1=$1};1' > $CLEAN_NAME.all.ls
	sort $CLEAN_NAME.CONCOMPRA.ls | uniq > $CLEAN_NAME.CONCOMPRA.ls.sorted
	sort $CLEAN_NAME.all.ls | uniq  > $CLEAN_NAME.all.ls.sorted
	comm -1 -3 $CLEAN_NAME.CONCOMPRA.ls.sorted $CLEAN_NAME.all.ls.sorted > $CLEAN_NAME.unmapped.ls
	seqtk subseq $CLEAN_NAME/$file $CLEAN_NAME.unmapped.ls > ../unmapped/$NO_DIR_NAME
	cd ..
done

mv temporary/*.CONCOMPRA.paf temporary/filteredPAFs
$TEMPLATE_DIR/merfePAF.py -i temporary/filteredPAFs/ > results/otu_table.csv

#creates a pdf of the umpa-hdbscan graphical output
bash $TEMPLATE_DIR/cluster_pictures.sh

#detect chimeric sequences from the concat consensus sequence file 
##add sequence counts to the consensus sequences
###obtain the total sequence counts after mapping
awk -F, 'NR > 1 {
  sum = 0;   # Initialize a variable to store the sum
  for (i = 2; i <= NF; i++) {  # Loop through all fields from the 2nd column to the last
    if ($i ~ /^[0-9]+(\.[0-9]+)?$/) {  # Check if the field is numeric
      sum += $i;  # Add the numeric field to the sum
    }
  }
  print $1, sum;  # Print the first column and the sum
}' OFS=, results/otu_table.csv > temporary/otu_sum.csv

##add the total sequence counts to the sequence identifier
awk '
NR==1   { next }
BEGIN   { FS="," }                         # set the field separator to semicolon
FNR==NR { id[$1]=$2 }                      # load id[] with ID to header field mapping
FNR!=NR {
    if (/^>/) {
        ndx=substr($1,2)                  # strip off ">"
        if (ndx in id) {                  # if 1st field (sans ">") is an index in id[] then ...
            $1 = ">" ndx ";size=" id[ndx]  # rewrite 1st field to include our id[] value
        }
    }
    print                                  # print current line (of 2nd file)
}
' temporary/otu_sum.csv results/clustered_consensus.fasta > temporary/across_sample_consensus_sequences_size.fas

#identify chimeric sequences and write them to a seperate fasta file - alternative options for output are possible
vsearch --uchime_denovo temporary/across_sample_consensus_sequences_size.fas --nonchimeras results/nonglobal.consensus.sequences.fas --chimeras results/chimeric_consensus.sequences.fas --xsize


#remove previously detected chimeras
find ./temporary -name *nochim.consensus.fasta -exec cat {} + | grep '>'  | cut -f 1 -d ' ' |  sed 's/>//g'   > temporary/no_chim_OTUs.txt
seqtk subseq results/nonglobal.consensus.sequences.fas temporary/no_chim_OTUs.txt   > results/noglobal_nolocalchim.consensus.sequences.fas

seqtk subseq results/clustered_consensus.fasta  temporary/no_chim_OTUs.txt   > results/nolocalchim.consensus.sequences.fas


rm -rf clusterplots
rm -rf temporary  #hash out if any of the intermediate output would be of interest to you
#r import to phyloseq object or other workflow for post processing

