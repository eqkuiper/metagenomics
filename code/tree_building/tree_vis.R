library(tidyverse)
library(ggtree)
library(ggnewscale)
library(ape)
library(paletteer)
library(plotly)

# USER INPUTS
parent_dir = "/projects/p32449/maca_mags_metabolic" # project directory
tree_fp = file.path(parent_dir, "data/2025-10-28_GToTree_out/2025-10-28_GToTree_out.tre") # tree fp
phy_fp = file.path(parent_dir, "data/phy_key.csv") # key with taxonomy
out_dir = file.path(parent_dir, "results") # output directory
tree_root = "GCA_000007345.1_ASM734v1_genomic" # genome on which to root tree
#

# load data
tree_raw <- read.tree(tree_fp)
phy <- read.csv(phy_fp) %>%
  select(genome, phylum) %>%
  mutate(
    phylum = if_else(
      is.na(phylum),
      NA_character_,
      paste0(toupper(substr(phylum, 1, 1)), substr(phylum, 2, nchar(phylum)))
    )
  ) %>% 
  mutate(
    genome_type = if_else(
      str_starts(genome, "GCA") | str_starts(genome, "GCF"), 
      "Reference genome",
      "Mammoth MAG"
    )
  ) %>% 
  mutate(phylum = case_when(
    phylum == "Bacteroidota_A" ~ "Bacteriodota", 
    phylum == "Desulfobacterota_B" ~ "Thermodesulfobacterota", 
    phylum == "Zixibacteria" ~ "Zixibacteriota", 
    .default = phylum
  ))

# reroot tree
tree_rerooted <- root(tree_raw, outgroup = tree_root)

# remove assembly info from tip names
tree_rerooted$tip.label <- str_replace(tree_rerooted$tip.label, "_ASM.*", "")

# visualize tree
tree_rerooted %>% 
  ggtree(layout = "equal_angle") %<+% phy +
  geom_tippoint(aes(color = phylum, shape = genome_type), size = 2) +
  scale_color_paletteer_d("palettesForR::Bears") +
  scale_shape_manual(values = c(16, 1)) + 
  labs(shape = "Genome type", color = "Phylum")

ggsave(paste0("results/figures/", Sys.Date(), "_equal_angle_tree.pdf"),
  width = 8, 
  height = 6)

tree_rect <- tree_rerooted %>% 
  ggtree() %<+% phy +
  geom_tippoint(aes(color = phylum, shape = genome_type, text = "genome"), size = 2) +
  scale_color_paletteer_d("ggsci::default_igv") +
  scale_shape_manual(values = c(16, 1)) + 
  labs(shape = "Genome type", color = "Phylum")

ggsave(paste0("results/figures/", Sys.Date(), "_rectangular_tree.pdf"),
  width = 8, 
  height = 20)

################

