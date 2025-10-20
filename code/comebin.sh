#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics-gpu
#SBATCH --gres=gpu:a100:1
#SBATCH -t 48:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --array=0-20 # adjust to number of metagenomes
#SBATCH --mem=200G
#SBATCH --job-name=comebin
#SBATCH --mail-user=esmee@u.northwestern.edu # change to your email
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --output=%A-%x.out

set -euo pipefail

# USER INPUTS
contig_dir=/scratch/jhr1326/02_assembled-spades
output_dir=/scratch/jhr1326/2025-10-20_COMEBin
aligned_dir=/scratch/jhr1326/2025-10-20_02.5_align
metagenome_list=/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt
#############

mkdir -p $output_dir

# define metagenome
IFS=$'\n' read -d '' -r -a input_args < "${metagenome_list}"
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

# make output directory for each genome
meta_out="${output_dir}/${metagenome}"
mkdir -p $meta_out

# set up
module load python-miniconda3
eval "$(conda shell.bash hook)"
conda activate /projects/p32449/goop_stirrers/miniconda3/envs/comebin_env
module load cuda

# run COMEBin

echo "Running COMEBin. Sit back and relax..."

run_comebin.sh \
-a $contig_dir/${metagenome}/scaffolds.fasta \
-o $meta_out \
-p $aligned_dir/$metagenome \
-t 4

echo "COMEBin run over! Go! Be free!!!" 
