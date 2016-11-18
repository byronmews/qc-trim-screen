#!/usr/bin/perl

###############################################################################
# Log files parser for qc_trim_screen_pe.groovy pipeline.		      #
#									      #
# Expects the trimmomatic stderr as a single file named: trimmomatic.err      #
#									      #
###############################################################################


use warnings;
use strict;

# In/Out file names
my $trim_log_file = "trimmomatic.err";
my $qc_summary = "qc_summary_stats.tsv";

# Arrays for all summary data
my @sample_ids; # sync output by sample name
my @trim_log_table; # trimmomatic log file
my @qc_passed_pe_read_table; # qc passed pe read number
my @fastq_screen_table; # fastq_screen result file per fastq


# Open trimmomatic stdout log file
open my $input_fh, '<', $trim_log_file
	or die "Could not open file $trim_log_file $!";

# Table header for @trim_log_table
my $table_header_trim_log = "input_read_pairs\ttrimmed_pairs_remaining\ttrimmed_pairs_remaining_%\tforward_orphan_reads\tforward_orphan_reads_%\treverse_orphan_reads\treverse_orphan_reads_%\tdiscarded_pairs\tdiscarded_pairs_%";

foreach my $line (<$input_fh>) {

	chomp $line;

	if($line =~ /^TrimmomaticPE: Started with arguments:\s+\-phred33\s+(\w+.*_S\d+_L001_R1_001.fastq.gz)\s+\w+/) {
		
		# Expecting this line in the log file:
		# TrimmomaticPE: Started with arguments: -phred33 1-2_S2_L001_R1_001.fastq.gz 1-2_S2_L001_R2_001.fastq.gz ...

		my $sample_id = $1;
		
		# Lose the fastq suffix name
		$sample_id =~ s/_L001_R1_001.fastq.gz//;
		push @sample_ids, $sample_id;
	}
	elsif($line =~ /^Input Read Pairs:/)  {
	
		# Expecting this line in log file:
		# Input Read Pairs: 30958 Both Surviving: 30703 (99.18%) Forward Only Surviving: 106 (0.34%) Reverse Only Surviving: 61 (0.20%) Dropped: 88 (0.28%)
		
		# Remove all % and bracket chars as these can be interpreted by external programs
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


# Table header for @fastq_sreen_table
my $table_header_fastq_screen = "sample_id\tinput_pe_reads\thuman_mapped_pe_reads\thuman_mapped_pe_reads_pct\tunivec_mapped_pe_reads\tunivec_mapped_pe_reads_pct";

# Open FastQ Screen report file, cycling through all files using @sample_id
foreach my $sample_id (@sample_ids) {

        my $lines = 0; # line number counter

        # Change to fastq screen suffix naming convention
	my $fastq_screen_file = $sample_id . "_L001_R1_001_PE_screen.txt";
        
	# Open sample specific fastq_screen report file
	open $input_fh, '<', $fastq_screen_file
		or die "Could not open file $fastq_screen_file $!";

	foreach my $line (<$input_fh>) {	

		chomp $line;

		# Ignore all lines except hard set screened library name
		if($line =~ /^Human/) {
			
			# Split line by space character
			my @split = split /\s/,$line;

			# Metrics slected for summary table
			my $db_name = $split[0];
			my $pe_reads_processed = $split[1];
			my $unmapped_pe_reads = $split [2];
			my $mapped_pe_reads = ($pe_reads_processed - $unmapped_pe_reads);
			my $mapped_pe_reads_pct = (($mapped_pe_reads / $pe_reads_processed) * 100);

			push @fastq_screen_table, "$sample_id\t$pe_reads_processed\t$mapped_pe_reads\t$mapped_pe_reads_pct";
		}
		if($line =~ /^UniVec/) {

                        # Split line by space character
                        my @split = split /\s/,$line;

			# Metrics slected for summary table
                        my $pe_reads_processed = $split[1];
			my $unmapped_pe_reads = $split [2];
                        my $mapped_pe_reads = ($pe_reads_processed - $unmapped_pe_reads);
                        my $mapped_pe_reads_pct = (($mapped_pe_reads / $pe_reads_processed) * 100);
			
			push @fastq_screen_table, "$mapped_pe_reads\t$mapped_pe_reads_pct";
		}
	}
	close $input_fh;
}


# Table header for @qc_passed_pe_reads
my $table_header_read_number = "qc_passed_pe_reads\tqc_passed_r1_pe_filename";

# Count final PE reads in QC passed fastqs
foreach my $sample_id (@sample_ids) {

        my $lines = 0; # line number counter

        # Change to fastq screen output fastq suffix naming convention
        my $qc_passed_r1_file = $sample_id . "_L001_R1_001_PE_no_hits_file.1.fastq";

        # Open QC passed fastq file
        open my $fastq_fh, $qc_passed_r1_file
                or die "Could not open file $qc_passed_r1_file $!";

        # Count all lines in file
        $lines++ while (<$fastq_fh>);
        close $fastq_fh;
        my $read_number = $lines/4; # adjust for fastq format

        push @qc_passed_pe_read_table, "$read_number\t$qc_passed_r1_file";
}


####
# Format summary table output and write to file

my $i = 0; # counter for all except fastq_screen
my $j = 0; # counter for fastq_screen

# Write to file
open(my $output_fh, '>', $qc_summary);

print $output_fh "sample_id\t$table_header_trim_log\t$table_header_fastq_screen\t$table_header_read_number"; # header row

# Cycle using sample id to sync rows, single row per fastq file
foreach my $sample (@sample_ids) {

	chomp($sample);

	print $output_fh "\n$sample\t";
	print $output_fh "$trim_log_table[$i]\t";
	print $output_fh "$fastq_screen_table[$j]\t$fastq_screen_table[$j+1]\t"; # output all dbs screened on single row
	print $output_fh "$qc_passed_pe_read_table[$i]";

	$i++;
	$j = $j+2; # two dbs screened per fastq
}
close $output_fh;

print "Summary file generated: $qc_summary\n";


=head1 AUTHOR
Graham Rose <graham.rose@phe.gov.uk>
=cut



