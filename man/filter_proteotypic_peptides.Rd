% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/filter_proteotypic_peptides.R
\name{filter_proteotypic_peptides}
\alias{filter_proteotypic_peptides}
\title{Filter for proteins that are supported by proteotypic peptides.}
\usage{
filter_proteotypic_peptides(data, rm.decoy = TRUE)
}
\arguments{
\item{data}{A data frame containing SWATH data.}

\item{rm.decoy}{Option to remove the decoys during filtering.}

\item{column}{Which column to query for filtering?}
}
\value{
Returns a data frame with only the data supported by proteotypic
  peptides.
}
\description{
Peptides can match to several proteins. With this function proteotypic
peptides, peptides that are only contained in one protein are
selected. Additionally the number of proteins are counted and printed.
}
\examples{
 data("OpenSWATH_data", package="SWATH2stats")
 data("Study_design", package="SWATH2stats")
 data <- sample_annotation(OpenSWATH_data, Study_design)
 data.filtered.decoy <- filter_mscore(data, 0.01)
 data.all <- filter_proteotypic_peptides(data.filtered.decoy)
}
\author{
Peter Blattmann
}
