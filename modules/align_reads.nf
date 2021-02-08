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

process build_target_indices{
	input:
		tuple val(ID), path(TARGET)
	output:
		tuple val(ID), path('*')
	script:
		"""
		bowtie-build $TARGET $ID
		"""
}

process remove_unwanted_reads{
	input:
		tuple val(ID), path(FASTA)
		path(INDEX)		
		val(ALL)
		val(MM)
	output:
		tuple val(ID), path('*_cleaned.fa')
	script:
		OPT_ALL = ALL ? '--all':''
		"""
		bowtie -f -v${MM} $OPT_ALL --un ${ID}_cleaned.fa subtract $FASTA
		"""
}

process align_to_targets{
	input:
		tuple val(REF), path(INDEX)
		tuple val(ID), path(FASTA)
		val(ALL)
		val(MM)
	output:
		path '*'
	script:
		OPT_ALL = ALL ? '--all':'' 
		"""
		bowtie -f -v${MM} $OPT_ALL $REF $FASTA > "${ID}_${REF}.out"
		"""
}
