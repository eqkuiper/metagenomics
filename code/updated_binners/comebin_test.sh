#!/bin/bash
#SBATCH -A p32449
#SBATCH -p gengpu
#SBATCH --gres=gpu:h100:1
#SBATCH -t 48:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --mem=60G
#SBATCH --job-name=comebin_test
#SBATCH --mail-user=esmee@u.northwestern.edu # change to your email
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --output=%A-%x.out

# user inputs
contig_file=/scratch/jhr1326/02_assembled-spades/CX_GO_13_21_S3/contigs.fasta 
output_path=/scratch/jhr1326/comebin_test
path_to_bamfiles=/scratch/jhr1326/02.5_align_test # DIR with bam files

# set up
module load python-miniconda3
eval "$(conda shell.bash hook)"
conda activate /projects/p32449/goop_stirrers/miniconda3/envs/comebin_env
module load cuda

# preprocess bam files
echo "Sorting BAM files and generating sorted coverage files..."

mkdir -p ${output_path}/sorted_bams
mkdir -p ${output_path}/coverage

for bam in ${path_to_bamfiles}/*.bam; do
    base=$(basename ${bam} .bam)
    sorted_bam=${output_path}/sorted_bams/${base}.sorted.bam
    coverage_file=${output_path}/coverage/${base}.coverage.txt
    sorted_cov=${output_path}/coverage/${base}.coverage.sorted.txt

    echo "Processing ${bam} ..."

    # Sort and index BAM
    samtools sort -o ${sorted_bam} ${bam}
    samtools index ${sorted_bam}

    # Generate coverage
    samtools depth -a ${sorted_bam} > ${coverage_file}

    # Sort coverage by contig name (critical for COMEBin)
    sort -k1,1 -V ${coverage_file} > ${sorted_cov}

    echo "Generated sorted coverage: ${sorted_cov}"
done

echo "All coverage files prepared successfully."

# run COMEBin
run_comebin.sh \
-a ${contig_file} \
-o ${output_path} \
-p ${output_path}/sorted_bams \
-t 40

