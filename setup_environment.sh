#!/bin/bash

################################################################################
# SETUP SCRIPT FOR ARCHAEA GENOMICS PIPELINE
# Installs all required bioinformatics tools and databases using environment.yml
# Runtime: ~30-60 minutes (depending on internet speed)
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}ARCHAEA GENOMICS PIPELINE - SETUP${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if mamba/conda is installed
if ! command -v mamba &> /dev/null && ! command -v conda &> /dev/null; then
    echo -e "${RED}ERROR: Conda or Mamba not found.${NC}"
    echo "Please install Miniconda first:"
    echo "  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    echo "  bash Miniconda3-latest-Linux-x86_64.sh"
    exit 1
fi

# Prefer mamba for speed
if command -v mamba &> /dev/null; then
    PKG_MANAGER="mamba"
else
    PKG_MANAGER="conda"
fi

echo -e "${GREEN}✓ Using $PKG_MANAGER as package manager${NC}"

# Create/Update conda environment
echo -e "${BLUE}Creating/Updating conda environment from environment.yml...${NC}"
if [ -d "$($PKG_MANAGER info --base)/envs/archaea_env" ]; then
    echo -e "${YELLOW}Environment 'archaea_env' already exists. Updating...${NC}"
    $PKG_MANAGER env update -f environment.yml --prune
else
    $PKG_MANAGER env create -f environment.yml
fi

# Activate environment
echo -e "${BLUE}Activating environment...${NC}"
eval "$(conda shell.bash hook)"
conda activate archaea_env

# Download antiSMASH databases
echo -e "${BLUE}Downloading antiSMASH databases...${NC}"
echo -e "${YELLOW}This downloads ~3 GB. May take 10-15 minutes...${NC}"
download-antismash-databases --verbose

# Download DRAM databases
echo -e "${BLUE}Setting up DRAM databases...${NC}"
echo -e "${YELLOW}This downloads ~15 GB. May take 20-30 minutes...${NC}"
# Upgrade pip in the env just in case, though handled by conda usually
python -m pip install --upgrade pip setuptools
DRAM.py setup_databases --verbose

# Download GTDB-Tk databases (on first run)
echo -e "${BLUE}Verifying GTDB-Tk...${NC}"
echo -e "${YELLOW}Note: GTDB-Tk database (~27 GB) will be downloaded on first analysis run.${NC}"
echo -e "${YELLOW}      You can pre-download it now by running:${NC}"
echo -e "${YELLOW}      gtdbtk download-db --release 220${NC}"

# Verify installations
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}VERIFYING INSTALLATIONS${NC}"
echo -e "${BLUE}========================================${NC}"

verify_tool() {
    if $1 --version &>/dev/null 2>&1 || $1 --help &>/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1"
        return 1
    fi
}

verify_tool "fastp"
verify_tool "spades.py"
verify_tool "bowtie2"
verify_tool "samtools"
verify_tool "checkm2"
verify_tool "gtdbtk"
verify_tool "antismash"
verify_tool "iqtree2"
verify_tool "quast.py"
verify_tool "metabat2"
verify_tool "DAS_Tool" 

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}SETUP COMPLETE!${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Activate the environment:"
echo "   ${BLUE}mamba activate archaea_env${NC}"
echo ""
echo "2. Run the pipeline:"
echo "   ${BLUE}./archaea_pipeline.sh -1 sample_R1.fq.gz -2 sample_R2.fq.gz${NC}"
echo ""
echo "3. For GTDB-Tk database (if not auto-downloaded):"
echo "   ${BLUE}mamba activate archaea_env${NC}"
echo "   ${BLUE}gtdbtk download-db --release 220${NC}"
echo ""
echo -e "${GREEN}Happy analyzing!${NC}"