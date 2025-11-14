#!/bin/bash
#SBATCH -A p32449
#SBATCH -p normal
#SBATCH -t 12:00:00
#SBATCH -N 1
#SBATCH -n 16
#SBATCH --mem=20G
#SBATCH --job-name=coverm
#SBATCH --mail-user=esmee@u.northwestern.edu # change to your email
#SBATCH --mail-type=START,FAIL,END
#SBATCH --output=%A_%a-%x.out

# user inputs
bams_dir=/scratch/jhr1326/2025-10-20_02.5_align
mags_dir=/projects/p32449/maca_mags_metabolic/2025-09-16_metagenomes
out_dir=/projects/p32449/maca_mags_metabolic/2025-11-14_coverm
# -----------

mkdir -p $out_dir

# load coverm
module load python-miniconda3
eval "$(conda shell.bash hook)" 
conda activate /projects/p32449/goop_stirrers/miniconda3/envs/coverm

# run coverm
coverm genome \
    -b ${bams_dir}/*/*_sorted.bam \
    -m relative_abundance \
    --genome-fasta-directory ${mags_dir} \
    --threads 16 \
    > ${out_dir}/coverm_relative_abundance.tsv
