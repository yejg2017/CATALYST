% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotDiffHeatmap.R
\name{plotDiffHeatmap}
\alias{plotDiffHeatmap}
\title{Plot differential heatmap}
\usage{
plotDiffHeatmap(
  x,
  y,
  top_n = 20,
  all = FALSE,
  order = TRUE,
  th = 0.1,
  hm1 = TRUE,
  fun = c("median", "mean"),
  scale = TRUE,
  normalize = TRUE,
  row_anno = TRUE,
  col_anno = TRUE,
  hm1_pal = rev(brewer.pal(11, "RdBu")),
  hm2_pal = rev(brewer.pal(11, "PuOr"))
)
}
\arguments{
\item{x}{a \code{\link[SingleCellExperiment]{SingleCellExperiment}}.}

\item{y}{a \code{SummarizedExperiment} containing differential testing
results as returned by one of \code{\link[diffcyt]{testDA_edgeR}}, 
\code{\link[diffcyt]{testDA_voom}}, \code{\link[diffcyt]{testDA_GLMM}}, 
\code{\link[diffcyt]{testDS_limma}}, or \code{\link[diffcyt]{testDS_LMM}}.
Alternatively, a list as returned by \code{\link[diffcyt]{diffcyt}}.}

\item{top_n}{numeric. Number of top clusters (if \code{type = "DA"}) or
cluster-marker combinations (if \code{type = "DS"}) to display.}

\item{all}{logical. Specifies whether all clusters or cluster-marker combinations 
should be displayed. If \code{TRUE}, \code{top_n} will be ignored.}

\item{order}{logical. Should results be ordered by significance?}

\item{th}{numeric. Threshold on adjusted p-values below which clusters (DA) 
or cluster-marker combinations (DS) should be considered significant.}

\item{hm1}{logical. Specifies whether the left-hand side heatmap should be plotted.}

\item{fun}{character string specifying the function to use 
as summary statistic for aggregation of expression values.}

\item{scale}{logical specifying whether expression values should be scaled
between 0 and 1 using lower (1\%) and upper (99\%) quantiles as boundaries.}

\item{normalize}{logical. Specifies whether Z-score normalized values should be plotted 
in the right-hand side heatmap. If \code{y} contains DA analysis results, 
relative population abundances will be arcsine-square-root scaled 
prior to normalization.}

\item{row_anno}{logical. Should a row annotation indicating whether cluster (DA) 
or cluster-marker combinations (DS) are significant, 
as well as adjusted p-values be included?}

\item{col_anno}{logical. Should column annotations for each factor 
in \code{metadata(x)} be included?}

\item{hm1_pal, hm2_pal}{character vector of 
colors to interpolate for each heatmap(s).}
}
\value{
a \code{\link{HeatmapList-class}} object.
}
\description{
Heatmaps summarizing differental abundance 
& differential state testing results.
}
\details{
For DA tests, \code{plotDiffHeatmap} will display
\itemize{
  \item{median (arcsinh-transformed) 
    cell-type marker expressions (across all samples)}
  \item{cluster abundances by samples}
  \item{row annotations indicating if detected clusteres
    are significant (i.e. adj. p-value >= \code{th})}
}
For DS tests, \code{plotDiffHeatmap} will display
  \itemize{
  \item{median (arcsinh-transformed) 
    cell-type marker expressions (across all samples)}
  \item{median (arcsinh-transformed) 
    cell-state marker expressions by sample}
  \item{row annotations indicating if detected cluster-marker combinations
    are significant (i.e. adj. p-value >= \code{th})}
}
}
\examples{
# construct SCE & run clustering
data(PBMC_fs, PBMC_panel, PBMC_md)
sce <- prepData(PBMC_fs, PBMC_panel, PBMC_md)
sce <- cluster(sce)

## differential analysis
library(diffcyt)

# create design & constrast matrix
design <- createDesignMatrix(PBMC_md, cols_design=3:4)
contrast <- createContrast(c(0, 1, 0, 0, 0))

# test for
# - differential abundance (DA) of clusters
# - differential states (DS) within clusters

da <- diffcyt(sce, design = design, contrast = contrast, 
    analysis_type = "DA", method_DA = "diffcyt-DA-edgeR",
    clustering_to_use = "meta20")
    
ds <- diffcyt(sce, design = design, contrast = contrast, 
    analysis_type = "DS", method_DS = "diffcyt-DS-limma",
    clustering_to_use = "meta20")
    
# display test results for
# - top DA clusters
# - top DS cluster-marker combintations
plotDiffHeatmap(sce, da)
plotDiffHeatmap(sce, ds)

# visualize results for subset of clusters
sub <- filterSCE(sce, k = "meta20", cluster_id \%in\% seq_len(5))
plotDiffHeatmap(sub, da)

}
\author{
Lukas M Weber & 
Helena L Crowell \email{helena.crowell@uzh.ch}
}
