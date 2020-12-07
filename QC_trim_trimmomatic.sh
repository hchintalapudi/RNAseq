#!/bin/bash
##########################
#Author:Himanshu
#Date:11/12/2019
#This program accepts required input and creates different folders if donot exit as required 
# and performs quality control and read trimming using trimmomatic
# works for PE and SE.
##########################

proj_dir=$1
sample=$2
threads=$3
fastq1=$4
fastq2=$5

##############################
script="QC_trim_trimmomatic.sh"
# check for correct number of arguments.
# checking for 4 to consider SE reads.
if [ "$#" -lt 4 ]; then
        echo -e "\n ERROR:Wrong number of arguments supplied for $script \n" >&2
        echo -e "\n USAGE: $script project_dir sample threads fastq[or fastq's]  \n" >&2
        exit 1
fi
######################################
# directory for trimmed files
trim_dir="${proj_dir}/Trimmed"
mkdir -p "$trim_dir"
# directory for trimmomatic logs.
trim_log_dir="${proj_dir}/Trimmomatic_Logs"
mkdir -p "$trim_log_dir"
# log file
trim_log="${trim_log_dir}/${sample}.txt"

# adapter files:
adapters1="/dartfs-hpc/rc/lab/L/LeachLab/HIMANSHU/adapters/TruSeq3-PE.fa"
adapters2="/dartfs-hpc/rc/lab/L/LeachLab/HIMANSHU/adapters/NexteraPE.fa"

# define output files.
fastq1_trim="$trim_dir/${sample}_R1_trimmed.fastq.gz"
fastq2_trim="$trim_dir/${sample}_R2_trimmed.fastq.gz"
fastq1_trim_unpaired="$trim_dir/${sample}_R1_trim_unpaired.fastq.gz"
fastq2_trim_unpaired="$trim_dir/${sample}_R2_trim_unpaired.fastq.gz"
#################################################################
# Run Trimmomatic:

# check for input parameters to either run trimmomatic in SE or PE mode.
# run trimmomatic in PE mode if two fastqs(fastq2 not empty) are supplied else in SE
if [ -n "$fastq2" ] ; then
    echo "Running Trimmomatic in PE Mode"
    run_type="PE"
    files_args="$fastq1 $fastq2 $fastq1_trim $fastq1_trim_unpaired $fastq2_trim $fastq2_trim_unpaired"
else
    run_type="SE"
    files_args="$fastq1 $fastq1_trim"
fi


bash_cmd="trimmomatic \
$run_type \
-threads $threads \
$files_args \
ILLUMINACLIP:$adapters1:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:35 \
2>$trim_log
"
echo "CMD: $bash_cmd"
eval "$bash_cmd"
sleep 30

if [ ! -s "$fastq1_trim" ] ; then
    echo "\n $script ERROR: $fastq1_trim Not Generated \n" >&2
    exit 1
fi

# delete unpaired reads
eval "rm $fastq1_trim_unpaired $fastq2_trim_unpaired "

