// Generic Illumina QC for SE reads
//
// Workflow: FastQC > Trimmomatic > FastQC > Fastq Screen
// Usage: bpipe run -r qc_trim_screen_se.groovy *
// Author: Graham Rose
//



TRIMMOMATIC="java -jar /usr/local/src/trimmomatic-0.32.jar"
SCREEN="/usr/local/etc/fastq_screen_v0.4.4_config/fastq_screen_human.conf"

fastqc_pre = {
	
	doc "Run fastQC on raw reads"
	
	// Fastqc output dir
	output.dir = "fastqc_pre_qc"	

	exec "mkdir -p $output.dir" 
	exec "fastqc -k 8 --nogroup $input.gz -t 12 -o $output.dir"
	
	forward input.gz

}

trimmomatic_PE = {

		doc "Trim reads using Trimmomatic using SE mode"
	
		// Transform fastqc.gz to fastq
		input_extension = ".fastq.gz"
			
		products = [
            	("$input".replaceAll(/.*\//,"") - input_extension + '_SE.fastq'),
		]

		// Transform fastqc.gz to fastq
		produce(products) {
		exec """
			$TRIMMOMATIC SE -phred33 
			$input.gz
			${output1}
			ILLUMINACLIP:/srv/data0/dbs/trimmomatic_db/contaminant_list.fasta:2:30:10
			LEADING:20 TRAILING:20 MINLEN:40
			2>>trimmomatic.err
		""" 
		}
}

fastqc_post = {

        doc "Run fastQC on trimmed reads"

        // Fastqc output dir
        output.dir = "fastqc_post_qc"
	
	exec "mkdir -p $output.dir"
	exec "fastqc -k 8 --nogroup $input.fastq  -t 12 -o $output.dir"
}

// Host screen defaults to human/univec screen config file, see readme
screen = {

	// Map all reads against human and univec db
	doc "Run FastQ Screen, using Human and UniVec db"
	
	exec """
		fastq_screen --conf $SCREEN 
		--aligner bowtie2 --threads 12 
		--nohits 
		$input.fastq
	"""
}

qc_summary = {

	// Results summarised with se parser
	doc "QC stats summary file"
	
	exec """
		perl qc_results_parser_se.pl
	"""


}



// Single sample, no parallelism
//Bpipe.run {
//	fastqc_pre + trimmomatic_PE + fastqc_post + screen
//}

// Multiple samples where file names begin with sample name separated by regex
// such as: 1-2_S2_L001_R1_001.fastq.gz)
Bpipe.run {
	"%.fastq.gz" * [ fastqc_pre + trimmomatic_PE + fastqc_post + screen ] + qc_summary
} 







