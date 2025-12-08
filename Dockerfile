# Use a base image with Conda installed
FROM condaforge/mambaforge:latest

# Set metadata
LABEL maintainer="Alex Prima <alex.prima@tu-dortmund.de>"
LABEL description="Container for Archaea Genomics Pipeline (X-ARCH)"
LABEL version="1.0"

# Set working directory
WORKDIR /app

# Copy environment file
COPY environment.yml .

# Create the conda environment
# We install into the base environment or a named one. 
# Installing into base is often easier for containers.
RUN mamba env update -n base -f environment.yml && \
    mamba clean -afy

# Copy pipeline scripts and configuration
COPY archaea_pipeline.sh .
COPY scripts/ scripts/
COPY config.yaml .
COPY setup_environment.sh .

# Make scripts executable
RUN chmod +x archaea_pipeline.sh setup_environment.sh scripts/*.py

# Create directories for mounting data
RUN mkdir -p /data /output /databases

# Set environment variables for the pipeline
ENV PATH="/app:${PATH}"
ENV PIPELINE_WORK_DIR="/output"
# We don't set data paths here as they are dynamic, but we can set defaults
ENV GTDBTK_DATA_PATH="/databases/gtdbtk"
ENV CHECKM2_DB="/databases/checkm2"

# Entrypoint
ENTRYPOINT ["/app/archaea_pipeline.sh"]
CMD ["-h"]
