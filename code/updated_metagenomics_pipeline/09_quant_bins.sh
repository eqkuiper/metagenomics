#!/bin/bash
#SBATCH -A p31618
#SBATCH -p short
#SBATCH -t 04:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --array=0-20
#SBATCH --mem-per-cpu=12G
#SBATCH --job-name=quant_bins-nonreassembled_mags
#SBATCH --mail-user=esmee@u.northwestern.edu
#SBATCH --mail-type=END
#SBATCH --output=%A_%a-%x.out

# user inputs -----------------------------
sample_list=/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt
initial_bins=/scratch/jhr1326/2025-11-25_metaWRAP-refined-bins-50compl-50contam
output_dir=/scratch/jhr1326/2025-12-01_quant_nonreassembled_bins
reads_dir=/projects/p31618/nu-seq/Osburn02_12.10.2021_metagenomes/reads
metagenome_assembly=/scratch/jhr1326/02_assembled-spades_10Nov2025
# ------------------------------------------

# load sample names correctly
IFS=$'\n' read -d '' -r -a input_args < $sample_list
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

mkdir -p ${output_dir}/${metagenome}

# load software
module purge all
module load checkm
module load mamba
source activate /projects/p31618/software/metawrap
PATH=/projects/p31618/software/metaWRAP/bin:$PATH
module load salmon/1.9.0

# temp bin directory (per job)
tmp_bin_dir=/scratch/${USER}/tmp-nonreassembled-bins/${metagenome}
mkdir -p ${tmp_bin_dir}

# copy bin fastas to tmp
cp ${initial_bins}/${metagenome}/metawrap_50_50_bins/*.fa ${tmp_bin_dir}

# temp read directory (per job)
tmp_read_dir=/scratch/${USER}/tmp-read-pairs/${metagenome}
mkdir -p ${tmp_read_dir}

# If using unzipped reads
cp ${reads_dir}/${metagenome}*R1*.fastq* ${tmp_read_dir} 2>/dev/null
cp ${reads_dir}/${metagenome}*R2*.fastq* ${tmp_read_dir} 2>/dev/null

# normalize read names
forward_reads=${tmp_read_dir}/${metagenome}_1.fastq
reverse_reads=${tmp_read_dir}/${metagenome}_2.fastq

for f in ${tmp_read_dir}/*R1*.fastq*; do
    gunzip -c "$f" > "$forward_reads"
done

for f in ${tmp_read_dir}/*R2*.fastq*; do
    gunzip -c "$f" > "$reverse_reads"
done

# quantify bins
metawrap quant_bins \
  -b ${tmp_bin_dir} \
  -o ${output_dir}/${metagenome} \
  -a ${metagenome_assembly}/${metagenome}/scaffolds.fasta \
  -t ${SLURM_NTASKS} \
  ${forward_reads} \
  ${reverse_reads}