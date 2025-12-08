# Contributing to Archaea Genomics Pipeline

Thank you for your interest in contributing to this project! This document provides guidelines for contributing.

---

## Types of Contributions

We welcome:

- **Bug reports** – Found an issue? Please report it!
- **Feature requests** – Ideas for improvements?
- **Documentation improvements** – Clearer examples, better explanations?
- **Code contributions** – New tools, optimizations, or bug fixes?
- **Test cases** – Help us validate the pipeline on different systems?

---

## Reporting Bugs

1. **Check existing issues** first to avoid duplicates
2. **Create a new issue** with:
   - **Title:** Clear, concise description
   - **Description:** What happened vs. what should happen?
   - **Steps to reproduce:** Exact commands and input files
   - **Environment:** OS, RAM, CPU, tool versions (run `setup_environment.sh` and share output)
   - **Logs:** Attach relevant error messages from `logs/pipeline_*.log`
   - **Expected vs. Actual behavior**

**Example:**

```
Title: CheckM2 crashes on archaeal MAGs with "Model loading failed"

Environment:
- OS: Ubuntu 22.04 LTS
- RAM: 256 GB
- Python: 3.10.9
- CheckM2: 1.0.1

Steps to reproduce:
1. Run: ./archaea_pipeline.sh -1 sample_R1.fq.gz -2 sample_R2.fq.gz
2. Pipeline fails at Stage D (Quality Assessment)

Error log excerpt:
[ERROR] CheckM2 failed with: "Model loading failed"

Expected: Bins assessed for completeness/contamination
Actual: Pipeline crashes, no quality_report.tsv generated
```

---

## Suggesting Features

1. **Check existing issues/discussions** – Someone may have proposed it already
2. **Explain the use case:** Why is this feature needed?
3. **Provide context:** How would it benefit users?
4. **Suggest implementation** (optional): Pseudocode, reference papers, or related tools

**Example:**

```
Title: Add support for long-read assembly (PacBio/Nanopore)

Use case:
- Many extreme environment samples have complex strain mixtures
- Long reads improve assembly contiguity, especially for MAG recovery

Suggested implementation:
- Add HiFiASM or Flye as alternative assemblers
- Auto-detect read type from FASTQ headers
- Output longer scaffolds to improve binning

Related: Paper on long-read metagenomics (https://doi.org/...)
```

---

## Contributing Code

### Setup for Development

```bash
# 1. Fork the repository on GitHub

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/X-ARCH.git
cd X-ARCH

# 3. Add upstream remote
git remote add upstream https://github.com/axp-knickei/X-ARCH.git

# 4. Create a feature branch
git checkout -b feature/your-feature-name
# or for bug fixes:
git checkout -b bugfix/issue-description
```

### Code Standards

- **Bash scripts:**
  - Use `#!/bin/bash` and `set -e` for error handling
  - Add comments for complex logic
  - Follow ShellCheck recommendations: `shellcheck archaea_pipeline.sh`
  - Use meaningful variable names

- **Python code:**
  - Follow PEP 8 style guide
  - Use type hints where applicable
  - Include docstrings for functions
  - Test with Python 3.8+ 

- **Documentation:**
  - Write clear, concise comments
  - Update README.md if behavior changes
  - Include examples for new features

### Testing Your Changes

Before submitting a PR:

```bash
# 1. Verify Bash syntax
bash -n archaea_pipeline.sh

# 2. Run on test data (if small enough)
./archaea_pipeline.sh -1 test_R1.fq.gz -2 test_R2.fq.gz -s test_sample -t 4 -m 64

# 3. Check output structure
ls -la archaea_analysis/results/

# 4. Review logs for errors
cat archaea_analysis/logs/pipeline_*.log | tail -50
```

### Commit Best Practices

```bash
# Keep commits atomic (one feature/fix per commit)
git add file1.sh file2.py
git commit -m "Add support for antiSMASH 7.0+ database downloads"

# Use clear commit messages:
# - Imperative mood: "Add" not "Added" or "Adds"
# - Reference issues: "Fixes #42" or "Related to #123"

# Good examples:
git commit -m "Add automated DRAM database installation"
git commit -m "Fix CheckM2 database path handling on macOS"
git commit -m "Update GTDB-Tk to v2.3.2 (Fixes #105)"
```

### Create a Pull Request

1. **Push your branch:**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Open a PR on GitHub** with:
   - **Title:** Clear description of changes
   - **Description:** What changed? Why? Links to related issues?
   - **Testing:** How did you verify it works?
   - **Checklist:**
     - [ ] Code follows style guidelines
     - [ ] Documentation updated (README, comments)
     - [ ] Tested on multiple systems (if applicable)
     - [ ] No breaking changes to existing functionality

3. **Address feedback** – We may suggest improvements

4. **Merge** – Once approved, your PR will be merged!

---

## Documentation Contributions

Documentation improvements are highly valued! Edit `README.md`, create tutorials, or clarify complex sections.

### Documentation Standards

- Use clear, accessible language
- Include examples with realistic data
- Explain the "why" not just the "how"
- Link to relevant papers/tools
- Keep formatting consistent

---

## Development Roadmap

### Planned Features (v1.1+)

- [ ] Support for long-read assemblies (PacBio, Nanopore)
- [ ] Integration with anvi'o for interactive visualization
- [ ] Automated pangenome analysis
- [ ] KEGG pathway mapping for extremophile metabolism
- [ ] Nextflow/Snakemake workflow wrapper
- [ ] Docker/Singularity container support
- [ ] Web-based results viewer
- [ ] Integration with NMDC standards

### Help Wanted

- **Windows WSL2 testing** – Verify all tools work on WSL
- **HPC cluster integration** – SLURM/PBS job submission templates
- **Tool benchmarking** – Compare binning methods on real datasets
- **Case studies** – Document analysis of specific extreme environments

---

## Questions?

- **GitHub Issues:** Not available for now
- **Email:** alexprima@students.ub.ac.id
- **Slack/Community:** Not available for now

---

## Recognition

All contributors are acknowledged in:
- README.md (Contributors section)
- CHANGELOG.md (for significant contributions)
- Zenodo/GitHub releases

---

## Contributor Code of Conduct

This project is committed to providing a welcoming and inclusive environment for all contributors. We ask that you:

- Treat others with respect
- Be constructive in feedback
- Respect different levels of expertise
- Follow open science principles

---

**Thank you for contributing! 🎉**
