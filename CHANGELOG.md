# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

- [ ] Workflow managers
  - Nextflow version
  - Snakemake version
  - Singularity container support
  - Docker image on Docker Hub

- [ ] HPC integration
  - SLURM job submission templates
  - PBS/Torque compatibility
  - Job dependency management

- [ ] Quality-of-life improvements
  - Progress bars during long steps
  - Email notifications on completion
  - Checkpoint/resume functionality
  - Parallel multi-sample analysis

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
