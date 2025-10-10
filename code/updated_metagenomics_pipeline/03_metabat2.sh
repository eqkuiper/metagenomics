#!/bin/bash
#SBATCH -A p31618
#SBATCH -p short
#SBATCH -t 04:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --array=0-3 # do NOT edit this line in this script
#SBATCH --mem=8G
#SBATCH --job-name=metabat2-mammoth-scaffolds
#SBATCH --mail-user=esmee@u.northwestern.edu # change to your email
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --output=%A_%a-%x.out

### USER INPUTS
parent_dir="/projects/p32449/maca_mags_metabolic/data/2025-10-07_maca_metaG" # directory for current metagenomics project
spades_dir="/scratch/jhr1326/02_assembled-spades" # directory with output from assembler
min_contig_length=(3000 2500 2000 1500) # should be >= 1500
###############

# define output
out_dir=${parent_dir}/03_metabat2-scaffolds-c_${min_contig_length[$SLURM_ARRAY_TASK_ID]}
mkdir -p "$out_dir"

# load metabat2 conda environment
module load python-miniconda3
source activate /projects/p31618/software/metabat2-2.18
export LD_LIBRARY_PATH=/projects/p31618/software/metabat2-2.18/lib:$LD_LIBRARY_PATH

# bin contigs with metabat2 for each subdirectory:
for dir in "$spades_dir"/*/; do

sample=$(basename $dir)

echo "Binning from:"
echo "$dir"

mkdir -p $out_dir/$sample

SECONDS=0
metabat \
-i $contigs_dir/scaffolds.fasta \
-m ${min_contig_length[$SLURM_ARRAY_TASK_ID]} \
-o $out_dir/$sample/${sample}_bin \
-t $SLURM_NTASKS \
--unbinned

echo "[$SECONDS seconds] required to bin MAGs."
echo "Saved to "$out_dir/$sample"."
echo "Have a wonderful $(date +%A), and don't your dreams be dreams."

done




