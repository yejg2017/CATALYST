# x: SingleCellExperiment
# y: length 1 character string 
#    appearing uniquely in assayNames(x)
#' @importFrom SummarizedExperiment assayNames
.check_assay <- function(x, y) {
    stopifnot(
        length(y) == 1, 
        is.character(y),
        sum(y == assayNames(x)) == 1)
    return(TRUE)
}

# PREPROCESSING ================================================================

#' @importFrom methods is
#' @importFrom flowCore isFCSfile
#' @importFrom SingleCellExperiment int_metadata
.check_args_normCytof <- function(u) {
    stopifnot(
        is(u$x, "SingleCellExperiment"),
        length(u$assays) == 2,
        .check_assay(u$x, u$assays[1]),
        .check_assay(u$x, u$assays[2]),
        is.numeric(u$k), length(u$k) == 1, u$k > 1,
        is.numeric(u$trim), length(u$trim) == 1, u$trim >= 0,
        is.logical(u$remove_beads), length(u$remove_beads) == 1,
        is.null(u$norm_to) || is(u$norm_to, "flowFrame") 
        || is.character(u$norm_to) & sum(isFCSfile(u$norm_to) == 1),
        is.logical(u$overwrite), length(u$overwrite) == 1,
        is.logical(u$transform), length(u$transform) == 1,
        !is.null(u$cofactor) || !is.null(int_metadata(u$x)$cofactor),
        is.logical(u$plot), length(u$plot) == 1,
        is.logical(u$verbose), length(u$verbose) == 1)
}

#' @importFrom methods is
.check_args_assignPrelim <- function(u) {
    stopifnot(
        is(u$x, "SingleCellExperiment"), 
        .check_assay(u$x, u$assay), is.numeric(unlist(u$bc_key)), 
        is.vector(u$bc_key) || all(unlist(u$bc_key) %in% c(0, 1)),
        is.logical(u$verbose), length(u$verbose) == 1)
}

#' @importFrom methods is
#' @importFrom S4Vectors metadata
.check_args_estCutoffs <- function(u) {
    stopifnot(
        is(u$x, "SingleCellExperiment"),
        !is.null(metadata(u$x)$bc_key),
        !is.null(u$x$bc_id), !is.null(u$x$delta))
}

#' @importFrom methods is
#' @importFrom S4Vectors metadata
.check_args_applyCutoffs <- function(u) {
    stopifnot(
        is(u$x, "SingleCellExperiment"), 
        .check_assay(u$x, u$assay),
        !is.null(u$x$bc_id), !is.null(u$x$delta),
        is.numeric(u$mhl_cutoff), length(u$mhl_cutoff) == 1,
        !is.null(u$sep_cutoffs) || !is.null(metadata(u$x)$sep_cutoffs))
}

#' @importFrom methods is
#' @importFrom S4Vectors metadata
#' @importFrom SingleCellExperiment int_metadata
.check_args_compCytof <- function(u) {
    stopifnot(
        is(u$x, "SingleCellExperiment"), 
        .check_assay(u$x, u$assay),
        !is.null(u$sm) || !is.null(metadata(u$x)$spillover_matrix),
        is.logical(u$overwrite), length(u$overwrite) == 1,
        is.logical(u$transform), length(u$transform) == 1,
        !is.null(u$cofactor) || !is.null(int_metadata(u$x)$cofactor))
}

#' @importFrom methods is
#' @importFrom S4Vectors metadata
#' @importFrom SingleCellExperiment int_metadata
.check_args_sce2fcs <- function(u) {
    stopifnot(
        is(u$x, "SingleCellExperiment"), 
        .check_assay(u$x, u$assay),
        is.null(u$split_by) || is.character(u$split_by) 
        && length(u$split_by) == 1 && !is.null(u$x[[u$split_by]]),
        is.logical(u$keep_cd), length(u$keep_cd) == 1,
        is.logical(u$keep_dr), length(u$keep_dr) == 1)
}

# plotting ---------------------------------------------------------------------

#' @importFrom methods is
#' @importFrom SummarizedExperiment colData rowData
#' @importFrom SingleCellExperiment int_colData
.check_args_plotScatter <- function(u) {
    stopifnot(is(u$x, "SingleCellExperiment"))
    cd_vars <- c(names(colData(u$x)), names(int_colData(u$x)))
    rd_vars <- unlist(rowData(u$x)[c("channel_name", "marker_name")])
    stopifnot(
        .check_assay(u$x, u$assay), 
        length(u$facet_by) <= 2,
        is.character(u$chs), 
        length(u$chs) >= 2, 
        u$chs %in% c(cd_vars, rd_vars),
        is.logical(u$zeros), 
        length(u$zeros) == 1)
    for (i in seq_along(u$facet_by))
        .check_cd_factor(u$x, u$facet_by[i])
    if (!is.null(u$color_by)) 
        stopifnot(
            is.character(u$color_by), 
            length(u$color_by) == 1, 
            u$color_by %in% cd_vars)
}

# ==============================================================================
# Validity check for 'which' in 'plotEvents()' and 'plotYields()'
#       - stop if not a single ID is valid
#       - warning if some ID(s) is/are not valid and remove it/them
# ------------------------------------------------------------------------------
# which: input argument to plotEvents/Yields
# ids:   valid barcode IDs including 'all' for plotEvents
# fun:   function call (used to vary message)
.check_which <- function(which, ids, fun = c("events", "yields")) {
    msg_events <- c(
        " Valid values for 'which' are IDs that occur as row names in the\n",
        " 'bc_key' slot of the supplied 'dbFrame', or 0 for unassigned events.")
    msg_yields <- c(
        " Valid values for 'which' are IDs that occur as row names in the\n",
        " 'bc_key' slot of the supplied 'dbFrame', or 0 for all barcodes.")
    
    if (length(which) == 1 && !which %in% c(0, ids)) {
        if (fun == "events" & which != "all") {
            stop(paste(which), 
                " is not a valid barcode ID.\n", 
                msg_events, call.=FALSE)
        } else if (fun == "yields") {
            stop(paste(which), 
                " is not a valid barcode ID.\n", 
                msg_yields, call.=FALSE)
        }
    } else {
        new <- which[!is.na(match(which, c(0, ids)))]
        removed <- which[!which %in% new]
        if (length(new) == 0) {
            if (fun == "events") {
                stop(paste(removed, collapse=", "), 
                    " are not valid barcode IDs.\n",
                    msg_events, call.=FALSE)
            } else if (fun == "yields") {
                stop(paste(removed, collapse=", "), 
                    " are not valid barcode IDs.\n",
                    msg_yields, call.=FALSE)
            }
        } else if (length(new) != length(which)) {
            which <- new
            if (length(removed) == 1) {
                warning(paste(removed),
                    " is not a valid barcode ID and has been skipped.",
                    call.=FALSE)
            } else {
                warning(paste(removed, collapse=", "),
                    " are not valid barcode IDs and have been skipped.",
                    call.=FALSE)
            }
        } 
    }
    as.character(which)
}

# DIFFERENTIAL =================================================================

# x: SingleCellExperiment
# k: valid clustering identifier
.check_k <- function(x, k) {
    kids <- names(cluster_codes(x))
    if (is.null(k)) return(kids[1])
    stopifnot(length(k) == 1, is.character(k))
    if (!k %in% kids)
        stop("Clustering ", dQuote(k), 
            " doesnt't exist; valid are",
            " 'names(cluster_codes(x))'.")
    return(k)
}

# x: SingleCellExperiment
# y: logical; should cluster() have been run?
#' @importFrom methods is
#' @importFrom S4Vectors metadata
.check_sce <- function(x, y = FALSE) {
    stopifnot(
        is(x, "SingleCellExperiment"), 
        !is.null(x$sample_id))
    if (y) 
        stopifnot(
            !is.null(x$cluster_id),
            !is.null(metadata(x)$SOM_codes),
            !is.null(metadata(x)$delta_area),
            !is.null(metadata(x)$cluster_codes))
}

# x: SingleCellExperiment
# y: character string corresponding to 
#    non-numeric cell metadata column
#' @importFrom methods is
#' @importFrom S4Vectors metadata
#' @importFrom SummarizedExperiment colData
.check_cd_factor <- function(x, y) {
    if (is.null(y))
        return(TRUE)
    stopifnot(
        is.character(y), length(y) == 1, 
        !is.null(x[[y]]), !is.numeric(x[[y]]))
    return(TRUE)
}

# plotting ---------------------------------------------------------------------

#' @importFrom grDevices col2rgb
.check_colors <- function(x, n = 2) {
    if (is.null(x)) 
        return(TRUE)
    stopifnot(
        length(x) >= n,
        is.character(x))
    foo <- tryCatch(col2rgb(x),
        error = function(e) {})
    if (is.null(foo)) {
        arg_nm <- deparse(substitute(x))
        stop(sprintf("'%s' is invalid.", arg_nm))
    }
    return(TRUE)
}

.check_args_plotClusterHeatmap <- function(u) {
    .check_sce(u$x, TRUE)
    .check_k(u$x, u$k)
    .check_k(u$x, u$m)
    stopifnot(
        .check_assay(u$x, u$assay),
        .check_cd_factor(u$x, u$split_by),
        .check_colors(u$k_pal), .check_colors(u$m_pal),
        .check_colors(u$hm1_pal), .check_colors(u$hm2_pal),
        is.logical(u$scale), length(u$scale) == 1,
        is.logical(u$row_anno), length(u$row_anno) == 1,
        is.logical(u$row_dend), length(u$row_dend) == 1,
        is.logical(u$col_dend), length(u$col_dend) == 1,
        is.logical(u$draw_freqs), length(u$draw_freqs) == 1)
    if (!is.null(u$hm2))
        stopifnot(
            is.character(u$hm2), all(u$hm2 %in% rownames(u$x)) 
            || length(u$hm2) == 1 && u$hm2 %in% c("abundances", "state"))
}

.check_args_plotDiffHeatmap <- function(u) {
    .check_sce(u$x)
    stopifnot(
        .check_colors(u$hm1_pal), .check_colors(u$hm2_pal),
        is.numeric(u$top_n), length(u$top_n) == 1, u$top_n > 1,
        is.logical(u$order), length(u$order) == 1,
        is.numeric(u$th), length(u$th) == 1, 
        is.logical(u$hm1), length(u$hm1) == 1,
        is.logical(u$normalize), length(u$normalize) == 1,
        is.logical(u$row_anno), length(u$row_anno) == 1,
        is.logical(u$col_anno), length(u$col_anno) == 1)
}