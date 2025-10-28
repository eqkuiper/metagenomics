#!/bin/bash
#SBATCH -A b1042                 # Account
#SBATCH -p genomics              # Partition
#SBATCH -t 12:00:00              # Max time
#SBATCH -N 1                     # Number of nodes
#SBATCH -n 4                     # Number of CPU cores
#SBATCH --mem=60G                # Memory
#SBATCH --job-name=GToTree
#SBATCH --mail-user=esmee@u.northwestern.edu # Change to user email
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=%A_%x.out

#  USER INPUTS
# Path to list of genome file paths for tree -- use full file paths
genome_list=/projects/p32449/maca_mags_metabolic/data/2025-09-16_metagenomes/genome_list_genbank.txt
# Path to conda environment with GToTree installed
gtotree=/projects/p32449/goop_stirrers/miniconda3/envs/gtotree
# Directory where the outputs from GToTree will go
out_dir=/projects/p32449/maca_mags_metabolic/data/2025-10-28_GToTree_out
##############

# Make the output directory if it doesn't already exist
# mkdir -p $out_dir

# Make sure genome list fp exists
if [[ ! -f $genome_list ]]; then
    echo "ERROR: Genome list not found."
    echo "Double check your file path."
    exit 1
fi

# Load conda environment
echo "Booting up conda"
module load python-miniconda3
eval "$(conda shell.bash hook)"
if conda activate "$gtotree"; then
    echo "GToTree environment activated!"
else
    echo "Failed to activate conda env: $gtotree"
    exit 1
fi

# Run GToTree
echo "Running GToTree..."
GToTree -f $genome_list -H Bacteria_and_Archaea -o $out_dir

echo "Tree building complete. Goodbye."
