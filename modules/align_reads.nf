nextflow.preview.dsl=2
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
	container "exsquire/diminion:1.0.0"
	input:
		tuple val(TARGID), path(TARGFASTA), val(SUBID), path(SUBFASTA)
		val(ALL)
		val(MM)
	output:
		path('*')
		tuple val(DESIG), path('*unmapped.fa'), emit: unmapped 
		tuple val(DESIG), path('*.stdout'), emit: stdout
		tuple val(DESIG), path('*.stderr'), emit: stderr
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

process align_to_targets{
	outdir = set_outdir(params.output_dir, "target_alignments")
	publishDir "${outdir}/stdout", pattern: "*.stdout", mode: 'link'
	publishDir "${outdir}/stderr", pattern: "*.stderr", mode: 'link'
	publishDir "${outdir}/bam", pattern: "*.bam", mode: 'link'
	publishDir "${outdir}/unmapped", pattern: "*unmapped.fa",mode: 'link'
	container "exsquire/diminion:1.0.0"
	input:
		tuple val(ID), path(FASTA), val(REFID), path(REF_FASTA)
		val(ALL)
		val(MM)
	output:
		path '*'
		tuple val(ID), path(FASTA), path('*stdout'), emit: to_plot
	script:
		OPT_ALL = ALL ? '--all':'' 
		"""
		bowtie-build $REF_FASTA $REFID
		bowtie -f -v${MM} $OPT_ALL --un ${ID}_${REFID}_unmapped.fa -x $REFID $FASTA \
														2> "${ID}_${REFID}.stderr" \
														1> "${ID}_${REFID}.stdout"
		bowtie -f --sam -v${MM} $OPT_ALL -x $REFID $FASTA > "${ID}_${REFID}.sam"
		samtools view -bS "${ID}_${REFID}.sam" > "${ID}_${REFID}.bam"	
		
		"""
}

