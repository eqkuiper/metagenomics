#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics-himem
#SBATCH -t 48:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --mem-per-cpu=110G
#SBATCH --output=%A.out
#SBATCH --mail-user=esmee@u.northwestern.edu
#SBATCH --mail-type=END,FAIL

# go to METABOLIC running directory

cd /projects/p32449/goop_stirrers/METABOLIC_2025-09-02/METABOLIC || exit 1

# activate conda environment

module purge
eval "$(conda shell.bash hook)"
conda activate /projects/p32449/goop_stirrers/miniconda3/envs/METABOLIC_v4.0
export GTDBTK_DATA_PATH="/projects/p32449/goop_stirrers/gtdbtk_data/release226"

# run METABOLIC-C test
echo "Running METABOLIC-C test..."
perl METABOLIC-C.pl -test true

