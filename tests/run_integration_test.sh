#!/bin/bash
set -e

# Setup directories
TEST_DIR="$(pwd)/test_run"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
mkdir -p "$TEST_DIR/data"

# Create dummy input files
touch "$TEST_DIR/data/R1.fq.gz"
touch "$TEST_DIR/data/R2.fq.gz"

# Create a test config
cat > "$TEST_DIR/config.yaml" << EOF
pipeline:
  threads: 4
  max_memory_gb: 8
  sample_name: "test_sample"
  work_dir: "$TEST_DIR/analysis"
tools:
  spades_mode: "meta"
EOF

# Add mocks to PATH
export PATH="$(pwd)/tests/mocks:$PATH"

echo "Running integration test with mocks..."
echo "PATH is: $PATH"

# Run the pipeline
# Note: We need to point to the actual script location
./archaea_pipeline.sh \
    -1 "$TEST_DIR/data/R1.fq.gz" \
    -2 "$TEST_DIR/data/R2.fq.gz" \
    -s "test_sample" \
    -w "$TEST_DIR/analysis" \
    -t 4 \
    -m 8

# Verification
echo "Verifying output..."
if [[ -f "$TEST_DIR/analysis/results/test_sample_ANALYSIS_REPORT.txt" ]]; then
    echo "SUCCESS: Report generated."
else
    echo "FAILURE: Report not found."
    exit 1
fi

if [[ -f "$TEST_DIR/analysis/results/submission/bin.1_ncbi_ready.fasta" ]]; then
    echo "SUCCESS: NCBI ready genome found."
else
    echo "FAILURE: NCBI ready genome not found."
    exit 1
fi

echo "Integration test completed successfully!"
