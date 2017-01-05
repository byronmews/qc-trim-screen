// Generic Illumina QC PE reads
//
// Workflow: FastQC > Trimmomatic > FastQC > Fastq Screen
// Usage: bpipe run -r qc_trim_screen.groovy *
// Author: Graham Rose
//



TRIMMOMATIC="java -jar /usr/local/src/trimmomatic-0.32.jar"
SCREEN="/usr/local/etc/fastq_screen_v0.4.4_config/fastq_screen_human.conf"

// Pre trim check 
fastqc_pre = {
	
	doc "Run fastQC on raw reads"
	
	// Fastqc output dir
	output.dir = "fastqc_pre_qc"	

	exec "mkdir -p $output.dir" 
	exec "fastqc -k 8 --nogroup $input1.gz -t 12 -o $output.dir"
	exec "fastqc -k 8 --nogroup $input2.gz -t 12 -o $output.dir"
	
	forward input1.gz, input2.gz

}

// Trim using trimmomatic PE mode. Adapter/vector database hard set.
trimmomatic_PE = {

		doc "Trim reads using Trimmomatic using PE mode"
	
		input_extension = ".fastq.gz"
			
		products = [
            	("$input1".replaceAll(/.*\//,"") - input_extension + '_PE.fastq'),
           	("$input1".replaceAll(/.*\//,"") - input_extension + '_SE.fastq'),
            	("$input2".replaceAll(/.*\//,"") - input_extension + '_PE.fastq'),
            	("$input2".replaceAll(/.*\//,"") - input_extension + '_SE.fastq')
		]

		// Transform fastqc.gz to fastq
		produce(products) {
		exec """
			$TRIMMOMATIC PE -phred33 
			$input1.gz $input2.gz
			${output1} ${output2}
			${output3} ${output4}
			ILLUMINACLIP:/srv/data0/dbs/trimmomatic_db/contaminant_list.fasta:2:30:10
			LEADING:20 TRAILING:20 MINLEN:40
			2>>trimmomatic.err
		""" 
		}
}

// Post trim check
fastqc_post = {

        doc "Run fastQC on trimmed reads"

        // Fastqc output dir
        output.dir = "fastqc_post_qc"
	
	exec "mkdir -p $output.dir"
	exec "fastqc -k 8 --nogroup $input1.fastq  -t 12 -o $output.dir"
        exec "fastqc -k 8 --nogroup $input3.fastq -t 12 -o $output.dir"
}

// Host screen defaults to human/univec screen config file, see readme
screen = {

	// Map all reads against human and univec db. Variable refers to fastq_screen config file.
	doc "Run FastQ Screen, using Human and UniVec db"
	
	exec """
		fastq_screen --conf $SCREEN 
		--aligner bowtie2 --threads 12 
		--nohits 
		--paired 
		$input1.fastq $input3.fastq
	"""
}

// Calls pe perl parser to  write all output to formatted table
qc_summary = {

	// Results parser
	doc "QC stats summary file"
	
	exec """
		perl qc_results_parser_pe.pl
	"""


}



// Single sample, no parallelism
//Bpipe.run {
//	fastqc_pre + trimmomatic_PE + fastqc_post + screen
//}

// Multiple samples where file names begin with sample name separated by regex
// such as: 1-2_S2_L001_R1_001.fastq.gz)
Bpipe.run {
	"%_S*_L001_R*_*.fastq.gz" * [ fastqc_pre + trimmomatic_PE +  fastqc_post +  screen ] + qc_summary
} 







