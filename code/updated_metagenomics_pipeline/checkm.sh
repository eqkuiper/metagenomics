#!/bin/bash
#SBATCH -A p31618
#SBATCH -p normal
#SBATCH -t 48:00:00
#SBATCH --mem=48G
#SBATCH -N 1
#SBATCH --ntasks-per-node=4
#SBATCH --mail-user=your-email@u.northwestern.edu # change to your email
#SBATCH --mail-type=END
#SBATCH --job-name="CheckM"
#SBATCH --output=%j-%x.out
#SBATCH --array=0-20

# USER INPUTS ----------------------------
parent_dir=/projects/p32449/maca_mags_metabolic
input_genomes=${parent_dir}/data/2025-10-21_COMEBin
checkm_out=${parent_dir}/data/2025-11-21_checkm/COMEBin_checkm
scratch=/scratch/${USER}/tmp
sample_list=/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt # list of samples
# -----------------------------------------

# Load CheckM
module purge all
module load checkm

# Load metagenome from sample list using array index
IFS=$'\n' read -d '' -r -a input_args < "$sample_list"
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

# Tell the out log a little bit about what we're doing
echo "Date: `date`"
echo "Node: `hostname`"
echo "Genome: ${metagenome}"
echo "Job : ${SLURM_JOB_ID}"
echo "Out : ${checkm_out}"
echo "Path: `pwd`"

# Move genomes to single scratch folder 
mkdir -p ${scratch}/${metagenome}
cd ${input_genomes}/${metagenome}/comebin_res/comebin_res_bins
cp *\.fa ${scratch}/${metagenome}

mkdir -p $checkm_out

# Run CheckM
checkm lineage_wf \
  -t $SLURM_NTASKS \
  -x fa \
  ${scratch}/${metagenome} \
  ${checkm_out}/${metagenome}

# Calculate completeness/contamination for each bin
checkm qa \
  -t $SLURM_NTASKS \
  -o 1 \
  -f ${checkm_out}/${metagenome}/qa_results.txt \
  --tab_table \
  ${checkm_out}/${metagenome}/lineage.ms \
  ${checkm_out}/${metagenome}

# Remove tmp directory
rm -r ${scratch}/${metagenome}