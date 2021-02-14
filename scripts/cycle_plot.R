# Reads in fasta file using Short Read
sread_fasta <- function(fasta){
  require(ShortRead)
  sread(readFasta(fasta))
}

# Returns the max sequence length in fasta, unless length exceeds a 
# max value, in which case, returns max value
barwidth <- function(sread, cap = 40){
  ifelse(max(sread@ranges@width) > cap, cap, max(sread@ranges@width))
}

# Creates a matrix of counts per alphabet value
# Defaults to the bases A, C, T ,G across the number of cycles
# determined by barwidth()
pull_cycle_data <- function(sread, len, bases = c("A","C","T","G")){
  # Subset sread obj by alphabet and number of cycles
  alphabetByCycle(sread)[bases,seq(len)]
}

# Process the output of pull_cycle_data for barplotting
# prop flag reports proportion of bases per cycle
gen_cycle_plot <- function(cyc_df, prop = FALSE){
  proplab = ifelse(prop, "(%)", "")
  as_tibble(t(cyc_df)) %>%
    array_tree(margin = 1) %>%
    map(~ if(prop){ .x/sum(.x) * 100}else{.x}) %>%
    bind_rows() %>%
    rownames_to_column("pos") %>%
    pivot_longer(!pos) %>%
    rename(base = name) %>%
    ggplot(aes(x = as.numeric(pos), y = value)) +
    geom_col(aes(fill = base)) +
    scale_x_continuous(breaks = seq(len)) +
    scale_fill_manual(values = c("firebrick2", 
                                 "springgreen2", 
                                 "steelblue2", 
                                 "goldenrod2")) +
    labs(y = paste0("Cycle Composition ", proplab), x = "Cycle") +
    theme_bw()
}

make_cycle_plot <- function(fasta, 
                            bases = c("A","C","T","G"),
                            prop = FALSE){
  gen_cycle_plot(pull_cycle_data(sread = sread_fasta(fasta), 
                                 len = barwidth(sread_fasta(fasta)), 
                                 bases = bases), 
                 prop = prop)
}
