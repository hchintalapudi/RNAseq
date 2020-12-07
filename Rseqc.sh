#!/bin/bash
##########################
#Author:Himanshu
#Date:11/12/2019
#This program accepts required input and creates different folders if donot exist as required 
# and performs rseqc
# input directory path for bam file. (bam files need to be indexed and .bain should be in the same directory)
# absolute path for bed file.
##########################
# required parameters
proj_dir=$1
bam_path=$2
bedfile=$3
threads=$4
script="Rseqc.sh"
# check for correct number of arguments.
if [ "$#" -lt 4 ]; then
        echo -e "\n ERROR:Wrong number of arguments supplied for $script \n" >&2
        echo -e "\n USAGE: $script project_dir sample fastq threads \n" >&2
        exit 1
fi

output="${proj_dir}/RSeQC"
mkdir -p "$output"
# get bam files as list and use GNU parallel to run rseqc.
Rseqc_cmd="find $bam_path -type f -name '*.bam' | parallel -j 10 geneBody_coverage.py -r $bedfile -i{} -o{}"
echo "CMD: $Rseqc_cmd"
eval "$Rseqc_cmd"
wait
eval "mv $bam_path/*.txt $output"
eval "mv $bam_path/*.pdf $output"
