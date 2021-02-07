nextflow.enable.dsl=2
include { remove_barcodes } from './modules/process_reads.nf'


if(params.dev){
    log.info "Running in Develop Mode"
}

input = Channel.fromPath("${params.input_dir}/*{.fastq,.fq}*").map {
    id = "${it.getSimpleName()}"
    tuple id, it
}

input.view()

workflow{
	remove_barcodes(input,
					params.ca_adapt5p,
					params.ca_adapt3p,
					params.ca_trim_n,
					params.ca_max_n,
					params.ca_min_len)	
}


