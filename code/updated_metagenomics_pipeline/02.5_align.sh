#!/bin/bash
#SBATCH -A b1042                 # Account
#SBATCH -p genomics              # Partition
#SBATCH -t 12:00:00              # Max time
#SBATCH -N 1                     # Number of nodes
#SBATCH -n 4                     # Number of CPU cores
#SBATCH --mem=16G                # Memory
#SBATCH --job-name=bowtie2_align
#SBATCH --mail-user=youremail@domain.com
#SBATCH --mail-type=BEGIN,END,FAIL

# USER INPUTS
metagenome_list="/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt" # list of metagenomes
contig_dir="/scratch/jhr1326/02_assembled-spades"
reads_dir="/projects/p32449/maca_mags_metabolic/data/2025-10-07_maca_metaG/01_trimmomatic_out"
out_dir="/scratch/jhr1326/2025-10-20_02.5_align"
#############

mkdir -p $out_dir

# define metagenome
IFS=$'\n' read -d '' -r -a input_args < "${metagenome_list}"
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

# make output directory for each genome
data_out="${out_dir}/${metagenome}"
mkdir -p $data_out

# define inputs for bowtie2 function
contig="$contig_dir/$metagenome/contigs.fasta"
fastq1="$reads_dir/${metagenome}_R1_paired.fastq"
fastq2="$reads_dir/${metagenome}_R2_paired.fastq"
outfile="$data_out/${metagenome}.sam"
errorlog="$data_out/${metagenome}.err"
bamfile="$data_out/${metagenome}.bam"

module load bowtie2 # load bowtie module aready in Quest
module load samtools

# Build index if not already done
if [ ! -f "${contig}.1.bt2" ]; then
    echo "Building Bowtie2 index..."
    bowtie2-build $contig $contig
fi

echo "Starting alignment at $(date)"

# Run bowtie2
bowtie2 -x $contig -1 $fastq1 -2 $fastq2 -S $outfile -p $SLURM_NTASKS 2> $errorlog

# Check exit status
if [ $? -ne 0 ]; then
    echo "Bowtie2 failed! Check error log: $errorlog"
    exit 1
else
    echo "Alignment completed successfully at $(date)"
fi

# Convert to BAM file required for most downstream processing steps
echo "Converting SAM to BAM for $metagenome..."
samtools view -bS "$outfile" > "$bamfile"

# Sort and index BAM
echo "Sorting and indexing BAM file..."
samtools sort "$bamfile" -o "${data_out}/${metagenome}_sorted.bam"
if [ $? -ne 0 ]; then
    echo "samtools sorting failed for $metagenome" >> "$errorlog"
    exit 1
else
    echo "BAM sorting completed successfully at $(date)"
fi

samtools index "${data_out}/${metagenome}_sorted.bam"
if [ $? -ne 0 ]; then
    echo "samtools index failed for $metagenome" >> "$errorlog"
    exit 1
else
    echo "BAM indexing completed successfully at $(date)"
fi

# Final verification
if [ -f "${data_out}/${metagenome}_sorted.bam" ] && [ -f "${data_out}/${metagenome}_sorted.bam.bai" ]; then
    echo "All steps completed successfully for $metagenome at $(date)"
else
    echo "Final output files missing for $metagenome — check logs." >> "$errorlog"
    exit 1
fi

echo "Job finished for $metagenome on $(hostname) at $(date). Best of luck with the rest of your day!"

