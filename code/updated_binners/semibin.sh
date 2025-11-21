#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics-gpu
#SBATCH --gres=gpu:a100:1
#SBATCH -t 24:00:00
#SBATCH -N 1
#SBATCH --cpus-per-task=4
#SBATCH --ntasks=1
#SBATCH --mem=50G
#SBATCH --array=0-20%4                       # <-- adjust based on sample count
#SBATCH --job-name=semibin_array_take_2
#SBATCH --mail-user=esmee@u.northwestern.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=%A_%a_semibin.out  # one log per array job

################################################################################
#                          USER CONFIGURATION SECTION
################################################################################

# --- Sample list (one metagenome ID per line)
sample_list="/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt"

# --- Input directories
bam_dir="/scratch/jhr1326/2025-10-20_02.5_align_20Nov2025"
fasta_dir="/scratch/jhr1326/02_assembled-spades_10Nov2025"

# --- Output root directory (one subdir per metagenome will be made)
out_root="/scratch/jhr1326/semibin_results_gpu_all"

# --- Conda environment for MetaDecoder
semibin_env="/projects/p32449/goop_stirrers/miniconda3/envs/SemiBin"

################################################################################
#                       PIPELINE EXECUTION (DO NOT EDIT BELOW)
################################################################################

module load python-miniconda3
eval "$(conda shell.bash hook)"
conda activate "$semibin_env"

# Load metagenome from sample list using array index
IFS=$'\n' read -d '' -r -a input_args < "$sample_list"
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

echo "[$(date)] Starting SemiBin for sample: ${metagenome}"
echo "Running on node: $(hostname)"

# Create output directory for this sample
out_dir="${out_root}/${metagenome}"
mkdir -p "$out_dir"
cd "$out_dir"

export OMP_NUM_THREADS=1

# Generate features (data.csv/data_split.csv files)
SemiBin2 generate_sequence_features_single \
-i "${fasta_dir}/${metagenome}/scaffolds.fasta" \
-b "${bam_dir}/${metagenome}/${metagenome}_sorted.bam" \
-o "${out_dir}"

# Train a model 
SemiBin2 train_self \
    --data "${out_dir}/data.csv" \
    --data-split "${out_dir}/data_split.csv" \
    -o "${out_dir}"

# Bin
SemiBin2 bin_short \
    -i "${fasta_dir}/${metagenome}/scaffolds.fasta" \
    --model "${out_dir}/model.pt" \
    --data "${out_dir}/data.csv" \
    -o "${out_dir}" \
    --verbose \
    --threads 1

echo "[$(date)] Finished SemiBin for sample: ${metagenome}"