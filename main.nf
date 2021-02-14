nextflow.enable.dsl=2
// Main nextflow script for the diminion pipeline

include { remove_barcodes; unique_fasta; trim_reads } from './modules/process_reads.nf'
include { build_subtractive_index; remove_unwanted_reads; build_target_indices; align_to_targets } from './modules/align_reads.nf'

log.info print_header()

input = Channel.fromPath("${params.input_dir}/*{.fastq,.fq}*").map {
    id = "${it.getSimpleName()}"
    tuple id, it
}

targets = Channel.fromPath("${params.target_dir}/*{.fasta,.fa}*").map { 
	id = "${it.getSimpleName()}"
	tuple id, it
}


// Build a concatenated fasta for subtractive alignment
subtract = Channel.fromPath("${params.subtract_dir}/*{.fasta,.fa}*")
	.collectFile(name: "subtract.fa")


workflow{
	remove_barcodes(input,
					params.ca_adapt5p,
					params.ca_adapt3p,
					params.ca_trim_n,
					params.ca_max_n,
					params.ca_min_len)
	unique_fasta(remove_barcodes.out)
	build_subtractive_index(subtract)
	build_target_indices(targets)
	remove_unwanted_reads(unique_fasta.out.unique,
						  build_subtractive_index.out,
						  params.bwt_all,
						  params.bwt_mismatch)
	target_ch = remove_unwanted_reads.out.combine(build_target_indices.out)
	align_to_targets(target_ch,
					 params.bwt_all,
					 params.bwt_mismatch)
	trim_reads(align_to_targets.out.unmapped)
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
summary['Subtract dir'] = params.subtract_dir
summary['Target dir']   = params.target_dir
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
