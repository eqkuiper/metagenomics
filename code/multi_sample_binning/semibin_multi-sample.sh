#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics-gpu
#SBATCH --gres=gpu:a100:1
#SBATCH -t 24:00:00
#SBATCH -N 1
#SBATCH --cpus-per-task=4
#SBATCH --ntasks=1
#SBATCH --mem=80G
#SBATCH --job-name=semibin_multi-sample
#SBATCH --mail-user=esmee@u.northwestern.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=%A_semibin.out  # one log per array job

################################################################################
#                          USER CONFIGURATION SECTION
################################################################################

# --- Input directories
bam_dir="/scratch/jhr1326/2025-10-20_02.5_align_20Nov2025"
fasta_dir="/projects/p31618/eqk_metagenome_files/maca_scaffolds"

# --- Output root directory (one subdir per metagenome will be made)
out_root="/scratch/jhr1326/semibin_results_multi-sample"

# --- Conda environment for MetaDecoder
semibin_env="/projects/p32449/goop_stirrers/miniconda3/envs/SemiBin"

################################################################################
#                       PIPELINE EXECUTION (DO NOT EDIT BELOW)
################################################################################

module load python-miniconda3
eval "$(conda shell.bash hook)"
conda activate "$semibin_env"

export OMP_NUM_THREADS=1

# generate lists of fasta and bam files
# fasta_list="${out_root}/fasta_list.txt"
# bam_list="${out_root}/bam_list.txt"

# find "${fasta_dir}" -maxdepth 1 -type f \
#     \( -name "*.fa" -o -name "*.fna" -o -name "*.fasta" -o -name "*.fa.gz" -o -name "*.fna.gz" -o -name "*.fasta.gz" \) \
#     > "$fasta_list"

# find "${bam_dir}" -maxdepth 1 -type f -name "*_sorted.bam" \
#     > "$bam_list"

# Generate concatenated.fa
SemiBin2 concatenate_fasta \
    --input-fasta ${fasta_dir}/*.fasta \
    --output ${out_root}

# Generate features (data.csv/data_split.csv files)
SemiBin2 generate_sequence_features_multi \
    -i ${out_root}/concatenated.fa.gz \
    -b ${bam_list} \
    -o ${out_root}

# Train a model 
for fasta in ${fasta_dir}/*.fasta ; do
    SemiBin2 train_self \
        --data ${out_root}/samples/${fasta}/data.csv \
        --data-split ${out_root}/samples/${fasta}/data_split.csv \
        --output ${out_root}/${fasta}_output
done

# Bin
for fasta in ${fasta_dir}/*.fasta ; do
    SemiBin2 bin_short \
        -i ${fasta}.fasta \
        --model ${out_root}/${fasta}_output/model.pt \
        --data ${out_root}/samples/${fasta}/data.csv \
        -o ${out_root}
done