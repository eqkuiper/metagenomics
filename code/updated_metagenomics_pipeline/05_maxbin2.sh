#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 48:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --array=0-20  # change to number of metagenomes
#SBATCH --mem=8G
#SBATCH --job-name=metawrap-binning_maxbin2
#SBATCH --mail-user=esmee@u.northwestern.edu # change to your email
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --output=%A_%a-%x.out

### USER INPUTS
# define parent genome directory and trimmed reads folder
parent_dir=/projects/p32449/maca_mags_metabolic/data/2025-10-07_maca_metaG 
assemblies=/scratch/jhr1326/02_assembled-spades # assemblies directory
out_dir=${parent_dir}/05_metaWRAP-maxbin2 # output directory
reads_dir=${parent_dir}/01_trimmomatic_out # trimmed reads folder
sample_list=/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt # list of samples
###############

mkdir -p $out_dir

# list of samples from which to bin (not run):
IFS=$'\n' read -d '' -r -a input_args < $sample_list
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

module purge all
PATH=/projects/p31618/software/metaWRAP/bin/:$PATH
module load mamba
source activate /projects/p31618/software/metawrap
## as of Oct 10, 2025, metawrap has not been updated since ~3 ybp
module load bwa
module load openssl
module load samtools

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

cd /scratch/$USER

# note: /projects/p31618/software/metawrap contains dependencies for concoct package here
metawrap binning \
  -o ${out_dir}/${metagenome} \
  -t $SLURM_NTASKS \
  -a ${assemblies}/${metagenome}/scaffolds.fasta \
  --maxbin2 \
  /scratch/$USER/${metagenome}*.fastq
