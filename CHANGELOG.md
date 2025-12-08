# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2025-12-08

### The Modernization & Reproducibility Update

### Added

- **Improved Reproducibility:**
  - Introduced `environment.yml` for precise version pinning of all Conda/Pip dependencies, replacing unpinned `setup_environment.sh`.
  - Ensured `metabat2` (previously missing) is installed as per `README.md` specification.
- **Enhanced Code Structure:**
  - Extracted inline Python heredocs from `archaea_pipeline.sh` into dedicated, modular Python scripts (`scripts/extract_qc_stats.py`, `scripts/filter_hq_bins.py`, `scripts/filter_contigs.py`).
  - Parameterized Python helper scripts for reusability and testability.
  - Organized helper scripts into a new `scripts/` directory.
- **Centralized Configuration Management:**
  - Replaced `config.sh` with a structured `config.yaml` for all pipeline parameters.
  - Implemented `scripts/read_config.py` to parse `config.yaml` and make variables accessible in `archaea_pipeline.sh`.
  - Updated `archaea_pipeline.sh` to load configuration from `config.yaml` and allow command-line overrides.
  - Dynamic display of default values in `--help` message.
- **Comprehensive Testing Infrastructure:**
  - Added unit tests (`tests/test_python_scripts.py`) for Python helper scripts using `pytest`.
  - Developed a mock-based integration test (`tests/run_integration_test.sh`) to verify `archaea_pipeline.sh` flow without heavy tool execution.
  - Created `tests/mocks/` directory with dummy executables for bioinformatics tools.
  - Provided `TESTING.md` documentation for running tests.
- **Containerization Support:**
  - Created `Dockerfile` for building a reproducible Docker image based on the Conda environment.
  - Provided `config_docker.yaml` with container-optimized paths.
  - Documented Docker build and run instructions in `DOCKER_README.md`.
- **Modern Workflow Management (Snakemake):**
  - Implemented a `Snakefile` to orchestrate the entire pipeline, defining rules for each stage.
  - Integrated `config.yaml` with Snakemake for parameter management.
  - Provided `SNAKEMAKE_README.md` for guidance on running the pipeline with Snakemake.

### Changed

- `setup_environment.sh`: Modified to use `environment.yml` for Conda environment creation/update.
- `archaea_pipeline.sh`:
  - Updated to load parameters from `config.yaml` and support command-line overrides.
  - Replaced inline Python code with calls to external scripts.
  - Updated NCBI submission template to use `config.yaml` values.
- `README.md`: Added sections for Docker and Snakemake usage.
- `environment.yml`: Added `pyyaml`, `pytest`, and `snakemake` dependencies.

### Removed

- `config.sh`: Superseded by `config.yaml`.
- Inline Python code blocks from `archaea_pipeline.sh`.

---

## [1.0.0] - 2025-12-07

### Initial Release

First release of the Archaea Genomics Pipeline for extreme environment metagenomics.

#### Added

- **Complete WGS workflow** from raw reads to NCBI-ready genomes
  - Stage A: fastp-based quality control
  - Stage B: MetaSPAdes metagenomic assembly
  - Stage C: Multi-method genome binning (SemiBin2 + MetaBAT2)
  - Stage D: CheckM2 lineage-agnostic quality assessment
  - Stage E: GTDB-Tk taxonomic classification
  - Stage F: DRAM functional annotation + antiSMASH BGC detection
  - Stage G: IQ-TREE2 phylogenomic tree construction
  - Stage H: Automated reporting and visualization
  - Stage I: NCBI submission preparation

- **Comprehensive documentation**
  - README with quick-start guide
  - Detailed tool reference table
  - Troubleshooting guide
  - CONTRIBUTING.md for community involvement

- **Installation automation**
  - `setup_environment.sh` for one-command conda environment setup
  - Automated database downloads for GTDB-Tk, DRAM, antiSMASH
  - Dependency validation and verification

- **Configuration management**
  - `config.sh` template for persistent settings
  - Support for environment variables
  - Sample metadata pre-configuration

- **Reproducibility features**
  - Comprehensive logging with timestamps
  - Tool version tracking
  - Parameter documentation in output reports
  - Methods section template for manuscripts

#### Tools Integrated

| Tool | Version | Purpose |
| :--- | :--- | :--- |
| fastp | v0.23.4+ | Adapter trimming & QC |
| MetaSPAdes | v3.15.5+ | Metagenomic assembly |
| QUAST | v5.2+ | Assembly quality metrics |
| Bowtie2 | v2.5+ | Read mapping |
| SemiBin2 | v1.4+ | Deep learning genome binning |
| MetaBAT2 | v2.16+ | Coverage-based binning |
| CheckM2 | v1.0+ | ML-based bin quality assessment |
| GTDB-Tk | v2.3.2+ | Archaeal taxonomy |
| DRAM | v1.3.6+ | Metabolic annotation |
| antiSMASH | v7.0+ | Secondary metabolite detection |
| IQ-TREE2 | v2.3+ | Phylogenomic trees |

#### System Requirements

- Minimum: 128 GB RAM, 16 cores, 2 TB SSD
- Recommended: 512 GB RAM, 64+ cores, 10 TB NVMe SSD
- OS: Linux (Ubuntu 22.04 LTS) or WSL2
- Conda/Mamba required for package management

#### Known Issues

- GTDB-Tk database (~27 GB) requires ~200 GB temp space during download (first run only)
- MetaSPAdes assembly may timeout on extremely large/diverse samples (>50 million reads)
- Some antiSMASH features require MEME license agreement

---

## [Unreleased] - Development

### Planned for v1.1

#### Planned Additions

- [ ] Long-read assembly support (PacBio HiFi, Nanopore)
  - HiFiASM integration
  - Flye alternative assembler
  - Hybrid assembly workflows

- [ ] Interactive visualization
  - Anvi'o integration module
  - Web-based results dashboard
  - Comparative genomics heatmaps

- [ ] Advanced analyses
  - Pangenome analysis (anvi'o/GET_HOMOLOGUES)
  - KEGG pathway reconstruction for extremophiles
  - Horizontal gene transfer detection

#### Community Feedback

- [ ] Test on macOS (M1/M2 chips)
- [ ] Windows compatibility improvements
- [ ] Performance benchmarks on different systems
- [ ] Case studies from diverse environments

---

## Version History Template (For Future Releases)

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New feature description

### Changed
- Updated behavior description

### Fixed
- Bug fix description

### Deprecated
- Soon-to-be-removed feature

### Removed
- Removed feature description

### Security
- Security vulnerability fix
```

---

## How to Report

- **Bugs:** [Open an issue](https://github.com/axp-knickei/X-ARCH/issues/new/choose)
- **Feature requests:** [Discussions tab](https://github.com/axp-knickei/X-ARCH/discussions)
- **Security concerns:** Email [alexprima@student.ub.ac.id] (do not open public issue)

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute improvements to this changelog and project.

---

## Acknowledgments

- **Bioconda maintainers** – For packaging bioinformatics tools
- **Tool developers** – MetaSPAdes, GTDB-Tk, DRAM, antiSMASH, and all integrated tools
- **Community feedback** – Users who report issues and suggest improvements
- **Funding** – [Your institution/funding agency]

