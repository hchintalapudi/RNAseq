#!/bin/bash
##########################
#Author:Himanshu
#Date:11/12/2019
#This program accepts required input and creates different folders if donot exit as required 
# and performs star alignment to the given reference genome.
# converts sam output to bam and index bam.
##########################
# required parameters
proj_dir=$1
sample=$2
threads=$3
reference=$4
fastq1=$5
fastq2=$6

# check for correct number of arguments.
if [ $# -lt 5 ] ; then
        echo -e "\n ERROR:Wrong number of arguments supplied for star_align.sh\n" >&2
        echo -e "\n USAGE: STAR_Align.sh project_dir sample threads reference fastq[or fastq's] \n" >&2
        exit 1
fi

# create folders and file as required.
star_bam_dir="${proj_dir}/BAM_STAR"
mkdir -p "${star_bam_dir}"

bam="${star_bam_dir}/${sample}.bam"
bai="${star_bam_dir}/${sample}.bam.bai"

star_quant_dir="${proj_dir}/STAR_quant"
mkdir -p "${proj_dir}/STAR_quant"
# log files
star_logs_dir="${proj_dir}/STAR_logs"
mkdir -p "$star_logs_dir"
star_prefix="${star_logs_dir}/${sample}_"

sam="${star_logs_dir}/${sample}_Aligned.out.sam"

# run STAR alignment.
scriptname="STAR_Align.sh"
star_cmd="STAR --runThreadN $threads \
        --limitGenomeGenerateRAM 120000000000 \
        --genomeDir $reference \
        --readFilesCommand gunzip -c \
        --readFilesIn  $fastq1  $fastq2  \
        --outFileNamePrefix  $star_prefix \
        --outSAMstrandField intronMotif \
	--outSAMattributes NH   HI   AS   nM   NM   MD   XS \
        --outFilterType BySJout \
        --twopassMode Basic \
        --outFilterMismatchNoverLmax 0.2 \
        --outFilterMultimapNmax 1 \
        --quantMode GeneCounts
        "
echo "CMD:$star_cmd"
eval "$star_cmd"
sleep 30

echo -e "$sam\n" >&2
# check if sam file is generated from STAR
if [ ! -s "$sam" ] ; then
        echo -e "\n $scriptname ERROR: SAM file not generated from STAR\n" >&2
        exit 1
fi
# if sam file present continue
# convert sam to sorted bam
bash_cmd="samtools view -bS $sam | samtools sort -m 10G -@8 -o $bam"
echo "CMD: $bash_cmd"
eval "$bash_cmd"
# generate bam index
bash_cmd_index="samtools index $bam"
echo "CMD: $bash_cmd_index"
eval "$bash_cmd_index"
sleep 30

# if both bam and index files are successfully generated delete sam files.
if [ -s "$bam" ] ; then
        echo "BAM files created successfully; deleting SAM files"
        rm -fv "$sam"
else
        echo "Error in generating Bam file or Index, exiting .. "
        exit 1
fi

echo "Alignment and bam conversions done for $sample"

