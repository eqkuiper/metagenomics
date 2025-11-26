#!/bin/bash

#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 48:00:00
#SBATCH -N 1
#SBATCH -n 12
#SBATCH --array=0-20
#SBATCH --mem-per-cpu=8G
#SBATCH --job-name=reassemble_bins_mags
#SBATCH --mail-user=esmee@u.northwestern.edu 
#SBATCH --mail-type=END
#SBATCH --output=%A_%a-%x.out

# user inputs -----------------------------
## note that you may need to chance the structure of the actual metawrap command (at the bottom of this file)
## depending on the structure of your bin directories
sample_list=/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt
initial_bins=/scratch/jhr1326/2025-11-25_metaWRAP-refined-bins-50compl-50contam
output_dir=/scratch/jhr1326/2025-11-26_reassembled_bins
reads_dir=/projects/p31618/nu-seq/Osburn02_12.10.2021_metagenomes/reads
# ------------------------------------------

mkdir -p ${output_dir}

# load software
module purge
module load mamba
source activate /projects/p31618/software/metawrap
PATH=/projects/p31618/software/metaWRAP/bin:$PATH
module load bwa
module load checkm
module load spades/3.14.1

# get metagenome ID for this array task
IFS=$'\n' read -d '' -r -a input_args < ${sample_list}
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

echo "Running sample: ${metagenome}"

# make scratch dirs
tmp_bin_dir=/scratch/${USER}/tmp-bins/${metagenome}
tmp_read_dir=/scratch/${USER}/tmp-read-pairs/${metagenome}
mkdir -p ${tmp_bin_dir} ${tmp_read_dir}

# copy bin files
cp ${initial_bins}/${metagenome}/metawrap_50_50_bins/*.fa ${tmp_bin_dir}

# decompress & rename reads safely
for fq in ${reads_dir}/${metagenome}_R*.fastq.gz; do
    base=$(basename "$fq")
    # identify R1 vs R2
    if [[ $base == *"R1"* ]]; then
        gunzip -c "$fq" > ${tmp_read_dir}/${metagenome}_1.fastq
    elif [[ $base == *"R2"* ]]; then
        gunzip -c "$fq" > ${tmp_read_dir}/${metagenome}_2.fastq
    fi
done

forward_reads=${tmp_read_dir}/${metagenome}_1.fastq
reverse_reads=${tmp_read_dir}/${metagenome}_2.fastq

# run reassembly
metawrap reassemble_bins \
    -o ${output_dir}/${metagenome} \
    -1 ${forward_reads} \
    -2 ${reverse_reads} \
    -t ${SLURM_NTASKS} \
    -c 30 \
    -x 30 \
    -b ${tmp_bin_dir}

# cleanup for this sample only
rm -r ${tmp_bin_dir}
rm -r ${tmp_read_dir}