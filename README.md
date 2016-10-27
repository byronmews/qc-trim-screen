Bpipe stages for running fastqc, trimmomatic, host screen with a summarised table of run results
--------------

Requires: qc_results_parser.pl

Usage example:
--------------

Expects PE fastq files. All PE fastq within folder are analysed, using the string before illumina sample index number as sample ID.

  $ bpipe run -r qc_trim_screen.groovy *
  
Produces the following files with suffixes or names:
 
- fastqc_pre_qc/.html: fastqc output before trimming
- PE.fastq|SE.fastq: four trimmed fastq output files, both PE and orphan SE
- fastqc_pre_qc/.html: fastqc ouput after trimming
- PE_no_hits_file.1.fastq/PE_no_hits_file.2.fastq: Human host and UniVec unmapped reads for each pair
- PE_screen.png: Human host and UniVec unmapped read distribution
- qc_summary_stats.tsv: qc summary metrics

