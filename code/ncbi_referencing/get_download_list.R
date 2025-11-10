library(tidyverse)

setwd("/projects/p32449/maca_mags_metabolic")

# user input: fp to dir with tsvs with genomes of interest
genome_tsv_dir <- "data/MOBs_ncbi_refseqs"

# list tsvs
tsv_files <- list.files(genome_tsv_dir, pattern = "\\.tsv$", full.names = TRUE)

# read in tsvs
genomes <- map_dfr(tsv_files, ~ read_tsv(.x) %>% mutate(source_file = basename(.x))) 

# select only accession numbers
asc_list <- as.character(genomes$`Assembly Accession`)

writeLines(asc_list, paste0(genome_tsv_dir, "/MOB_total_list.txt"))

# make phy_key 
genomes_phy <- genomes %>% 
  mutate(phy = str_remove(source_file, "\\.tsv$"), 
    genome = `Assembly Accession`, 
    .keep = "unused") %>% 
  select(genome, phy)

write.csv(genomes_phy,"data/MOB_ncbi_refseqs/MOB_ncbi_phy_key.csv")
