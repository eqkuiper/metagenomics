#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics-gpu
#SBATCH --gres=gpu:a100:1
#SBATCH -t 24:00:00
#SBATCH -N 1
#SBATCH --cpus-per-task=1
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
fasta_dir="/projects/p31618/eqk_metagenome_files/maca_scaffolds"
reads_dir="/projects/p32449/maca_mags_metabolic/data/2025-10-07_maca_metaG/01_trimmomatic_out"
metagenome_list="/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt"

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
module load cuda
module load bowtie2
module load samtools

export OMP_NUM_THREADS=1

# Generate concatenated.fa
if [[ ! -s "${out_root}/concatenated.fa.gz" ]]; then
    echo "Generating concenated fasta..."
    SemiBin2 concatenate_fasta \
        --input-fasta ${fasta_dir}/*.fasta \
        --output ${out_root} \
        --verbose
else
    echo "concatenated.fa.gz exists — skipping"
fi

# Build index for concatenateßd fasta
if [[ ! -s "${out_root}/concatenated_idx.1.bt2l" ]]; then
    echo "Indexing concatenated fasta..."
    bowtie2-build ${out_root}/concatenated.fa.gz ${out_root}/concatenated_idx
else
    echo "Bowtie2 index exists — skipping"
fi

echo "Step one complete. Confirm outputs and continue to next steps..."
