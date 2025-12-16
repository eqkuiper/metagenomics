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
reads_dir="/projects/p32449/maca_mags_metabolic/2025-10-07_maca_metaG/01_trimmomatic_out"

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
Echo "Generating concenated fasta..."
SemiBin2 concatenate_fasta \
    --input-fasta ${fasta_dir}/*.fasta \
    --output ${out_root} \
    --verbose

# Build index for concatenated fasta
Echo "Indexing concatenated fasta..."
bowtie2 ${out_root}/concatenated.fa.gz ${out_root}/concatenated_idx

Echo "Aligning by sample..."
for fasta in ${fasta_dir}/*.fasta; do 
    sample=$(basename ${fasta} .fasta)
    bowtie2 \
    -x ${out_root}/concatenated_idx \
    -1 ${reads_dir}/${sample}_R1_paired.fastq \
    -2 ${reads_dir}/${sample}_R2_paired.fastq \
    -S ${out_root}/${sample}.sam \
    -p $SLURM_NTASKS
done

# Convert to BAM file required for most downstream processing steps
echo "Converting SAM to BAM..."
for fasta in ${fasta_dir}/*.fasta; do 
    sample=$(basename ${fasta} .fasta)
    samtools view -bS ${out_root}/${sample}.sam > ${out_root}/${sample}.bam
done

# Sort and index BAM
echo "Sorting and indexing BAM file..."
for fasta in ${fasta_dir}/*.fasta; do 
    sample=$(basename ${fasta} .fasta)
    samtools sort ${out_root}/${sample}.bam -o ${out_root}/${sample}_sorted.bam
done
for fasta in ${fasta_dir}/*.fasta; do 
    sample=$(basename ${fasta} .fasta)
    samtools index ${out_root}/${sample}_sorted.bam
done

# Generate features (data.csv/data_split.csv files)
echo "Generating feature tables..."
for fasta in ${fasta_dir}/*.fasta; do 
    sample=$(basename ${fasta} .fasta) 
    SemiBin2 generate_sequence_features_multi \
        -i ${out_root}/concatenated.fa.gz \
        -b ${out_root}/${sample}_sorted.bam \
        -o ${out_root} \
        --verbose
done

# Train a model 
for fasta in ${fasta_dir}/*.fasta ; do
    sample=$(basename ${fasta} .fasta)
    SemiBin2 train_self \
        --data ${out_root}/samples/${sample}/data.csv \
        --data-split ${out_root}/samples/${sample}/data_split.csv \
        --output ${out_root}/${sample}_output \
        --verbose
done

# Bin
for fasta in ${fasta_dir}/*.fasta ; do
    sample=$(basename ${fasta} .fasta)
    mkdir -p ${out_root}/${sample}_output/binning \
    SemiBin2 bin_short \
        -i ${fasta} \
        --model ${out_root}/${sample}_output/model.pt \
        --data ${out_root}/${sample}_output/data.csv \
        -o ${out_root}/${sample}_output/binning\
        --verbose
done