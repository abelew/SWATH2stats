load_mart <- function(species, ensembl.path, mart, verbose = FALSE){
  dataset.mart <- species
  ensembl.mart <- useMart(mart, dataset=dataset.mart, host=ensembl.path)
  
  list.datasets <- listDatasets(ensembl.mart)
  list.datasets[which(list.datasets == dataset.mart), "version"]
  list.marts <- listMarts(ensembl.mart, host=ensembl.path)
  list.marts[which(list.marts == mart), "version"]
  
  if(verbose){
    sink(file= paste(Sys.Date(), species, "Ensembl_Version.txt", sep="_"))
    writeLines(c(paste("Species:", species), 
                 paste("Host:", ensembl.path), 
                 paste("Date:", Sys.Date()),
                 paste("Dataset:", list.datasets[which(list.datasets == dataset.mart), "version"]), 
                 paste("Version:", list.marts[which(list.marts == mart), "version"])))
    sink() 
    sink(type="message")
  }
  return(ensembl.mart)
}

add_genesymbol <- function(data_table, gene.ID.table, column.name = "Protein", 
                           ID1 = "uniprotswissprot", ID2 = "hgnc_symbol"){
  # remove column if it already exists
  if(ID2 %in% colnames(data_table)){
    data_table[,ID2] <- NULL
  }
  gene.ID.table[,ID2] <- as.character(gene.ID.table[,ID2])
  data_table <- merge(data_table, gene.ID.table, 
                      by.x=column.name, by.y=ID1, all.x=TRUE)
  
  #annotate the shared peptides
  .ids <- which(is.na(data_table[,ID2]))
  .ids <- intersect(.ids, grep("/", data_table[,column.name]))

  for(i in .ids){
    .Protein <- as.character(data_table[i,column.name])
    .Protein.single <- unlist(strsplit(.Protein, "/"))
    .Protein.new <- .Protein
    for(k in .Protein.single[.Protein.single %in% gene.ID.table[,ID1]]){
      .Protein.new <- gsub(k, gene.ID.table[gene.ID.table[,ID1] == k,ID2], 
                           .Protein.new)
    }
    data_table[data_table[,column.name] == .Protein, ID2] <- .Protein.new
  }

  #bring gene_symbol column in front
  data_table <- data_table[,c(ID2, colnames(data_table)[seq(length(colnames(data_table))-1)])]
  return(data_table)
}

convert_protein_ids <- function(data_table, column.name = "Protein", 
                             species = "hsapiens_gene_ensembl", 
                             host = "www.ensembl.org", 
                             mart = "ENSEMBL_MART_ENSEMBL",
                             ID1 = "uniprotswissprot", 
                             ID2 = "hgnc_symbol", verbose = FALSE){
  
  if(class(data_table) == "data.frame"){
    type <- "data.frame"
  } else {
    type <- "file"
    data_table <- data.frame(fread(file, sep="\t", header=TRUE))
  }
  
  if(!(column.name %in% colnames(data_table))){
    stop("Column name does not exist in data. ", 
         paste(colnames(data_table), collapse = ", "))
  }
  
  # obtain Identifiers to map 
  IDs <- unique(as.character(data_table[,column.name]))
  
  # separate non-proteotypic peptides
  IDs.np <- IDs[grep("/", IDs)]
  IDs.np <- gsub("^[[:digit:]]+/", "", IDs.np)
  IDs.np <- unlist(strsplit(IDs.np, "/"))
  
  # remove contaminant peptides
  IDs <- IDs[grep("^CONT_", IDs, invert = TRUE)]
  IDs.np <- IDs.np[grep("^CONT_", IDs.np, invert = TRUE)]
  
  IDs <- unique(c(IDs, IDs.np))
  length(IDs)
  
  organism.mart <- load_mart(species, host, mart)
  gene.ID.table <- getBM(attributes = c(ID2, ID1), filters= c(ID1), 
                           values = IDs, mart=organism.mart)
    
  n.ids <- table(gene.ID.table[,ID1])
  n.ids.multiple <- names(n.ids[n.ids > 1])
  for(i in n.ids.multiple){
    new.id <- paste(gene.ID.table[gene.ID.table[,ID1] == i, ID2], 
                    collapse = "/")
    gene.ID.table <- gene.ID.table[gene.ID.table[,ID1] != i,]
    new.id.df <- data.frame(uniprotswissprot = i, hgnc_symbol = new.id)
    colnames(new.id.df) <- c(ID1, ID2)
    gene.ID.table <- rbind(gene.ID.table, new.id.df)
  }
  
  data_table_output <- add_genesymbol(data_table, 
                                      gene.ID.table, 
                                      column.name, ID1, ID2)

  if(type == "file"){
    file.name <- gsub("\\..*", "", file)
    file.ext <- gsub(".*\\.", "", file)
    write.table(data_table_output, paste(file.name, "_annotated.", 
                                         file.ext, sep=""),
                quote=FALSE, row.names=FALSE, sep="\t")
  }

  if(type == "data.frame"){
    data_table_output
  }
}