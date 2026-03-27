#!/bin/bash

# Ensure robustness
set -e # Only to ensure scrpt executions
set -u # To avoid undefined variables usage
set -o pipefail # To avoid failed runs

srr_id="$1" # Single SRR ID to download

output_dir="data/${srr_id}"

if [[ ! -d $output_dir ]]; then
    mkdir "$output_dir"
fi 

#donwload with fastq
conda run -n bio_informatics prefetch "$srr_id" --output-directory "$output_dir"

conda run -n bio_informatics fasterq-dump "$output_dir/$srr_id/$srr_id.sra" -O "$output_dir" --split-files --threads 4 --force