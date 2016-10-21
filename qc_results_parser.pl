#!/usr/bin/perl

###############################################################################
# Parser for qc_trim_screen pipeline.					      #
#									      #
# Expects the trimmomatic std err as a single file named as: trimmomatic.err  #
#									      #
###############################################################################


use warnings;
use strict;

# Vars
my $trim_log_file = "trimmomatic.err";
my $qc_summary = "qc_summary_stats.tsv";

# Arrays
my @trim_log_table; # trimmomatic log file
my @sample_ids; # sync output by sample name
my @qc_passed_pe_reads; # qc passed pe read number

open my $input_fh, '<', $trim_log_file
	or die "Could not open file $trim_log_file $!";

# Table header for @trim_log_table
my $table_header_trim_log = "input_read_pairs\ttrimmed_pairs_remaining\ttrimmed_pairs_remaining_%\tforward_orphan_reads\tforward_orphan_reads_%\treverse_orphan_reads\treverse_orphan_reads_%\tdiscarded_pairs\tdiscarded_pairs_%\t";

# Read log file by line
foreach my $line (<$input_fh>) {

	chomp $line;

	if($line =~ /^TrimmomaticPE: Started with arguments:\s+\-phred33\s+(\w+.*_S\d+_L001_R1_001.fastq.gz)\s+\w+/) {
		
		# Expecting this line in log file:
		# TrimmomaticPE: Started with arguments: -phred33 1-2_S2_L001_R1_001.fastq.gz 1-2_S2_L001_R2_001.fastq.gz ...
		
		my $sample_id = $1;
		
		# Lose the fastq suffix name
		$sample_id =~ s/_L001_R1_001.fastq.gz//;
		push @sample_ids, $sample_id;
	}
	elsif($line =~ /^Input Read Pairs:/)  {
	
		# Expecting this line in log file:
		# Input Read Pairs: 30958 Both Surviving: 30703 (99.18%) Forward Only Surviving: 106 (0.34%) Reverse Only Surviving: 61 (0.20%) Dropped: 88 (0.28%)
		
		# Remove all % and bracket chars as these can be interpreted poorly by external programs
		$line =~ s/(\%|\(|\))//g;

		# Split line by space character
		my @split = split /\s/,$line;

		# Metrics selected for summary table
		my $input_read_pairs = $split[3];
		my $surviving_read_pairs = $split[6];
		my $surviving_read_pairs_pct = $split[7];
		my $forward_only = $split[11];
		my $forward_only_pct = $split[12];
		my $reverse_only = $split[16];
		my $reverse_only_pct = $split[17];
		my $discarded = $split[19];
		my $discarded_pct = $split[20];
		
		# Add to table array
		push @trim_log_table, "$input_read_pairs\t$surviving_read_pairs\t$surviving_read_pairs_pct\t$forward_only\t$forward_only_pct\t$reverse_only\t$reverse_only_pct\t$discarded\t$discarded_pct";
	}
}
close $input_fh;


# Table header for @qc_passed_pe_reads
my $table_header_read_number = "qc_passed_r1_filename\tread_number\t";

# Count final read pairs in QC passed fastqs
foreach my $sample_id (@sample_ids) {
	
	my $lines = 0; # line number counter
		
	# Change to fastq screen suffix naming convention
	my $qc_passed_r1_filename = $sample_id . "_L001_R1_001_PE_no_hits_file.1.fastq";	

	# Open QC passed fastq file
	open my $fastq_fh, $qc_passed_r1_filename
		or die "Could not open file $qc_passed_r1_filename $!";
	
	# Count lines in file, adjust for fastq count
	$lines++ while (<$fastq_fh>);
	close $fastq_fh;
	my $read_number = $lines / 4;
	
	# Build array
	push @qc_passed_pe_reads, "$qc_passed_r1_filename\t$read_number\t";
}

##########
# Final output

# Write to stdout
my $i = 0; # counter for all arrays

print "sample_id\t$table_header_trim_log $table_header_read_number\n";

foreach my $sample (@sample_ids) {
	chomp($sample);
	print "$sample\t$trim_log_table[$i]\t$qc_passed_pe_reads[$i]\n";
	$i++;
}

# Write to file
#open(my $output_fh, '>', $qc_summary);
#print $output_fh @summary_table;
#close $output_fh;


=head1 AUTHOR
Graham Rose <graham.rose@phe.gov.uk>
=cut
