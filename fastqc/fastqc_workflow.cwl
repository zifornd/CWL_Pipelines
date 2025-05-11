cwlVersion: v1.2
class: Workflow
label: FastQC Pipeline
doc: A CWL pipeline for performing quality control on FASTQ files in a folder using FastQC.

requirements:
  ScatterFeatureRequirement: {}
  StepInputExpressionRequirement: {}
  InlineJavascriptRequirement: {}

inputs:
  fastq_dir:
    type: Directory
    label: Input directory containing FASTQ files

  threads:
    type: int
    default: 1
    label: Number of threads for FastQC

steps:
  list_fastq:
    run:
      class: ExpressionTool
      inputs:
        dir:
          type: Directory
          loadListing: deep_listing
      outputs:
        fastq_files:
          type: File[]
      expression: >
        ${
          return {
            fastq_files: inputs.dir.listing.filter(f =>
              f.class === "File" &&
              (f.basename.endsWith(".fastq") ||
               f.basename.endsWith(".fastq.gz") ||
               f.basename.endsWith(".fq") ||
               f.basename.endsWith(".fq.gz"))
            )
          };
        }
    in:
      dir: fastq_dir
    out: [fastq_files]

  fastqc:
    run:
      class: CommandLineTool
      label: FastQC for quality control
      requirements:
        DockerRequirement:
          dockerPull: quay.io/biocontainers/fastqc:0.11.9--0
      inputs:
        fastq:
          type: File
          inputBinding:
            position: 1
        threads:
          type: int
          inputBinding:
            prefix: --threads
      outputs:
        fastqc_zip:
          type: File
          outputBinding:
            glob: "*.zip"
        fastqc_html:
          type: File
          outputBinding:
            glob: "*.html"
      baseCommand: ["fastqc", "--outdir", "."]
    scatter: fastq
    in:
      fastq: list_fastq/fastq_files
      threads: threads
    out: [fastqc_zip, fastqc_html]

outputs:
  fastqc_zip_files:
    type: File[]
    outputSource: fastqc/fastqc_zip
    label: FastQC ZIP reports

  fastqc_html_files:
    type: File[]
    outputSource: fastqc/fastqc_html
    label: FastQC HTML reports