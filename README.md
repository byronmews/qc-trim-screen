Bpipe stages for running core QC
--------------

Run as either PE or SE versions.

Requires: qc_results_parser_[se|pe].pl from repository

Uses fastqc, trimmomatic, fasqtc_screen and summarises results into single table.

If running PE version all PE fastq within folder are analysed, using the string before illumina sample index number as sample ID.

Usage PE example:
--------------

  $ bpipe run -r qc_trim_screen_pe.groovy *
  
Produces the following files with suffixes or names:
 
- fastqc_pre_qc/.html: fastqc output before trimming
- PE.fastq|SE.fastq: four trimmed fastq output files, both PE and orphan SE
- fastqc_pre_qc/.html: fastqc ouput after trimming
- PE_no_hits_file.1.fastq/PE_no_hits_file.2.fastq: Human host and UniVec unmapped reads for each pair
- PE_screen.png: Human host and UniVec unmapped read distribution
- qc_summary_stats.tsv: qc summary metrics


Also requires:

- FastQC
- Trimmomatic
- Bowtie2
- Fastq_screen (http://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/)

Fastq screen uses bowtie2 indexes of human assembly GRCh38 and the Univec v8 database (ftp://ftp.ncbi.nlm.nih.gov/pub/UniVec/)

