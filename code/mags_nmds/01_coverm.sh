#!/bin/bash
#SBATCH -A p32449
#SBATCH -p normal
#SBATCH -t 12:00:00
#SBATCH -N 1
#SBATCH -n 16
#SBATCH --mem=20G
#SBATCH --job-name=coverm
#SBATCH --mail-user=esmee@u.northwestern.edu
#SBATCH --mail-type=START,FAIL,END
#SBATCH --output=%A_%a-%x.out

# user inputs
bams_dir=/scratch/jhr1326/2025-10-20_02.5_align
mags_dir=/projects/p32449/maca_mags_metabolic/data/2025-09-16_metagenomes
tmp_dir=/scratch/jhr1326/maca_mags_metabolic_tmp
out_dir=/projects/p32449/maca_mags_metabolic/2025-11-14_coverm
# -----------

mkdir -p $out_dir
mkdir -p $tmp_dir

# copy and rename MAGs to tmp dir with underscores
cd $mags_dir
for f in *.orig.fasta *.strict.fasta *.permissive.fasta; do
    # convert filename suffix
    newname="${f/.orig.fasta/_orig.fna}"
    newname="${newname/.strict.fasta/_strict.fna}"
    newname="${newname/.permissive.fasta/_permissive.fna}"

    # copy to tmp
    cp "$f" "$tmp_dir/$newname"

    # make contig headers unique by prepending MAG name
    mag_base=$(basename "$newname" .fna)
    sed -i "s/^>/>${mag_base}_/g" "$tmp_dir/$newname"
done

# load coverm environment
module load python-miniconda3
eval "$(conda shell.bash hook)"
conda activate /projects/p32449/goop_stirrers/miniconda3/envs/coverm

# run coverm using the tmp MAGs
coverm genome \
    -b ${bams_dir}/*/*_sorted.bam \
    -m relative_abundance \
    --genome-fasta-directory $tmp_dir \
    --threads 16 \
    > ${out_dir}/coverm_relative_abundance.tsv
