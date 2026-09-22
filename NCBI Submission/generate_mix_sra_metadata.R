## generate_mix_sra_metadata.R
## Builds the SRA metadata batch TSV for MIX, pairing each BioSample accession
## with its FASTQ file. Mirrors LPHY's SRA submission structure (SUB16315294):
## full-length 16S rRNA (27F/1492R, V1-V9), PacBio HiFi CCS, single-end layout.

library(dplyr)
library(readr)

# ---- 1. BioSample accessions from the processed MIX BioSample submission (SUB16397967) ----
mix_accessions <- read_tsv("attributes__2_.tsv", show_col_types = FALSE) %>%
  select(sample_name, accession, treatment_group)

# ---- 2. Sequencing parameters (confirm instrument_model against sequencing core run report) ----
INSTRUMENT_MODEL <- "Sequel II"   # <-- CONFIRM: "PacBio HiFi" describes chemistry/read type,
#     not a valid NCBI instrument string. Verify against
#     the actual run report (Sequel II / Sequel IIe / Revio).

sra_defaults <- tibble(
  library_strategy   = "AMPLICON",
  library_source     = "METAGENOMIC",
  library_selection  = "PCR",
  library_layout     = "single",
  platform           = "PACBIO_SMRT",
  instrument_model   = INSTRUMENT_MODEL,
  design_description = "Full-length 16S rRNA gene amplicon (V1-V9), 27F/1492R Kinnex primers, PacBio HiFi CCS sequencing",
  filetype           = "fastq"
)

# ---- 3. Assemble SRA metadata rows ----
mix_sra_metadata <- mix_accessions %>%
  mutate(
    biosample_accession = accession,   # NCBI SRA wizard requires this exact header
    library_ID        = paste0("MIX_", sample_name),   # must be unique -- do not reuse LPHY's library_IDs
    title             = paste0(
      "16S rRNA amplicon sequencing of ", treatment_group, " sample ", sample_name
    ),
    filename          = paste0(sample_name, ".fastq.gz")
  ) %>%
  bind_cols(sra_defaults[rep(1, nrow(.)), ]) %>%
  select(
    biosample_accession, library_ID, title, library_strategy, library_source,
    library_selection, library_layout, platform, instrument_model,
    design_description, filetype, filename
  )

write_tsv(mix_sra_metadata, "mix_sra_metadata_submission.tsv", na = "")

message(nrow(mix_sra_metadata), " SRA experiment rows written to mix_sra_metadata_submission.tsv")
message("REMINDER: confirm instrument_model = '", INSTRUMENT_MODEL, "' against your sequencing core's run report before submitting.")

