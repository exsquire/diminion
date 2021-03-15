# diminion
The diminion project packages the small RNA bioinformatics workflow found in Zhang et al. (2020, BMC Genomics) into a distributable pipeline that uses contemporary techniques of bioinformatic pipeline development. The workflow removes the barcodes from raw single-end fastqs, subtractively aligns the unique reads to tRNA, rDNA, and repetetive element libraries, trims the output down and aligns it to target annotated transcript and whole genome fastas. The user has access to all intermediates produced by the pipeline, but the main outputs are nucleotide distribution plots of the trimmed fastq and an index stats table produced from the whole genome alignment bam. 

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

#### Reproducibility
One of the biggest bug-a-boos of bioinformatic workflows is the inability to confidently reproduce a result without meticulous attention to the exact software version/workstation configuration. 

Docker to the rescue! 

Docker lets us ensure that all software, scripts, and workstation settings are the same for each run of the pipeline, no matter who runs it, by building a "virtual computer" for the program to run inside. The specifications of this virtual computer is called an "image", and when activated, it can spin up a "container" for our code to run in, as many as we want, all identical. We build the image using a set of instructions called a "dockerfile", specifying the type of computer we want and what we want on it, and then we push it up to a docker registry, like dockerhub (like github, but for docker images).

Diminion has 2 subdirectories dedicated to reproducibility
* **dockfiles:** contains instructures for building the docker images used by the pipeline
  * *dimidock-dockerfile:* builds off the continuumio/miniconda2 base image - easily downloads and installs software from the bioconda repository 
  * *diminion_r-dockerfile:* builds off the bioconductor/bioconductor_docker:devel - useful for installing R libraries only available through bioconductor
* **bin:** contains ready-to-use software binaries used in the pipeline, in this case usearch is the only 3rd party software we needed a binary of. 
  * *usearch:* a popular tool for 16S analysis that comes with a suite of convenience functions for fasta/fastq processing 

We can instruct Nextflow to pull down a docker image from a registry and run specific parts of the pipeline within containers of our choosing. 

#### Results Processing
Nextflow usually relies on scripts from other programming languages to handle the processing of pipeline intermediates into result outputs like tables and plots. Diminion uses 
* **scripts:** contains the helper Rscripts for output generation
  * *cycle_plot.R:* Generates nucleotide distribution plots from fasta files using ShortRead
  * *process_alignment.R:* Generates strand count tables from bowtie alignment stdout text files
  * *diminion.R:* Sources and runs the previous scripts

We can mount folders into the docker containers called by Nextflow. In diminion, we mount the scripts folder into the path '/scripts', so the current versions in the scripts directory will be used in the pipeline. 

#### Main Pipeline
In Nextflow, data are held in "Channels" that can be manipulated in a number of ways to get data into the right order/shape/combination/format/etc. Like water in a river, Channel data flows into "Processes" as an "Input Channel" where they are *processed* by 3rd party software (e.g. bowtie, samtools, etc) or custom scripts and passed out of the Process as an "Output Channel". This process repeats until the end of the pipeline.  

These are the 3 main components of a standard nextflow pipeline written in the DSL2 syntax. DSL2 is the latest flavor of Nextflow that allows Processes to be coded in modular format, like how program functions are written to be generalizable and packaged for reuse in libraries. The "modules" subdirectory contains nextflow scripts that group Processes by function within the pipeline. 

* **main.nf:** Holds the main "workflow" that dictates the order of the pipeline, specifies any included modules, and anything else needed to be done when the main script is run. 
* **nextflow.config:** Defines defaults for the Nextflow pipeline and much more. 
* **modules/:**
 * **align_reads.nf:** 
  * *subtractive_alignment:* Takes in 2 fastas, one containing reads to be removed (subfasta) and to be filtered for subfasta reads (fasta). Builds bowtie index of subfasta, then aligns fasta to index, outputting the unmapped sequences. Output is fasta filtered for subfasta reads. 
  * *align_to_target:* Takes in 2 fastas, one to be aligned to (referncefasta) and one to align (fasta). Builds bowtie index of referencefasta, aligns fasts to index and outputs a sam file. Sam file is converted to sorted bam file, indexed, and idxstated to get counts of mapped reads. 
 * **process_reads.nf:**
  * *remove_barcodes:* Takes in fastqs and parameters for cutadapt, outputs trimmed fastqs
  * *unique_fasta:* Takes in fastqs and passes them to usearch's fastx_uniques function, which reduces a read file to uniques, gives each unique read a size annotation of how many there were, and outputs the unique reads in a specified format, in this case a fasta file. 
  * *trim_reads:* Takes in a fasta and uses usearch's fastx_truncate to trim the reads to a specified length
