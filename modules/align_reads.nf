nextflow.enable.dsl=2
def set_outdir(dir, sub) {dir ? "${dir}/${sub}" : "${sub}"} 


// Performs subtractive alignment on a tuple with the form
// tuple val(subID), path(subFASTA), val(targetID), path(targetFASTA)
// Builds a bowtie index with the subFASTA and performs subtractive alignment
// on the targetFASTA by outputting the unmapped output fasta
// Emits the unmapped fasta "${targetID}_${subID}_unmapped.fa"
// and bowtie's stdout and stderr from the alignment
process subtractive_alignment{
	outdir = set_outdir(params.output_dir, "subtractive_alignment") 
	publishDir "${outdir}/unmapped", pattern: "*unmapped.fa", mode: 'link' 
    publishDir "${outdir}/stdout", pattern: "*stdout", mode: 'link' 
    publishDir "${outdir}/stderr", pattern: "*stderr", mode: 'link'
	publishDir "${outdir}/index", pattern: "*ebwt", mode: 'link'  

	input:
		tuple val(TARGID), path(TARGFASTA), val(SUBID), path(SUBFASTA)
		val(ALL)
		val(MM)
	output:
		path('*')
		tuple val(DESIG), path('*unmapped.fa'), emit: unmapped 
	script:
		DESIG = TARGID+"_sub"+SUBID
		OPT_ALL = ALL ? '--all':''
		"""
		bowtie-build $SUBFASTA $SUBID
		bowtie -f -v${MM} $OPT_ALL --un ${DESIG}_unmapped.fa -x $SUBID $TARGFASTA \
															2> ${DESIG}.stderr \
															1> ${DESIG}.stdout 
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
		tuple val(ID), path('*_cleaned.fa'), emit: cleaned
		tuple val(ID), path('*subtract.out')
	script:
		OPT_ALL = ALL ? '--all':''
		"""
		bowtie -f -v${MM} $OPT_ALL --un ${ID}_cleaned.fa subtract $FASTA > ${ID}_subtract.out
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

