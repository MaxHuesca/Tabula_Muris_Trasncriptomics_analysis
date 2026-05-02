#!/usr/bin/env bash 
#Ensure robusteness
set -e # Only to ensure scrpt executions
set -u # To avoid undefined variables usage
set -o pipefail # To avoid failed runs

#Make the fastqc reports for fastq files 
#Arguments: 
#   $1: number of bases to trim from the front
#   $2: conda enviroment for runing fastp
#   $3: the zip directory for the first read
#   $4: the zip directory for the second read 
#The script generate one directory with all the fastqc report on zip and html format

trim_fron=$1
fastp_env=$2
zip_1=$3
zip_2=$4


#create the path to the fastq 1 
base_1=$(basename $zip_1)
#obtain the srr_id
srr_id=${base_1%%_*}
base_1="${base_1%_*}.fastq"
#unzip the directory 
unzip -q $zip_1
sum="${zip_1%%\.*}/summary.txt"
basal_args="--in1 ${base_1} -o ${srr_id}_1_clean.fastq -h ${base_1%%_*}_clean.html"


if [[ -f $zip_2 ]]; then 
    #create the path to the fastq 2
    base_2=$(basename $zip_2)
    base_2="${base_2%_*}.fastq"
    #unzip the zip second directory 
    unzip -q $zip_2
    sum=$(cat "${zip_1%%\.*}/summary.txt" "${zip_2%%\.*}/summary.txt")
    basal_args="--in1 ${base_1} --in2 ${base_2} -o ${srr_id}_1_clean.fastq -O ${srr_id}_2_clean.fastq -h ${base_1%%_*}_clean.html"
fi 

#review the Per base sequence content field 
base_cont=$(grep "Per base sequence content" <(echo -e $sum) | cut -f1 | grep "FAIL" | uniq)
if [[ $base_cont=="FAIL" ]]; then 
    base_cont="--trim_front1 ${trim_fron}"
else 
    base_cont=""
fi 


#review the Sequence Duplication Levels 
dup_lev=$(grep "Sequence Duplication Levels" <(echo -e $sum) | cut -f1 | grep "FAIL" | uniq )
if [[ $dup_lev=="FAIL" ]]; then 
    dup_lev="--dedup"
else
    dup_lev=""
fi 

#review the over represetation sequences
over=$(grep "Sequence Duplication Levels" <(echo -e $sum) | cut -f1 | grep "FAIL" | uniq)
if [[ $over=="FAIL" ]]; then 
    over="--overrepresentation_analysis"
else
    over=""
fi 

conda run -n $fastp_env fastp $basal_args ${base_cont} ${dup_lev} ${over}