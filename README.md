# CONCOMPRA
consensus approach for community profiling with nanopore amplicon sequencing data

## Table of contents
* [General info](#general-info)
* [Installation](#installation)
* [Running CONCOMPRA](#running-concompra)



## General info
This project is still under construction

## Installation

* download and install conda if you do not have it yet (if you have freshly installed conda, refresh your session)
* retrieve this repository using git [or simply download the files]:
```
git clone https://github.com/willem-stock/CONCOMPRA.git
```
* create the conda environments from the yml files
[execute in  the conda_environments directory]
```
find . -name "*yml" -exec conda env create -f {} \;
```
this is likely to take a few minutes

* download and setup an appropriate vsearch compatible reference databse for your amplicon  

```
wget https://www.drive5.com/sintax/rdp_16s_v16_sp.fa.gz
gunzip rdp_16s_v16_sp.fa.gz
conda activate ssu-align
vsearch --makeudb_usearch rdp_16s_v16_sp.fa --output rdp_v16_sp.udb
```

* edit directory_list.txt to have the appropriate paths 

## Running CONCOMPRA

The current version only works with uncompressed fastq files

* adjust the minimal and maximal allowed read length in function of your amplicon in the mainsh script in the scripts directory [NanoFilt  -l MIN_LENGTH --maxlength MAX_LENGTH]
* move or copy the directory_list.txt to the folder containing all fastq files that need to be analysed
* with the folder containing the fastqs as your present working directory: excute the main.sh in the script directory 

```
bash ../scripts/main.sh
```
it is advised the use the detaches the command from the terminal if you are analysing many files simultaneously

```
nohup bash ../scripts/main.sh &
```

this will generate a nohup.out where you can monitor the process

[remark: if the analyses is halted whilst not all files in a folder have been processed, just execute the main.sh again as it will only process files which have not been processed yet]

* the output files can be further processed with phyloseq in R (an r script is available in this reposatory to get you started: CONCOMPRA_local_postprocessing.R ]
