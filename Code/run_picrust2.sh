#!/bin/bash
# run_picrust2.sh
# PICRUSt2 v2.6.2 functional prediction pipeline for MIX-March2025
# Full-length 16S long-read ASVs (DADA2, PacBio/Nanopore error model)
# Chloe McGovern

set -euo pipefail

echo "=== Starting PICRUSt2 pipeline: $(date) ==="

source /programs/miniconda3/bin/activate picrust2.6

INPUT_DIR=/home/cjm423/MIX-March2025/Data/16S/picrust2_input
OUTPUT_DIR=/home/cjm423/MIX-March2025/Data/16S/picrust2_output
DEFAULT_FILES=/workdir/cjm423/picrust2-2.6.2/picrust2/default_files

REF_DIR1=${DEFAULT_FILES}/bacteria/bac_ref
REF_DIR2=${DEFAULT_FILES}/archaea/arc_ref

if [ -d "${OUTPUT_DIR}" ]; then
    echo "Removing existing (likely incomplete) output directory: ${OUTPUT_DIR}"
    rm -rf "${OUTPUT_DIR}"
fi

# This installed build is the newer two-domain wrapper (separate bacteria + archaea
# reference trees), NOT the single-reference picrust2_pipeline.py described in the
# HPC wiki notes - that doc is out of date for this conda env. Because -r1/-r2 are
# non-default, every other reference path (marker gene tables, trait tables, pathway
# mapfiles) must ALSO be set explicitly - none of them fall back to the workdir
# download automatically, they all default to the (nonexistent) conda-bundled paths.
picrust2_pipeline.py \
  -s ${INPUT_DIR}/ASV_seqs.fasta \
  -i ${INPUT_DIR}/ASV_table.tsv \
  -o ${OUTPUT_DIR} \
  -r1 ${REF_DIR1} \
  -r2 ${REF_DIR2} \
  --marker_gene_table_ref1 ${DEFAULT_FILES}/bacteria/16S.txt.gz \
  --marker_gene_table_ref2 ${DEFAULT_FILES}/archaea/16S.txt.gz \
  --custom_trait_tables_ref1 ${DEFAULT_FILES}/bacteria/ec.txt.gz,${DEFAULT_FILES}/bacteria/ko.txt.gz \
  --custom_trait_tables_ref2 ${DEFAULT_FILES}/archaea/ec.txt.gz,${DEFAULT_FILES}/archaea/ko.txt.gz \
  --reaction_func ec.txt \
  --pathway_map ${DEFAULT_FILES}/pathway_mapfiles/metacyc_pathways_structured_filtered_v24.txt \
  --regroup_map ${DEFAULT_FILES}/pathway_mapfiles/ec_level4_to_metacyc_rxn_new.tsv \
  -p 1 \
  --verbose

echo "=== PICRUSt2 pipeline finished: $(date) ==="


