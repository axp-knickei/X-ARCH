#!/bin/bash

################################################################################
# ARCHAEA GENOMICS PIPELINE v1.0
# Identification and Genomic Characterization of Archaea from Extreme Environments
# Complete WGS Analysis from Raw Reads to NCBI-Ready Submission
#
# Author: ALEX PRIMA
# License: MIT
# Repository: https://github.com/axp-knickei/X-ARCH
# Last Updated: December 2025
#
# Citation: Please cite this pipeline and its dependencies in your publications
################################################################################

set -e  # Exit on any error

################################################################################
# CONFIGURATION & GLOBAL VARIABLES
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load configuration from config.yaml
log "Loading configuration from config.yaml..."
# Ensure python and pyyaml are in PATH, preferably via activated conda env
if ! command -v python3 &> /dev/null; then
    error "python3 is not installed. Please ensure your conda environment is activated."
fi
eval "$(python3 scripts/read_config.py config.yaml)"

# Set actual variables, prioritizing config.yaml values
THREADS=${PIPELINE_THREADS:-32}
MAX_MEMORY=${PIPELINE_MAX_MEMORY_GB:-500} # Rename to MAX_MEMORY to match existing usage
SAMPLE_NAME=${PIPELINE_SAMPLE_NAME:-"archaea_sample"}
WORK_DIR=${PIPELINE_WORK_DIR:-"$(pwd)/archaea_analysis"}

# Derived values
LOG_DIR="${WORK_DIR}/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/pipeline_${TIMESTAMP}.log"

# Tool versions (for logging/display only - actual versions are from environment.yml)
# These are kept for display purposes in logs/reports, but the pipeline relies on the versions
# installed in the active conda environment as defined by environment.yml
FASTP_VERSION="0.23.4"
SPADES_VERSION="3.15.5"
CHECKM2_VERSION="1.0.1"
GTDBTK_VERSION="2.3.2"
DRAM_VERSION="1.3.6"

################################################################################
# FUNCTIONS
################################################################################

# Logger function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if tool is installed
check_tool() {
    if command -v "$1" &> /dev/null; then
        success "$1 is installed"
        return 0
    else
        error "$1 is NOT installed. Please install it via: mamba install -c bioconda $1"
        return 1
    fi
}

# Initialize working directories
init_directories() {
    log "Initializing working directories..."
    mkdir -p "$WORK_DIR"/{logs,data,results,temp}
    mkdir -p "$WORK_DIR"/results/{qc,assembly,binning,annotation,phylogeny,submission}
    success "Directories created in: $WORK_DIR"
}

# Print usage information
usage() {
    cat << EOF

${BLUE}========================================${NC}
ARCHAEA GENOMICS PIPELINE v1.0
${BLUE}========================================${NC}

Usage: $0 [OPTIONS]

Configuration:
    Parameters can be set via 'config.yaml' or overridden by command-line arguments.
    Defaults are shown below.

Required OPTIONS:
    -1, --read1     PATH    Raw forward reads (FASTQ/FASTQ.GZ)
    -2, --read2     PATH    Raw reverse reads (FASTQ/FASTQ.GZ)

Optional OPTIONS:
    -s, --sample    NAME    Sample identifier (default: ${SAMPLE_NAME})
    -t, --threads   INT     Number of threads (default: ${THREADS})
    -m, --memory    INT     Max memory in GB (default: ${MAX_MEMORY})
    -w, --workdir   PATH    Working directory (default: ${WORK_DIR})
    -h, --help              Display this help message

Examples:
    $0 -1 sample_R1.fastq.gz -2 sample_R2.fastq.gz -s HydroVent_01 -t 64 -m 1000
    $0 -1 raw_1.fq -2 raw_2.fq -s Acidic_Spring

${BLUE}========================================${NC}

EOF
}

################################################################################
# STAGE A: RAW DATA QUALITY CONTROL
################################################################################

stage_qc() {
    local r1="$1"
    local r2="$2"
    
    log "=== STAGE A: RAW DATA QUALITY CONTROL ==="
    
    # Validate input files
    if [[ ! -f "$r1" ]]; then
        error "Read 1 file not found: $r1"
    fi
    if [[ ! -f "$r2" ]]; then
        error "Read 2 file not found: $r2"
    fi
    
    log "Input reads detected successfully"
    log "Processing with fastp v${FASTP_VERSION}..."
    
    # Run fastp
    fastp \
        -i "$r1" -I "$r2" \
        -o "${WORK_DIR}/results/qc/${SAMPLE_NAME}_R1_clean.fq.gz" \
        -O "${WORK_DIR}/results/qc/${SAMPLE_NAME}_R2_clean.fq.gz" \
        -h "${WORK_DIR}/results/qc/${SAMPLE_NAME}_fastp.html" \
        -j "${WORK_DIR}/results/qc/${SAMPLE_NAME}_fastp.json" \
        --detect_adapter_for_pe \
        --correction \
        --thread "$THREADS" \
        2>&1 | tee -a "$LOG_FILE"
    
    success "Quality control completed. Output: ${WORK_DIR}/results/qc/"
    
    # Extract QC statistics
    log "Extracting quality statistics..."
    python3 scripts/extract_qc_stats.py "${WORK_DIR}/results/qc/${SAMPLE_NAME}_fastp.json"
}

################################################################################
# STAGE B: METAGENOMIC ASSEMBLY
################################################################################

stage_assembly() {
    log "=== STAGE B: METAGENOMIC ASSEMBLY ==="
    log "Assembling with MetaSPAdes v${SPADES_VERSION}..."
    log "This step may take 24-72 hours for complex samples. Consider using screen/tmux."
    
    spades.py --meta \
              -1 "${WORK_DIR}/results/qc/${SAMPLE_NAME}_R1_clean.fq.gz" \
              -2 "${WORK_DIR}/results/qc/${SAMPLE_NAME}_R2_clean.fq.gz" \
              -o "${WORK_DIR}/results/assembly/${SAMPLE_NAME}_spades" \
              -t "$THREADS" \
              -m "$MAX_MEMORY" \
              2>&1 | tee -a "$LOG_FILE"
    
    # Copy key assembly files
    cp "${WORK_DIR}/results/assembly/${SAMPLE_NAME}_spades/contigs.fasta" \
       "${WORK_DIR}/results/assembly/${SAMPLE_NAME}_contigs.fasta"
    
    success "Assembly completed: ${WORK_DIR}/results/assembly/${SAMPLE_NAME}_contigs.fasta"
    
    # Assembly QC with QUAST
    log "Running QUAST for assembly quality assessment..."
    quast.py "${WORK_DIR}/results/assembly/${SAMPLE_NAME}_contigs.fasta" \
             -o "${WORK_DIR}/results/assembly/quast_results" \
             --threads "$THREADS" \
             2>&1 | tee -a "$LOG_FILE"
    
    success "QUAST report: ${WORK_DIR}/results/assembly/quast_results/report.html"
}

################################################################################
# STAGE C: MAPPING & BINNING
################################################################################

stage_binning() {
    log "=== STAGE C: MAPPING & BINNING (Metagenome-Assembled Genomes) ==="
    
    local CONTIGS="${WORK_DIR}/results/assembly/${SAMPLE_NAME}_contigs.fasta"
    local R1="${WORK_DIR}/results/qc/${SAMPLE_NAME}_R1_clean.fq.gz"
    local R2="${WORK_DIR}/results/qc/${SAMPLE_NAME}_R2_clean.fq.gz"
    
    # Index reference with Bowtie2
    log "Indexing assembly with Bowtie2..."
    bowtie2-build "$CONTIGS" "${WORK_DIR}/temp/${SAMPLE_NAME}_index" \
        --threads "$THREADS" \
        2>&1 | tee -a "$LOG_FILE"
    
    # Map reads
    log "Mapping reads back to assembly..."
    bowtie2 -x "${WORK_DIR}/temp/${SAMPLE_NAME}_index" \
            -1 "$R1" -2 "$R2" \
            -p "$THREADS" \
            2>&1 | samtools view -bS - | samtools sort -o "${WORK_DIR}/temp/${SAMPLE_NAME}.sorted.bam" -
    
    samtools index "${WORK_DIR}/temp/${SAMPLE_NAME}.sorted.bam"
    success "Mapping completed: ${WORK_DIR}/temp/${SAMPLE_NAME}.sorted.bam"
    
    # Binning with SemiBin2
    log "Running SemiBin2 for genome binning (Deep Learning-based)..."
    SemiBin2 single_easy_bin \
             -i "$CONTIGS" \
             -b "${WORK_DIR}/temp/${SAMPLE_NAME}.sorted.bam" \
             -o "${WORK_DIR}/results/binning/semibin2_results" \
             --environment global \
             -p "$THREADS" \
             2>&1 | tee -a "$LOG_FILE"
    
    success "SemiBin2 binning completed"
    
    # Optional: Additional binning with MetaBAT2 for ensemble
    log "Running MetaBAT2 for comparison..."
    mkdir -p "${WORK_DIR}/temp/metabat_depth"
    jgi_summarize_bam_contig_depths --outputDepth "${WORK_DIR}/temp/metabat_depth.txt" \
                                     "${WORK_DIR}/temp/${SAMPLE_NAME}.sorted.bam" \
                                     2>&1 | tee -a "$LOG_FILE"
    
    metabat2 -i "$CONTIGS" \
             -a "${WORK_DIR}/temp/metabat_depth.txt" \
             -o "${WORK_DIR}/results/binning/metabat2_results/bin" \
             -t "$THREADS" \
             2>&1 | tee -a "$LOG_FILE"
    
    success "MetaBAT2 binning completed"
}

################################################################################
# STAGE D: QUALITY ASSESSMENT & REFINEMENT
################################################################################

stage_quality_assessment() {
    log "=== STAGE D: BIN QUALITY ASSESSMENT ==="
    
    local BINS_DIR="${WORK_DIR}/results/binning/semibin2_results/output_bins"
    
    # CheckM2 for lineage-agnostic quality assessment
    log "Running CheckM2 v${CHECKM2_VERSION} (Machine Learning-based)..."
    checkm2 predict \
            --input "$BINS_DIR" \
            --output-directory "${WORK_DIR}/results/binning/checkm2_results" \
            --threads "$THREADS" \
            2>&1 | tee -a "$LOG_FILE"
    
    success "CheckM2 quality assessment completed"
    
    # Generate quality summary
    log "Generating quality summary..."
    cat "${WORK_DIR}/results/binning/checkm2_results/quality_report.tsv" | head -20 | tee -a "$LOG_FILE"
    
    # Filter high-quality bins (completeness > 90%, contamination < 5%)
    log "Filtering high-quality bins (>90% complete, <5% contamination)..."
    
    python3 << 'PYTHON_FILTER'
import pandas as pd
import os

qc_file = "archaea_analysis/results/binning/checkm2_results/quality_report.tsv"
if os.path.exists(qc_file):
    df = pd.read_csv(qc_file, sep='\t')
    hq_bins = df[(df['Completeness'] > 90) & (df['Contamination'] < 5)]
    print(f"\nHigh-Quality Bins: {len(hq_bins)}/{len(df)}")
    print(hq_bins[['Name', 'Completeness', 'Contamination']])
PYTHON_FILTER
}

################################################################################
# STAGE E: TAXONOMIC CLASSIFICATION
################################################################################

stage_taxonomy() {
    log "=== STAGE E: TAXONOMIC CLASSIFICATION ==="
    
    local BINS_DIR="${WORK_DIR}/results/binning/semibin2_results/output_bins"
    
    log "Running GTDB-Tk v${GTDBTK_VERSION} for archaeal taxonomy..."
    log "Database size is ~27 GB. First run will download database."
    
    gtdbtk classify_wf \
        --genome_dir "$BINS_DIR" \
        --out_dir "${WORK_DIR}/results/annotation/gtdbtk_results" \
        --cpus "$THREADS" \
        --pplacer_cpus 1 \
        2>&1 | tee -a "$LOG_FILE"
    
    success "GTDB-Tk classification completed"
    
    # Parse and display taxonomy
    log "Taxonomic assignments:"
    if [[ -f "${WORK_DIR}/results/annotation/gtdbtk_results/ar53.summary.tsv" ]]; then
        head -10 "${WORK_DIR}/results/annotation/gtdbtk_results/ar53.summary.tsv" | tee -a "$LOG_FILE"
    fi
}

################################################################################
# STAGE F: FUNCTIONAL ANNOTATION
################################################################################

stage_annotation() {
    log "=== STAGE F: FUNCTIONAL ANNOTATION ==="
    
    local BINS_DIR="${WORK_DIR}/results/binning/semibin2_results/output_bins"
    
    log "Running DRAM v${DRAM_VERSION} for metabolic profiling..."
    log "This step may take several hours depending on bin count."
    
    DRAM.py annotate \
        -i "${BINS_DIR}/*.fasta" \
        -o "${WORK_DIR}/results/annotation/dram_results" \
        --threads "$THREADS" \
        --verbose \
        2>&1 | tee -a "$LOG_FILE"
    
    log "Generating DRAM distillation (metabolic heatmap)..."
    DRAM.py distill \
        -i "${WORK_DIR}/results/annotation/dram_results/annotations.tsv" \
        -o "${WORK_DIR}/results/annotation/dram_distillation" \
        --verbose \
        2>&1 | tee -a "$LOG_FILE"
    
    success "DRAM annotation completed: ${WORK_DIR}/results/annotation/dram_distillation/product.html"
    
    # Secondary metabolites with antiSMASH
    log "Running antiSMASH 7.0 for secondary metabolite detection..."
    
    for bin in "${BINS_DIR}"/*.fasta; do
        bin_name=$(basename "$bin" .fasta)
        log "Processing $bin_name..."
        
        antismash \
            "$bin" \
            --outdir "${WORK_DIR}/results/annotation/antismash_results/${bin_name}" \
            --cpus "$THREADS" \
            --genefinding-tool prodigal \
            2>&1 | tee -a "$LOG_FILE"
    done
    
    success "antiSMASH analysis completed"
}

################################################################################
# STAGE G: PHYLOGENOMICS
################################################################################

stage_phylogeny() {
    log "=== STAGE G: PHYLOGENOMIC ANALYSIS ==="
    
    local GTDBTK_DIR="${WORK_DIR}/results/annotation/gtdbtk_results"
    
    log "Building phylogenetic tree with IQ-TREE2..."
    
    # Extract MSA from GTDB-Tk results
    if [[ -f "${GTDBTK_DIR}/align/gtdbtk.bac120.user_msa.fasta" ]]; then
        MSA="${GTDBTK_DIR}/align/gtdbtk.bac120.user_msa.fasta"
    elif [[ -f "${GTDBTK_DIR}/align/gtdbtk.ar53.user_msa.fasta" ]]; then
        MSA="${GTDBTK_DIR}/align/gtdbtk.ar53.user_msa.fasta"
    else
        error "GTDB-Tk MSA file not found. Check GTDB-Tk output."
    fi
    
    iqtree2 -s "$MSA" \
            -m MFP \
            -B 1000 \
            -T AUTO \
            --prefix "${WORK_DIR}/results/phylogeny/${SAMPLE_NAME}_tree" \
            2>&1 | tee -a "$LOG_FILE"
    
    success "Phylogenetic tree: ${WORK_DIR}/results/phylogeny/${SAMPLE_NAME}_tree.treefile"
}

################################################################################
# STAGE H: VISUALIZATION & REPORT GENERATION
################################################################################

stage_visualization() {
    log "=== STAGE H: VISUALIZATION & REPORT GENERATION ==="
    
    log "Creating summary report..."
    
    cat > "${WORK_DIR}/results/${SAMPLE_NAME}_ANALYSIS_REPORT.txt" << EOF
================================================================================
ARCHAEA GENOMICS PIPELINE - ANALYSIS REPORT
================================================================================

Sample ID: $SAMPLE_NAME
Analysis Date: $(date)
Pipeline Version: v1.0
Computational Resources: $THREADS threads, ${MAX_MEMORY} GB RAM

================================================================================
ANALYSIS SUMMARY
================================================================================

A. QUALITY CONTROL
   - QC Report: results/qc/${SAMPLE_NAME}_fastp.html
   - Cleaned Reads: results/qc/${SAMPLE_NAME}_R*.fq.gz

B. ASSEMBLY
   - Contigs: results/assembly/${SAMPLE_NAME}_contigs.fasta
   - QUAST Report: results/assembly/quast_results/report.html

C. BINNING
   - SemiBin2 Results: results/binning/semibin2_results/output_bins/
   - MetaBAT2 Results: results/binning/metabat2_results/

D. QUALITY ASSESSMENT
   - CheckM2 Report: results/binning/checkm2_results/quality_report.tsv

E. TAXONOMY (GTDB-Tk)
   - Archaeal Taxonomy: results/annotation/gtdbtk_results/ar53.summary.tsv

F. FUNCTIONAL ANNOTATION
   - DRAM Results: results/annotation/dram_results/
   - DRAM Heatmap: results/annotation/dram_distillation/product.html
   - antiSMASH BGCs: results/annotation/antismash_results/

G. PHYLOGENOMICS
   - Phylogenetic Tree: results/phylogeny/${SAMPLE_NAME}_tree.treefile
   - Tree Visualization: results/phylogeny/${SAMPLE_NAME}_tree.svg

================================================================================
NEXT STEPS FOR PUBLICATION
================================================================================

1. Review all quality metrics in CheckM2 report
2. Select high-quality MAGs (>90% completion, <5% contamination)
3. Prepare genome sequences and metadata for NCBI submission
4. Generate publication figures from antiSMASH and DRAM results
5. Prepare Methods section describing tool versions and parameters

NCBI SUBMISSION GUIDE:
   - Create BioProject at: https://submit.ncbi.nlm.nih.gov/
   - Submit cleaned reads to SRA
   - Submit assembled genomes as WGS/MAGs
   - Include MIMS metadata for each sample

================================================================================
LOG FILE
================================================================================

Full pipeline log: logs/pipeline_${TIMESTAMP}.log

================================================================================
EOF
    
    success "Report generated: ${WORK_DIR}/results/${SAMPLE_NAME}_ANALYSIS_REPORT.txt"
    cat "${WORK_DIR}/results/${SAMPLE_NAME}_ANALYSIS_REPORT.txt"
}

################################################################################
# STAGE I: NCBI SUBMISSION PREPARATION
################################################################################

stage_submission_prep() {
    log "=== STAGE I: NCBI SUBMISSION PREPARATION ==="
    
    local BINS_DIR="${WORK_DIR}/results/binning/semibin2_results/output_bins"
    local SUBMISSION_DIR="${WORK_DIR}/results/submission"
    
    log "Preparing genomes for NCBI submission..."
    
    # Run FCS-GX contamination screening
    log "Screening for contaminants with FCS-GX..."
    
    for bin in "${BINS_DIR}"/*.fasta; do
        bin_name=$(basename "$bin" .fasta)
        
        # Filter contigs < 200 bp (NCBI requirement)
        log "Filtering contigs < 200 bp for $bin_name..."
        
        python3 << PYTHON_FILTER_CONTIGS
import sys
from pathlib import Path

input_fasta = "$bin"
output_fasta = "$SUBMISSION_DIR/${bin_name}_ncbi_ready.fasta"

min_length = 200
count_kept = 0
count_removed = 0

with open(input_fasta) as f_in, open(output_fasta, 'w') as f_out:
    seq_id = None
    seq = []
    
    for line in f_in:
        line = line.rstrip()
        if line.startswith('>'):
            if seq_id and len(''.join(seq)) >= min_length:
                f_out.write(f'{seq_id}\\n')
                f_out.write(''.join(seq) + '\\n')
                count_kept += 1
            else:
                count_removed += 1
            seq_id = line
            seq = []
        else:
            seq.append(line)
    
    if seq_id and len(''.join(seq)) >= min_length:
        f_out.write(f'{seq_id}\\n')
        f_out.write(''.join(seq) + '\\n')
        count_kept += 1
    else:
        count_removed += 1

print(f"{bin_name}: Kept {count_kept}, Removed {count_removed} contigs")
PYTHON_FILTER_CONTIGS
    done
    
    # Generate submission metadata template
    log "Generating NCBI submission metadata template..."
    
    cat > "${SUBMISSION_DIR}/SUBMISSION_METADATA_TEMPLATE.txt" << EOF
# NCBI BioProject and BioSample Metadata Template
# Please fill out and use for submission at: https://submit.ncbi.nlm.nih.gov/

## BioProject Information
bioproject_title: "Genomic characterization of novel Archaea from ${SAMPLE_METADATA_ISOLATION_SOURCE}"
bioproject_description: "Metagenomic analysis and recovery of metagenome-assembled genomes (MAGs) from ${SAMPLE_METADATA_ISOLATION_SOURCE} environment"
bioproject_type: "Metagenome"

## BioSample Information (MIMS - Minimum Information about a Metagenome Sequence)
sample_title: "${SAMPLE_NAME}" # Uses pipeline's sample name
isolation_source: "${SAMPLE_METADATA_ISOLATION_SOURCE}"
geographic_location: "${SAMPLE_METADATA_GEOGRAPHIC_LOCATION}"
collection_date: "${SAMPLE_METADATA_COLLECTION_DATE}"
latitude: "${SAMPLE_METADATA_LATITUDE}"
longitude: "${SAMPLE_METADATA_LONGITUDE}"
depth: "${SAMPLE_METADATA_DEPTH_METERS}" # meters, if applicable
environment_biome: "environmental" # Hardcoded for now, could be configurable
environment_feature: "${SAMPLE_METADATA_ISOLATION_SOURCE}" # Re-using isolation_source
environment_material: "not applicable" # Hardcoded for now
ph: "${SAMPLE_METADATA_PH_VALUE}"
temperature: "${SAMPLE_METADATA_TEMPERATURE_CELSIUS}" # Celsius

## Sequencing Information
sequencing_platform: "Illumina"
sequencing_kit: "not specified" # Could be configurable
library_strategy: "WGS (Whole Genome Shotgun)"
assembly_method: "MetaSPAdes v${SPADES_VERSION}" # Using actual version
binning_methods: "SemiBin2, MetaBAT2, DAS Tool"
quality_assessment: "CheckM2 v${CHECKM2_VERSION}" # Using actual version

## Quality Metrics
genome_completeness: "[percentage]" # To be filled manually
genome_contamination: "[percentage]" # To be filled manually
n50_scaffold: "[value]" # To be filled manually
number_scaffolds: "[value]" # To be filled manually
total_length_bp: "[value]" # To be filled manually

## Contact Information
submitter_name: "${SUBMITTER_NAME}"
submitter_email: "${SUBMITTER_EMAIL}"
submitter_institution: "${SUBMITTER_INSTITUTION}"

EOF
    
    success "Submission preparation completed"
    log "Submit genomes to NCBI: ${SUBMISSION_DIR}/"
    log "Use metadata template: ${SUBMISSION_DIR}/SUBMISSION_METADATA_TEMPLATE.txt"
}

################################################################################
# MAIN WORKFLOW ORCHESTRATION
################################################################################

main() {
    # Parse arguments
    local R1=""
    local R2=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -1|--read1) R1="$2"; shift 2 ;;
            -2|--read2) R2="$2"; shift 2 ;;
            -s|--sample) SAMPLE_NAME="$2"; shift 2 ;;
            -t|--threads) THREADS="$2"; shift 2 ;;
            -m|--memory) MAX_MEMORY="$2"; shift 2 ;;
            -w|--workdir) WORK_DIR="$2"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            *) echo "Unknown option: $1"; usage; exit 1 ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$R1" ]] || [[ -z "$R2" ]]; then
        error "Read files (-1/-2) are required"
    fi
    
    # Initialize
    init_directories
    
    {
        log "=========================================="
        log "ARCHAEA GENOMICS PIPELINE v1.0"
        log "=========================================="
        log "Sample: $SAMPLE_NAME"
        log "Working Directory: $WORK_DIR"
        log "Threads: $THREADS"
        log "Max Memory: ${MAX_MEMORY} GB"
        log "Start Time: $(date)"
        log "=========================================="
        
        # Check dependencies
        log "Checking for required tools..."
        for tool in fastp spades.py bowtie2 samtools checkm2 gtdbtk DRAM.py antismash iqtree2; do
            check_tool "$tool" || warning "$tool not found - this stage may fail"
        done
        
        # Run pipeline stages
        stage_qc "$R1" "$R2"
        stage_assembly
        stage_binning
        stage_quality_assessment
        stage_taxonomy
        stage_annotation
        stage_phylogeny
        stage_visualization
        stage_submission_prep
        
        log "=========================================="
        log "PIPELINE COMPLETED SUCCESSFULLY"
        log "End Time: $(date)"
        log "=========================================="
        log "Results directory: $WORK_DIR/results/"
        log "Log file: $LOG_FILE"
        
    } 2>&1 | tee -a "$LOG_FILE"
}

################################################################################
# ENTRY POINT
################################################################################

# Show help if no arguments
if [[ $# -eq 0 ]]; then
    usage
    exit 0
fi

# Run main function
main "$@"
