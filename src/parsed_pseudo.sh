#!/bin/bash 
#script for parsing the pseudo aligment results from kallisto and salmon 

#Ensure robusteness
set -e # Only to ensure scrpt executions
set -u # To avoid undefined variables usage
set -o pipefail # To avoid failed runs 

#Arguments 
#  -p: the path where the kallisto and salmon directories are located
#  -o: the output path for the parsed result
#  -b: number of bootstraps that were made using kallisto/salmon
#  -l: the directorti with the logs files 

#parsed the arguments
while getopts "p:o:b:l:" opt; do
  case $opt in
    p) res_pth="$OPTARG" ;;
    o) out_pth="$OPTARG" ;;
    b) boots="$OPTARG" ;;
    l) log_pth="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG" >&2 ;;
  esac
done 
shift $((OPTIND - 1))

#=====================================================================
#parse arguments
#=====================================================================
#check if the input path exist, if not exit with error
if [ ! -d "$res_pth" ]; then
  echo "Input path $res_pth does not exist. Exiting."
  exit 1
fi  
#asign default values to the optional arguments if they are not set by the user
if [[ -z "${out_pth:-}" ]]; then
    out_pth=$res_pth
fi
if [[ -z "${boots:-}" ]]; then
    boots=100
fi
#finally parsed the log path
if [[ -z "${log_pth:-}" ]]; then
    log_pth="temp_pseudo_align/align_errors/"
fi

#=====================================================================
#clean kallisto
#=====================================================================
#first clean the abudance tables form the bootsraps only store the first and the last one 
range_boots=$(($boots-2))
for SRR_dir in "${res_pth}"/kallisto/*; do
    #delete all the abudance that are not relevants
    for i in $(seq 0 $range_boots); do
        rm -f ${SRR_dir}/*_${i}.tsv
    done
    #clean the to left tables 
    for file in ${SRR_dir}/*.tsv; do
        [[ "$file" == *_clean.tsv ]] && continue
        awk 'BEGIN{OFS="\t"} NR==1 {print; next} {sub(/\..*/,"",$1); print}' "$file" > "${file%.tsv}_clean.tsv"
    done 
done

#=====================================================================
#parse the stats
#=====================================================================
#first we create the header in the file
echo -e "SRR_id\tAligner\tType\t%_aligned\tTime(min)" > "${out_pth}"/pseudo_align_stats.tsv

for log_file in "${log_pth}"*.err; do
    #get the base name of log file to parsed it 
    base_name=$(basename "$log_file" .err)
    #get the SRR id 
    Srr_id=${base_name%%_*}
    #get the aligner and the type of alignment
    aligner_type=${base_name##*_}
    aligner=${aligner_type:0:3}
    type=${aligner_type:3:2} 
    #get the time of the alignment process
    time_raw=$(grep "^real" "$log_file" | cut -f2)
    min=${time_raw%%m*}
    sec=${time_raw#*m}; sec=${sec%s}
    time=$(awk -v m=$min -v s=$sec 'BEGIN{print m+(s/60)}') 
    if [[ $aligner == "sal" ]];then 
        #get the overall alignment rate 
        align_rate=$( grep "Mapping rate" "$log_file" | cut -d " " -f8)
        align_rate=${align_rate%\%} #remove the % sign
    elif [[ $aligner == "kal" ]]; then
        #get the overall alignment rate
        aligned=$(grep "reads pseudoaligned" "$log_file" | cut -d " " -f5)
        total=$(grep "reads pseudoaligned" "$log_file" | cut -d " " -f3)
        align_rate=$(awk -v alig=$aligned -v tot=$total 'BEGIN{if(tot>0) print (alig/tot)*100; else print "NaN"}')
    fi 
    #write the results in the file
    echo -e "${Srr_id}\t${aligner}\t${type}\t${align_rate}\t${time}" >> "${out_pth}"/pseudo_align_stats.tsv
done 



