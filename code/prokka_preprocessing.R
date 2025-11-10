library(tidyverse)

good_mags_fp <- "data/MJS_MAG_key.csv"
mag_dir <- "data/2025-09-16_metagenomes"
ref_mobs <- "data/MOBs_ncbi_refseqs/reference_fasta"

setwd("/projects/p32449/maca_mags_metabolic")

refs <- list.files(ref_mobs, full.names = TRUE, pattern = "\\.fna$") %>%
  tibble(file = .) %>%
  mutate(base = tools::file_path_sans_ext(basename(file)))

good_mags <- read_csv(good_mags_fp)

mags <- list.files(mag_dir, full.names = TRUE) %>%
  tibble(file = .) %>%
  mutate(base = tools::file_path_sans_ext(basename(file))) %>% 
  filter(base %in% good_mags$MAG_name) 

all_fasta <- bind_rows(refs, mags)

writeLines(all_fasta$file, "/projects/p32449/maca_mags_metabolic/data/2025-11-04_mob_protein_tree/MOB_mammoth_fasta_list.txt")

