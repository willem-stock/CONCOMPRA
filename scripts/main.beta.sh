source directory_list.txt #set to file containing directories

file=$1
#neighbors=$2
#clustersize=$3
#minsamples=$4
#epsilon=$5

mkdir temporary
conda activate $CONDA_DIR/preprocess
NanoFilt  -l 1200 --maxlength 1700 $file > temporary/$file
bash $TEMPLATE_DIR/consensus_generation.beta.prep.sh $file directory_list.txt
mkdir results_para
for neighbors in {10,}; do for clustersize in {20,30}; do for minsamples in {5,10,15}; do for epsilon in {0.3,0.5,0.7}; do \
bash $TEMPLATE_DIR/consensus_generation.beta.parap.sh $file $neighbors $clustersize $minsamples $epsilon; done; done; done; done;

bash $TEMPLATE_DIR/blast.beta.sh


