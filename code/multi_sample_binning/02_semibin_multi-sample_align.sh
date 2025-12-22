#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 24:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --mem=40G
#SBATCH --array=0-20 # change to number of metagenomes
#SBATCH --job-name=semibin_multi-sample
#SBATCH --mail-user=esmee@u.northwestern.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=%A-%a_semibin.out  # one log per array job

################################################################################
#                          USER CONFIGURATION SECTION
################################################################################

# --- Input directories
fasta_dir="/projects/p31618/eqk_metagenome_files/maca_scaffolds"
reads_dir="/projects/p32449/maca_mags_metabolic/data/2025-10-07_maca_metaG/01_trimmomatic_out"

# --- Output root directory (one subdir per metagenome will be made)
out_root="/scratch/jhr1326/semibin_results_multi-sample"

# --- Conda environment for MetaDecoder
semibin_env="/projects/p32449/goop_stirrers/miniconda3/envs/SemiBin"

################################################################################
#                       PIPELINE EXECUTION (DO NOT EDIT BELOW)
################################################################################

module load bowtie2
module load samtools

# define metagenome
echo "Defining metagenome"
mapfile -t input_args < "${metagenome_list}"
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}
echo "Sample: $metagenome"

echo "Aligning by sample..."
    bowtie2 \
    -x ${out_root}/concatenated_idx \
    -1 ${reads_dir}/${metagenome}_R1_paired.fastq \
    -2 ${reads_dir}/${metagenome}_R2_paired.fastq \
    -S ${out_root}/${metagenome}.sam \
    -p $SLURM_NTASKS

# Convert to BAM file required for most downstream processing steps
echo "Converting SAM to BAM..."
    samtools view -bS ${out_root}/${metagenome}.sam > ${out_root}/${metagenome}.bam

# Sort and index BAM
echo "Sorting and indexing BAM file..."
    samtools sort ${out_root}/${metagenome}.bam -o ${out_root}/${metagenome}_sorted.bam
    samtools index ${out_root}/${sample}_sorted.bam

echo "Step two complete. Confirm outputs and proceed to final step..."