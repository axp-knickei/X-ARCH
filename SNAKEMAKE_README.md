## 🐍 Running with Snakemake

The pipeline has been migrated to **Snakemake** for better workflow management, scalability, and error handling.

### 1. Configure

Edit `config.yaml` to set your parameters and input file paths:

```yaml
reads:
  r1: "path/to/reads_R1.fq.gz"
  r2: "path/to/reads_R2.fq.gz"

pipeline:
  work_dir: "archaea_analysis"
  sample_name: "MySample"
  threads: 32
  max_memory_gb: 500
```

### 2. Run

```bash
# Activate environment
mamba activate archaea_env

# Run pipeline (local)
snakemake --cores 32 --use-conda

# Run pipeline (dry-run to see what will happen)
snakemake -n
```

### 3. Advanced Usage

*   **Cluster Execution:** Snakemake supports SLURM, PBS, etc.
    ```bash
    snakemake --executor slurm --jobs 100 --use-conda
    ```
*   **Resume:** If the pipeline fails, simply re-run the command. Snakemake will pick up where it left off.
*   **Force Re-run:** Use `-F` or `--forceall` to re-run everything.

---
