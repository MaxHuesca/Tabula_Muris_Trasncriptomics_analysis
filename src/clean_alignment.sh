#!/bin/bash 
#script for cleaning the aligments generated in bam format

#Ensure robusteness
set -e # Only to ensure scrpt executions
set -u # To avoid undefined variables usage
set -o pipefail # To avoid failed runs 

#Arguments 
#  -p: the path where are stored the aligments bam files
#  -s: the srr ids for parse those bam files  
#  -o: the output path for the clean aligments

#parsed the arguments
while getopts "p:s:o" opt; do
  case $opt in
    p) in_pth="$OPTARG" ;;
    s) srr_id="$OPTARG" ;;
    o) out_pth="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG" >&2 ;;
  esac
done
shift $((OPTIND - 1))

#check if the input path exist, if not exit with error
if [ ! -d "$in_pth" ]; then
  echo "Input path $in_pth does not exist. Exiting."
  exit 1
fi 

#check if the user provided a output path, if not make the dafault one
if [ -z "${out_pth:-}" ]; then
    out_pth="${in_pth}/clean/"
fi

#check if the output path exist, if not create it
if [ ! -d "$out_pth" ]; then
  mkdir -p "$out_pth"
fi 

#construct the paths for the bam files associated with the srr id
bam_HIun="${in_pth}/${srr_id}_UN.sort.bam" 
bam_HIpr="${in_pth}/${srr_id}_PR.sort.bam" 
bam_SRun="${in_pth}/${srr_id}_strUNAligned.sortedByCoord.out.bam"
bam_SRpr="${in_pth}/${srr_id}_strPRAligned.sortedByCoord.out.bam"

#make the error path for the aligment process
err_pth="${out_pth}/errors/"

mkdir -p "$err_pth"

#make the cleaning using samtools 
echo "samtools view -bq 10 ${bam_HIun} -o ${srr_id}_HIun_clean.bam" | \
qsub \
  -N "parse_${SRR_id}" \
  -cwd \
  -o "${err_pth}${SRR_id}_parse.out" \
  -e "${err_pth}${SRR_id}_parse.err" \


echo "samtools view -bq 10 ${bam_HIpr} -o ${srr_id}_HIpr_clean.bam" | \
qsub \
  -N "parse_${SRR_id}" \
  -cwd \
  -o "${err_pth}${SRR_id}_parse.out" \
  -e "${err_pth}${SRR_id}_parse.err" \

echo "samtools view -bq 10 ${bam_SRpr} -o ${srr_id}_SRpr_clean.bam" | \
qsub \
  -N "clean_${SRR_id}" \
  -cwd \
  -o "${err_pth}${SRR_id}_parse.out" \
  -e "${err_pth}${SRR_id}_parse.err" \

echo "samtools view -bq 10 ${bam_SRun} -o ${srr_id}_SRun_clean.bam" | \
qsub \
  -N "clean_${SRR_id}" \
  -cwd \
  -o "${err_pth}${SRR_id}_parse.out" \
  -e "${err_pth}${SRR_id}_parse.err" \






