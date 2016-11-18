#!/usr/bin/perl

###############################################################################
# Log files parser for qc_trim_screen_se.groovy pipeline.		      #
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
my @qc_passed_read_table; # qc passed read number
my @fastq_screen_table; # fastq_screen result file per fastq


# Open trimmomatic stdout log file
open my $input_fh, '<', $trim_log_file
	or die "Could not open file $trim_log_file $!";

# Table header for @trim_log_table
my $table_header_trim_log = "input_reads\ttrimmed_reads_remaining\ttrimmed_reads_remaining_%\tdiscarded_reads\tdiscarded_reads_%";

foreach my $line (<$input_fh>) {

	chomp $line;

	if($line =~ /^TrimmomaticSE: Started with arguments:\s+\-phred33\s+(\w+.*.fastq.gz)\s+\w+/) {
		
		# Expecting this line in the log file:
		# TrimmomaticSE: Started with arguments: -phred33 1-2_S2_L001_R1_001.fastq.gz ...

		my $sample_id = $1;
		
		# Lose the fastq suffix name
		$sample_id =~ s/.fastq.gz//;
		push @sample_ids, $sample_id;
	}
	elsif($line =~ /^Input Reads:/)  {
	
		# Expecting this line in log file:
		# Input Reads: 30958 Surviving: 30703 (99.18%) Dropped: 88 (0.28%)
		
		# Remove all % and bracket chars as these can be interpreted by external programs
		$line =~ s/(\%|\(|\))//g;

		# Split line by space character
		my @split = split /\s/,$line;

		# Metrics selected for summary table
		my $input_reads = $split[2];
		my $surviving_reads = $split[4];
		my $surviving_reads_pct = $split[5];
		my $discarded = $split[7];
		my $discarded_pct = $split[8];
		
		# Add to table array
		push @trim_log_table, "$input_reads\t$surviving_reads\t$surviving_reads_pct\t$discarded\t$discarded_pct";
	}
}
close $input_fh;


# Table header for @fastq_sreen_table
my $table_header_fastq_screen = "sample_id\tinput_reads\thuman_mapped_reads\thuman_mapped_reads_pct\tunivec_mapped_reads\tunivec_mapped_reads_pct";

# Open FastQ Screen report file, cycling through all files using @sample_id
foreach my $sample_id (@sample_ids) {

        my $lines = 0; # line number counter

        # Change to fastq screen suffix naming convention
	my $fastq_screen_file = $sample_id . "_SE_screen.txt";
        
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
			my $se_reads_processed = $split[1];
			my $unmapped_se_reads = $split [2];
			my $mapped_se_reads = ($se_reads_processed - $unmapped_se_reads);
			my $mapped_se_reads_pct = (($mapped_se_reads / $se_reads_processed) * 100);

			push @fastq_screen_table, "$sample_id\t$se_reads_processed\t$mapped_se_reads\t$mapped_se_reads_pct";
		}
		if($line =~ /^UniVec/) {

                        # Split line by space character
                        my @split = split /\s/,$line;

			# Metrics slected for summary table
                        my $se_reads_processed = $split[1];
			my $unmapped_se_reads = $split [2];
                        my $mapped_se_reads = ($se_reads_processed - $unmapped_se_reads);
                        my $mapped_se_reads_pct = (($mapped_se_reads / $se_reads_processed) * 100);
			
			push @fastq_screen_table, "$mapped_se_reads\t$mapped_se_reads_pct";
		}
	}
	close $input_fh;
}


# Table header for @qc_passed_reads
my $table_header_read_number = "qc_passed_reads\tqc_passed_filename";

# Count final reads in QC passed fastqs
foreach my $sample_id (@sample_ids) {

        my $lines = 0; # line number counter

        # Change to fastq screen output fastq suffix naming convention
        my $qc_passed_file = $sample_id . "_SE_no_hits.fastq";

        # Open QC passed fastq file
        open my $fastq_fh, $qc_passed_file
                or die "Could not open file $qc_passed_file $!";

        # Count all lines in file
        $lines++ while (<$fastq_fh>);
        close $fastq_fh;
        my $read_number = $lines/4; # adjust for fastq format

        push @qc_passed_read_table, "$read_number\t$qc_passed_file";
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
	print $output_fh "$qc_passed_read_table[$i]";

	$i++;
	$j = $j+2; # two dbs screened per fastq
}
close $output_fh;

print "Summary file generated: $qc_summary\n";


=head1 AUTHOR
Graham Rose <graham.rose@phe.gov.uk>
=cut



