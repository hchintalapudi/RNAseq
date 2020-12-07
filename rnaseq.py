#!/usr/bin/python3

import os
import subprocess as sp
import re
import logging
import sys
#############################################################
#Author:Himanshu
#date :11/12/2019
# This is wrapper script written to call different shell scripts in their sequential order to analyse RNASeq Data.
# All paths used should be abs paths.(shell scripts and files)
# This script also creates a Run_Pipeline_Log.txt.
#
#############################################################

logger = logging.getLogger("run_pipeline")
logger.setLevel(logging.DEBUG)
# create console handler and set level to debug
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
# create formatter
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
# add formatter to ch
ch.setFormatter(formatter)
# add ch to logger
logger.addHandler(ch)
# file handle to write log file.
file_hand = logging.FileHandler('Run_Pipeline_Log2.txt')
file_hand.setLevel(logging.INFO)
file_hand.setFormatter(formatter)
logger.addHandler(file_hand)

########################################################
Proj_Dir = "/dartfs-hpc/rc/lab/L/LeachLab"
Script_dir = "/dartfs-hpc/rc/lab/L/LeachLab/scripts/RNAseq"
Trim_Fastqs = "/dartfs-hpc/rc/lab/L/LeachLab/Trimmed"
Input_fastqs = "/dartfs-hpc/rc/lab/L/LeachLab/AlexPenson"
STAR_ref = "/dartfs-hpc/rc/lab/L/LeachLab/genomes/hg38/STAR_index_hg38"
bam_path = "/dartfs-hpc/rc/lab/L/LeachLab/BAM_STAR"
Threads = 20

##########
# get sample names in to list (excluding R1 and R2 suffix.)
my_list = []
for file in os.listdir(Input_fastqs):
    if file.endswith('.fastq'):	
        sample = re.match(r"(.*)_R(.*)\.fastq$",file)
        sample_name = sample.group(1)
        my_list.append(sample_name)
uniq = list(set(my_list))

#print (uniq)
#uniq = ["LKO_SS_3_S6"]
########################################################
def FastQc(p_dir,fq_path,n_thread):
    FQC_run = sp.run(["%s/%s"%(Script_dir,"Fastqc.sh"),p_dir,fq_path,str(n_thread)])
    if (FQC_run.returncode == 0):
        logger.info("%s FASTQC DONE ON ", fq_path)
    else:
        logger.info("%s error in Performing FASTQC", fq_path)

def Trim_Reads(p_dir,s_name,n_thread,fq_1,fq_2):
    Trim_run = sp.run(["%s/%s"%(Script_dir,"QC_trim_trimmomatic.sh"),p_dir,s_name,str(n_thread),fq_1,fq_2])
    if (Trim_run.returncode == 0):
            logger.info("%s Read Trimming",s_name)
    else:
            logger.info("%s error in Performing Read Trimming ",s_name)

def Star_Align(p_dir,s_name,n_thread,g_ref_index,fq_1,fq_2):
    Align_run = sp.run(["%s/%s"%(Script_dir,"STAR_Align.sh"),p_dir,s_name,str(n_thread),g_ref_index,fq_1,fq_2])
    if(Align_run.returncode == 0):
        logger.info("%s Succesfully Aligned to Ref Genome",s_name)
    else:
        logger.info("%s error in Aligning to Ref Genome",s_name)

def Counts(p_dir,s_name,b_path,n_thread,run_type,strand):
    Feature_count = sp.run(["%s/%s"%(Script_dir,"Featurecounts.sh"),p_dir,s_name,b_path,str(n_thread),run_type,strand])
    if(Feature_count.returncode == 0):
        logger.info("%s Succesfully completed feature Counts",s_name)
    else:
        logger.info("%s error in performing Feature Counts",s_name)

def Rseqc(p_dir,b_path,bed_file,n_thread):
    reseq = sp.run(["%s/%s"%(Script_dir,"Rseqc.sh"),p_dir,b_path,bed_file,str(n_thread)])
    if(reseq.returncode == 0):
        logger.info("%s Succesfully completed Rseqc")
    else:
        logger.info("%s error in performing Rseqc")

###############################
# Run Shell scripts

# run Fastqc on all files in the directory using GNU parallel
# Must provide abs path for fastqs directory.
#FastQc(Proj_Dir,Input_fastqs,Threads)

# foreach sample run trimming , align and counts.
for file in uniq:
    # unique file name
    sample_name = file
    # generate fastq names for PE reads
    fastq1 = file + "_R1_001.fastq"
    fastq2 = file + "_R2_001.fastq"
    # get absolute paths for fastqs
    #print (fastq1)
    fastq1_path = "%s/%s"%(Input_fastqs,fastq1)
    fastq2_path = "%s/%s"%(Input_fastqs,fastq2)
    fastq1_trim = file + "_R1_trimmed.fastq"
    fastq2_trim = file + "_R2_trimmed.fastq"
    fastq1_trim_path = "%s/%s"%(Trim_Fastqs,fastq1_trim)
    fastq2_trim_path = "%s/%s"%(Trim_Fastqs,fastq2_trim) 
    #get aligned bam file path for sample name
    file_bam_path = "%s/%s.%s"%(bam_path,sample_name,"bam")
    #print(file_bam_path)
    # run triimomatic on the sample
    #Trim_Reads(Proj_Dir,sample_name,Threads,fastq1_path,fastq2_path)
    # Align reads to reference genome using STAR 
    Star_Align(Proj_Dir,sample_name,Threads,STAR_ref,fastq1_trim_path,fastq2_trim_path)
    # Define array to get counts files for different orientations.
    strand_array=["fwd","rev","unstr"]
    # run feturecounts on different orientations
    for i in strand_array:
        Counts(Proj_Dir,sample_name,file_bam_path,Threads,"PE",i)
        
# fastqc on trimmed reads.
#Trim_Fastqs = "/dartfs-hpc/rc/lab/L/LeachLab/Trimmed"
#FastQc(Proj_Dir,Trim_Fastqs,Threads)

#Rseqc on bam files.
#runs Rseqc on GNU parallel.
Rseqc(Proj_Dir,bam_path,"/dartfs-hpc/rc/lab/L/LeachLab/genomes/GRCm38.p6/gencode.vM23.primary_assembly.annotation.bed","10")
