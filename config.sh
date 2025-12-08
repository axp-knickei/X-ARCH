# Archaea Genomics Pipeline Configuration Template
# Edit this file and source it before running the pipeline for persistent settings
# Usage: source config.sh && ./archaea_pipeline.sh ...

################################################################################
# COMPUTATIONAL RESOURCES
################################################################################

# Number of CPU threads to use
export THREADS=32

# Maximum RAM in GB
export MAX_MEMORY=500

################################################################################
# SAMPLE METADATA (for NCBI submission)
################################################################################

# Sample identifier
export SAMPLE_NAME="archaea_sample"

# Sample collection location
export ISOLATION_SOURCE="hydrothermal_vent"
export GEOGRAPHIC_LOCATION="COUNTRY: REGION"
export LATITUDE="00.0000"
export LONGITUDE="00.0000"

# Sample collection date (YYYY-MM-DD)
export COLLECTION_DATE="2024-01-01"

# Environmental parameters (if known)
export TEMPERATURE="90.5"  # Celsius
export PH_VALUE="2.5"
export DEPTH="2800"  # meters

################################################################################
# WORKING DIRECTORIES
################################################################################

# Base working directory for all analysis
export WORK_DIR="$(pwd)/archaea_analysis"

# Data input directory
export DATA_DIR="$(pwd)/input_data"

################################################################################
# DATABASE PATHS (Optional: for local installations)
################################################################################

# GTDB-Tk database (auto-downloaded on first run if not specified)
# export GTDBTK_DATA_PATH="/path/to/gtdbtk/db"

# DRAM databases (auto-downloaded on first run if not specified)
# export DRAM_DB_PATH="/path/to/dram/db"

# CheckM2 models (auto-downloaded on first run if not specified)
# export CHECKM2_DB="/path/to/checkm2/models"

################################################################################
# TOOL-SPECIFIC OPTIONS
################################################################################

# MetaSPAdes assembly mode
# Options: 'meta' (default), 'metaviral', 'ionhq'
export SPADES_MODE="meta"

# DRAM annotation
# Include structural annotation (slower but more comprehensive)
export DRAM_STRUCTURAL_ANNOTATION="true"

# antiSMASH detection strictness
# Options: 'strict', 'relaxed' (default)
export ANTISMASH_STRICTNESS="relaxed"

# IQ-TREE2 bootstrap replicates
export IQTREE_BOOTSTRAP=1000

################################################################################
# NCBI SUBMISSION SETTINGS
################################################################################

# Submitter information (for BioSample metadata)
export SUBMITTER_NAME="Your Name"
export SUBMITTER_EMAIL="your.email@institution.edu"
export SUBMITTER_INSTITUTION="Your Institution"

# Biosafety level (1, 2, 3, 4)
export BIOSAFETY_LEVEL="1"
