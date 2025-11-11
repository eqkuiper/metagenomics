#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics-himem
#SBATCH --job-name=prokka_array
#SBATCH --output=prokka_%A_%a.out
#SBATCH --time=24:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=2
#SBATCH --array=0-195

source activate /projects/p31618/software/prokka

mag_list="/projects/p32449/maca_mags_metabolic/data/2025-11-04_mob_protein_tree/MOB_mammoth_fasta_list.txt"
OUTPUT_DIR="/projects/p32449/maca_mags_metabolic/data/2025-11-10_mob_protein_tree/prokka_redo_2"

mkdir -p "$OUTPUT_DIR"

# list of mags:
IFS=$'\n' read -d '' -r -a input_args < $mag_list
mag=${input_args[$SLURM_ARRAY_TASK_ID]}

# Extract base name
BASE=$(basename "$mag")
BASE=${BASE%.fna}
BASE=${BASE%.fasta}

# Run Prokka
prokka --cpus 2 --outdir "$OUTPUT_DIR/$BASE" --prefix "$BASE" "$mag"