nextflow.preview.dsl=2

if(params.dev){
    log.info "Running in Develop Mode"
}

input = Channel.fromPath("${params.input_dir}/*.fastq").map {
    id = "${it.getSimpleName()}"
    tuple id, it
}

index_base = Channel.fromPath("${params.index_basedir}/*.fa").map {
    id = "${it.getSimpleName()}"
    tuple id, it  
}

process remove_barcodes {
    input:
        tuple val(ID), path(FASTQ)

    output:
        tuple val(ID), path('*trimmed.fq')

    script:
    """
    cutadapt -g ^CGATC -a gacgt --trim-n --max-n 5 --minimum-length 15 $FASTQ > ${ID}_trimmed.fq
    """
}

process fastq_to_fasta {
    input:
        tuple val(ID), path(FASTQ)

    output:
        path '*'

    script:
        """
        sed -n '1~4s/^@/>/p;2~4p' $FASTQ > ${ID}.fa
        """
}
