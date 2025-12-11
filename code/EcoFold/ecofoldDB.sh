#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics-gpu
#SBATCH --gres=gpu:a100:1
#SBATCH -t 20:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --array=0-20 # adjust to number of genomes
#SBATCH --mem=10G
#SBATCH --job-name=EcoFoldDB
#SBATCH --mail-user=esmee@u.northwestern.edu # change to your email
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --output=%A_%a-%x.out

# USER INPUTS
# tsv with genome fp and genome id as cols
faa_dir=/projects/p32449/maca_mags_metabolic/2025-12-11_prodigal
out_dir=/scratch/jhr1326/ecofold_11Dec2025
metagenome_list="/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt"
#############

# load cuda
module load mpi/openmpi-4.1.6rc2-gcc-12.3.0-cuda-12.4.1   
echo "Using GPU: $CUDA_VISIBLE_DEVICES"
nvidia-smi

mkdir -p "${out_dir}/tmp"

# define metagenome
echo "Defining metagenome..."
mapfile -t input_args < "${metagenome_list}"
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

# Add Foldseek/EcoFoldDB to PATH
export PATH=/projects/p31618/software/EcoFoldDB/foldseek/bin/:$PATH

# Move to EcoFoldDB directory
cd /projects/p31618/software/EcoFoldDB

# Define output directory
genome_out="${out_dir}/annotated/${metagenome}"

# Run annotation
./EcoFoldDB-annotate.sh \
    --EcoFoldDB_dir /projects/p31618/software/EcoFoldDB/EcoFoldDB_v2.0 \
    --gpu 1 \
    --ProstT5_dir /projects/p31618/software/EcoFoldDB/ProstT5_dir \
    -o "${genome_out}" \
    "${faa_dir}/${metagenome}/${metagenome}.faa"

rm -rf ${out_dir}/tmp



