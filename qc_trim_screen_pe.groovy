// FastQC > Trimmomatic > FastQC > Fastq Screen



TRIMMOMATIC="/usr/local/src/trimmomatic-0.32.jar"
SCREEN="/usr/local/etc/fastq_screen_v0.4.4_config/fastq_screen_human.conf"


fastqc_pre = {
	
	// Fastqc output dir
	output.dir = "fastqc_pre_qc"

	// How the file name is getting transformed
	transform(".fastq.gz") to ("_fastqc.zip") {
	
		exec "mkdir -p $output.dir; fastqc -k 8 --nogroup $input1.gz -t 12 -o $output.dir"
		exec "fastqc -k 8 --nogroup $input2.fastq.gz -t 12 -o $output.dir"
	}
}



// Single sample, no parallelism
run { fastqc_pre }

// Multiple samples where file names begin with sample
// name and are separated by underscore from the rest of the 
// file name
//run { "%_*.fastq.gz" * [ fastqc_pre ] }
