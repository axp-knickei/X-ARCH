import pytest
import json
import pandas as pd
import tempfile
import os
import sys
from io import StringIO
from unittest.mock import patch, MagicMock

# Ensure scripts directory is in path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../scripts')))

# We import the modules. Note: The scripts need to be importable. 
# Since they have if __name__ == "__main__", we can import them, 
# but we might need to refactor them slightly if we want to test individual functions cleanly.
# However, the current scripts are main-heavy. 
# For testing purposes, it's often better to subprocess them or refactor them.
# Given I just wrote them, I'll refactor them slightly in-place to be testable 
# OR just test them via subprocess for true black-box testing.
# Let's use subprocess for the CLI scripts to ensure argument parsing works.

import subprocess

SCRIPTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '../scripts'))

class TestExtractQCStats:
    def test_extract_qc_stats_valid(self, tmp_path):
        # Create a dummy fastp json
        data = {
            "summary": {
                "before_filtering": {"total_reads": 1000},
                "after_filtering": {
                    "total_reads": 900,
                    "q30_rate": 0.955,
                    "gc_content": 0.50
                }
            }
        }
        json_file = tmp_path / "fastp.json"
        with open(json_file, 'w') as f:
            json.dump(data, f)
            
        script_path = os.path.join(SCRIPTS_DIR, "extract_qc_stats.py")
        result = subprocess.run([sys.executable, script_path, str(json_file)], capture_output=True, text=True)
        
        assert result.returncode == 0
        assert "Reads before filtering: 1000" in result.stdout
        assert "Q30 rate (after): 95.50%" in result.stdout

    def test_extract_qc_stats_missing_file(self):
        script_path = os.path.join(SCRIPTS_DIR, "extract_qc_stats.py")
        result = subprocess.run([sys.executable, script_path, "nonexistent.json"], capture_output=True, text=True)
        assert result.returncode == 1
        assert "Error: File not found" in result.stderr


class TestFilterHQBins:
    def test_filter_hq_bins(self, tmp_path):
        # Create dummy TSV
        tsv_content = "Name\tCompleteness\tContamination\nBin1\t95.0\t2.0\nBin2\t80.0\t1.0\nBin3\t99.0\t10.0\n"
        tsv_file = tmp_path / "quality_report.tsv"
        with open(tsv_file, 'w') as f:
            f.write(tsv_content)
            
        script_path = os.path.join(SCRIPTS_DIR, "filter_hq_bins.py")
        result = subprocess.run(
            [sys.executable, script_path, str(tsv_file), "--completeness", "90", "--contamination", "5"], 
            capture_output=True, text=True
        )
        
        assert result.returncode == 0
        assert "Bin1" in result.stdout
        assert "Bin2" not in result.stdout # Low completeness
        assert "Bin3" not in result.stdout # High contamination
        assert "95.0" in result.stdout


class TestFilterContigs:
    def test_filter_contigs(self, tmp_path):
        # Create dummy FASTA
        fasta_content = ">seq1\n" + "A" * 300 + "\n>seq2\n" + "C" * 100 + "\n>seq3\n" + "G" * 250 + "\n"
        input_file = tmp_path / "input.fasta"
        output_file = tmp_path / "output.fasta"
        with open(input_file, 'w') as f:
            f.write(fasta_content)
            
        script_path = os.path.join(SCRIPTS_DIR, "filter_contigs.py")
        result = subprocess.run(
            [sys.executable, script_path, "-i", str(input_file), "-o", str(output_file), "--min_length", "200"],
            capture_output=True, text=True
        )
        
        assert result.returncode == 0
        assert "Kept 2, Removed 1" in result.stdout
        
        with open(output_file, 'r') as f:
            content = f.read()
            assert ">seq1" in content
            assert ">seq2" not in content
            assert ">seq3" in content

class TestReadConfig:
    def test_read_config(self, tmp_path):
        config_data = """
        pipeline:
          threads: 16
        tools:
          spades_mode: "meta"
        """
        config_file = tmp_path / "test_config.yaml"
        with open(config_file, 'w') as f:
            f.write(config_data)

        script_path = os.path.join(SCRIPTS_DIR, "read_config.py")
        result = subprocess.run(
            [sys.executable, script_path, str(config_file)],
            capture_output=True, text=True
        )

        assert result.returncode == 0
        assert 'PIPELINE_THREADS=16' in result.stdout
        assert 'TOOLS_SPADES_MODE="meta"' in result.stdout
