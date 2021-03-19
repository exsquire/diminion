nextflow.preview.dsl=2
def set_outdir(dir, sub) {dir ? "${dir}/${sub}" : "${sub}"}

process remove_barcodes{
	outdir = set_outdir(params.output_dir, "no_barcodes")
	publishDir "${outdir}"
	container "exsquire/diminion:1.0.0"
	input:
		tuple val(ID), path(FASTQ)
		val(ADAPT_5P)
		val(ADAPT_3P)
		val(TRIM_N)
		val(MAX_N)
		val(MIN_LEN)
		
	output:
		tuple val(ID), path('*nobarcodes.fq')

	script:
		OPT_TRIM_N = TRIM_N ? '--trim-n' : '' 
		"""
		cutadapt -g $ADAPT_5P -a $ADAPT_3P --max-n $MAX_N --minimum-length $MIN_LEN $OPT_TRIM_N $FASTQ > ${ID}_nobarcodes.fq 
		"""
}

process unique_fasta {
	outdir = set_outdir(params.output_dir, "unique_reads")
	publishDir "${outdir}", pattern: "*unique.fa"
	publishDir "${outdir}", pattern: "*tabbedout.txt"
	container "exsquire/diminion:1.0.0"
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
	outdir = set_outdir(params.output_dir, "trimmed_reads")
	publishDir "${outdir}", pattern: "*trimmed*"
	container "exsquire/diminion:1.0.0"
	input:
		tuple val(ID), path(FASTA)
	output:
		tuple val(ID), path('*trimmed*'), emit: trimmed

	script:
		"""
		usearch -fastx_truncate $FASTA  -trunclen $params.trunclen -label_suffix _$params.trunclen -fastaout ${ID}_trimmed${params.trunclen}.fa
		"""
}

process make_plots {
	outdir = set_outdir(params.output_dir, "plots")
	publishDir "${outdir}/${ID}"
	container "exsquire/diminion_r:1.0.0"
	containerOptions "--volume ${workflow.projectDir}/scripts:/scripts"
	input:
		tuple val(ID), path(FASTA), path(STDOUT)
		val(CYC)
	output:
		path('*')
	script:
		OPT_CYC = CYC ? '--proportion':''
		"""
		Rscript /scripts/diminion.R -f $FASTA -a $STDOUT $OPT_CYC
		""" 
}
