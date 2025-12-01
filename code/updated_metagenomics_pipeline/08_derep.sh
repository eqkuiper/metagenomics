#!/bin/bash
#SBATCH -A p31618
#SBATCH -p short
#SBATCH -t 04:00:00
#SBATCH -N 1
#SBATCH -n 12
#SBATCH --array=0-20
#SBATCH --mem-per-cpu=8G
#SBATCH --job-name=derep-reassembled_mags
#SBATCH --mail-user=your-email@u.northwestern.edu # change to your email
#SBATCH --mail-type=END
#SBATCH --output=%j-%x.out

# user inputs -----------------------------
sample_list=/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt
output_dir=/scratch/jhr1326/2025-12-01_dereplicated-bins
input_genomes=/scratch/jhr1326/2025-11-26_reassembled_bins 
# ------------------------------------------

# list of samples from which to bin:
IFS=$'\n' read -d '' -r -a input_args < ${sample_list}
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

module purge all
module load python-miniconda3
source activate /projects/p31618/software/drep-3.6.2
module load checkm

# copy bin fastas to tmp scratch folder
tmp_genomes=/scratch/${USER}/reassembled_bins_${SLURM_JOB_ID}
mkdir -p $tmp_genomes

cp ${input_genomes}/${metagenome}/reassembled_bins/*.fa \
   ${tmp_genomes}/

dRep dereplicate \
  ${output_dir}/${metagenome} \
  -g ${tmp_genomes}/*.fa \
  -l 10000 \
  -comp 50 \
  -con 10 \
  -p ${SLURM_NTASKS}