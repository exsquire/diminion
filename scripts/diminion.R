suppressPackageStartupMessages({
	library(getopt)
	library(data.table)
	library(ShortRead)
	library(dplyr)
	library(stringr)
	library(tidyr)
	library(purrr)
	library(tibble)
	library(ggplot2)
})
source("/scripts/cycle_plot.R")
source("/scripts/process_alignment.R")

spec = matrix(c(
  'fasta',     'f', 1, "character", "Path to input FASTA. <REQUIRED>",
  'alignment', 'a', 1, "character", "Path to Bowtie alignment output text file. <REQUIRED>",
  'bases',     'b', 2, "character", "Bases to subset cycle matrix. (Default: ACTG)",
  'proportion','p', 0, "logical"  , "Visualize Cycle Composition as proportion of bases per cycle (Default: FALSE)",
  'help',      'h', 0, "logical"  , "Print a help menu"
  ), byrow=TRUE, ncol=5)

args = getopt(spec)

if ( !is.null(args$help) | is.null(args$fasta) | is.null(args$alignment)) {
  cat(getopt(spec, usage=TRUE))
  cat("Minimal Usage:\nRscript diminion.R -f path/to/fasta -a path/to/alignment\n")
  q(status=1)
}


# Defaults
if(is.null(args$bases)){ args$bases = "ACTG" }
if(is.null(args$prop)) { args$prop  = FALSE  }
alph_str <- str_split(args$bases, "") %>% unlist

print(args)
print(alph_str)

# Make bases by cycle plot
ggsave("cycle_plot.png", make_cycle_plot(args$fasta))

# Make sense/antisense dataframe
out <- count_strands(fread(args$alignment, check.names = FALSE))
write.csv(out, "strand_count.csv", quote = FALSE, row.names = FALSE)



