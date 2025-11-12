#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 12:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --mem=20G
#SBATCH --array=0-19                        # <-- adjust based on sample count
#SBATCH --job-name=metadecoder_array
#SBATCH --mail-user=esmee@u.northwestern.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=logs/%A_%a_metadecoder.out  # one log per array job

################################################################################
#                          USER CONFIGURATION SECTION
################################################################################

# --- Sample list (one metagenome ID per line)
sample_list="/projects/p31618/sample_lists/metadecoder_samples.txt"

# --- Input directories
bam_dir="/scratch/jhr1326/2025-10-20_02.5_align"
fasta_dir="/scratch/jhr1326/02_assembled-spades_10Nov2025"

# --- Output root directory (one subdir per metagenome will be made)
out_root="/scratch/jhr1326/metadecoder_results"

# --- Conda environment for MetaDecoder
metadecoder_env="/projects/p31618/software/MetaDecoder-1.2.1"

# --- Number of threads to use for MetaDecoder seed step
threads=4

################################################################################
#                       PIPELINE EXECUTION (DO NOT EDIT BELOW)
################################################################################

module load python-miniconda3
eval "$(conda shell.bash hook)"
conda activate "$metadecoder_env"

# Load metagenome from sample list using array index
IFS=$'\n' read -d '' -r -a input_args < "$sample_list"
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

echo "[$(date)] Starting MetaDecoder for sample: ${metagenome}"

# Create output directory for this sample
out_dir="${out_root}/${metagenome}"
mkdir -p "$out_dir"
cd "$out_dir"

################################################################################
# Step 1: Coverage
################################################################################
echo "[$(date)] Running coverage..."
metadecoder coverage \
  -b "${bam_dir}/${metagenome}/${metagenome}_sorted.bam" \
  -o "${metagenome}.COVERAGE"

################################################################################
# Step 2: Seed
################################################################################
echo "[$(date)] Running seed..."
metadecoder seed --threads "$threads" \
  -f "${fasta_dir}/${metagenome}/scaffolds.fasta" \
  -o "${metagenome}.SEED"

################################################################################
# Step 3: Cluster
################################################################################
echo "[$(date)] Running cluster..."
metadecoder cluster \
  -f "${fasta_dir}/${metagenome}/scaffolds.fasta" \
  -c "${metagenome}.COVERAGE" \
  -s "${metagenome}.SEED" \
  -o "${metagenome}_MetaDecoder"

echo "[$(date)] MetaDecoder complete for ${metagenome}"
