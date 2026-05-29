#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 04:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --mem=64G
#SBATCH --output=%A_%a-%x.out
#SBATCH --mail-user=esmee@u.northwestern.edu # change to your email
#SBATCH --mail-type=END,FAIL

tar -xvf /projects/p31618/kraken2/kraken2_db/k2_pluspf_20240904.tar.gz