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
	publishDir "${outdir}/${TARGID}/unmapped", pattern: "*unmapped.fa", mode: 'link' 
    publishDir "${outdir}/${TARGID}/stdout", pattern: "*stdout", mode: 'link' 
    publishDir "${outdir}/${TARGID}/stderr", pattern: "*stderr", mode: 'link'
	publishDir "${outdir}/${TARGID}/index", pattern: "*ebwt", mode: 'link'  
	container "exsquire/diminion:1.0.0"
	input:
		tuple val(TARGID), path(TARGFASTA), val(SUBID), path(SUBFASTA)
		val(ALL)
		val(MM)
	output:
		path('*')
		tuple val(TARGID), path('*unmapped.fa'), emit: unmapped 
		tuple val(TARGID), path('*.stdout'), emit: stdout
		tuple val(TARGID), path('*.stderr'), emit: stderr
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
	publishDir "${outdir}/${ID}/stdout", pattern: "*.stdout", mode: 'link'
	publishDir "${outdir}/${ID}/stderr", pattern: "*.stderr", mode: 'link'
	publishDir "${outdir}/${ID}/bam", pattern: "*.bam*", mode: 'link'
	publishDir "${outdir}/${ID}", pattern: "*.report",mode: 'link'
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
		samtools view -bS ${ID}_${REFID}.sam | samtools sort -o ${ID}_${REFID}.sorted.bam -
		samtools index ${ID}_${REFID}.sorted.bam	
		samtools idxstats ${ID}_${REFID}.sorted.bam > ${ID}_${REFID}.idx.stats
		awk '{ if (\$4 != 0 || \$3 != 0) { print } }' ${ID}_${REFID}.idx.stats | sort -r -nk3 - | awk 'BEGIN{print "REF\tlen\tmapped\tunmapped"}1' > ${ID}_${REFID}.stat.report
		"""
}

