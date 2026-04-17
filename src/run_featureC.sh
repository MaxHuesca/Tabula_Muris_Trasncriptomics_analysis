#!/bin/bash 
#script for meging the aligment result of the alignments 

#Ensure robusteness
set -e # Only to ensure scrpt executions
set -u # To avoid undefined variables usage
set -o pipefail # To avoid failed runs 

#Arguments 
#  -p: the path where are stored the clean aligments bam files
#  -o: the output path for the count matrixes
#  -g: the path to the gtf file for the annotation
 
while getopts "p:o:g:" opt; do
  case $opt in
    p) in_pth="$OPTARG" ;;
    o) out_pth="$OPTARG" ;;
    g) gtf_pth="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG" >&2 ;;
  esac
done
shift $((OPTIND - 1))

#=====================================================================
#required arguments 
#=====================================================================

#check if the input path exist, if not exit with error
if [ ! -d "$in_pth" ]; then
  echo "Input path $in_pth does not exist. Exiting."
  exit 1
fi 

#the gtf is also required
if [ ! -f "$gtf_pth" ]; then
  echo "GTF path $gtf_pth does not exist. Exiting."
  exit 1
fi 

#=====================================================================
#output arguments 
#=====================================================================
#check if the user provided a output path, if not make the dafault one
if [ -z "${out_pth:-}" ]; then
    out_pth="results/count_mtr/"
fi
#check if the output path exist, if not create it
mkdir -p "$out_pth"

#finally make the error path for the aligment process
err_pth="${out_pth}/errors/"
mkdir -p "$err_pth"

#make the temporary files
mkdir -p featureC_HI_un_tmp featureC_HI_pr_tmp featureC_SR_un_tmp featureC_SR_pr_tmp

#=====================================================================
#hisat2
#===================================================================== 

#unpaired data  
echo "conda run -n subread featureCounts -o ${out_pth}HI_un_countMtr.txt --tmpDir featureC_HI_un_tmp \
-T 8 -a ${gtf_pth} results/alignments/clean/*HIun_clean.bam" |\
qsub \
  -N "featureC_HI_un" \
  -cwd \
  -l h_vmem=10G \
  -pe smp 8 \
  -l h_rt=2:00:00 \
  -o "${err_pth}/featureC_HI_un.out" \
  -e "${err_pth}/featureC_HI_un.err" \
  -q default 

#paired data
echo "conda run -n subread featureCounts -o ${out_pth}HI_pr_countMtr.txt --tmpDir featureC_HI_pr_tmp \
-T 8 -p -C -a ${gtf_pth} results/alignments/clean/*HIpr_clean.bam" |\
qsub \
  -N "featureC_HI_pr" \
  -cwd \
  -l h_vmem=10G \
  -pe smp 8 \
  -l h_rt=2:00:00 \
  -o "${err_pth}/featureC_HI_pr.out" \
  -e "${err_pth}/featureC_HI_pr.err" \
  -q default 


#=====================================================================
#star
#===================================================================== 

#unpaired data  
echo "conda run -n subread featureCounts -o ${out_pth}SR_un_countMtr.txt --tmpDir featureC_SR_un_tmp \
-T 8 -a ${gtf_pth} results/alignments/clean/*SRun_clean.bam" |\
qsub \
  -N "featureC_SR_un" \
  -cwd \
  -l h_vmem=10G \
  -pe smp 8 \
  -l h_rt=2:00:00 \
  -o "${err_pth}/featureC_SR_un.out" \
  -e "${err_pth}/featureC_SR_un.err" \
  -q default 

#paired data
echo "conda run -n subread featureCounts -o ${out_pth}SR_pr_countMtr.txt --tmpDir featureC_SR_pr_tmp \
-T 8 -p -C -a ${gtf_pth} results/alignments/clean/*SRpr_clean.bam" |\
qsub \
  -N "featureC_SR_pr" \
  -cwd \
  -l h_vmem=10G \
  -pe smp 8 \
  -l h_rt=2:00:00 \
  -o "${err_pth}/featureC_SR_pr.out" \
  -e "${err_pth}/featureC_SR_pr.err" \
  -q default 