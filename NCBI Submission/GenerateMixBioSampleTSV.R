## generate_mix_biosample_tsv.R
## Builds the MIX BioSample batch submission TSV (MIMARKS: survey, host-associated; v6.0)
## Mirrors the schema/values used in LPHY's biosample_submission_FINAL.tsv
## - 15 new Mix Dose 1-3 samples (5 reps each), parsed from Dropbox filenames
## - 4 shared H2O background controls, duplicated from LPHY with new sample_name/host_subject_id
##   (physical sample identity preserved via reused SAMN# at the SRA Experiment/Run step,
##    NOT re-registered as new BioSamples here -- those were already linked to PRJNA1510685
##    via the BioProject wizard's "Existing BioSample" field)

library(dplyr)
library(readr)
library(stringr)

# ---- 1. Fixed schema (72 columns, same order as LPHY submission) ----
mimarks_cols <- c(
  "sample_name","sample_title","bioproject_accession","organism","collection_date",
  "env_broad_scale","env_local_scale","env_medium","geo_loc_name","host","lat_lon",
  "altitude","ances_data","biol_stat","chem_administration","collection_method","depth",
  "elev","genetic_mod","gravidity","host_age","host_blood_press_diast","host_blood_press_syst",
  "host_body_habitat","host_body_product","host_body_temp","host_color","host_common_name",
  "host_diet","host_disease","host_dry_mass","host_family_relationship","host_genotype",
  "host_growth_cond","host_height","host_last_meal","host_length","host_life_stage",
  "host_phenotype","host_sex","host_shape","host_subject_id","host_subspecf_genlin",
  "host_substrate","host_symbiont","host_taxid","host_tissue_sampled","host_tot_mass",
  "isolation_source","misc_param","neg_cont_type","omics_observ_id","organism_count",
  "oxy_stat_samp","perturbation","pos_cont_type","rel_to_oxygen","samp_capt_status",
  "samp_collect_device","samp_dis_stage","samp_mat_process","samp_salinity","samp_size",
  "samp_store_dur","samp_store_loc","samp_store_temp","samp_vol_we_dna_ext","size_frac",
  "source_material_id","temp","description","treatment_group"
)

MIX_PRJNA <- "PRJNA1510685"

# ---- 2. Constants shared across LPHY and MIX (same animal model, same collection protocol) ----
# NOTE: collection_date below is inherited from LPHY as a placeholder -- CONFIRM this is
# correct for the MIX cohort before submitting; update if MIX samples were collected on a
# different date than LPHY's.
shared_defaults <- tibble(
  bioproject_accession = MIX_PRJNA,
  organism             = "chicken gut metagenome",
  collection_date       = "2025-03-11",     # <-- CONFIRM for MIX cohort
  env_broad_scale       = "ENVO:00009003",
  env_local_scale       = "ENVO:08000006",
  env_medium            = "ENVO:00002047",
  geo_loc_name          = "USA: Ithaca, NY",
  host                  = "Gallus gallus",
  lat_lon               = "not collected",
  host_body_habitat     = "gastrointestinal tract",
  host_taxid            = "9031",
  host_tissue_sampled   = "cecum",
  isolation_source      = "cecal content",
  samp_collect_device   = "tissue biopsy",
  samp_mat_process      = "dissected and snap-frozen in liquid nitrogen"
)

# ---- 3. New Mix Dose 1-3 samples, parsed from Dropbox filenames ----
mix_filenames <- c(
  "MIX-1-1.3_42","MIX-1-2.3_43","MIX-1-3.4_36","MIX-1-4.4_37","MIX-1-5.4_38",
  "MIX-2-1.4_39","MIX-2-2.4_40","MIX-2-3.4_41","MIX-2-4.4_42","MIX-2-5.4_43",
  "MIX-3-1.5_36","MIX-3-2.5_37","MIX-3-3.5_38","MIX-3-4.5_39","MIX-3-5.5_40"
)

mix_sample_sheet <- tibble(sample_name = mix_filenames) %>%
  mutate(
    dose            = str_extract(sample_name, "(?<=MIX-)\\d"),
    replicate       = str_extract(sample_name, "(?<=MIX-\\d-)\\d"),
    treatment_group = paste0("MIX", dose),
    sample_title    = paste(treatment_group, "replicate", replicate),
    host_subject_id = sample_name,
    description     = paste0(
      "16S rRNA amplicon library, ", treatment_group,
      " treatment arm, 27F_1492R_Kinnex primers, PacBio_HiFi sequencing"
    )
  ) %>%
  select(-dose, -replicate)

mix_new_rows <- mix_sample_sheet %>%
  bind_cols(shared_defaults[rep(1, nrow(.)), ]) %>%
  select(any_of(mimarks_cols))

# ---- 4. Duplicate the shared H2O background controls under new identifiers ----
# Only H2O is shared -- confirmed no "No Injection" control exists for sequencing.
lphy_tsv <- read_tsv(
  "C:/Users/Chloe/OneDrive - Cornell University/study-1-march25/LPHY/NCBI Submission Files/biosample_submission_FINAL.tsv",
  col_types = cols(.default = col_character()),  # prevent type-guessing (e.g. collection_date -> Date)
  show_col_types = FALSE
)

controls_duplicated <- lphy_tsv %>%
  filter(treatment_group == "H2O") %>%
  mutate(
    sample_name         = paste0("MIX-", sample_name),
    sample_title         = paste("MIX batch -", sample_title),
    host_subject_id       = paste0("MIX-", host_subject_id),
    # source_material_id was blank in the LPHY source data -- guard against
    # paste0() turning NA/"" into the literal string "MIX-NA"
    source_material_id    = if_else(
      is.na(source_material_id) | source_material_id == "",
      source_material_id,
      paste0("MIX-", source_material_id)
    ),
    bioproject_accession   = MIX_PRJNA,
    description           = paste0(description, " [shared control, reuses SAMN# from LPHY submission]")
  ) %>%
  select(any_of(mimarks_cols))

# ---- 5. Assemble and write ----
mix_biosample_tsv <- bind_rows(mix_new_rows, controls_duplicated)

write_tsv(mix_biosample_tsv, "mix_biosample_submission.tsv", na = "")

message(nrow(mix_new_rows), " new Mix Dose samples + ", nrow(controls_duplicated),
        " duplicated H2O controls = ", nrow(mix_biosample_tsv), " total rows written.")
