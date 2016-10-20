#!/usr/bin/perl

###############################################################################
# Parser for qc_trim_screen pipeline.					      #
#									      #
# Expects the trimmomatic std err as a single file named as: trimmomatic.err  #
#									      #
###############################################################################


use warnings;
use strict;

my $trim_log_file = "trimmomatic.err";
my $qc_summary = "qc_summary_stats.tsv";

my @gen_table ="sample_id trimmed_pairs_remaining\n";

open(my $input, $trim_log_file)
	or die "Could not open file $trim_log_file $!";

foreach my $line (<$input>) {

	chomp $line;

	if($line =~ /^TrimmomaticPE: Started with arguments:\s+\-phred33\s+(\w+.*_L001_R1_001.fastq.gz)\s+\w+/) {
		
		# Expecting this line:
		# TrimmomaticPE: Started with arguments: -phred33 1-2_S2_L001_R1_001.fastq.gz 1-2_S2_L001_R2_001.fastq.gz ...
		my $sample_id = $1;
		
		# Loose the fastq suffix name
		$sample_id =~ s/_L001_R1_001.fastq.gz//;
		push @gen_table, "$sample_id ";
	}
	elsif($line =~ /^Input Read Pairs:/)  {
	
		# Expecting this line:
		# Input Read Pairs: 30958 Both Surviving: 30703 (99.18%) Forward Only Surviving: 106 (0.34%) Reverse Only Surviving: 61 (0.20%) Dropped: 88 (0.28%)
		
		# Split line by space
		my @split = split / /, $line;	

		# Stats selected for summary file
		my $input_read_pairs = $split[3];
		my $surviving_read_pairs = $split[6];
		my $surviving_read_pairs_pct = $split[7];
		my $forward_only = $split[11];
		my $forward_only_pct = $split[12];
		my $reverse_only = $split[16];
		my $reverse_only_pct = $split[17];
		my $discarded = $split[19];
		my $discarded_pct = $split[20];

		# Add to running array	
		push @gen_table, "$input_read_pairs $surviving_read_pairs $surviving_read_pairs_pct \n";
	}
}


print "@gen_table \n"; 


=head1 AUTHOR
Graham Rose <graham.rose@phe.gov.uk>
=cut
