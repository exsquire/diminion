# diminion
The diminion project packages the small RNA bioinformatics workflow found in Zhang et al. (2020, BMC Genomics) into a distributable pipeline that uses contemporary techniques of bioinformatic pipeline development. The workflow removes the barcodes from raw paired-end fastqs, subtractively aligns the unique reads to tRNA, rDNA, and repetetive element libraries, trims the output down and aligns it to target annotated transcript and whole genome fastas. The user has access to all intermediates produced by the pipeline, but the main outputs are nucleotide distribution plots of the trimmed fastq and an index stats table produced from the whole genome alignment bam. 

## Pipeline 
Nextflow is a domain specific language (DSL) belonging to the "workflow manager" class. Workflow managers can be used to build powerful, distributable, and user-friendly bioinformatics pipelines. The code itself is written in "Groovy", which is a superset of Java. 

### Dependencies
Nextflow is designed to be lightweight and trivial to use. All a user needs is a POSIX-compatible system like Unix or Mac OS X, Bash 3.2+, and Java 8+. 
For the specific and mercifully short installaltion instructions - see the Nextflow docs here: https://www.nextflow.io/docs/latest/getstarted.html

### Structure
