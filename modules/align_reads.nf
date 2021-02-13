nextflow.enable.dsl=2
def set_outdir(dir, sub) {dir ? "${dir}/${sub}" : "${sub}"} 

process build_subtractive_index{
	outdir = set_outdir(params.output_dir, "subtractive_index")
	publishDir "${outdir}", mode: 'link'
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
	outdir = set_outdir(params.output_dir, "target_index")
	publishDir "${outdir}", mode: 'link' 
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
	outdir = set_outdir(params.output_dir, "cleaned_reads") 
	publishDir "${outdir}", pattern: "*cleaned*",mode: 'link' 
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
	outdir = set_outdir(params.output_dir, "target_alignments")
	publishDir "${outdir}/bowtie_stdout", pattern: "*.out",mode: 'link'
	publishDir "${outdir}/unmapped", pattern: "*unmapped.fa",mode: 'link'
	input:
		tuple val(ID), path(FASTA), val(REF), path(INDEX)
		val(ALL)
		val(MM)
	output:
		path '*'
		tuple val(ID), path('*unmapped.fa'), emit: unmapped
	script:
		OPT_ALL = ALL ? '--all':'' 
		"""
		bowtie -f -v${MM} $OPT_ALL --un ${ID}_${REF}_unmapped.fa $REF $FASTA > "${ID}_${REF}.out"
		"""
}

