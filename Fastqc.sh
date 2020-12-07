#!/bin/bash
##########################
#Author:Himanshu
#Date:11/12/2019
#This program accepts required input and creates different folders if donot exit as required 
# and performs fastqc 
##########################
# required parameters
proj_dir=$1
fastq=$2
threads=$3

script="Fastqc.sh"
# check for correct number of arguments.
if [ "$#" -lt 3 ]; then
        echo -e "\n ERROR:Wrong number of arguments supplied for $script \n" >&2
        echo -e "\n USAGE: $script project_dir sample fastq threads \n" >&2
        exit 1
fi

output="${proj_dir}/FastQC"
mkdir -p "$output"

# run FASTQC

#fastqc_cmd="fastqc \
#--quiet \
#--threads $threads \
#--outdir $output \
#$fastq
#"
# run fastqc on all files of the folder. Input folder containing fastqs instead of file paths.
parallel_fastqc="find $fastq -type f -name '*.fastq.gz' | parallel -j $threads fastqc --quiet --outdir $output {}"
echo "CMD: $parallel_fastqc"

eval "$parallel_fastqc"


#end
