# ==============================================================================
# colors for 30 ConensusClusterPlus metaclusters
# ------------------------------------------------------------------------------
.cluster_cols <- c(
    "#DC050C", "#FB8072", "#1965B0", "#7BAFDE", "#882E72",
    "#B17BA6", "#FF7F00", "#FDB462", "#E7298A", "#E78AC3",
    "#33A02C", "#B2DF8A", "#55A1B1", "#8DD3C7", "#A6761D",
    "#E6AB02", "#7570B3", "#BEAED4", "#666666", "#999999",
    "#aa8282", "#d4b7b7", "#8600bf", "#ba5ce3", "#808000",
    "#aeae5c", "#1e90ff", "#00bfff", "#56ff0d", "#ffff00")

# ==============================================================================
# helper to get & check features for plotting; should be either
# - a character string specifiying a subset of features to include
# - one of "type", "state", "none" if 'rowData(x)$marker_class' exists
# ------------------------------------------------------------------------------
.get_features <- function(x, fs) {
    if (is.null(fs)) {
        fs <- rownames(x)
    } else {
        stopifnot(is.character(fs))
        if (length(fs) > 1) {
            stopifnot(fs %in% rownames(x))
        } else {
            fs <- match.arg(fs, c("type", "state", "none")) 
            stopifnot(!is.null(marker_classes(x)))
            fs <- rownames(x)[marker_classes(x) == fs]
            if (length(fs) == 0)
                stop("No features matched the specified marker class.")
        }
    }
    return(fs)
}

.get_shapes <- function(x, shape_by) {
    if (is.null(shape_by))
        return(NULL)
    # default shapes
    shapes <- c(16, 17, 15, 3, 7, 8) 
    n <- nlevels(x[[shape_by]])
    if (n > 18) {
        message(
            "At most 17 shapes are currently supported but ",
            n, " are required; setting 'shape_by' to NULL.")
        return(NULL)
    } else if (n > 6) {
        more_shapes <- setdiff(c(seq_len(16)-1, 18), shapes)
        shapes <- c(shapes, more_shapes[seq_len(n-length(shapes))])
    } else shapes <- shapes[seq_len(n)]
    return(shapes)
}

# ==============================================================================
# scale expression to values b/w 0 and 1 using 
# low (1%) and high (99%) quantiles as boundaries
# ------------------------------------------------------------------------------
#' @importFrom matrixStats rowQuantiles
#' @importFrom methods is
.scale_exprs <- function(x, margin = 1) {
    if (!is(x, "matrix")) x <- as.matrix(x)
    qs <- c(rowQuantiles, colQuantiles)[[margin]]
    qs <- qs(x, probs = c(.01, .99))
    qs <- matrix(qs, ncol = 2)
    x <- switch(margin,
        "1" = (x - qs[, 1]) / (qs[, 2] - qs[, 1]),
        "2" = t((t(x) - qs[, 1]) / (qs[, 2] - qs[, 1])))
    x[x < 0 | is.na(x)] <- 0
    x[x > 1] <- 1
    return(x)
}

# ==============================================================================
# calculate non-redundancy score (NRS) for ea. feature & sample
# ------------------------------------------------------------------------------
#' @importFrom Matrix rowSums
#' @importFrom stats prcomp
.nrs <- function(u, n=3) {
    if (ncol(u) < n) return(NULL)
    pc <- prcomp(t(u), center=TRUE, scale.=FALSE)
    rowSums(abs(pc$rotation[, seq_len(n)]) 
        *outer(rep(1, nrow(u)), pc$sdev[seq_len(n)]^2))
}

# ==============================================================================
# wrapper for ComplexHeatmap annotations
# ------------------------------------------------------------------------------
#' @importFrom ComplexHeatmap rowAnnotation
#' @importFrom dplyr mutate_all
#' @importFrom grDevices colorRampPalette
#' @importFrom grid gpar unit
.get_row_anno <- function(x, k, m, k_pal, m_pal) {
    kids <- levels(cluster_ids(x, k))
    nk <- length(kids)
    if (nk > length(k_pal))
        k_pal <- colorRampPalette(k_pal)(nk)
    k_pal <- k_pal[seq_len(nk)]
    names(k_pal) <- kids
    df <- data.frame(cluster_id = kids)
    col <- list(cluster_id = k_pal)
    if (!is.null(m)) {
        i <- match(kids, cluster_codes(x)[, k])
        mids <- droplevels(cluster_codes(x)[, m][i])
        nm <- nlevels(mids)
        if (nm > length(m_pal))
            m_pal <- colorRampPalette(m_pal)(nk)
        m_pal <- m_pal[seq_len(nm)]
        names(m_pal) <- levels(mids)
        df$merging_id <- mids
        col$merging_id <- m_pal
    }
    df <- mutate_all(df, function(u)
        factor(u, unique(u)))
    rowAnnotation(
        df = df, col = col,
        width = unit(4, "mm"),
        gp = gpar(col = "white"))
}

#' @importFrom ComplexHeatmap columnAnnotation rowAnnotation
#' @importFrom grid gpar
#' @importFrom methods is
#' @importFrom scales hue_pal
.anno_factors <- function(df, type = c("row", "column")) {
    # check that all data.frame columns are factors
    stopifnot(is(df, "data.frame"))
    stopifnot(all(vapply(as.list(df), is.factor, logical(1))))
    # for ea. factor, extract levels & nb. of levels
    lvls <- lapply(as.list(df), levels)
    nlvls <- vapply(lvls, length, numeric(1))
    cols <- hue_pal()(sum(nlvls))
    names(cols) <- unlist(lvls)
    cols <- split(cols, rep.int(seq_len(ncol(df)), nlvls))
    names(cols) <- names(df)
    HeatmapAnnotation(which = match.arg(type),
        df = df, col = cols, gp = gpar(col = "white"))
}

# ==============================================================================
# change in area under CDF curve
# ------------------------------------------------------------------------------
.triangle <- function(m) {
    n <- ncol(m)
    nm <- matrix(0, ncol=n, nrow=n)
    fm <- m
    nm[upper.tri(nm)] <- m[upper.tri(m)]
    fm <- t(nm) + nm
    diag(fm) <-  diag(m)
    nm <- fm
    nm[upper.tri(nm)] <- NA
    diag(nm) <- NA
    m[lower.tri(nm)]
}

.plot_delta_area <- function(mc) {
    # empirical CDF distribution
    maxK <- length(mc)
    v <- lapply(mc[seq_len(maxK)[-1]], function(x) .triangle(x$ml))
    h <- lapply(v, function(x) {
        h <- graphics::hist(x, breaks=seq(0, 1, .01), plot=FALSE)
        h$counts <- cumsum(h$counts) / sum(h$counts)
        return(h)
    })
    # calculate area under CDF curve, by histogram method &
    # calculate proportional increase relative to prior k
    areaK <- vapply(h, function(x) cumsum(x$counts * .01)[100], numeric(1))
    deltaK <- c(areaK[1], diff(areaK) / areaK[seq_len(maxK-2)])
    
    df <- data.frame(k=seq_len(maxK)[-1], y=deltaK)
    y_max <- ceiling(max(df$y)*2)/2
    ggplot(df, aes_string(x="k", y="y")) + 
        theme_classic() + geom_line(color="steelblue", lty=2) + 
        geom_point(size=2.5, color="navy") + coord_fixed(4) +
        scale_x_continuous(breaks=seq(2, 20, 2), expand=c(0,.5)) +
        scale_y_continuous(limits=c(0, y_max), expand=c(0,.125), 
            breaks=function(x) seq(x[1]+.125, x[2], .5)) +
        ylab("Relative change\nin area under CDF curve") +
        theme(plot.title=element_text(face="bold"),
            axis.text=element_text(color="black"),
            panel.grid.major=element_line(color="grey", size=.2))
}

# ==============================================================================
# get differential analysis type from differential test result 
# as returned by 'diffcyt::testDA_*()' & 'diffcyt::testDS_*()'
# ------------------------------------------------------------------------------
.get_dt_type <- function(x) {
    # check correctness of column names
    da_GLMM <- c("cluster_id", "p_val", "p_adj")
    da_edgeR <- c("cluster_id", "logFC", "logCPM", "LR", "p_val", "p_adj")
    da_voom <- c("cluster_id", "logFC", "AveExpr", "t", "p_val", "p_adj", "B")
    
    ds_LMM <- c("cluster_id", "marker_id", "p_val", "p_adj")
    ds_limma <- c("cluster_id", "marker_id", 
        "ID", "logFC", "AveExpr", "t", "p_val", "p_adj", "B")
    
    res_nms <- list(da_GLMM, da_edgeR, da_voom, ds_LMM, ds_limma)
    names(res_nms) <- c(rep("da", 3), rep("ds", 2))
    
    test <- vapply(res_nms, identical, y = names(x), logical(1))
    test <- vapply(test, isTRUE, logical(1))
    type <- names(test)[test]
    if (length(type) == 0) 
        type <- "none"
    
    # get no. of clusters
    k <- length(unique(x$cluster_id))
    m <- length(unique(x$marker_id))
    
    if (type == "da" && nrow(x) == k) {
        return("DA")
    } else if (type == "ds" && nrow(x) == (k * m)) {
        return("DS")
    } else {
        stop(deparse(substitute(x)), " does not seem to be ", 
            "a valid differential test result.\n",
            "Should be a 'SummarizedExperiment' as returned by ", 
            "'diffcyt::testDA_*()' or 'diffcyt::testDS_*()'.")
    }
}

# ==============================================================================
# wrapper for Z-score normalization
# ------------------------------------------------------------------------------
.z_normalize <- function(es, th=2.5) {
    es_n <- apply(es, 1, function(x) {
        sd <- stats::sd(x, na.rm=TRUE)
        x <- x - mean(x, na.rm=TRUE)
        if (sd != 0) x <- x / sd
        x[x >  th] <-  th
        x[x < -th] <- -th
        return(x)
    })
    return(t(es_n))
}

# ==============================================================================
# split cell indices by cell metadata factor(s)
#   - x:   a SCE with rows = cells, columns = features
#   - by:  colData columns specifying factor(s) to aggregate by
# ------------------------------------------------------------------------------
#' @importFrom data.table data.table
#' @importFrom SummarizedExperiment colData
#' @importFrom purrr map_depth
.split_cells <- function(x, by) {
    stopifnot(is.character(by), by %in% colnames(colData(x)))
    cd <- data.frame(colData(x))
    dt <- data.table(cd, i = seq_len(ncol(x)))
    dt_split <- split(dt, by = by, sorted = TRUE, flatten = FALSE)
    map_depth(dt_split, length(by), "i")
}

# ==============================================================================
# aggregation of single-cell to pseudobulk data; 
# e.g., median expression by cluster- or cluster-sample
#   - x:   a SCE with rows = cells, columns = features
#   - by:  colData columns specifying factor(s) to aggregate by
#   - fun: aggregation function specifying the
#          summary statistic, e.g., sum, mean, median
# ------------------------------------------------------------------------------
#' @importFrom dplyr bind_rows
#' @importFrom Matrix rowMeans rowSums
#' @importFrom matrixStats rowMedians
#' @importFrom purrr map_depth
#' @importFrom SummarizedExperiment assay
.agg <- function(x, 
    by = c("cluster_id", "sample_id"), 
    fun = c("median", "mean", "sum"),
    assay = "exprs") {
    fun <- switch(
        match.arg(fun), 
        median = rowMedians, 
        mean = rowMeans, 
        sum = rowSums)
    cs <- .split_cells(x, by)
    pb <- map_depth(cs, -1, function(i) {
        if (length(i) == 0) return(numeric(nrow(x)))
        fun(assay(x, assay)[, i, drop = FALSE])
    })
    map_depth(pb, -2, function(u) as.matrix(data.frame(
        u, row.names = rownames(x), check.names = FALSE)))
}

# ==============================================================================
# generate a toy dataset SCE for unit-testing
# ------------------------------------------------------------------------------
#' @importFrom SingleCellExperiment SingleCellExperiment
.toySCE <- function() {
    gs <- paste0("g", seq_len(ngs <- 100))
    cs <- paste0("c", seq_len(ncs <- 2e3))
    y <- sample(100, ngs * ncs, replace = TRUE)
    y <- matrix(y, ngs, ncs, TRUE, list(gs, cs))
    cd <- data.frame(
        mapply(function(i, n) 
            sample(paste0(i, seq_len(n)), ncs, TRUE),
            i = c("k", "s", "g"), n = c(5, 4, 3)),
        stringsAsFactors = TRUE)
    cd$s <- factor(paste(cd$s, cd$g, sep = "."))
    colnames(cd) <- paste(c("cluster", "sample", "group"), "id", sep = "_")
    SingleCellExperiment(assay = list(exprs = y), colData = cd)
}
