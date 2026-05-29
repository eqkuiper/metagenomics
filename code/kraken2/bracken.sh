#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 01:00:00
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --array=0-20
#SBATCH --job-name=bracken_phylum
#SBATCH --output=%A_%a-%x.out
#SBATCH --mail-user=esmee@u.northwestern.edu
#SBATCH --mail-type=END,FAIL

# =============================================================================
# Bracken — phylum level — SLURM job array
# Runs on existing Kraken2 .report files
# =============================================================================

# --- USER CONFIG -------------------------------------------------------------
CONDA_ENV="/projects/p31618/kraken2"      # path to conda env with bracken
KRAKEN_DB="/projects/p31618/kraken2/kraken2_db"
KRAKEN_OUT="/scratch/jhr1326/260529_kraken2_out"  # your existing kraken2 output dir
READ_LEN=150
BRACKEN_LEVEL="P"                          # P = phylum
MIN_READS=10                               # min reads to report a taxon
# -----------------------------------------------------------------------------

# Activate conda
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

# Build sample list from existing kraken2 reports
mapfile -t SAMPLES < <(
    ls "${KRAKEN_OUT}"/*/*.kraken2.report \
    | xargs -n1 basename \
    | sed "s/.kraken2.report//" \
    | sort
)

# Validate array index
if [[ ${SLURM_ARRAY_TASK_ID} -ge ${#SAMPLES[@]} ]]; then
    echo "ERROR: SLURM_ARRAY_TASK_ID (${SLURM_ARRAY_TASK_ID}) >= number of samples (${#SAMPLES[@]})"
    exit 1
fi

SAMPLE="${SAMPLES[${SLURM_ARRAY_TASK_ID}]}"
SAMPLE_OUT="${KRAKEN_OUT}/${SAMPLE}"
KRAKEN_REPORT="${SAMPLE_OUT}/${SAMPLE}.kraken2.report"

echo "=============================="
echo "Job array ID : ${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
echo "Sample       : ${SAMPLE}"
echo "Kraken report: ${KRAKEN_REPORT}"
echo "Level        : Phylum"
echo "=============================="

# Sanity check
if [[ ! -f "${KRAKEN_REPORT}" ]]; then
    echo "ERROR: Kraken2 report not found: ${KRAKEN_REPORT}"
    exit 1
fi

# Skip if output already exists
if [[ -f "${SAMPLE_OUT}/${SAMPLE}.bracken.P.tsv" ]]; then
echo "[$(date)] Output already exists, skipping: ${SAMPLE}.bracken.P.tsv"
exit 0
fi

echo "[$(date)] Running Bracken at phylum level..."

bracken \
    -d "${KRAKEN_DB}" \
    -i "${KRAKEN_REPORT}" \
    -o "${SAMPLE_OUT}/${SAMPLE}.bracken.P.tsv" \
    -w "${SAMPLE_OUT}/${SAMPLE}.bracken.P.report" \
    -r "${READ_LEN}" \
    -l "${BRACKEN_LEVEL}" \
    -t "${MIN_READS}"

BRACKEN_EXIT=$?
if [[ ${BRACKEN_EXIT} -ne 0 ]]; then
    echo "ERROR: Bracken failed with exit code ${BRACKEN_EXIT}"
    exit ${BRACKEN_EXIT}
fi

echo "[$(date)] Bracken phylum complete for: ${SAMPLE}"

