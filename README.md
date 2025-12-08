# Archaea Genomics Pipeline

**A bioinformatics workflow for identifying and characterizing Archaea from extreme environmental samples using whole-genome shotgun (WGS) sequencing.**

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Bash](https://img.shields.io/badge/bash-5.1+-green.svg)
![Python](https://img.shields.io/badge/python-3.8+-blue.svg)
![Snakemake](https://img.shields.io/badge/snakemake-7.x+-green.svg)
![Docker](https://img.shields.io/badge/docker-enabled-blue.svg)
![GitHub](https://img.shields.io/badge/github-repo-blue?logo=github)

---

## 🎯 Overview

This pipeline integrates current bioinformatics tools (2023–2025) to process raw Illumina sequencing reads into:

- **Metagenome-Assembled Genomes (MAGs)** with high quality metrics
- **Taxonomic classification** using GTDB-Tk (Genome Taxonomy Database)
- **Functional annotation** with metabolic pathway analysis
- **Secondary metabolite detection** via antiSMASH
- **Phylogenomic reconstruction** with IQ-TREE2
- **NCBI submission-ready** files and metadata

**Best suited for:**
- Extreme environment samples (hydrothermal vents, acid mine drainage, salt lakes, subsurface)
- Environmental metagenomic studies
- Novel archaeal isolate characterization
- Genome-centric metagenomics workflows

---

## Requirements

### Computational Environment

| Requirement | Minimum | Recommended (Production) | Why? |
| :--- | :--- | :--- | :--- |
| **RAM** | 128 GB | **512 GB – 1 TB** | MetaSPAdes and GTDB-Tk are memory-intensive |
| **CPU** | 16 cores | **64+ cores** | Parallelization reduces runtime by days |
| **Storage** | 2 TB SSD | **10 TB NVMe** | Assembly graphs and BAM files are massive |
| **OS** | Linux (Ubuntu 20.04+) or WSL2 on Windows | Linux (Ubuntu 22.04 LTS) | — |

### Software Dependencies

All tools are installed via **Conda/Mamba**. See installation instructions below.

---

## 🚀 Quick Start

### 1. Install Conda/Mamba

If you don't have Conda installed, download **Miniconda**:

```bash
# Download Miniconda for Linux
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p ~/miniconda3

# Activate conda
source ~/miniconda3/bin/activate
```

### 2. Clone This Repository

```bash
git clone https://github.com/axp-knickei/X-ARCH.git
cd archaea-genomics-pipeline
chmod +x archaea_pipeline.sh setup_environment.sh
```

### 3. Set Up Bioinformatics Environment

```bash
./setup_environment.sh
```

This creates a Conda environment with all required tools and downloads necessary databases (GTDB, DRAM, antiSMASH — ~50 GB total).

### 4. Configure the Pipeline

The pipeline uses a `config.yaml` file for all parameters. You can edit this file directly or override specific parameters via command-line arguments.

**Default Configuration (`config.yaml`):**

```yaml
# General pipeline settings
pipeline:
  threads: 32
  max_memory_gb: 500 # in GB
  sample_name: "archaea_sample"
  work_dir: "./archaea_analysis"
  data_dir: "./input_data"
# ... other settings for databases, tools, sample metadata, submitter info
```
For more details, see `config.yaml`.

---

## 🚀 Available Workflows

You can run the pipeline using the original bash script, Snakemake, or via Docker.

### Option A: Run with Bash Script (`archaea_pipeline.sh`)

This is the traditional way to run the pipeline. Ensure your `archaea_env` conda environment is activated.

```bash
# Activate the environment
mamba activate archaea_env

# Run with your data (parameters override config.yaml)
./archaea_pipeline.sh \
    -1 /path/to/sample_R1.fastq.gz \
    -2 /path/to/sample_R2.fastq.gz \
    -s MyArchaeaSample \
    -t 64 \
    -m 1000 \
    -w /path/to/my_analysis_output
```
For more details on bash script usage, refer to `./archaea_pipeline.sh --help`.

### Option B: Run with Snakemake

Snakemake provides robust workflow management, automatic parallelization, and resume capabilities.

1.  **Configure:** Ensure `config.yaml` is updated with your input read paths and desired parameters.
    ```yaml
    reads:
      r1: "/path/to/sample_R1.fq.gz"
      r2: "/path/to/sample_R2.fq.gz"
    # ... other pipeline settings
    ```
2.  **Run:**
    ```bash
    # Activate environment
    mamba activate archaea_env

    # Run pipeline locally with 32 cores, using the conda environment
    snakemake --cores 32 --use-conda
    ```
    For advanced Snakemake usage (cluster execution, dry-runs), see `SNAKEMAKE_README.md`.

### Option C: Run with Docker

Containerization ensures maximum reproducibility and portability.

1.  **Build the Image:**
    ```bash
    docker build -t x-arch:v1.0 .
    ```
2.  **Run the Pipeline:**
    ```bash
    docker run --rm -it \
        -v /path/to/your/data:/data \
        -v /path/to/your/output:/output \
        -v /path/to/local/databases:/databases \
        x-arch:v1.0 \
        -1 /data/sample_R1.fq.gz \
        -2 /data/sample_R2.fq.gz \
        -s MySample \
        -t 16 \
        -m 64
    ```
    Note: Paths passed to `-1`, `-2`, etc., should be relative to the container's mounted volumes (e.g., `/data/sample_R1.fq.gz`).
    For more details on Docker usage, see `DOCKER_README.md`.

---

## 🧪 Testing

The pipeline includes unit tests for helper scripts and a mocked integration test for the main workflow.

```bash
# Activate environment
mamba activate archaea_env

# Run unit tests
pytest tests/test_python_scripts.py

# Run mocked integration test
./tests/run_integration_test.sh
```
For more detailed testing instructions and troubleshooting, see `TESTING.md`.

---

## Pipeline Stages

### **Stage A: Raw Data Quality Control**
- **Tool:** fastp v0.23.4
- **Input:** Raw FASTQ files
- **Output:** Cleaned FASTQ + HTML QC report
- **Runtime:** ~1–5 minutes

### **Stage B: Metagenomic Assembly**
- **Tool:** MetaSPAdes v3.15.5
- **Input:** Clean paired-end reads
- **Output:** Assembly contigs (FASTA)
- **Runtime:** 24–72 hours (depends on coverage & complexity)

### **Stage C: Mapping & Binning**
- **Tools:**
  - **Bowtie2:** Map reads back to assembly for coverage
  - **SemiBin2:** Deep learning-based genome binning (primary)
  - **MetaBAT2:** Coverage/composition-based binning (secondary)
- **Output:** Genome bins (FASTA files)
- **Runtime:** 6–12 hours

### **Stage D: Quality Assessment**
- **Tool:** CheckM2 v1.0.1 (Machine Learning–based, lineage-agnostic)
- **Metrics:** Completeness (%), Contamination (%), Strain heterogeneity
- **Filter:** High-quality bins: >90% complete, <5% contamination
- **Runtime:** 2–4 hours

### **Stage E: Taxonomic Classification**
- **Tool:** GTDB-Tk v2.3.2 (Genome Taxonomy Database)
- **Output:** Archaeal lineage assignments (phylum, class, order, family, genus, species)
- **Runtime:** 3–6 hours (first run downloads ~27 GB database)

### **Stage F: Functional Annotation**
- **Tools:**
  - **DRAM:** Gene annotation + metabolic pathway reconstruction
  - **antiSMASH 7.0:** Secondary metabolite/Biosynthetic Gene Cluster detection
- **Output:** Heatmaps, metabolic profiles, BGC visualizations
- **Runtime:** 8–16 hours

### **Stage G: Phylogenomics**
- **Tool:** IQ-TREE2 v2.3+
- **Input:** 122 concatenated archaeal marker genes (from GTDB-Tk)
- **Output:** Maximum likelihood phylogenetic tree (Newick format)
- **Runtime:** 2–4 hours

### **Stage H: Visualization & Reporting**
- Summary analysis report
- Automated figure generation
- **Runtime:** <1 hour

### **Stage I: NCBI Submission Preparation**
- Filters contigs <200 bp (NCBI requirement)
- Runs FCS-GX contamination screening
- Generates submission metadata template
- **Output:** NCBI-ready genome files + BioSample/BioProject metadata
- **Runtime:** 1–2 hours

---

## Output Directory Structure

```
archaea_analysis/
├── logs/
│   └── pipeline_YYYYMMDD_HHMMSS.log
├── results/
│   ├── qc/
│   │   ├── sample_R1_clean.fq.gz
│   │   ├── sample_R2_clean.fq.gz
│   │   └── sample_fastp.html
│   ├── assembly/
│   │   ├── sample_contigs.fasta
│   │   └── quast_results/
│   ├── binning/
│   │   ├── semibin2_results/output_bins/
│   │   ├── metabat2_results/
│   │   └── checkm2_results/quality_report.tsv
│   ├── annotation/
│   │   ├── gtdbtk_results/ar53.summary.tsv
│   │   ├── dram_results/ + dram_distillation/product.html
│   │   └── antismash_results/
│   ├── phylogeny/
│   │   ├── sample_tree.treefile
│   │   └── sample_tree.svg
│   ├── submission/
│   │   ├── *_ncbi_ready.fasta
│   │   └── SUBMISSION_METADATA_TEMPLATE.txt
│   └── sample_ANALYSIS_REPORT.txt
└── temp/
    └── [intermediate files]
```

---

## Usage Examples

### **Example 1: Basic Usage**

```bash
./archaea_pipeline.sh -1 reads_R1.fq.gz -2 reads_R2.fq.gz
```

### **Example 2: With Custom Sample Name & High Resources**

```bash
./archaea_pipeline.sh \
    -1 /data/hydrothermal_R1.fq.gz \
    -2 /data/hydrothermal_R2.fq.gz \
    -s HydroVent_Deep_Sea_01 \
    -t 128 \
    -m 1000 \
    -w /mnt/hpc_storage/analysis
```

### **Example 3: Running with screen (for long jobs)**

```bash
screen -S archaea_analysis
mamba activate archaea_env
./archaea_pipeline.sh -1 R1.fq.gz -2 R2.fq.gz -s Sample_001 -t 64 -m 512

# Detach: Ctrl+A, then D
# Reattach: screen -r archaea_analysis
```

---

## Tool References & Links

| Stage | Tool | Version | Reference | Link |
| :--- | :--- | :--- | :--- | :--- |
| **QC** | fastp | v0.23.4 | Chen et al. (2023) | [GitHub](https://github.com/OpenGene/fastp) |
| **Assembly** | MetaSPAdes | v3.15.5 | Nurk et al. (2017) | [SourceForge](http://spades.bioinf.spbau.ru/) |
| **QC** | QUAST | v5.2+ | Gurevich et al. (2013) | [SourceForge](http://quast.sourceforge.net/) |
| **Mapping** | Bowtie2 | v2.5+ | Langmead & Salzberg (2012) | [SourceForge](http://bowtie-bio.sourceforge.net/) |
| **Binning** | SemiBin2 | v1.4+ | Pan et al. (2023) | [GitHub](https://github.com/BigDataBiology/SemiBin) |
| **Binning** | MetaBAT2 | v2.16+ | Kang et al. (2019) | [BitBucket](https://bitbucket.org/berkeleylab/metabat) |
| **QC** | CheckM2 | v1.0+ | Chklovski et al. (2023) | [GitHub](https://github.com/chklovski/CheckM2) |
| **Taxonomy** | GTDB-Tk | v2.3+ | Rinke et al. (2021) | [GitHub](https://github.com/Ecogenomics/GTDBTk) |
| **Annotation** | DRAM | v1.3+ | Shaffer et al. (2020) | [GitHub](https://github.com/WrightonLabCSU/DRAM) |
| **BGCs** | antiSMASH | v7.0+ | Blin et al. (2023) | [Web](https://antismash.secondarymetabolites.org/) |
| **Phylogeny** | IQ-TREE2 | v2.3+ | Minh et al. (2020) | [GitHub](https://github.com/iqtree/iqtree2) |

---

## Citation

If you use this pipeline in your research, please cite:

```bibtex
@software{archaea_pipeline_2025,
  author = {Alex Prima},
  title = {Archaea Genomics Pipeline: A workflow for extreme environment metagenomics},
  year = {2025},
  url = {https://github.com/axp-knickei/X-ARCH},
  doi = {10.XXXX/zenodo.XXXXXXX}  % Optional: add Zenodo DOI if available
}
```

Also cite the individual tools (see References section below).

---

## Troubleshooting

### **1. "fastp: command not found"**
```bash
mamba activate archaea_env
# Re-run setup if environment was not properly created
./setup_environment.sh
```

### **2. MetaSPAdes "Killed" (Out of Memory)**
- Reduce `-m` parameter to available RAM
- Reduce `-t` (threads) to free up memory
- Example: `./archaea_pipeline.sh ... -m 250 -t 32`

### **3. GTDB-Tk "Database not found"**
- First run downloads the GTDB database (~27 GB)
- Check internet connection and disk space
- Manual database download: `gtdbtk download-db --release 220`

### **4. CheckM2 "Model loading failed"**
- Download models manually: `checkm2 database --download --path /path/to/models`
- Set environment variable: `export CHECKM2_DB=/path/to/models`

### **5. Pipeline crashes mid-run**
- Check `logs/pipeline_*.log` for detailed error messages
- Ensure input files are not corrupted: `gunzip -t reads_R1.fq.gz`
- Verify disk space: `df -h`

---

## 📝 Methods Section Template

For your manuscript, include:

```
The quality of raw sequencing reads was assessed and trimmed using fastp (v0.23.4) 
with parameters: [specify your parameters]. Assembly was performed with MetaSPAdes 
(v3.15.5) with a maximum memory limit of [X] GB. Metagenome-assembled genomes (MAGs) 
were recovered using SemiBin2 (v1.4+) and MetaBAT2 (v2.16+), with genome quality 
assessed using CheckM2 (v1.0+). Taxonomy was assigned using GTDB-Tk (v2.3+) against 
the GTDB database (Release 220). Functional annotation was performed with DRAM (v1.3+), 
and biosynthetic gene clusters were identified using antiSMASH (v7.0+). Phylogenomic 
reconstruction was conducted using IQ-TREE2 (v2.3+) with 1000 ultrafast bootstraps.
```

---

## Contributing

We welcome contributions! Please:

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -am 'Add improvement'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

---

## License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.

---

## 🙋 Support & Questions

- **GitHub Issues:** [Report bugs or request features](https://github.com/axp-knickei/X-ARCH/issues)
- **Discussions:** [Start discussion here](https://github.com/axp-knickei/X-ARCH/discussions)
- **Email:** alex.prima@tu-dortmund.de

---

## References

1. Nurk, S., Meleshko, D., Korobeynikov, A., & Pevzner, P. A. (2017). metaSPAdes: a new versatile metagenomic assembler. *Genome Research*, 27(5), 824–834.
2. Kang, D. D., Li, F., Kirton, E. S., et al. (2019). MetaBAT 2: an adaptive binning algorithm for robust and efficient genome reconstruction from metagenomic data. *PeerJ*, 7, e7359.
3. Chklovski, A., Parks, D. H., Woodcroft, B. J., & Tyson, G. W. (2023). CheckM2: a rapid, scalable and accurate tool for assessing microbial genome quality. *bioRxiv*.
4. Rinke, C., Chuvochina, M., Mussig, A. J., et al. (2021). Standardized archaeal taxonomy in GTDB-Tk provides insight into archaeal diversity. *bioRxiv*.
5. Shaffer, M., Borton, M. A., McGivern, B. B., et al. (2020). DRAM for distilled and refined annotation of metabolism. *Nucleic Acids Research*, 48(15), 8883–8894.
6. Blin, K., Shaw, S., Kautsar, S. A., et al. (2023). antiSMASH 7.0: New and improved predictions of biosynthetic gene clusters. *Nucleic Acids Research*, 51(W1), W46–W50.
7. Minh, B. Q., Schmidt, H. A., Chernomor, O., et al. (2020). IQ-TREE 2: New models and efficient methods for phylogenetic inference in the genomic era. *Molecular Biology and Evolution*, 37(5), 1530–1534.

---

## Acknowledgments

This pipeline was developed with inspiration from:
- [NMDC Metagenome Assembled Genome Workflow](https://docs.microbiomedata.org/)
- [Anvi'o Metagenomics Workflows](https://anvio.org/)
- [Genome Taxonomy Database (GTDB)](https://gtdb.ecogenomic.org/)

---

**Last Updated:** December 2025  
**Maintained by:** Alex Prima ([Universitas Brawijaya](https://www.ub.ac.id/))  
**Status:** Active
