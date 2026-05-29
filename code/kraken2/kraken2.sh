#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 04:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G
#SBATCH --array=0-20
#SBATCH --job-name=kraken2
#SBATCH --output=%A_%a-%x.out
#SBATCH --mail-user=esmee@u.northwestern.edu
#SBATCH --mail-type=END,FAIL
# =============================================================================
# Kraken2 + Bracken SLURM job array
# =============================================================================
# BEFORE SUBMITTING — edit the five variables below 
#
# Expected input naming convention:
#   {SAMPLE_NAME}_R1.fastq.gz  /  {SAMPLE_NAME}_R2.fastq.gz
# (edit R1_SUFFIX / R2_SUFFIX below if yours differ)
# =============================================================================

# --- USER CONFIG -------------------------------------------------------------
CONDA_ENV="/projects/p31618/kraken2" # name of your conda environment
KRAKEN_DB="/projects/p31618/kraken2/kraken2_db" # directory containing hash.k2d etc.
INPUT_DIR="/projects/p31618/nu-seq/Osburn02_12.10.2021_metagenomes/trimmomatic"  # directory containing your FASTQs
OUTPUT_DIR="/scratch/jhr1326/260529_kraken2_out"      # will be created if absent
READ_LEN=150     # your trimmed read length (for Bracken)
BRACKEN_LEVEL="S"  # taxonomic level: S=species, G=genus, F=family
R1_SUFFIX="_R1_paired.fastq.gz"
R2_SUFFIX="_R2_paired.fastq.gz"
# -----------------------------------------------------------------------------

# Activate conda environment
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

# Build sample list from R1 files (sorted for reproducible array indexing)
mapfile -t SAMPLES < <(
    ls "${INPUT_DIR}"/*"${R1_SUFFIX}" \
    | xargs -n1 basename \
    | sed "s/${R1_SUFFIX}//" \
    | sort
)

# Validate array index
if [[ ${SLURM_ARRAY_TASK_ID} -ge ${#SAMPLES[@]} ]]; then
    echo "ERROR: SLURM_ARRAY_TASK_ID (${SLURM_ARRAY_TASK_ID}) >= number of samples (${#SAMPLES[@]})"
    exit 1
fi

SAMPLE="${SAMPLES[${SLURM_ARRAY_TASK_ID}]}"
R1="${INPUT_DIR}/${SAMPLE}${R1_SUFFIX}"
R2="${INPUT_DIR}/${SAMPLE}${R2_SUFFIX}"
SAMPLE_OUT="${OUTPUT_DIR}/${SAMPLE}"

echo "=============================="
echo "Job array ID : ${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
echo "Sample       : ${SAMPLE}"
echo "R1           : ${R1}"
echo "R2           : ${R2}"
echo "Output dir   : ${SAMPLE_OUT}"
echo "=============================="

# Sanity checks
for f in "${R1}" "${R2}"; do
    if [[ ! -f "${f}" ]]; then
        echo "ERROR: Input file not found: ${f}"
        exit 1
    fi
done

mkdir -p "${SAMPLE_OUT}" logs

# --- Kraken2 -----------------------------------------------------------------
echo "[$(date)] Running Kraken2..."

THREADS=${SLURM_CPUS_PER_TASK:-8}

kraken2 \
    --db "${KRAKEN_DB}" \
    --threads "${THREADS}" \
    --paired \
    --gzip-compressed \
    --report "${SAMPLE_OUT}/${SAMPLE}.kraken2.report" \
    --report-minimizer-data \
    --output "${SAMPLE_OUT}/${SAMPLE}.kraken2.output" \
    "${R1}" "${R2}"

KRAKEN_EXIT=$?
if [[ ${KRAKEN_EXIT} -ne 0 ]]; then
    echo "ERROR: Kraken2 failed with exit code ${KRAKEN_EXIT}"
    exit ${KRAKEN_EXIT}
fi

echo "[$(date)] Kraken2 complete."

# --- Bracken -----------------------------------------------------------------
echo "[$(date)] Running Bracken (level=${BRACKEN_LEVEL}, read_len=${READ_LEN})..."

bracken \
    -d "${KRAKEN_DB}" \
    -i "${SAMPLE_OUT}/${SAMPLE}.kraken2.report" \
    -o "${SAMPLE_OUT}/${SAMPLE}.bracken.${BRACKEN_LEVEL}.tsv" \
    -w "${SAMPLE_OUT}/${SAMPLE}.bracken.${BRACKEN_LEVEL}.report" \
    -r "${READ_LEN}" \
    -l "${BRACKEN_LEVEL}" \
    -t 10

BRACKEN_EXIT=$?
if [[ ${BRACKEN_EXIT} -ne 0 ]]; then
    echo "ERROR: Bracken failed with exit code ${BRACKEN_EXIT}"
    exit ${BRACKEN_EXIT}
fi

echo "[$(date)] Bracken complete."
echo "[$(date)] All done for sample: ${SAMPLE}"