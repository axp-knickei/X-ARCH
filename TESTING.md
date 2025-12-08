# Testing the Archaea Genomics Pipeline

This repository includes both unit tests for helper scripts and an integration test for the full pipeline.

## Prerequisites

Ensure you have set up the environment:

```bash
./setup_environment.sh
mamba activate archaea_env
```

This environment includes `pytest`, `pyyaml`, and all necessary dependencies.

## 1. Unit Tests

We use `pytest` to verify the logic of the Python helper scripts in `scripts/`.

**Run unit tests:**
```bash
pytest tests/test_python_scripts.py
```

## 2. Integration Test (Mocked)

We provide a "dry run" integration test that verifies the pipeline's orchestration logic (file handling, configuration loading, control flow) without running the heavy bioinformatics tools. It uses "mock" scripts (dummy executables) that simulate the output of tools like `SPAdes`, `CheckM2`, and `GTDB-Tk`.

**Run the integration test:**
```bash
./tests/run_integration_test.sh
```

**What this test does:**
1. Creates a temporary test directory `test_run/`.
2. Creates dummy FASTQ input files.
3. Generates a temporary `config.yaml`.
4. Adds `tests/mocks/` to the `$PATH` so the pipeline calls the dummy tools instead of the real ones.
5. Runs `archaea_pipeline.sh`.
6. Checks if the expected output report and results exist.

## Troubleshooting

- **Missing dependencies:** If `pytest` or `yaml` is missing, make sure you activated the conda environment (`mamba activate archaea_env`).
- **Permission denied:** Ensure the scripts are executable:
  ```bash
  chmod +x archaea_pipeline.sh tests/run_integration_test.sh tests/mocks/*
  ```
