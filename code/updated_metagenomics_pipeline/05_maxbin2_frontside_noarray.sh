#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 48:00:00
#SBATCH -N 1
#SBATCH -n 8
#SBATCH --mem=20G
#SBATCH --job-name=maxbin2
#SBATCH --mail-user=esmee@u.northwestern.edu # change to your email
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --output=%A_%a-%x.out

### USER INPUTS
# define parent genome directory and trimmed reads folder
parent_dir=/projects/p32449/maca_mags_metabolic/data/2025-10-07_maca_metaG 
assemblies=/scratch/jhr1326/02_assembled-spades # assemblies directory
out_dir=/projects/p32449/maca_mags_metabolic/data/2025-10-07_maca_metaG/05_maxbin_out # output directory
reads_dir=${parent_dir}/01_trimmomatic_out # trimmed reads folder
sample_list=/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt # list of samples
###############

mkdir -p $out_dir

module load python-miniconda3
eval "$(conda shell.bash hook)" 
conda activate /projects/p31618/software/maxbin2-2.2.7
export PATH=/projects/p31618/software/maxbin2-2.2.7/bin:$PATH
module load mpi/openmpi-4.1.1-gcc.10.2.0

# Verify dependencies for debugging
echo "Checking binary locations..."
which hmmscan || { echo "hmmscan not found! Exiting."; exit 1; }
which FragGeneScan || { echo "FragGeneScan not found! Exiting."; exit 1; }
which bowtie2 || { echo "bowtie2 not found! Exiting."; exit 1; }

# Read all sample names from the list
mapfile -t samples < "$sample_list"

echo "Starting MaxBin2 for ${#samples[@]} samples..."
echo "Samples: ${samples[*]}"
echo "--------------------------------------------"

for metagenome in "${samples[@]}"; do
    echo "Processing sample: $metagenome"
    workdir=/scratch/$USER/${metagenome}
    mkdir -p "$workdir"
    cd "$workdir" || exit 1

    # Locate reads (paired)
    forward=$(ls ${reads_dir}/${metagenome}*_R1_paired.fastq* 2>/dev/null)
    reverse=$(ls ${reads_dir}/${metagenome}*_R2_paired.fastq* 2>/dev/null)

    if [[ -z "$forward" || -z "$reverse" ]]; then
        echo "Warning: missing reads for $metagenome, skipping..."
        continue
    fi

    # Copy to scratch, preserving gzip state
    if [[ $forward == *.gz ]]; then
        cp "$forward" ${workdir}/${metagenome}_1.fastq.gz
        cp "$reverse" ${workdir}/${metagenome}_2.fastq.gz
        read1=${workdir}/${metagenome}_1.fastq.gz
        read2=${workdir}/${metagenome}_2.fastq.gz
    else
        cp "$forward" ${workdir}/${metagenome}_1.fastq
        cp "$reverse" ${workdir}/${metagenome}_2.fastq
        read1=${workdir}/${metagenome}_1.fastq
        read2=${workdir}/${metagenome}_2.fastq
    fi

    mkdir -p ${out_dir}/${metagenome}

    # Run MaxBin2
    run_MaxBin.pl \
        -contig ${assemblies}/${metagenome}/scaffolds.fasta \
        -reads $read1 \
        -reads2 $read2 \
        -out ${out_dir}/${metagenome}/${metagenome}_maxbin2

    echo "Finished sample: $metagenome"
    echo "--------------------------------------------"
done

echo "All samples processed!"