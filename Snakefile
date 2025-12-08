configfile: "config.yaml"

import os

# --- Helper Functions ---
def get_mem_gb(wildcards, attempt):
    return max(config["pipeline"]["max_memory_gb"] // 4 * attempt, config["pipeline"]["max_memory_gb"])

# --- Directories ---
WORK_DIR = config["pipeline"]["work_dir"]
RESULT_DIR = os.path.join(WORK_DIR, "results")
QC_DIR = os.path.join(RESULT_DIR, "qc")
ASSEMBLY_DIR = os.path.join(RESULT_DIR, "assembly")
BINNING_DIR = os.path.join(RESULT_DIR, "binning")
ANNOTATION_DIR = os.path.join(RESULT_DIR, "annotation")
PHYLOGENY_DIR = os.path.join(RESULT_DIR, "phylogeny")
SUBMISSION_DIR = os.path.join(RESULT_DIR, "submission")
TEMP_DIR = os.path.join(WORK_DIR, "temp")

SAMPLE_NAME = config["pipeline"]["sample_name"]

# --- Input Files ---
# We assume the user provides R1 and R2 paths via command line or config
# For this Snakefile, we'll look for them in the config or default to standard locations
R1 = config.get("reads", {}).get("r1", "input_data/R1.fastq.gz")
R2 = config.get("reads", {}).get("r2", "input_data/R2.fastq.gz")

# --- Rules ---

rule all:
    input:
        os.path.join(RESULT_DIR, f"{SAMPLE_NAME}_ANALYSIS_REPORT.txt"),
        os.path.join(SUBMISSION_DIR, "SUBMISSION_METADATA_TEMPLATE.txt")

rule qc:
    input:
        r1 = R1,
        r2 = R2
    output:
        r1_clean = os.path.join(QC_DIR, f"{SAMPLE_NAME}_R1_clean.fq.gz"),
        r2_clean = os.path.join(QC_DIR, f"{SAMPLE_NAME}_R2_clean.fq.gz"),
        html = os.path.join(QC_DIR, f"{SAMPLE_NAME}_fastp.html"),
        json = os.path.join(QC_DIR, f"{SAMPLE_NAME}_fastp.json")
    threads: config["pipeline"]["threads"]
    conda: "archaea_env"
    shell:
        """
        fastp \
            -i {input.r1} -I {input.r2} \
            -o {output.r1_clean} -O {output.r2_clean} \
            -h {output.html} -j {output.json} \
            --detect_adapter_for_pe --correction \
            --thread {threads}
        python3 scripts/extract_qc_stats.py {output.json} > {output.json}.summary
        """

rule assembly:
    input:
        r1 = rules.qc.output.r1_clean,
        r2 = rules.qc.output.r2_clean
    output:
        contigs = os.path.join(ASSEMBLY_DIR, f"{SAMPLE_NAME}_contigs.fasta"),
        scaffolds = os.path.join(ASSEMBLY_DIR, f"{SAMPLE_NAME}_spades", "scaffolds.fasta")
    params:
        outdir = os.path.join(ASSEMBLY_DIR, f"{SAMPLE_NAME}_spades"),
        mode = config["tools"]["spades_mode"],
        memory = config["pipeline"]["max_memory_gb"]
    threads: config["pipeline"]["threads"]
    conda: "archaea_env"
    shell:
        """
        spades.py --{params.mode} \
            -1 {input.r1} -2 {input.r2} \
            -o {params.outdir} \
            -t {threads} -m {params.memory}
        cp {params.outdir}/contigs.fasta {output.contigs}
        """

rule quast:
    input:
        contigs = rules.assembly.output.contigs
    output:
        report = directory(os.path.join(ASSEMBLY_DIR, "quast_results"))
    threads: config["pipeline"]["threads"]
    conda: "archaea_env"
    shell:
        """
        quast.py {input.contigs} \
            -o {output.report} \
            --threads {threads}
        """

rule mapping:
    input:
        contigs = rules.assembly.output.contigs,
        r1 = rules.qc.output.r1_clean,
        r2 = rules.qc.output.r2_clean
    output:
        bam = os.path.join(TEMP_DIR, f"{SAMPLE_NAME}.sorted.bam"),
        bai = os.path.join(TEMP_DIR, f"{SAMPLE_NAME}.sorted.bam.bai")
    params:
        index_base = os.path.join(TEMP_DIR, f"{SAMPLE_NAME}_index")
    threads: config["pipeline"]["threads"]
    conda: "archaea_env"
    shell:
        """
        bowtie2-build {input.contigs} {params.index_base} --threads {threads}
        bowtie2 -x {params.index_base} \
            -1 {input.r1} -2 {input.r2} \
            -p {threads} \
            | samtools view -bS - | samtools sort -o {output.bam} -
        samtools index {output.bam}
        """

rule semibin:
    input:
        contigs = rules.assembly.output.contigs,
        bam = rules.mapping.output.bam
    output:
        bins_dir = directory(os.path.join(BINNING_DIR, "semibin2_results"))
    threads: config["pipeline"]["threads"]
    conda: "archaea_env"
    shell:
        """
        SemiBin2 single_easy_bin \
            -i {input.contigs} \
            -b {input.bam} \
            -o {output.bins_dir} \
            --environment global \
            -p {threads}
        """

rule metabat_depth:
    input:
        bam = rules.mapping.output.bam
    output:
        depth = os.path.join(TEMP_DIR, "metabat_depth.txt")
    conda: "archaea_env"
    shell:
        "jgi_summarize_bam_contig_depths --outputDepth {output.depth} {input.bam}"

rule metabat:
    input:
        contigs = rules.assembly.output.contigs,
        depth = rules.metabat_depth.output.depth
    output:
        bins_dir = directory(os.path.join(BINNING_DIR, "metabat2_results"))
    threads: config["pipeline"]["threads"]
    conda: "archaea_env"
    shell:
        """
        mkdir -p {output.bins_dir}
        metabat2 -i {input.contigs} \
            -a {input.depth} \
            -o {output.bins_dir}/bin \
            -t {threads}
        """

# We focus on SemiBin2 results for downstream analysis as per original pipeline default flow,
# but ideally we would integrate both. The original script used SemiBin2 output for CheckM2.

rule checkm2:
    input:
        bins = rules.semibin.output.bins_dir
    output:
        outdir = directory(os.path.join(BINNING_DIR, "checkm2_results")),
        report = os.path.join(BINNING_DIR, "checkm2_results", "quality_report.tsv")
    threads: config["pipeline"]["threads"]
    conda: "archaea_env"
    shell:
        """
        checkm2 predict \
            --input {input.bins}/output_bins \
            --output-directory {output.outdir} \
            --threads {threads} --force
        """

rule gtdbtk:
    input:
        bins = rules.semibin.output.bins_dir
    output:
        outdir = directory(os.path.join(ANNOTATION_DIR, "gtdbtk_results")),
        summary = os.path.join(ANNOTATION_DIR, "gtdbtk_results", "gtdbtk.ar53.summary.tsv") # Assumption: Archaea
    threads: config["pipeline"]["threads"]
    conda: "archaea_env"
    shell:
        """
        # Ensure database path is set if provided in config
        # export GTDBTK_DATA_PATH="{config[databases][gtdbtk_data_path]}"
        gtdbtk classify_wf \
            --genome_dir {input.bins}/output_bins \
            --out_dir {output.outdir} \
            --cpus {threads} \
            --pplacer_cpus 1 \
            --extension fasta --force
        """

rule dram:
    input:
        bins = rules.semibin.output.bins_dir
    output:
        outdir = directory(os.path.join(ANNOTATION_DIR, "dram_results")),
        distill = directory(os.path.join(ANNOTATION_DIR, "dram_distillation"))
    threads: config["pipeline"]["threads"]
    conda: "archaea_env"
    shell:
        """
        DRAM.py annotate \
            -i {input.bins}/output_bins/*.fasta \
            -o {output.outdir} \
            --threads {threads} --verbose
        
        DRAM.py distill \
            -i {output.outdir}/annotations.tsv \
            -o {output.distill} \
            --verbose
        """

# For antiSMASH, the original script iterates over files. Snakemake handles this best with a checkpoint
# or by using `expand` if we know the filenames. Since filenames are dynamic (from binning),
# we'll use a simple shell loop inside a rule for now to mimic the original script's behavior,
# or treating the whole folder as an output.

rule antismash:
    input:
        bins = rules.semibin.output.bins_dir
    output:
        outdir = directory(os.path.join(ANNOTATION_DIR, "antismash_results"))
    threads: config["pipeline"]["threads"]
    conda: "archaea_env"
    shell:
        """
        mkdir -p {output.outdir}
        for bin in {input.bins}/output_bins/*.fasta; do
            bin_name=$(basename "$bin" .fasta)
            antismash \
                "$bin" \
                --outdir "{output.outdir}/$bin_name" \
                --cpus {threads} \
                --genefinding-tool prodigal
        done
        """

# Phylogeny depends on GTDB-Tk MSA.
# Note: GTDB-Tk might output bac120 or ar53 depending on input.
# The original script checks for both. Snakemake needs a deterministic input.
# We will use a checkpoint or a dynamic function, but for simplicity here 
# we'll assume the user knows it's Archaea (as per pipeline name).
# We can also wrap the logic in a python function or shell.

rule phylogeny:
    input:
        # We depend on GTDB-Tk completion
        summary = rules.gtdbtk.output.summary,
        outdir = rules.gtdbtk.output.outdir
    output:
        tree = os.path.join(PHYLOGENY_DIR, f"{SAMPLE_NAME}_tree.treefile")
    threads: config["pipeline"]["threads"]
    conda: "archaea_env"
    shell:
        """
        # Find the MSA file
        MSA=$(find {input.outdir}/align -name "*.user_msa.fasta" | head -n 1)
        if [ -z "$MSA" ]; then
            echo "Error: MSA not found"
            exit 1
        fi
        iqtree2 -s "$MSA" \
            -m MFP -B {config[tools][iqtree_bootstrap_replicates]} \
            -T AUTO --ntmax {threads} \
            --prefix {PHYLOGENY_DIR}/{SAMPLE_NAME}_tree
        """

rule submission_prep:
    input:
        bins = rules.semibin.output.bins_dir
    output:
        outdir = directory(SUBMISSION_DIR),
        template = os.path.join(SUBMISSION_DIR, "SUBMISSION_METADATA_TEMPLATE.txt")
    conda: "archaea_env"
    shell:
        """
        mkdir -p {output.outdir}
        for bin in {input.bins}/output_bins/*.fasta; do
            bin_name=$(basename "$bin" .fasta)
            python3 scripts/filter_contigs.py \
                -i "$bin" \
                -o "{output.outdir}/$bin_name_ncbi_ready.fasta" \
                --min_length 200
        done
        
        # We need to replicate the metadata template generation
        # Since the values are in config.yaml, we can use a python script or shell heredoc with parsing
        # For simplicity, we call a slightly modified version of the original shell logic or a new python script.
        # Here we just generate a placeholder as this is a migration step.
        # Ideally, we'd move that logic to a proper python script.
        
        echo "Placeholder for metadata template. See original script for full generation logic." > {output.template}
        """

rule report:
    input:
        qc_html = rules.qc.output.html,
        quast = rules.quast.output.report,
        checkm2 = rules.checkm2.output.report,
        dram = rules.dram.output.outdir,
        tree = rules.phylogeny.output.tree
    output:
        report = os.path.join(RESULT_DIR, f"{SAMPLE_NAME}_ANALYSIS_REPORT.txt")
    shell:
        """
        echo "Analysis Report for {SAMPLE_NAME}" > {output.report}
        echo "Date: $(date)" >> {output.report}
        echo "Results are in {RESULT_DIR}" >> {output.report}
        """
