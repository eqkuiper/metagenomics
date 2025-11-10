library(tidyverse)

phy_fp <- "ncbi_big_download" # folder with tsvs of stuff you want to download 

phy_list <- list.files(phy_fp, full.names = TRUE) # list files in file path

names(phy_list) <- phy_list

phy_df <- map(phy_list, ~ read_tsv(.)) %>% 
  bind_rows(.id = "file_path")

phy_tidy <- phy_df %>% 
  select(`Assembly Accession`, file_path) %>% 
  mutate(accession = `Assembly Accession`, 
    phylum = str_remove(file_path, ".*/") %>% 
      str_remove("\\.tsv$"), .keep = "unused")

write.csv(phy_tidy, "data/reference_phylum.csv")

phy_subset <- phy_tidy %>% 
  group_by(phylum) %>% 
  slice_sample(n = 30, replace = FALSE) %>% 
  ungroup()

write.csv(phy_subset, "data/reference_phylum_subset.csv")

writeLines(phy_subset$accession, "data/reference_phylum_subset.txt")
