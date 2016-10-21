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

my $table_header = "sample_id\ttrimmed_pairs_remaining\ttrimmed_pairs_remaining_%\tforward_orphan_reads\tforward_orphan_reads_%\treverse_orphan_reads\treverse_orphan_reads_%\tdiscarded_pairs\tdiscarded_pairs_%\n";

#push @summary_table,$table_header;


open my $input_fh, '<', $trim_log_file
	or die "Could not open file $trim_log_file $!";

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
		push @trim_log_table, "$input_read_pairs\t$surviving_read_pairs\t$surviving_read_pairs_pct\t$forward_only\t$forward_only_pct\t$reverse_only\t$reverse_only_pct\t$discarded\t$discarded_pct\t";
	}
}
close $input_fh;

# Count final read pairs in QC passed fastqs
foreach my $sample_id (@sample_ids) {
	
	my $lines = 0; # line number counter
		
	# Change to fastq screen suffix naming convention
	#$sample =~ s/.fastq.gz/_PE.no_hits_file.1.fastq/;	
	#$sample =~ s/.fastq.gz/_PE.fastq/;
	# currrently set as alt suffix
	my $sample_full_name = $sample_id . "_L001_R1_001_PE.fastq";
	
	# Open QC passed fastq file
	open my $fastq_fh, $sample_full_name
		or die "Could not open file $sample_full_name $!";
	
	# Count lines in file, adjust for fastq count
	$lines++ while (<$fastq_fh>);
	close $fastq_fh;
	
	my $read_number = $lines / 4;
	
	push @qc_passed_pe_reads, "$sample_full_name\t$read_number\t";
	
}

##########
# Final output
my $i = 0;

foreach my $sample (@sample_ids) {
	chomp($sample);
	print "$sample $trim_log_table[$i] $qc_passed_pe_reads[$i]\n";
	$i++;
}


#open(my $output_fh, '>', $qc_summary);
#print $output_fh @summary_table;
#close $output_fh;


=head1 AUTHOR
Graham Rose <graham.rose@phe.gov.uk>
=cut
