# app.R
# Single-file Shiny app for NMDS plotting

library(shiny)
library(tidyverse)
library(vegan)
library(plotly)
library(paletteer)

# -----------------------------
# 1. Load preprocessed data
# -----------------------------

# Relative paths
tsv_fp <- "data/2025-09-16_metabolic_out_tsv1"
color_fp <- "data/color_dictionary_draft07.csv"
classification_fp <- "data/2025-09-25_gtdbtk_outputs/arbac_all_out.csv"
isotopes_fp <- "data/mammoth_meta_may25.csv"
metadata_fp <- "data/MasterSampleList(sediment&water).csv"

# ---- Read and tidy metabolic TSVs ----
tsv_list <- list.files(tsv_fp, full.names = TRUE)
read_safe_tsv <- function(f) {
  read_tsv(f, show_col_types = FALSE) |> 
    mutate(source_file = basename(f))
}
tsv_dfs <- lapply(tsv_list, read_safe_tsv)

# Metadata
metadata_df <- tsv_dfs[[1]] %>% 
  select(Category:`Hmm detecting threshold`) %>% 
  mutate(hmm_files = `Hmm file`)

# Remove metadata
tsvs_naked <- map(tsv_dfs, function(df) {
  start <- match("Category", names(df))
  end   <- match("Hmm detecting threshold", names(df))
  df[ , -(start:end)]
})

tsvs_naked_all <- bind_cols(tsvs_naked, .id = "source_file")
tsvs_metadata <- bind_cols(metadata_df, tsvs_naked_all)

# Pivot longer
tsvs_tidy <- tsvs_metadata |> 
  select(-starts_with("source_file"), -.id) |> 
  mutate(across(-c(Category:hmm_files), as.character)) |> 
  pivot_longer(
    cols = -c(Category:hmm_files),
    names_to = "sample_bin_measure",
    values_to = "value"
  ) |> 
  separate(sample_bin_measure, into = c("sample_bin", "measurement"), sep = " ", extra = "merge") |> 
  pivot_wider(names_from = "measurement", values_from = "value") |> 
  mutate(Gene.name = `Gene name`, .keep = "unused") |> 
  mutate(hmm_files_singles = as.character(hmm_files)) |> 
  separate_rows(hmm_files_singles, sep = "[\\s,]+")

# ---- Color dictionary ----
color_dictionary <- read_csv(color_fp)
color_dictionary_long <- color_dictionary %>% 
  mutate(hmm_files_singles = as.character(hmm_files), .keep = "unused")
color_map <- setNames(color_dictionary$color_func, color_dictionary$module)

# ---- Taxonomy ----
tax_raw <- read_csv(classification_fp)
tsvs_tax <- tsvs_tidy %>% 
  left_join(tax_raw, by = c("sample_bin" = "user_genome")) %>% 
  separate(classification, into = c("domain","phylum","class","order","family","genus","species"),
           sep=";", fill="right", remove=FALSE) %>% 
  mutate(across(domain:species, ~ sub(".*__", "", .))) %>% 
  mutate(KO = `Corresponding KO`, .keep = "unused")

# ---- Sample metadata ----
samp_metadata <- read_csv(metadata_fp) %>% select(-starts_with("..."))
samp_isotopes <- read_csv(isotopes_fp)
samp_metadata <- samp_metadata %>% 
  left_join(samp_isotopes) %>% 
  group_by(reconciled_name) %>% slice(1)

# ---- Join everything ----
tsvs_plot <- tsvs_tax %>% 
  left_join(color_dictionary_long, by = "hmm_files_singles") %>% 
  mutate(sample = str_remove(sample_bin, "_bin.*$")) %>% 
  mutate(metadata_samp = str_remove(sample, "_S\\d+")) %>% 
  left_join(samp_metadata, by = c("metadata_samp" = "reconciled_name"))

# -----------------------------
# 2. Prepare NMDS datasets
# -----------------------------
# Function to prep NMDS per category
prep_nmds <- function(df, cat_filter = NULL) {
  if (!is.null(cat_filter)) df <- df %>% filter(Category %in% cat_filter)
  
  nmds_data <- df %>% 
    select(ends_with("Hit numbers")) %>% 
    rename_with(~ str_remove(., " Hit numbers$"))
  
  rownames(nmds_data) <- df$`Gene name` %>% make.unique()
  
  nmds_data <- as.data.frame(nmds_data) %>% 
    select(where(~ sum(.x, na.rm = TRUE) > 0)) %>% 
    filter(rowSums(across(everything()), na.rm = TRUE) > 0) %>% 
    as.matrix()
  
  nmds_data_rel <- decostand(t(nmds_data), method="total")
  nmds_data_dist <- vegdist(nmds_data_rel, method="bray")
  
  set.seed(62125)
  nmds_k2 <- metaMDS(nmds_data_dist, distance="bray", k=2)
  plot_df <- as.data.frame(scores(nmds_k2)) %>% 
    mutate(bin = rownames(.)) %>% 
    mutate(reconciled_name = str_remove(bin, "_S.*$")) %>% 
    left_join(samp_metadata, by = "reconciled_name")
  
  return(plot_df)
}

nmds_datasets <- list(
  "All marked genes" = prep_nmds(tsvs_metadata),
  "Nitrogen cycling" = prep_nmds(tsvs_metadata, "Nitrogen cycling"),
  "C1 metabolism/C fixation" = prep_nmds(tsvs_metadata, c("C1 metabolism","Methane metabolism","Carbon fixation")),
  "Sulfur cycling" = prep_nmds(tsvs_metadata, c("Sulfur cycling"))
)

allowed_cols <- c("Cave","sample_type","sample_type2","pct_OC","pct_ON","d13Corg","d15Norg")

# -----------------------------
# 3. Shiny UI
# -----------------------------
ui <- fluidPage(
  titlePanel("Interactive NMDS Plot"),
  sidebarLayout(
    sidebarPanel(
      selectInput("dataset","Choose NMDS dataset:", choices = names(nmds_datasets)),
      uiOutput("color_var_ui")
    ),
    mainPanel(
      plotlyOutput("nmdsPlot")
    )
  )
)

# -----------------------------
# 4. Shiny server
# -----------------------------
server <- function(input, output, session) {
  current_data <- reactive({ nmds_datasets[[input$dataset]] })
  
  output$color_var_ui <- renderUI({
    df <- current_data()
    selectable_cols <- intersect(colnames(df), allowed_cols)
    if(length(selectable_cols)==0) selectable_cols <- "NMDS1"
    selectInput("color_var","Color points by:", choices = selectable_cols)
  })
  
  output$nmdsPlot <- renderPlotly({
    req(input$color_var)
    df <- current_data()
    color_var <- input$color_var
    
    p <- ggplot(df, aes(x = NMDS1, y = NMDS2, color = !!sym(color_var),
                        text = paste0("bin: ", bin, "<br>",
                                      "sample: ", reconciled_name, "<br>",
                                      color_var, ": ", df[[color_var]]))) +
      geom_point(size = 3, alpha = 0.7) + theme_classic() + labs(color = color_var)
    
    if(is.numeric(df[[color_var]])) {
      p <- p + scale_color_paletteer_c("ggthemes::Purple", na.value = "grey")
    } else {
      lvls <- unique(df[[color_var]])
      p <- p + scale_color_manual(values = setNames(paletteer_d("MoMAColors::Klein", n = length(lvls)), lvls))
    }
    
    ggplotly(p, tooltip = "text")
  })
}

# -----------------------------
# 5. Run Shiny app
# -----------------------------
shinyApp(ui, server)
