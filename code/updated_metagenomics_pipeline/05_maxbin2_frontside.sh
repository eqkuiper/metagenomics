#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 48:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --array=0-20  # change to number of metagenomes
#SBATCH --mem=8G
#SBATCH --job-name=maxbin2
#SBATCH --mail-user=esmee@u.northwestern.edu # change to your email
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --output=%A_%a-%x.out

### USER INPUTS
# define parent genome directory and trimmed reads folder
parent_dir=/projects/p32449/maca_mags_metabolic/data/2025-10-07_maca_metaG 
assemblies=/scratch/jhr1326/02_assembled-spades # assemblies directory
out_dir=/scratch/jhr1326/05_maxbin2_folders # output directory
reads_dir=${parent_dir}/01_trimmomatic_out # trimmed reads folder
sample_list=/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt # list of samples
###############

module load python-miniconda3
source activate /projects/p31618/software/maxbin2-2.2.7
export PATH=/projects/p31618/software/maxbin2-2.2.7/bin:$PATH
module load mpi/openmpi-4.1.1-gcc.10.2.0

# list of samples from which to bin (not run):
IFS=$'\n' read -d '' -r -a input_args < $sample_list
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

echo "Processing sample: $metagenome"

# Copy reads to scratch, handle gzipped or plain fastq
forward=$(ls $reads_dir/${metagenome}*_R1_paired.fastq*)
reverse=$(ls $reads_dir/${metagenome}*_R2_paired.fastq*)

# Determine if files are gzipped, copy to scratch, rename with _[1,2].fastq ending required by metaWRAP
if [[ $forward == *.gz ]]; then
    cp $forward /scratch/$USER/${metagenome}_1.fastq.gz
    cp $reverse /scratch/$USER/${metagenome}_2.fastq.gz
    read1=/scratch/$USER/${metagenome}_1.fastq.gz
    read2=/scratch/$USER/${metagenome}_2.fastq.gz
else
    cp $forward /scratch/$USER/${metagenome}_1.fastq
    cp $reverse /scratch/$USER/${metagenome}_2.fastq
    read1=/scratch/$USER/${metagenome}_1.fastq
    read2=/scratch/$USER/${metagenome}_2.fastq
fi

# go to scratch for local processing
cd /scratch/$USER

mkdir -p $out_dir/${metagenome}

# run maxbin2
run_MaxBin.pl \
-contig ${assemblies}/${metagenome}/scaffolds.fasta \
-reads $read1 \
-reads2 $read2 \
-out $out_dir/${metagenome}/${metagenome}_maxbin2

echo "Finished sample: $metagenome"