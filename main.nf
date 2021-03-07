nextflow.enable.dsl=2
// Main nextflow script for the diminion pipeline

include { remove_barcodes; 
		  unique_fasta; trim_reads } from './modules/process_reads.nf'
include { subtractive_alignment as remove_rDNA;
		  subtractive_alignment as remove_tRNA;
		  subtractive_alignment as remove_repeats; 
		  align_to_targets as align_to_transcripts;
		  align_to_targets as align_to_genome } from './modules/align_reads.nf'

log.info print_header()

// Input channel formed from all the fastqs in the input directory parameter
input = Channel.fromPath("${params.input_dir}/*{.fastq,.fq}*")
	.map { tuple "${it.getSimpleName()}", it }

// Channels for rDNA, tRNA, and repeats fastas
// form sub channel via concatenation
rDNA_ch = Channel.fromPath(params.rDNA_fasta)
	.map{ tuple "${it.getSimpleName()}", it } 
tRNA_ch = Channel.fromPath(params.tRNA_fasta)
	.map{ tuple "${it.getSimpleName()}", it } 
repeats_ch = Channel.fromPath(params.repeats_fasta)
	.map{ tuple "${it.getSimpleName()}", it } 
transcripts_ch = Channel.fromPath(params.transcripts_fasta)
	.map{ tuple "${it.getSimpleName()}", it }
genome_ch = Channel.fromPath(params.genome_fasta)
	.map{ tuple "${it.getSimpleName()}", it }

workflow{
	remove_barcodes(input,
					params.ca_adapt5p,
					params.ca_adapt3p,
					params.ca_trim_n,
					params.ca_max_n,
					params.ca_min_len)
	unique_fasta(remove_barcodes.out)
	sub_ch = unique_fasta.out.unique.combine(rDNA_ch)
	remove_rDNA(sub_ch,
				params.bwt_all,
				params.bwt_mismatch)
	remove_tRNA(remove_rDNA.out.unmapped.combine(tRNA_ch),
				params.bwt_all, 
				params.bwt_mismatch)
	remove_repeats(remove_tRNA.out.unmapped.combine(repeats_ch),
				   params.bwt_all,
				   params.bwt_mismatch)
	trim_reads(remove_repeats.out.unmapped)
	align_to_transcripts(trim_reads.out.trimmed.combine(transcripts_ch),
					 params.bwt_all,
					 params.bwt_mismatch)
	align_to_genome(trim_reads.out.trimmed.combine(genome_ch),
					params.bwt_all,
					params.bwt_mismatch)
	align_to_genome.out.to_plot.view()
}

def print_header() {
    // Log colors ANSI codes
    c_yellow = "\033[0;33m"
	c_dim = "\033[2m"
	c_reset = "\033[0m"
    return """     -${c_dim}------------------------------------------${c_reset}-
	||     _  _         _       _             ||
	||   _| |[_] _ _ _ [_] _ _ [_] ___  _ _   ||
	||  / . || || ' ' || || ' || |/ . \\| ' |  ||
	||  \\___||_||_|_|_||_||_|_||_|\\___/|_|_|  ||
	--${c_dim}------------------------------------------${c_reset}
    """.stripIndent()
}

def summary = [:]
summary['Run name']     = workflow.runName
summary['Input fastq dir'] = params.input_dir
summary['Output dir']   = params.output_dir
summary['Launch dir']   = workflow.launchDir
summary['Working dir']  = workflow.workDir
summary['Script dir']   = workflow.projectDir
summary['User']         = workflow.userName
summary['CUTADAPT ARGS']= '=========='
summary["5' adapter"]   = params.ca_adapt5p
summary["3' adapter"]   = params.ca_adapt3p
summary["Trim N"]   = params.ca_trim_n ?: false
summary["Max N"] = params.ca_max_n 
summary["Min length"] = params.ca_min_len
summary['BOWTIE ARGS'] = '=========='
summary['All alignments'] = params.bwt_all ?: false
summary['Allowed mismatches'] = params.bwt_mismatch
summary['USEARCH ARGS'] = '=========='
summary['Truncation length'] = params.trunclen
summary['DIMINION ARGS'] = '=========='
summary['Cycle plot type']        = params.cyc_prop ? 'Total Counts' : 'Proportion'
log.info summary.collect { k,v -> if(k =~ 'ARGS'){
									"\n$v:$k:$v"} 
									else{ "${k.padRight(18)}: $v"}}.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"
