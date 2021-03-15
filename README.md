# diminion
The diminion project packages the small RNA bioinformatics workflow found in Zhang et al. (2020, BMC Genomics) into a distributable pipeline that uses contemporary techniques of bioinformatic pipeline development. The workflow removes the barcodes from raw paired-end fastqs, subtractively aligns the unique reads to tRNA, rDNA, and repetetive element libraries, trims the output down and aligns it to target annotated transcript and whole genome fastas. The user has access to all intermediates produced by the pipeline, but the main outputs are nucleotide distribution plots of the trimmed fastq and an index stats table produced from the whole genome alignment bam. 

## Pipeline 
Nextflow is a domain specific language (DSL) belonging to the "workflow manager" class. Workflow managers can be used to build powerful, distributable, and user-friendly bioinformatics pipelines. The code itself is written in "Groovy", which is a superset of Java. 

### Dependencies
Nextflow is designed to be lightweight and trivial to use. All a user needs is a POSIX-compatible system like Unix or Mac OS X, Bash 3.2+, and Java 8+. 
For the specific and mercifully short installaltion instructions - see the Nextflow docs here: https://www.nextflow.io/docs/latest/getstarted.html

### Quick Start
+ git clone the repository
+ cd diminion
+ nextflow run main.nf

### Structure and Function
Diminion follows a typical nextflow file structure. A nextflow "pipeline" is a single directory with a bunch of stuff in it, this one is called "diminion". Within diminion, you will find some subdirectories and some files. I'll explain what they are and why we need them here.

*Reproducibility:*
One of the biggest bug-a-boos of bioinformatic workflows is the inability to confidently reproduce a result without meticulous attention to the exact software version/workstation configuration/Lovecraftian incantation/phase of the moon from the original run. Docker to the rescue. Docker let's us ensure that all software, scripts, and workstation settings are the same for each run of the pipeline, no matter who runs it, by building a "virtual computer" for the program to run inside. The specifications of this virtual computer is called an "image", and when activated, it can spin up a "container" for our code to run in, as many as we want, all identical. We build the image using a set of instructions called a "dockerfile", specifying the type of computer we want and what we want on it. Creating this "safe space" where all the tools we need exist and settings and version numbers are locked in is often the first step to formalizing a pipeline. 

Diminion has 2 subdirectories for reproducibility
* **dockfiles:** contains instructures for building the docker images used by the pipeline
  * *dimidock-dockerfile:* builds off the continuumio/miniconda2 base image - easily downloads and installs software from the bioconda repository 
  * *diminion_r-dockerfile:* builds off the bioconductor/bioconductor_docker:devel - useful for installing R libraries only available through bioconductor
* **bin:** contains ready-to-use software binaries used in the pipeline, in this case usearch is the only 3rd party software we needed a binary of. 
  * *usearch:* a popular tool for 16S analysis that comes with a suite of convenience functions for fasta/fastq processing 

*Results Processing:*
Nextflow usually relies on scripts from other programming languages to handle the processing of pipeline intermediates into result outputs like tables and plots. Diminion uses 
* **scripts:** contains the helper Rscripts for output generation
  * *cycle_plot.R:* Generates nucleotide distribution plots from fasta files using ShortRead
  * *process_alignment.R:* Generates strand count tables from bowtie alignment stdout text files
