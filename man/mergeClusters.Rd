% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mergeClusters.R
\name{mergeClusters}
\alias{mergeClusters}
\title{Manual cluster merging}
\usage{
mergeClusters(x, k, table, id, overwrite = FALSE)
}
\arguments{
\item{x}{a \code{\link[SingleCellExperiment]{SingleCellExperiment}}.}

\item{k}{character string specifying the clustering to merge;
valid values are \code{names(cluster_codes(x))}.}

\item{table}{merging table with 2 columns containing the cluster IDs to
merge in the 1st, and the cluster IDs to newly assign in the 2nd column.}

\item{id}{character string used as a label for the merging.}

\item{overwrite}{logical specifying whether to force overwriting
should a clustering with name \code{id} already exist.}
}
\value{
a \code{\link[SingleCellExperiment]{SingleCellExperiment}} 
with newly added cluster codes stored in \code{cluster_codes(.)$id}.
}
\description{
\code{mergeClusters} provides a simple wrapper 
to store a manual merging inside the input \code{SingleCellExperiment}.
}
\details{
in the following code snippets, 
\code{x} is a \code{SingleCellExperiment} object.
\itemize{
\item{merging codes are accesible through \code{cluster_codes(x)$id}}
\item{all functions that ask for specification of a clustering 
  (e.g. \code{\link{plotAbundances}}, \code{\link{plotClusterHeatmap}})
  take the merging ID as a valid input argument.}}
}
\examples{
# construct SCE & run clustering
data(PBMC_fs, PBMC_panel, PBMC_md, merging_table)
sce <- prepData(PBMC_fs, PBMC_panel, PBMC_md)
sce <- cluster(sce)

# merge clusters
sce <- mergeClusters(sce, 
  k = "meta20", 
  id = "merging",
  table = merging_table)

# tabulate manual merging
table(cluster_ids(sce, k = "merging"))

# visualize median type-marker expression
plotClusterHeatmap(sce, k = "merging")

}
\references{
Nowicka M, Krieg C, Crowell HL, Weber LM et al. 
CyTOF workflow: Differential discovery in 
high-throughput high-dimensional cytometry datasets.
\emph{F1000Research} 2017, 6:748 (doi: 10.12688/f1000research.11622.1)
}
\author{
Helena L Crowell \email{helena.crowell@uzh.ch}
}
