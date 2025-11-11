#!/bin/bash
#SBATCH -A b1042                 # Account
#SBATCH -p genomics              # Partition
#SBATCH -t 12:00:00              # Max time
#SBATCH -N 1                     # Number of nodes
#SBATCH -n 4                     # Number of CPU cores
#SBATCH --mem=20G                # Memory
#SBATCH --job-name=metadecoder_test
#SBATCH --mail-user=esmee@u.northwestern.edu # Change to user email
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=%A_%x.out

module load python-miniconda3
eval "$(conda shell.bash hook)"
conda activate /projects/p31618/software/MetaDecoder-1.2.1

# Step 1: Obtain coverage of contigs
metadecoder coverage \
-b /scratch/jhr1326/2025-10-20_02.5_align/BS_MC_01_21_S1/BS_MC_01_21_S1_sorted.bam \
-o METADECODER.COVERAGE

# Step 2: Map single-copy marker genes to the assembly
metadecoder seed --threads 50 \
-f /scratch/jhr1326/02_assembled-spades_10Nov2025/BS_MC_01_21_S1/scaffolds.fasta
-o METADECODER.SEED

# Step 3: Run MetaDecoder algorithm to cluster contigs
metadecoder cluster \
-f /scratch/jhr1326/02_assembled-spades_10Nov2025/BS_MC_01_21_S1/scaffolds.fasta \
-c METADECODER.COVERAGE \
-s METADECODER.SEED \
-o METADECODER_test



