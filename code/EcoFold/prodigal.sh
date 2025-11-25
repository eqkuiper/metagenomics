#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH --gres=gpu:a100:1
#SBATCH -t 10:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --array=0-N # adjust to number of genomes
#SBATCH --mem=10G
#SBATCH --job-name=EcoFoldDB
#SBATCH --mail-user=esmee@u.northwestern.edu # change to your email
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --output=%A_%a-%x.out