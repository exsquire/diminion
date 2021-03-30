# diminion
The diminion project packages the small RNA bioinformatics workflow found in Zhang et al. (2020, BMC Genomics) into a distributable pipeline that uses contemporary techniques of bioinformatic pipeline development. The workflow removes the barcodes from raw single-end fastqs, subtractively aligns the unique reads to tRNA, rDNA, and repetetive element libraries, trims the output down and aligns it to target annotated transcript and whole genome fastas. The user has access to all intermediates produced by the pipeline, but the main outputs are nucleotide distribution plots of the trimmed fastq and an index stats table produced from the whole genome alignment bam. 

## Significance

Diminion's workflow can be used to extract biological significance from single-end FASTQ files that hold sequencing data from prepared libraries. The test case included in the repository is a snippet from an analysis of small RNA from the parasitic protozoan E. histolytica - a cause of dysentary and liver abscesses in humans from underdeveloped countries. Parasitic small RNA can participate in the targeted knockdown of host gene expression, so understanding their origin and structure could lead to valuable insights into human pathogens.

When small RNAs are extracted from biological samples and sequenced, diminion can extract the unique sequences, filter them for elements unnecessary to the analysis, trim them to a size of an expected subpopulation (e.g. 27 nucleotides), and then align them to annotated reference genomes and transcripts to find the associated contig/coding element.

![Alt text](assets/diminion_workflow.png?raw=true "Diminion Workflow Graph")

One of the main pipeline outputs is cycle plot, which can take in a fasta file (here, the uniformly trimmed processed fasta for genome alignment) and plot the base distribution per cycle. Such plots allow us to characterize certain populations of sRNAs by visualizing a nucleotide bias at specific positions. 

![Alt text](assets/cycle_plot.png?raw=true "Example Cycle Plot")

## Pipeline 
Nextflow is a domain specific language (DSL) belonging to the "workflow manager" class. Workflow managers can be used to build powerful, distributable, and user-friendly bioinformatics pipelines. The code itself is written in "Groovy", which is a superset of Java. 

### Dependencies
Nextflow is designed to be lightweight and trivial to use. All a user needs is a POSIX-compatible system like Unix or Mac OS X, Bash 3.2+, and Java 8+. 
For the specific and mercifully short installaltion instructions - see the Nextflow docs here: https://www.nextflow.io/docs/latest/getstarted.html

The preferred (but not only) way of running Diminion is by asking Nextflow to run its processes inside Docker containers - this, of course, requires Docker. Installing Docker and building docker images on your system requires administrative privileges. If you are on an HPC cluster, you might have to contact your system administrator to install docker and add your user ID to the 'docker' group. 

This error is commonly caused when a user has not been added to the 'docker' group
```
docker: Got permission denied while trying to connect to the Docker daemon socket
```

Add yourself and refresh groups with the following code block. 
```
sudo groupadd docker                                                           
sudo gpasswd -a $USER docker                                                           
newgrp docker    
```

### Quick Start
+ git clone the repository
+ cd diminion
+ nextflow run main.nf

### Input/Output 
A test case is included in the repository within the assets/test/dev folder. It includes 2 single-end FASTQ files representing 2 samples, the reference FASTA files for removing unwanted reads, and the reference FASTA files to which processed reads are aligned. 

![Alt text](assets/IO_0.png?raw=true "Input Example")

When successfully run, the pipeline produces a 'results' folder in the working directory, giving users access to the intermediate files generated throughout the pipeline. Each file is designated a sample id taken from the input files and relevant other relevant file names. For example, if sample 'A' is aligned to reference 'Z', the output might be 'A_Z'.

![Alt text](assets/IO_1.png?raw=true "Results Structure 1")
![Alt text](assets/IO_2.png?raw=true "Results Structure 2")

### Structure and Function
Diminion follows a typical nextflow file structure. A nextflow "pipeline" is a single directory with a bunch of stuff in it, this one is called "diminion". Within diminion, you will find some subdirectories and some files. I'll explain what they are and why we need them here.

#### Main Pipeline
In Nextflow, data are held in "Channels" that can be manipulated in a number of ways to get data into the right order/shape/combination/format/etc. Like water in a river, Channel data flows into "Processes" as an "Input Channel" where they are *processed* by 3rd party software (e.g. bowtie, samtools, etc) or custom scripts and passed out of the Process as an "Output Channel". This process repeats until the end of the pipeline.  

These are the 3 main components of a standard nextflow pipeline written in the DSL2 syntax. DSL2 is the latest flavor of Nextflow that allows Processes to be coded in modular format, like how program functions are written to be generalizable and packaged for reuse in libraries. The "modules" subdirectory contains nextflow scripts that group Processes by function within the pipeline. 

* **main.nf:** Holds the main "workflow" that dictates the order of the pipeline, specifies any included modules, and anything else needed to be done when the main script is run. 
* **nextflow.config:** Defines defaults for the Nextflow pipeline and much more. Parameters from the nextflow config can be called by name from the command line. nextflow run main.nf --<named parameter> <value>, will run the pipeline with <named parameter> set to <value>, overriding the default in nextflow.config. 
* **modules/:**
  * **align_reads.nf:** 
     * *subtractive_alignment:* Takes in 2 fastas, one containing reads to be removed (subfasta) and to be filtered for subfasta reads (fasta). Builds bowtie index of subfasta, then aligns fasta to index, outputting the unmapped sequences. Output is fasta filtered for subfasta reads. 
     * *align_to_target:* Takes in 2 fastas, one to be aligned to (referncefasta) and one to align (fasta). Builds bowtie index of referencefasta, aligns fasts to index and outputs a sam file. Sam file is converted to sorted bam file, indexed, and idxstated to get counts of mapped reads. 
   * **process_reads.nf:**
     * *remove_barcodes:* Takes in fastqs and parameters for cutadapt, outputs trimmed fastqs
     * *unique_fasta:* Takes in fastqs and passes them to usearch's fastx_uniques function, which reduces a read file to uniques, gives each unique read a size annotation of how many there were, and outputs the unique reads in a specified format, in this case a fasta file. 
     * *trim_reads:* Takes in a fasta and uses usearch's fastx_truncate to trim the reads to a specified length

#### Results Processing
Nextflow usually relies on scripts from other programming languages to handle the processing of pipeline intermediates into result outputs like tables and plots. Diminion uses 
* **scripts:** contains the helper Rscripts for output generation
  * *cycle_plot.R:* Generates nucleotide distribution plots from fasta files using ShortRead
  * *process_alignment.R:* Generates strand count tables from bowtie alignment stdout text files
  * *diminion.R:* Sources and runs the previous scripts

We can mount folders into the docker containers called by Nextflow. In diminion, we mount the scripts folder into the path '/scripts', so the current versions in the scripts directory will be used in the pipeline. 

#### Reproducibility
One of the biggest bug-a-boos of bioinformatic workflows is the inability to confidently reproduce a result without meticulous attention to the exact software version/workstation configuration. 

Docker to the rescue! 

Docker lets us ensure that all software, scripts, and workstation settings are the same for each run of the pipeline, no matter who runs it, by building a "virtual computer" for the program to run inside. The specifications of this virtual computer is called an "image", and when activated, it can spin up a "container" for our code to run in, as many as we want, all identical. We build the image using a set of instructions called a "dockerfile", specifying the type of computer we want and what we want on it, and then we push it up to a docker registry, like dockerhub (like github, but for docker images).

Diminion has 2 subdirectories dedicated to reproducibility
* **dockfiles:** contains instructures for building the docker images used by the pipeline - an amazing primer: https://www.nextflow.io/blog/2016/docker-and-nextflow.html
  * *dimidock-dockerfile:* builds off the continuumio/miniconda2 base image - easily downloads and installs software from the bioconda repository 
  * *diminion_r-dockerfile:* builds off the bioconductor/bioconductor_docker:devel - useful for installing R libraries only available through bioconductor
* **bin:** contains ready-to-use software binaries used in the pipeline, in this case usearch is the only 3rd party software we needed a binary of. 
  * *usearch:* a popular tool for 16S analysis that comes with a suite of convenience functions for fasta/fastq processing 

We can instruct Nextflow to pull down a docker image from a registry and run specific parts of the pipeline within containers of our choosing. 

