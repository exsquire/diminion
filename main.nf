nextflow.enable.dsl=2
include { remove_barcodes; unique_fasta } from './modules/process_reads.nf'
include { build_subtractive_index; remove_unwanted_reads; build_target_indices; align_to_targets } from './modules/align_reads.nf'

if(params.dev){
    log.info "Running in Develop Mode"
}

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
	build_target_indices.out.view()
	align_to_targets(build_target_indices.out,
					 remove_unwanted_reads.out,
					 params.bwt_all,
					 params.bwt_mismatch)	
}



