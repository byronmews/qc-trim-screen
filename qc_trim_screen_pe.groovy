// Generic Illumina QC
//
// Workflow: FastQC > Trimmomatic > FastQC > Fastq Screen
// Defaults to human/univec screen config

TRIMMOMATIC="java -jar /usr/local/src/trimmomatic-0.32.jar"
SCREEN="/usr/local/etc/fastq_screen_v0.4.4_config/fastq_screen_human.conf"


fastqc_pre = {
	
	doc "Run fastQC on raw reads"
	
	// Fastqc output dir
	output.dir = "fastqc_pre_qc"
	
	filter("fastqc") {
		// How the file name is getting transformed
		transform(".fastq.gz") to ("_fastqc.zip") {
			exec "mkdir -p $output.dir; fastqc -k 8 --nogroup $input1.gz -t 12 -o $output.dir"
			exec "fastqc -k 8 --nogroup $input2.gz -t 12 -o $output.dir"
		}
	}
}

trimmomatic_PE = {

		doc "Trim reads using Trimmomatic using PE mode"
	
		filter("trimmomatic_PE") {
		// Transforming the fastqc gz output filename to an unzippped fastq
		transform(".fastq.gz") to (".fastq") {	
		exec """
			$TRIMMOMATIC PE -phred33 
			$input1.gz $input2.gz
			$output1.fastq ${output1.prefix}.R1_001_SE.fastq
			$output2.fastq ${output2.prefix}.R2_001_PE.fastq					
			ILLUMINACLIP:/srv/data0/dbs/trimmomatic_db/contaminant_list.fasta:2:30:10
			LEADING:20 TRAILING:20 MINLEN:40
		""" 
		}
	}
}

trimmomatic_SE = {

                doc "Trim reads using Trimmomatic using SE mode"

                filter("trimmomatic_SE") {
                // Transforming the fastqc gz output filename to an unzippped fastq
                transform(".fastq.gz") to (".fastq") {
                exec """
                        $TRIMMOMATIC SE -phred33
                        $input1.gz
                        $output1.fastq ${output1.prefix}.R1_001_SE.fastq
                        ILLUMINACLIP:/srv/data0/dbs/trimmomatic_db/contaminant_list.fasta:2:30:10
                        LEADING:20 TRAILING:20 MINLEN:40
                """
                }
        }
}







// Single sample, no parallelism
run { fastqc_pre + trimmomatic_PE }

// Multiple samples where file names begin with sample
// name and are separated by underscore from the rest of the 
// file name
//Bpipe.run { 
//	"%_*.fastq.gz" * [ fastqc_pre, trimmomatic_PE ]
//}
