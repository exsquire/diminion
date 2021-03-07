# Pull in alignment file and relabel headers
# Group by gene
# summarize out number of sense and antisense rows from each group
count_strands <- function(outfile){
  as_tibble(outfile) %>%
    select(seqname = V1, strand = V2, geneID = V3, pos = V4, seq = V5) %>%
    group_by(geneID) %>%
    summarise(sense = length(strand[strand == "+"]),
              antisense = length(strand[strand == "-"]))
}

