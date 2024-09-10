# CONCOMPRA
consensus approach for community profiling with nanopore amplicon sequencing data

## Table of contents
* [General info](#general-info)
* [Installation](#installation)
* [Running CONCOMPRA](#running-concompra)
* [Optimising](#optimising)
* [Output](#output)



## General info
This project is still under construction

## Installation

* download and install conda/mamba if you do not have it yet (if you have freshly installed conda, don't forget to refresh your session)
* retrieve this repository using git [or simply download the files]:
```
git clone https://github.com/willem-stock/CONCOMPRA.git
```
* create the conda environments from the yml file
[execute in  the conda_environments directory]
> [!NOTE]
> a directory CONCOMPRA should have been created in your path. For the steps that follow, either replace '$CONCOMPRA_dir' by the path to this directory or assign the path to the variable 'CONCOMPRA_dir'  like this ```CONCOMPRA_dir="/home/user/CONCOMPRA/"``` and just copy the commands
```
conda env create -f $CONCOMPRA_dir/CONCOMPRA.yml
```
this is likely to take a few minutes resolve the environment (if this takes too long, consider updating conda or switch to mamba) 
* make sure that you can execute the scripts
```
chmod +x $CONCOMPRA_dir/scripts/*py
chmod +x $CONCOMPRA_dir/scripts/primer-chop/bin/primer-chop
chmod +x $CONCOMPRA_dir/scripts/primer-chop/bin/primer-chop-analyze
```
* prepare the folder with the fastq files you want to process
* move or copy the directory_list.txt' to this folder. Adjust the directories in this file and set the sequence length window
* provide the primer sequences in a fasta file (see info on how to format in the 'directory_list.txt' file; and example file is proved in the CONCOMPRA directory)
> [!TIP]
> a small 16S rRNA gene dataset is available for testing on [figshare](https://doi.org/10.6084/m9.figshare.26139061.v1)


## Running CONCOMPRA

CONCOMPRA works with uncompressed (.fastq) and compressed (.fastq.gz) files
* activate the conda environement
```
conda activate CONCOMPRA
```
* with the folder containing the fastqs as your present working directory: excute the main.sh in the script directory 

```
bash $CONCOMPRA_dir/scripts/main.sh
```
As it may take 5-30 min/sample, it is advised use a tmux session, screen or nohup (so you disconnect from the terminal)

```
nohup bash $CONCOMPRA_dir/scripts/main.sh &
```

this will generate a nohup.out where you can monitor the process

> [!NOTE]
> if the analysis is halted whilst not all files in a folder have been processed, just execute the main.sh again as it will skip the files which have already been processed

## Optimising
* using the sequences of not only the primers, but also the anchor sequences in the primer sequence file (primer_set.fa ) will likely improve the results
* only identical consensus sequences will be merged under the default settings. You decide to merge highly similar sequences by setting the MERGE_CONSENSUS parameter in directory_list.txt
* you can change the number of threads used though the THREADS parameter in directory_list.txt
* you can change the number of reads used per cluster to draw the consensus sequences though the READS_CONSENSUS parameter in directory_list.txt. If you expect very few errors, reducing this parameter will increase the speed and whilst likely retaining the precision  
* although the default clustering parameters have been chosen based on tests with various amplicons and sequencing chemistries, it could be that these are not ideal for your data. You can experiment with different parameters by changing these in the kmer_umap_OPTICS python script. Have a look at [UMAP](https://umap-learn.readthedocs.io/en/latest/) and [OPTICS](https://scikit-learn.org/stable/modules/generated/sklearn.cluster.OPTICS.html) to see how changing these parameters can influence the clustering.   

## Output
A result directory will be created in which there will be the most relevant files created by CONCOMPRA:
* a fasta file labelled all_consensus: this file contains all consensus sequences generated across the different samples (the sample names are incorporated in the sequence identifier)
* a fasta file labelled clustered_consensus: this file contains the consensus sequences, generated across the different samples, clustered according to the similarity you have set in the directory_list file (default is 1)
* a fasta file labelled noglobal_nolocalchim.consensus.sequences: this file contains the non-chimeric sequences consensus sequences, clustered according to the similarity you have set in the directory_list file  [this will likely be the file you'll want to use]
* the fasta files nolocalchim.consensus & noglobal_nolocalchim.consensus which contain the clustered consensus files not considered to be chimeric based on within sample chimeric check/global chimeric check respectively
* a fasta file labeled chimeric_consensus.sequences: contains the clustered consensus sequences flagged as chimeric based on the global chimeric check 
* the plots of the UMAP results (colours are used to indicate the different clusters; note that each dot is a sequence but only sequences used for generating consensus sequences are shown)
* the OTU table in the format of a comma-separated text file (easy to open in any text editor, Excel, R,..). Note that the OTUs in this file are the sequences in clustered_consensus fasta file   

The reads that failed to map to the consensus sequences are in the unmapped folder


The output files can be further processed with phyloseq in R (an r script is available in this repository to get you started: CONCOMPRA_local_postprocessing.R)
> [!TIP]
> You can use vsearch (which is present in the CONCOMPRA environment) to assign a taxonomy to your consensus sequences. 
> For this, you'll have to:
> * download one of the [available reference databases](https://www.drive5.com/usearch/manual/sintax_downloads.html)
> * create a UDB database file 
> ```
> vsearch -makeudb_usearch $DATABASE.gz -output $DATABASE.udb
> ```
> * generate taxonomic annotations
> ```
> vsearch --sintax $FASTA_FILE --db $DATABASE.udb --tabbedout reads.sintax
> ```
