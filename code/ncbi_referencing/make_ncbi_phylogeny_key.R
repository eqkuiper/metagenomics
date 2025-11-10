library(jsonlite)
library(dplyr)
library(purrr)
library(stringr)

# set base directory 
base_dir <- "/projects/p32449/maca_mags_metabolic/data/ncbi_dataset/"

# get list of json files with ncbi taxonomies 
jsonl_files <- list.files(base_dir, pattern = "\\.jsonl$", full.names = TRUE)

# make function to extract taxonomy from json files
extract_taxonomy <- function(fp) {

data <- fromJSON(fp)
  
domain <- data$reports$taxonomy$classification$domain$name
phylum <- data$reports$taxonomy$classification$phylum$name
`class` <- data$reports$taxonomy$classification$class$name
order <- data$reports$taxonomy$classification$order$name
family <- data$reports$taxonomy$classification$family$name
genus <- data$reports$taxonomy$classification$genus$name
species <- str_split(data$reports$taxonomy$classification$species$name, " ")[[1]][2]
gca <- list.files(paste0(str_remove(fp, "_taxonomy\\.jsonl")), pattern = "^GCA", 
  include.dirs = TRUE)
  
tibble(
  file = basename(fp), 
  assembly_id = gca, 
  domain = domain, 
  phylum = phylum, 
  class = class, 
  order = order, 
  family = family, 
  genus = genus, 
  species = species
)
}

# apply function to list of json files
json_df <- map_dfr(jsonl_files, extract_taxonomy)

# save df as csv
write.csv(json_df, "/projects/p32449/maca_mags_metabolic/data/ncbi_dataset/ncbi_dataset_taxonomy_key.csv",
  row.names = FALSE)
