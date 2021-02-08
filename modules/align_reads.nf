nextflow.enable.dsl=2

process build_subtractive_index{
	input:
		path(SUBDIR)
	output:
		path '*'
	script:
		"""
		bowtie-build $SUBDIR subtract	
		"""
}


process remove_unwanted_reads{
	input:
		tuple val(ID), path(FASTA)
		path(INDEX)		
		val(ALL)
		val(MM)
	output:
		path '*'
	script:
		OPT_ALL = ALL ? '--all':''
		"""
		bowtie -f -v${MM} $OPT_ALL --un ${ID}_cleaned.fa subtract $FASTA
		"""
}

