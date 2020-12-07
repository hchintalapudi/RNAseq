#!/bin/bash
##########################
#Author:Himanshu
#Date:11/12/2019
#This program accepts required input and creates different folders if donot exit as required 
# and performs feature counts.
# run with -h argument for usage details.
##########################


proj_dir=$1
sample=$2
bam=$3
threads=$4
run_type=$5
strand=$6

script="Featurecounts.sh"
#if [[ "${proj_dir}" =~ "-h" ]] ; then
 #   echo -e "\n USAGE: $script 123 project_dir sample bam threads runtype[SE or PE] strand[fwd,rev or unstr] \n"
  #  exit 1
#fi
if [ "$#" -lt 4 ]; then
        echo -e "\n ERROR:Wrong number of arguments supplied for $script \n" >&2
        echo -e "\n USAGE: $script project_dir sample bam threads runtype[SE or PE] strand \n" >&2
        exit 1
fi
# Define directories and files
fc_dir="${proj_dir}/Feature_Counts"
mkdir -p "$fc_dir"
 

fc_log="${proj_dir}/Feature_Counts_logs"
mkdir -p "$fc_log"


# Reference Annotation file.
gtf="/dartfs-hpc/rc/lab/L/LeachLab/genomes/GRCm38.p6/gencode.vM23.primary_assembly.annotation.gtf"
gtf2="/dartfs-hpc/rc/lab/L/LeachLab/HIMANSHU/genomes/ZF/Danio_rerio.GRCz11.101.gtf"
# check for run type and update runtype arg.
# produce error if runtype is not SE or PE and exit.

if [ "$run_type" == "SE" ] ; then
    run_type_arg=""
elif [ "$run_type" == "PE" ] ; then
    run_type_arg="-p"
else
    echo -e "\n $script ERROR:incorrect run type; please input SE or PE \n " >&2
    exit 1
fi
# check for strand input.
# modify output file name available 
# produce error if strand info supplied is wrong.
if [ "$strand" == "unstr" ]; then
    counts_raw="${fc_log}/${sample}_unstr.counts.txt"
    counts_clean="${fc_dir}/${sample}_unstr.counts.txt"
    strand_arg="0"
elif [ "$strand" == "fwd" ]; then
    counts_raw="${fc_log}/${sample}_fwd.counts.txt"
    counts_clean="${fc_dir}/${sample}_fwd.counts.txt"
    strand_arg="1"
elif [ "$strand" == "rev" ]; then
    counts_raw="${fc_log}/${sample}_rev.counts.txt"
    counts_clean="${fc_dir}/${sample}_rev.counts.txt"
    strand_arg="2"
else
    echo -e "\n $script ERROR: incorrect strand type entered. Please enter one of [fwd,rev,unstr]"
fi

bash_cmd="featureCounts \
-T $threads \
$run_type_arg \
-g gene_id \
-s $strand_arg \
-a $gtf2 \
-o $counts_raw \
$bam
"

echo "CMD: $bash_cmd"
eval "$bash_cmd"

if [ ! -s "$counts_raw" ]; then
    echo -e "\n FeatureCounts ERROR:Counts $counts_raw not generated \n" >&2
    exit 1
fi 
##
# Process the raw counts to extract required information.

echo -e "#GENE\t${sample}" > "$counts_clean"
cat $counts_raw | grep -v '#' | grep -v 'Geneid' | cut -f 1,7 | LC_ALL=C sort -k1,1 >> "$counts_clean"

# gene info table
gene_info_file="${proj_dir}/genes.featurecounts.txt"
echo -e "#GENE\tCHR\tSTART\tEND\tstrand\tLENGTH" > "$gene_info_file"
cat $counts_raw | grep -v '#' | grep -v 'Geneid' | cut -f 1-6 | LC_ALL=C sort -k1,1 >> "$gene_info_file"
