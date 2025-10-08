#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics-himem
#SBATCH -t 12:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --mem-per-cpu=60G
#SBATCH --job-name=ribotagger_biom
#SBATCH --output=%A.out
#SBATCH --mail-user=esmee@u.northwestern.edu # change to your email
#SBATCH --mail-type=BEGIN,END,FAIL

## USER INPUTS ##
in_dir="/projects/p32449/maca_mags_metabolic/data/2025-10-07_ribotagger" # directory with results from ribotagger.pl
out_dir="/projects/p32449/maca_mags_metabolic/data/2025-10-08_ribotagger_biom" # directory where you want results to go
region="v4" # should match variable region from previous step
ribotagger_dir="/projects/p32449/goop_stirrers/ribotagger-master/ribotagger" # path to folder with ribotagger scripts 
    # can download these scrips directly from github
experiment_name="mammoth_metagenomes" # project name to be used in naming output files
#################

# make output directory if it doesn't already exist
mkdir -p "$out_dir" 

# load perl module
module load perl

# run biom.pl from the ribotagger package
"${ribotagger_dir}/biom.pl" -r "$region" -i $in_dir/*.${region} -o "${out_dir}/${experiment_name}"
