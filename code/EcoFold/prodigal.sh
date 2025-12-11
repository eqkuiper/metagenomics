#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 10:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --array=0-20 # adjust to number of genomes
#SBATCH --mem=10G
#SBATCH --job-name=prodigal
#SBATCH --mail-user=esmee@u.northwestern.edu # change to your email
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --output=%A_%a-%x.out

# user paths ----------
input="/projects/p31618/eqk_metagenome_files/maca_scaffolds"
output="/projects/p32449/maca_mags_metabolic/2025-12-11_prodigal"
metagenome_list="/projects/p32449/maca_mags_metabolic/data/mags_to_annotate_assemblies.txt"
# ---------------------

# define metagenome
echo "Defining metagenome..."
mapfile -t input_args < "${metagenome_list}"
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

# load module 
echo "Loading prodigal..."
module load prodigal 

# make out dir
echo "Creating output directory..."
mkdir -p $output/${metagenome}

# run prodigal 
echo "Running prodigal..."
 
prodigal -i ${input}/${metagenome}.scaffolds.fasta \
             -o ${output}/${metagenome}/${metagenome}.genes \
             -a ${output}/${metagenome}/${metagenome}.faa \
             -d ${output}/${metagenome}/${metagenome}.fna \
             -f gff \
             -p meta


echo "Prodigal run complete!"

