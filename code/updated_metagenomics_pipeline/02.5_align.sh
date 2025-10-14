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
contig="/scratch/jhr1326/02_assembled-spades/CX_GO_13_21_S3/contigs.fasta"
fastq1="/scratch/jhr1326/CX_GO_13_21_S3_1.fastq" 
fastq2="/scratch/jhr1326/CX_GO_13_21_S3_2.fastq"
out="/scratch/jhr1326/02.5_align_test"
#############

outfile="$out/aligned.sam"
errorlog="$out/error.log"

mkdir -p $out

module load bowtie2 # load bowtie module aready in Quest

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

