## 🐳 Docker Support

The pipeline is containerized for reproducibility and ease of deployment.

### 1. Build the Image

```bash
docker build -t x-arch:v1.0 .
```

### 2. Prepare Data & Databases

You need to mount your input data and (optionally) pre-downloaded databases into the container.

*   **Input Data:** Place your FASTQ files in a local directory (e.g., `./my_data`).
*   **Databases:** (Recommended) Download GTDB-Tk, CheckM2, and DRAM databases locally to avoid re-downloading them every run.

### 3. Run the Pipeline

```bash
docker run --rm -it \
    -v $(pwd)/my_data:/data \
    -v $(pwd)/results:/output \
    -v /path/to/local/databases:/databases \
    x-arch:v1.0 \
    -1 /data/sample_R1.fq.gz \
    -2 /data/sample_R2.fq.gz \
    -s MySample \
    -t 16 \
    -m 64
```

**Note:**
*   `-v $(pwd)/results:/output`: Maps your local results folder to the container's output.
*   The container uses `config_docker.yaml` logic by default (looking for `/databases`), but you can override this by mounting your own `config.yaml` to `/app/config.yaml`.

```
