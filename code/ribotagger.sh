#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics-himem
#SBATCH -t 12:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --array=0-20 # change to number of metagenomes
#SBATCH --mem-per-cpu=60G
#SBATCH --job-name=ribotagger_all_take3
#SBATCH --output=%A_%a-%x.out
#SBATCH --mail-user=esmee@u.northwestern.edu # change to your email
#SBATCH --mail-type=BEGIN,END,FAIL

## USER INPUTS ##
metagenome_list="/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt"
metagenome_dir="/projects/p31618/nu-seq/Osburn02_12.10.2021_metagenomes/reads"
ribotagger_path="/projects/p32449/goop_stirrers/ribotagger-master/ribotagger"
region="v4"
out_dir="/projects/p32449/maca_mags_metabolic/data/2025-10-07_ribotagger"
#################

mkdir -p "$out_dir"

# list metagenomes, should follow sample-id_R1_001.fastq.gz
mapfile -t input_args < "$metagenome_list"
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}
# Strip any hidden newlines or carriage returns
metagenome=$(echo "$metagenome" | tr -d '\r\n')

# Define input files
in_r1="${metagenome_dir}/${metagenome}_R1_001.fastq.gz"
in_r2="${metagenome_dir}/${metagenome}_R2_001.fastq.gz"

# Check that input files exist
if [[ ! -f "$in_r1" || ! -f "$in_r2" ]]; then
    echo "ERROR: input files not found for $metagenome"
    exit 1
fi

module load perl

# Run Ribotagger
echo "Running Ribotagger for $metagenome..."

"${ribotagger_path}/ribotagger.pl" \
-r "$region" \
-in "$in_r1" "$in_r2" \
-out "${out_dir}/${metagenome}.v4" \
-no-eukaryota

echo "Ribotagger is complete for $metagenome"
