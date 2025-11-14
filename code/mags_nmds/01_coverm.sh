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
#SBATCH --error=%A_%x.err

# ===========================
# User inputs
# ===========================
BAMS_DIR=/scratch/jhr1326/2025-10-20_02.5_align
MAGS_DIR=/projects/p32449/maca_mags_metabolic/data/2025-09-16_metagenomes
TMP_DIR=/scratch/jhr1326/maca_mags_metabolic_tmp
OUT_DIR=/projects/p32449/maca_mags_metabolic/2025-11-14_coverm
THREADS=16
# ===========================

echo "[$(date)] Starting CoverM workflow"

# Create output and temporary directories
mkdir -p "$OUT_DIR"
mkdir -p "$TMP_DIR"
echo "[$(date)] Created output directory ($OUT_DIR) and temporary directory ($TMP_DIR)"

# Copy MAGs to tmp dir and rename contigs uniquely & safely
echo "[$(date)] Copying and renaming MAGs..."
cd "$MAGS_DIR" || { echo "ERROR: Cannot cd to $MAGS_DIR"; exit 1; }

for f in *.orig.fasta *.strict.fasta *.permissive.fasta; do
    # Determine new filename
    newname="${f/.orig.fasta/_orig.fna}"
    newname="${newname/.strict.fasta/_strict.fna}"
    newname="${newname/.permissive.fasta/_permissive.fna}"

    # Copy to tmp
    cp "$f" "$TMP_DIR/$newname"
    echo "  Copied $f -> $TMP_DIR/$newname"

    # Prepend MAG name to each contig header
    mag_base=$(basename "$newname" .fna)
    sed -i "s/^>/>${mag_base}_/g" "$TMP_DIR/$newname"

    # Sanitize headers: letters, numbers, underscores only
    sed -i "s/[^A-Za-z0-9_]/_/g" "$TMP_DIR/$newname"

    echo "  Renamed and sanitized contigs in $newname"
done

# Verify contig counts
echo "[$(date)] Contig counts per file in temporary directory:"
grep -c "^>" "$TMP_DIR"/*.fna

# Load CoverM environment
echo "[$(date)] Loading CoverM environment..."
module load python-miniconda3
eval "$(conda shell.bash hook)"
conda activate /projects/p32449/goop_stirrers/miniconda3/envs/coverm
echo "[$(date)] CoverM environment activated"

# Run CoverM
echo "[$(date)] Running CoverM..."
coverm genome \
    -b "${BAMS_DIR}"/*/*_sorted.bam \
    -m relative_abundance \
    --genome-fasta-directory "$TMP_DIR" \
    --threads "$THREADS" \
    > "${OUT_DIR}/coverm_relative_abundance.tsv"

echo "[$(date)] CoverM finished! Output saved to ${OUT_DIR}/coverm_relative_abundance.tsv"