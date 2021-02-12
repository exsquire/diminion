nextflow.enable.dsl=2

process remove_barcodes{
	input:
		tuple val(ID), path(FASTQ)
		val(ADAPT_5P)
		val(ADAPT_3P)
		val(TRIM_N)
		val(MAX_N)
		val(MIN_LEN)
		
	output:
		tuple val(ID), path('*trimmed.fq')

	script:
		OPT_TRIM_N = TRIM_N ? '--trim-n' : '' 
		"""
		cutadapt -g $ADAPT_5P -a $ADAPT_3P --max-n $MAX_N --minimum-length $MIN_LEN $OPT_TRIM_N $FASTQ > ${ID}_trimmed.fq 
		"""
}

process unique_fasta {
	input:
		tuple val(ID), path(FASTQ)
	output:
		tuple val(ID), path('*.fa'), emit: unique
		path '*.txt', emit: tabbed

	script:
		"""
		usearch -fastx_uniques $FASTQ -fastaout ${ID}_unique.fa -sizeout -relabel Uniq -tabbedout ${ID}_tabbedout.txt
		"""
}

process trim_reads {
	input:
		tuple val(ID), path(FASTA)
	output:
		tuple val(ID), path('*trimmed*'), emit: trimmed

	script:
		"""
		usearch -fastx_truncate $FASTA  -trunclen $params.trunclen -label_suffix _$params.trunclen -fastaout ${ID}_trimmed${params.trunclen}.fa
		"""
}
