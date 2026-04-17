#!/bin/bash 
#script for generating all the temporary paths and scripts for the salmon_pseudoalignments process

#Ensure robusteness
set -e # Only to ensure scrpt executions
set -u # To avoid undefined variables usage
set -o pipefail # To avoid failed runs 

#Arguments 
#  -t: the path for all the temporary fiiles in the generation of the alignments
#  -r: the path for the alignments results 

#parsed the arguments
while getopts "t:r:" opt; do
  case $opt in
    t) temp_pth="$OPTARG" ;;
    r) results_pth="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG" >&2 ;;
  esac
done

shift $((OPTIND - 1))

#Set default values if the variables are not set by the user
if [[ -z "${temp_pth:-}" ]]; then
    temp_pth="temp_pseudo_align/"
fi

if [[ -z "${results_pth:-}" ]]; then
    results_pth="results/pseudo_alignments/"
fi

mkdir -p "$temp_pth"

#now the result path 
sal_pth="results/pseudo_alignments/salmon"
kal_pth="results/pseudo_alignments/kallisto"

mkdir -p $sal_pth
mkdir -p $kal_pth

#generate the scripts for the alignments with heredocs

#=====================================================================
#salmon
#=====================================================================
cat <<Sal_PR > "$temp_pth/sal_pr.sh"
#!/bin/bash
#$ -cwd
#$ -q default
#$ -pe smp 4
#$ -l h_rt=04:00:00
#$ -l h_vmem=12G

#Arguments: 
#   \$1: the SRR of the samples to be aligned
#   \$2: the path for the first read file
#   \$3: the path for the second read file

#changue to the temp path 
cd $temp_pth || exit 1

time conda run -n salmon salmon quant \
-l A -p 4 \
-i ../data/indexes/salmon \
-1 ../\$2 \
-2 ../\$3 \
-o "../${sal_pth}/\${1}_salPR" \
--gcBias \
--seqBias \
--posBias \
--validateMappings \
--rangeFactorizationBins 4 \
--numBootstraps 100

Sal_PR

cat <<Sal_UN > "$temp_pth/sal_un.sh"
#!/bin/bash
#$ -cwd
#$ -q default
#$ -pe smp 4
#$ -l h_rt=04:00:00
#$ -l h_vmem=12G

#Arguments: 
#   \$1: the SRR of the samples to be aligned
#   \$2: the path for the first read file

#changue to the temp path 
cd $temp_pth || exit 1

time conda run -n salmon salmon quant \
-l A -p 4 \
-i ../data/indexes/salmon \
-r ../\$2 \
-o "../${sal_pth}/\${1}_salUN" \
--gcBias \
--seqBias \
--posBias \
--validateMappings \
--rangeFactorizationBins 4 \
--numBootstraps 100

Sal_UN

#=====================================================================
#kallisto
#=====================================================================

cat <<Kal_PR > "$temp_pth/kal_pr.sh"
#!/bin/bash
#$ -cwd
#$ -q default
#$ -pe smp 4
#$ -l h_rt=04:00:00
#$ -l h_vmem=12G 

#Arguments:
#   \$1: the SRR of the samples to be aligned
#   \$2: the path for the first read file
#   \$3: the path for the second read file 

#changue to the temp path
cd $temp_pth || exit 1 

time conda run -n kallisto kallisto quant \
-i ../data/indexes/kallisto/mouse_m36_transcriptome.idx \
-o "../${kal_pth}/\${1}_kalPR" \
-t 4 -b 100 --plaintext ../\$2 ../\$3


Kal_PR

cat <<Kal_UN > "$temp_pth/kal_un.sh"
#!/bin/bash
#$ -cwd
#$ -q default
#$ -pe smp 4
#$ -l h_rt=04:00:00
#$ -l h_vmem=12G

#Arguments:
#   \$1: the SRR of the samples to be aligned
#   \$2: the path for the first read file

#changue to the temp path
cd $temp_pth || exit 1

time conda run -n kallisto kallisto quant \
-i ../data/indexes/kallisto/mouse_m36_transcriptome.idx \
-o "../${kal_pth}/\${1}_kalUN" \
-t 4 -l 200 -s 20 --single -b 100 --plaintext ../\$2


Kal_UN


#make the scripts executable
chmod +x "$temp_pth"/*.sh