library(tidyverse)

setwd("/projects/p32449/maca_mags_metabolic")

mag_class_fp <- "./data/2025-09-25_gtdbtk_outputs/arbac_all_out.csv"
ncbi_key_lite_fp <- "data/ncbi_dataset/ncbi_dataset_taxonomy_key.csv"
reference_fasta_key_fp <- "data/reference_phylum_subset.csv"

mags <- read.csv(mag_class_fp)
test_ncbi <- read.csv(ncbi_key_lite_fp)

ncbi_list <- Sys.glob(ncbi_key_comp_fp)
ncbi_tax_key_dfs <- map(ncbi_list, ~ read.csv(.x) %>% 
  rename(genome = 1) %>% 
  mutate(source_file = basename(.x)))
ncbi_tax_key <- bind_rows(ncbi_tax_key_dfs) %>% 
  mutate(phylum = str_remove(source_file, "_list\\.txt"), .keep = "unused") %>% 
  mutate(phylum = paste0(toupper(substr(phylum, 1,1)), substr(phylum, 2, nchar(phylum))))

ncbi_tax_key <- read.csv(reference_fasta_key_fp) %>% 
  mutate(genome = accession) %>% 
  select(genome, phylum)

ncbi_test_tax_key <- test_ncbi %>% 
  mutate(genome = assembly_id) %>% 
  select(genome, phylum) 

mag_tax_key <- mags %>% 
  mutate(genome = user_genome, .keep = "unused") %>% 
  mutate(phylum = str_extract(classification, "(?<=p__)[^;]+")) %>% 
  select(-classification)

phy_key <- bind_rows(ncbi_tax_key, ncbi_test_tax_key, mag_tax_key)

write.csv(phy_key, "data/phy_key.csv")
