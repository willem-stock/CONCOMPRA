# CONCOMPRA
consensus approach for community profiling with nanopore amplicon sequencing data

## Table of contents
* [General info](#general-info)
* [Installation](#installation)
* [Running CONCOMPRA](#running-concompra)



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
```
conda env create -f CONCOMPRA.yml
```
this is likely to take a few minutes resolve the environment (if this takes too long, consider updating conda or switch to mamba) 
* make sure that you can execute the scripts
```
chmod +x $CONCOMPRA_dir/scripts/*py
chmod +x $CONCOMPRA_dir/scripts/primer-chop/bin/primer-chop
chmod +x $CONCOMPRA_dir/scripts/primer-chop/bin/primer-chop-analyze
```
* prepare the folder with the fastq files you want to process. move or copy the directory_list.txt' to this folder
* provide the primer sequences in a fasta file (see info on how to format in the 'directory_list.txt' file)


## Running CONCOMPRA

The current version only works with uncompressed fastq files
* activate the conda environement
```
conda activate CONCOMPRA
```
* with the folder containing the fastqs as your present working directory: excute the main.sh in the script directory 

```
bash ../scripts/main.sh
```
As it may take 15-30 min/sample, it is advised use a tmux session, screen or nohup (so you disconnect from the terminal)

```
nohup bash ../scripts/main.sh &
```

this will generate a nohup.out where you can monitor the process

[remark: if the analyses is halted whilst not all files in a folder have been processed, just execute the main.sh again as it will skip the files which have been processed]

* the output files can be further processed with phyloseq in R (an r script is available in this reposatory to get you started: CONCOMPRA_local_postprocessing.R)
