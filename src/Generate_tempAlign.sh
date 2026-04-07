#!/bin/bash 
#script for generating all the temporary paths and scripts for the alignment process

#Ensure robusteness
set -e # Only to ensure scrpt executions
set -u # To avoid undefined variables usage
set -o pipefail # To avoid failed runs 

#Arguments 
#  -t: the path for all the temprary fiiles in the generation of the alignments
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
    temp_pth="temp_align/"
fi

if [[ -z "${results_pth:-}" ]]; then
    results_pth="results/alignments/"
fi

mkdir -p "$temp_pth"
mkdir -p "$results_pth"

#generate the scripts for the alignments with heredocs
cat <<STAR_PR > "$temp_pth/star_pr.sh"
#!/bin/bash
#$ -cwd
#$ -q default
#$ -pe smp 4
#$ -l h_rt=06:00:00
#$ -l h_vmem=16G

#Arguments: 
#   \$1: the SRR of the samples to be aligned
#   \$2: the path for the first read file
#   \$3: the path for the second read file

#changue to the temp path 
cd $temp_pth || exit 1

conda run -n star STAR \
--runMode alignReads \
--genomeDir /export/space3/users/silvanac/transcriptomica_2026/indexes/mm39.gencode.M36.star/ \
--readFilesIn ../\$2 ../\$3 \
--outFileNamePrefix \${1}_strPR \
--outSAMtype BAM SortedByCoordinate 

#move the bam files to the results folder
mv \${1}_strPRAligned.sortedByCoord.out.bam "../${results_pth}"
STAR_PR

cat <<STAR_UN > "$temp_pth/star_un.sh"
#!/bin/bash
#$ -cwd
#$ -q default
#$ -pe smp 4
#$ -l h_rt=06:00:00
#$ -l h_vmem=16G

#Arguments: 
#   \$1: the SRR of the samples to be aligned
#   \$2: the path for the first read file

#changue to the temp path 
cd $temp_pth || exit 1

conda run -n star STAR \
--runMode alignReads \
--genomeDir /export/space3/users/silvanac/transcriptomica_2026/indexes/mm39.gencode.M36.star/ \
--readFilesIn ../\$2 \
--outFileNamePrefix \${1}_strUN \
--outSAMtype BAM SortedByCoordinate

#move the bam files to the results folder
mv \${1}_strUNAligned.sortedByCoord.out.bam "../${results_pth}"
STAR_UN

cat <<HI_PR > "$temp_pth/hisat_pr.sh"
#!/bin/bash
#$ -cwd
#$ -q default
#$ -pe smp 4
#$ -l h_rt=03:00:00
#$ -l h_vmem=10G

#Arguments: 
#   \$1: the SRR of the samples to be aligned
#   \$2: the path for the first read file
#   \$3: the path for the second read file 

#changue to the temp path 
cd $temp_pth || exit 1

sam_file="\$1"_PR.sam
hisat2 -x /export/space3/users/silvanac/transcriptomica_2026/indexes/mm39.gencode.M36.hisat/mm39.gencode.M36.hisat \
-p 4 -t --summary-file "\$1"_PR.txt -1 ../\$2 -2 ../\$3 -S "\$1"_PR.sam \
--met-file "\$1"_PR_met.txt --new-summary --met 1

samtools view -b "\$sam_file" | samtools sort -o "\${1}_PR.sort.bam" && rm "\$sam_file"
mv "\${1}_PR.sort.bam" "../${results_pth}"
HI_PR

cat <<HI_UN > "$temp_pth/hisat_un.sh"
#!/bin/bash
#$ -cwd
#$ -q default
#$ -pe smp 4
#$ -l h_rt=03:00:00
#$ -l h_vmem=10G

#Arguments: 
#   \$1: the SRR of the samples to be aligned
#   \$2: the path for the first read file

#changue to the temp path 
cd $temp_pth || exit 1

sam_file="\$1"_UN.sam
hisat2 -x /export/space3/users/silvanac/transcriptomica_2026/indexes/mm39.gencode.M36.hisat/mm39.gencode.M36.hisat \
-p 4 -t --summary-file "\$1"_UN.txt -U ../\$2 -S \$sam_file \
--met-file "\$1"_UN_met.txt --new-summary --met 1

samtools view -b "\$sam_file" | samtools sort -o "\${1}_UN.sort.bam" && rm "\$sam_file"
mv "\${1}_UN.sort.bam" "../${results_pth}"
HI_UN

#make the scripts executable
chmod +x "$temp_pth"/*.sh