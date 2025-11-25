#!/bin/bash
#SBATCH -A p32449
#SBATCH -p normal
#SBATCH -t 48:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --array=0-20 # change to number of metagenomes
#SBATCH --mem-per-cpu=20G
#SBATCH --job-name=bin_refinement-50compl-50contam
#SBATCH --mail-user=esmee@u.northwestern.edu # change to your email
#SBATCH --mail-type=START,FAIL,END
#SBATCH --output=%A_%a-%x.out

# user inputs -----------------------------
## note that you may need to chance the structure of the actual metawrap command (at the bottom of this file)
## depending on the structure of your bin directories
sample_list=/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt
parent_dir=/projects/p32449/maca_mags_metabolic/data
bins_a_dir=/scratch/jhr1326/2025-11-21_COMEBin
bins_b_dir=${parent_dir}/2025-11-21_metadecoder_results
bins_c_dir=/scratch/jhr1326/semibin_results_gpu_all
output_dir=/scratch/jhr1326/2025-11-25_metaWRAP-refined-bins-50compl-50contam
# ------------------------------------------

# list of samples from which to bin:
IFS=$'\n' read -d '' -r -a input_args < ${sample_list}
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

module purge all
module load checkm
module load mamba
source activate /projects/p31618/software/metawrap
PATH=/projects/p31618/software/metaWRAP/bin:$PATH

mkdir -p "${output_dir}/${metagenome}"

metawrap bin_refinement \
  -o ${output_dir}/${metagenome} \
  -t $SLURM_NTASKS \
  -A ${bins_a_dir}/${metagenome}/comebin_res/comebin_res_bins \
  -B ${bins_b_dir}/${metagenome}/*.fasta \
  -C ${bins_c_dir}/${metagenome}/output_bins \
  -c 50 -x 50

# back up results to scratch space
backup_dir=/scratch/$USER/refined_bins/${metagenome}
mkdir -p $backup_dir
cp -r ${output_dir} ${backup_dir}