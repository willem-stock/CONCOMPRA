#automate processing of fasta hits

REFERENCE='/media/HD3/home/student3/nanopore_wd/resources/mockdb/mock_shortheaders.fasta'
MIN_LENGTH=1400 #set the alignment lenght for which the blast match can be considered a good match

cd results_para

echo "blast results from parameter optimization"

echo "-----------------------------------------"
printf "%s: %s\n" "nr of sequencing in reference file " "$(grep ">" $REFERENCE | wc -l)"
echo $MIN_LENGTH
echo -e "\n"


for file in *.all_consensus.fasta
do
CLEAN_NAME="${file%.*}"
makeblastdb -in $file -parse_seqids -dbtype nucl 1> /dev/null
blastn -query $REFERENCE -db $file -num_alignments 1  -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore" -out $CLEAN_NAME.blastout
awk '!(($4 <= 1400)) ;' $CLEAN_NAME.blastout  > f_$CLEAN_NAME.blastout
echo $CLEAN_NAME
printf "%s: %s\n" "nr of OTUs created " "$(grep ">" $file | wc -l)"
printf "%s: %s\n" "nr of ref sequences with a sufficiently long hit " "$(wc -l < f_$CLEAN_NAME.blastout)"
printf "%s: %s %s\n" "av ref to otu similarity for good matches " "$(awk ' $3 >= 95 { total += $3;div += 1}  END { print total/div; print div}' f_$CLEAN_NAME.blastout)" "sequences with a good match"
echo -e "\n"
done
