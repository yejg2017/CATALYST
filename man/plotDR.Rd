% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotDR.R
\name{plotDR}
\alias{plotDR}
\title{Plot reduced dimensions}
\usage{
plotDR(
  x,
  dr = NULL,
  color_by = "condition",
  facet_by = NULL,
  k_pal = CATALYST:::.cluster_cols,
  scale = TRUE
)
}
\arguments{
\item{x}{a \code{\link[SingleCellExperiment]{SingleCellExperiment}}.}

\item{dr}{character string specifying which dimension reduction to use. 
Should be one of \code{reducedDimNames(x)}; default to the 1st available.}

\item{color_by}{character string corresponding to a
\code{colData(x)} column. Specifies the color coding.}

\item{facet_by}{character string specifying a
non-numeric cell metadata column to facet by; 
valid values are \code{names(colData(x))}.}

\item{k_pal}{character string specifying the cluster color palette; 
ignored when \code{color_by} is not one of \code{names(cluster_codes(x))}. 
If less than \code{nlevels(cluster_ids(x, k))} are supplied, 
colors will be interpolated via \code{\link[grDevices]{colorRampPalette}}.}

\item{scale}{logical specifying whether expression should be scaled
between 0 and 1 using lower (1\%) and upper (99\%) expression quantiles;
ignored if \code{!all(color_by \%in\% rownames(x))}.}
}
\value{
a \code{ggplot} object.
}
\description{
Dimension reduction plot colored 
by expression, cluster, sample or group ID.
}
\examples{
# construct SCE & run clustering
data(PBMC_fs, PBMC_panel, PBMC_md)
sce <- prepData(PBMC_fs, PBMC_panel, PBMC_md)

# run clustering & dimension reduction
sce <- cluster(sce)
sce <- runDR(sce, dr = "UMAP", cells = 100)

# color by scaled expression for 
# set of markers, split by condition
plotDR(sce, 
  scale = TRUE, 
  facet_by = "condition",
  color_by = sample(rownames(sce), 4))

# color by 8 metaclusters using custom 
# cluster color palette, split by sample
p <- plotDR(sce, 
  color_by = "meta8", 
  facet_by = "sample_id", 
  k_pal = c("lightgrey", "cornflowerblue", "navy")) 
p$facet$params$ncol <- 4; p

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
