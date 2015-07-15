#' @title flows
#' @name flows
#' @description This package contains various functions to filter flows matrices
#' (dominant and major flows), provides statistics on selection made
#'  and proposes map and graph visualisation.
#' @docType package
NULL

#' @title Commuters
#' @name nav
#' @description Data on commuters between Urban Areas of the Grand-Est Regions in 2011.
#' @details
#' Variables: \cr
#' \itemize{
#' \item{i: Code of urban area of residence}
#' \item{namei: Name of the urban area of residence}
#' \item{wi: Number of active occupied persons in the urban area of residence}
#' \item{j: Code of urban area of work}
#' \item{namej: Name of the urban area of work}
#' \item{wj: Number of active occupied persons in the urban area of work}
#' \item{fij: Number of persons commuting}
#' }
#' @references
#' \url{http://www.insee.fr/fr/themes/detail.asp?reg_id=99&ref_id=mobilite-professionnelle-11}
#' @docType data
NULL

#' @title Urban Areas
#' @name UA
#' @description SpatialPolygonsDataFrame of Urban Areas of the Grand-Est region
#' (2010 delineation).
#' @references
#' \url{http://professionnels.ign.fr/geofla#tab-3}
#' @docType data
NULL

#' @title Grand Est Region
#' @name GE
#' @description SpatialPolygonsDataFrame of the Grand-Est region.
#' @references
#' \url{http://professionnels.ign.fr/geofla#tab-3}
#' @docType data
NULL

#### Public

#' @title Flows Preparation
#' @name prepflows
#' @description From a long format matrix to a a wide
#' matrix of flows.
#' @param mat A data.frame of flows between origins and destinations: long format
#' matrix (origins, destinations, flows intensity).
#' @param i A character giving the origin field name in mat.
#' @param j A character giving the destination field name in mat.
#' @param fij A character giving the flow field name in mat.
#' @return A square matrix of flows. Diagonal can be filled or empty depending on data used.
#' @examples
#' data(nav)
#' myflows <- prepflows(mat = nav, i = "i", j = "j", fij = "fij")
#' myflows[1:5,1:5]
#' @import reshape2
#' @export
prepflows <- function(mat, i, j, fij){
  mat <- mat[,c(i,j,fij)]
  names(mat) <- c("i", "j", "fij")
  listUnits <- unique(c(unique(mat$i),unique(mat$j)))
  fullMat <- expand.grid(listUnits,listUnits, stringsAsFactors = F)
  names(fullMat) <- c("i","j")
  fullMat <- merge(fullMat,mat,by=c("i","j"),all.x=TRUE)
  fullMat <- reshape2::dcast(data = fullMat, formula = i~j, value.var="fij",
                             fill = 0, sum)
  row.names(fullMat) <- fullMat[,1]
  fullMat <- fullMat[, -1]
  fullMat <- as.matrix(fullMat)
  fullMat[is.na(fullMat)] <- 0
  #   w <- data.frame(id = row.names(fullMat),
  #                   sumOut = rowSums(fullMat),
  #                   sumIn = colSums(fullMat))
  # return(list(dfw = w, mat = fullMat))
  return(fullMat)
}


#' @title Descriptive Statistics on Flow Matrix
#' @name statmat
#' @description This function provides various indicators and graphical outputs
#' on a matrix of flows.
#' @param mat A square flow matrix.
#' @param output Graphical output. Choices are "all" for all graphics,
#' "none" to avoid graphical outputs, "degree" for degree distribution, "wdegree" for
#' weighted degree distribution, "lorenz" for Lorenz curve of link weights and
#' "boxplot" for boxplot of link weights (see Details).
#' @param verbose A boolean, if TRUE, returns statistics in the console.
#' @return  The function returns a list of statistics and may plot graphics.
#' \itemize{
#' \item{nblinks: number of cells with values > 0}
#' \item{density: number of links divided by number of possible links (also called gamma index by geographers)}
#' \item{connectcomp: number of connected components (isolates included,
#' weakly connected: use of \code{\link{clusters}} where mode = "weak")}
#' \item{connectcompx: number of connected components (isolates deleted,
#' weakly connected: use of \code{\link{clusters}} where mode = "weak")}
#' \item{sizecomp: a data.frame of connected components: size
#' and sum of flows per component (isolates included).}
#' \item{compocomp: a data.frame of connected components giving membership of units (isolates included).}
#' \item{degrees: a data.frame of nodes degrees and weighted degrees.}
#' \item{sumflows: sum of flows}
#' \item{min: minimum flow }
#' \item{Q1: first quartile of flows}
#' \item{median: median flow}
#' \item{Q3: third quartile of flows}
#' \item{max: maximum flow}
#' \item{mean: mean flow}
#' \item{sd: standart deviation of flows}}
#' @details Graphical ouputs concern outdegrees by default. If the matrix is
#' transposed, outputs concern indegrees.
#' @seealso \link{compmat}
#' @import igraph
#' @examples
#' data(nav)
#' myflows <- prepflows(mat = nav, i = "i", j = "j", fij = "fij")
#' x <- statmat(myflows)
#' # Size of connected components
#' x$sizecomp
#' # Sum of flows
#' x$sumflows
#' # Lorenz curve only
#' statmat(myflows, output = "lorenz", verbose = FALSE)
#' @export
statmat <- function(mat, output = "all", verbose = TRUE){
  nbcell <- length(mat)
  matdim <- dim(mat)[1]
  sumflows <- sum(mat)
  matbool <- mat
  matbool[mat > 0] <- 1
  nbcellfull <- sum(matbool)
  vmat <- as.vector(mat[mat > 0])
  vmat <- vmat[order(vmat, decreasing = FALSE)]
  sumflows <- sum(vmat)
  vmatcs <- cumsum(vmat) /  sumflows * 100
  summaryflows <- summary(vmat)
  summaryflows <- c(summaryflows, sd(vmat))
  names(summaryflows) <- NULL

  #prep graph
  deg <- rowSums(matbool)
  deg2 <- rowSums(mat)
  # df output
  degdf <- data.frame(id=names(deg), degree = deg, wdegree = deg2, stringsAsFactors = FALSE)
  deg <- deg[deg>0]
  deg2 <- deg2[deg2>0]

  if(output=="degree"){
    plot(deg[order(deg, decreasing = TRUE)], type = "l", log = "xy",
         xlab = "rank (log)", ylab = "size (log nb. flows)")
    title("rank - size")
  }
  if(output=="wdegree"){
    plot(deg2[order(deg2, decreasing = TRUE)], type = "l", log = "xy",
         xlab = "rank (log)", ylab = "size (log flow intensity)")
    title("rank - size (weighted)")
  }
  if(output=="lorenz"){
    plot( y = vmatcs, x = seq(0,100,length.out = length(vmatcs)), type = "l",
          xlim = c(0,100), ylim = c(0,100),
          xlab = "cum. nb. flows", ylab = "cum. intensity of flows")
    title ("Lorenz Curve")
  }
  if(output=="boxplot"){
    boxplot(as.vector(mat[mat>0]), log = "y")
    title("Boxplot")
  }
  if(output=="all"){
    ## graphic outputs
    old.par <- par (mfrow = c(2,2))
    ## rank-size link
    plot(deg[order(deg, decreasing = TRUE)], type = "l", log = "xy",
         xlab = "rank (log)", ylab = "size (log nb. flows)")
    title("rank - size")
    ## rank size flow
    plot(deg2[order(deg2, decreasing = TRUE)], type = "l", log = "xy",
         xlab = "rank (log)", ylab = "size (log flow intensity)")
    title("rank - size (weighted)")
    ##lorenz
    plot( y = vmatcs, x = seq(0,100,length.out = length(vmatcs)), type = "l",
          xlim = c(0,100), ylim = c(0,100),
          xlab = "cum. nb. flows", ylab = "cum. intensity of flows")
    title ("Lorenz Curve")
    ## boxplot
    boxplot(as.vector(mat[mat>0]), log = "y")
    title("Boxplot")
    par(old.par)
  }

  ## Connected components of a graph
  g <- graph.adjacency(adjmatrix = mat, mode = "directed", weighted = TRUE)
  clustg <- clusters(graph = g, mode = "weak")

  connectcomp <- clustg$no
  connectcompx <- length(clustg$csize[clustg$csize>1])
  compocomp <-  data.frame(id = V(g)$name, idcomp = clustg$membership, stringsAsFactors = FALSE)
  compocompw <- merge(compocomp, degdf, by = "id")
  compw <- aggregate(x = compocompw$wdegree,by = list(compocompw$idcomp),
                     FUN = sum)
  sizecomp <- data.frame(idcomp = seq(1, length(clustg$csize)),
                         sizecomp = clustg$csize, wcomp = compw$x)

  if (verbose == TRUE){
    ## stat cat
    cat('matrix dimension:', matdim, "X", matdim,"\n" )
    cat('nb. links:', nbcellfull, "\n" )
    cat('density:', nbcellfull/nbcell, "\n" )
    cat('nb. of components (weak)', connectcomp, "\n")
    cat("nb. of components (weak, size > 1)", connectcompx, "\n")
    cat('sum of flows:', sumflows, "\n")
    cat('min:', summaryflows[1] ,"\n")
    cat('Q1:', summaryflows[2] ,"\n")
    cat('median:', summaryflows[3] ,"\n")
    cat('Q3:', summaryflows[5] ,"\n")
    cat('max:', summaryflows[6] ,"\n")
    cat('mean:', summaryflows[4] ,"\n")
    cat('sd:', summaryflows[7] ,"\n")
  }
  ## stat list
  matstat <- list(matdim = dim(mat),
                  nblinks = nbcellfull,
                  density = nbcellfull/nbcell,
                  connectcomp = connectcomp,
                  connectcompx = connectcompx,
                  sizecomp = sizecomp,
                  compocomp = compocomp,
                  degrees = degdf,
                  sumflows = sumflows,
                  min =  summaryflows[1],
                  Q1 =  summaryflows[2],
                  median = summaryflows[3],
                  Q3 = summaryflows[5],
                  max = summaryflows[6],
                  mean = summaryflows[4],
                  sd = summaryflows[7]
  )
  return(invisible(matstat))

}



#' @title Comparison of Two Matrices
#' @name compmat
#' @description Compares two matrices of same dimension, with same column and
#' row names.
#' @param mat1 A square matrix of flows.
#' @param mat2 A square matrix of flows.
#' @param digits	An integer indicating the number of decimal places to be used
#' when printing the data.frame in the console (see \link{round}).
#' @return A data.frame that provides statistics on differences
#' between mat1 and mat2: absdiff are the
#' absolute diffences and reldiff are the relative differences (in percent).
#' @seealso \link{statmat}
#' @examples
#' data(nav)
#' mat <- prepflows(mat = nav, i = "i", j = "j", fij = "fij")
#' diag(mat) <- 0
#' x <- domflows(mat = mat, wi = colSums(mat), wj = colSums(mat), k = 1)
#' firstx <- firstflows(mat = mat, method = "nfirst", ties.method = "first", k = 1)
#' xnb <- firstflows(mat = mat, method = "xfirst", ties.method = "first", k = 20)
#' mat2 <- mat * firstx * x * xnb
#' compmat(mat1 = mat, mat2 = mat2, digits = 1)
#' @export
compmat <- function(mat1, mat2, digits = 0){
  x1 <- statmat(mat1, output = "none", verbose = FALSE)
  x2 <- statmat(mat2, output = "none", verbose = FALSE)
  compdf <- data.frame(mat1= c(x1$nblinks, x1$sumflows, x1$connectcompx,
                               x1$min, x1$Q1, x1$median, x1$Q3,
                               x1$max, x1$mean, x1$sd),
                       mat2= c(x2$nblinks, x2$sumflows,x2$connectcompx,
                               x2$min, x2$Q1, x2$median, x2$Q3,
                               x2$max, x2$mean, x2$sd),
                       row.names = c("nblinks","sumflows", "connectcompx",
                                     "min", "Q1", "median", "Q3",
                                     "max", "mean", "sd"))

  compdf$absdiff <- abs(compdf$mat1-compdf$mat2)
  compdf[4:10,"absdiff"] <- NA
  compdf$reldiff <- abs(compdf$mat1-compdf$mat2) / compdf$mat1 * 100
  compdf[3:10,"reldiff"] <- NA

  print(round(compdf, digits))
  return(invisible(compdf))
}



#' @title Flow Selection from Origins
#' @name firstflows
#' @description Flow selection from origins.
#' @param mat A square matrix of flows.
#' @param method One of "nfirst", "xfirst" or "xsumfirst":
#' \cr nfirst selects k first flows from origins,
#' \cr xfirst selects flows from origins greater than k,
#'\cr xsumfirst selects flows from origins while sum of flows is smaller than k.
#' @param ties.method In case of equality with "nfirst" method (use "random" or "first", see \link{rank}).
#' @param k Selection threshold.
#' @return A boolean matrix of selected flows.
#' @details As the output is a boolean matrix, use element-wise multiplication to get flows intensity.
#' @seealso \link{firstflowsg}, \link{domflows}
#' @examples
#' data(nav)
#' myflows <- prepflows(mat = nav, i = "i", j = "j", fij = "fij")
#'
#' #remove diagonal
#' diag(myflows) <- 0
#' statmat(myflows)
#'
#' #select 2 flows per spatial unit
#' fflows1 <- firstflows(myflows, method = "nfirst", ties.method = "first", k = 2)
#' # Use element-wise multiplication to get flows intensity.
#' fflow1 <- fflows1 * myflows
#' statmat(fflow1)
#'
#' #select flows > 20
#' fflows2 <- firstflows(myflows, method = "xfirst", k = 20)
#' fflow2 <- fflows2 * myflows
#' statmat(fflow2)
#'
#' # Select each flows that represent at least 10% of the outputs
#' myflowspct <- myflows / rowSums(myflows) * 100
#' fflows2 <- firstflows(mat = myflowspct, method = "xfirst", k = 10)
#' fflow2 <- fflows2 * myflows
#' statmat(fflow2)
#' @export
firstflows <- function(mat, method = "nfirst", ties.method = "first",k){
  # list of i, j selected
  lfirst <- apply(mat, 1, get(method), k = k, ties.method = ties.method)
  # if only one selected
  if(is.null(dim(lfirst))){
    lfirst <- as.list((lfirst))
  }
  # control class output
  if(is.matrix(lfirst)) {
    lfirst <- as.list(as.data.frame(lfirst, stringsAsFactors = FALSE))
  }
  matfinal <- mat
  matfinal[] <- 0
  # control 0 selection
  if (length(lfirst)<1){
    return(matfinal)
  }
  for (i in 1:nrow(matfinal)){
    matfinal[names(lfirst[i][]),lfirst[[i]]] <- 1
  }
  return(matfinal)
}


#' @title Flow Selection from Full Matrix
#' @name firstflowsg
#' @description Flow selection based on global criteria.
#' @param mat A square matrix of flows.
#' @param method One of "nfirst", "xfirst" or "xsumfirst":
#' \cr nfirst selects the k first flows,
#' \cr xfirst selects flows greater than k,
#'\cr xsumfirst selects flows while sum of flows is smaller than k.
#' @param ties.method In case of equality with "nfirst" method (use "random" or "first", see \link{rank}).
#' @param k Selection threshold.
#' @return A boolean matrix of selected flows.
#' @details As the output is a boolean matrix, use element-wise multiplication to get flows intensity.
#' @seealso \link{firstflows}, \link{domflows}
#' @examples
#' data(nav)
#' myflows <- prepflows(mat = nav, i = "i", j = "j", fij = "fij")
#' #remove diagonal
#' diag(myflows) <- 0
#' statmat(myflows)
#' #select 50 first flow on the whole matric
#' fflows1 <- firstflowsg(myflows, method = "nfirst", ties.method = "first", 50)
#' fflow1 <- fflows1 * myflows
#' statmat(fflow1)
#' #select flows > 50
#' fflows2 <- firstflowsg(myflows, method = "xfirst", ties.method = "first", 50)
#' fflow2 <- fflows2 * myflows
#' statmat(fflow2)
#' @export
firstflowsg <- function(mat, method = "nfirst", k, ties.method = "first"){
  matfinal <- mat
  matfinal[] <- 0
  if (method == "nfirst"){
    matfinal[rank(mat, ties.method = ties.method) > ((dim(mat)[1]*dim(mat)[2]) - k)] <- 1
  }
  if (method == "xfirst"){
    matfinal[mat >= k] <- 1
  }
  if (method == "xsumfirst"){
    matv <- as.vector(mat)
    names(matv) <- 1:length(matv)
    matvo <- matv[order(matv, decreasing = TRUE)]
    matvo <- cumsum(matvo)
    nbgood <- (length(matvo[matvo < k ])+1)
    matvo[] <- c(rep(1,nbgood), rep(0,(length(matvo)-nbgood)))
    matfinal[] <- matvo[order(as.numeric(names(matvo)), decreasing = FALSE)]
  }
  matfinal[mat == 0] <- 0
  return(matfinal)
}


#' @title Dominant Flows Selection
#' @name domflows
#' @description Find dominant flows in a matrix.
#' @param mat A square matrix of flows.
#' @param wi A vector of weight for rows.
#' @param wj A vector of weight for columns.
#' @param k A threshold (see Details).
#' @return A boolean matrix of selected flows.
#' @details This function selects which flow (fij or fji) must be kept.
#' If the ratio weight of destination (wj) / weight of origin (wi) is greater than k, then fij is kept.
#' This function can perform the second criterion of the Nystuen &
#' Dacey's dominants flows analysis.\cr
#' As the output is a boolean matrix, use element-wise multiplication to get flows intensity.
#' @seealso \link{firstflows}, \link{firstflowsg}, \link{plotDomFlows}, \link{plotMapDomFlows}
#' @references J. Nystuen & M. Dacey, 1961, A graph theory interpretation of nodal flows,
#' \emph{Papers and Proceedings of the Regional Science Association}, vol. 7,  29-42.
#' @examples
#' data(nav)
#' myflows <- prepflows(mat = nav, i = "i", j = "j", fij = "fij")
#' #remove diagonal
#' diag(myflows) <- 0
#' statmat(myflows)
#' #create the tree of dominant, intermediary and dominated nodes
#' domf <- domflows(mat = myflows, wi = colSums(myflows), wj = colSums(myflows), k = 1)
#' domfw <-domf * myflows
#' statmat(domfw)
#' @export
domflows <- function(mat, wi, wj, k){
  # list of i, j selected
  matfinal <- mat
  matfinal[] <- 0
  for (i in 1:dim(mat)[1]){
    for (j in 1:dim(mat)[2]){
      if (wi[i] > 0){
        if ((wj[j]/wi[i]) > k){
          matfinal[i,j] <- 1
        }
      }
    }
  }
  matfinal[mat == 0] <- 0
  return(matfinal)
}

#' @title Dominant Flows Graph
#' @name plotDomFlows
#' @description This function plots a dominant flows graph.
#' @param mat A square matrix of dominant flows (see \link{domflows}).
#' @param legend.flows.pos Position of the flows legend, one of "topleft", "top",
#' "topright", "left", "right", "bottomleft", "bottom", "bottomright".
#' @param legend.flows.title Title of the flows legend.
#' @param legend.nodes.pos Position of the nodes legend, one of "topleft", "top",
#' "topright", "left", "right", "bottomleft", "bottom", "bottomright".
#' @param legend.node.txt Text of the nodes legend.
#' @param labels A boolean, if TRUE, labels of dominant and intermediary nodes are plotted.
#' @note We do not propose visualisation for other outputs as square matrices can easily be plot
#' with \link[igraph]{plot.igraph} or \link[sna]{gplot} functions from igraph and sna packages.
#' @seealso \link{domflows}, \link{plotMapDomFlows}
#' @examples
#' data(nav)
#' mat <- prepflows(mat = nav, i = "i", j = "j", fij = "fij")
#' diag(mat) <- 0
#' x <- domflows(mat = mat, wi = colSums(mat), wj = colSums(mat), k = 1)
#' firstx <- firstflows(mat = mat, method = "nfirst", ties.method = "first", k = 1)
#' xnb <- firstflows(mat = mat, method = "xfirst", ties.method = "first", k = 20)
#' mat <- mat * firstx * x * xnb
#' plotDomFlows(mat)
#' @export
plotDomFlows <- function(mat, legend.flows.pos = "topright",
                         legend.flows.title = "Flows Intensity",
                         legend.nodes.pos = "bottomright",
                         legend.node.txt = c("Dominant", "Intermediary",
                                             "Dominated",
                                             "Size proportional\nto sum of inflows"),
                         labels = FALSE){
  g <- graph.adjacency(adjmatrix = mat,mode = "directed", weighted = TRUE)
  g <- delete.vertices(g, names(degree(g)[degree(g)==0]))
  vertexdf <-  data.frame(id = V(g)$name, col = NA, size = NA, name = NA)
  # Dominant
  vertexdf[(degree(g, mode = "in") > 0) & (degree(g, mode = "out") < 1), "col"] <- "red"
  vertexdf[(degree(g, mode = "in") > 0) & (degree(g, mode = "out") < 1), "size"] <- 6
  vertexdf[(degree(g, mode = "in") > 0) & (degree(g, mode = "out") < 1), "name"] <-
    as.character(vertexdf[(degree(g, mode = "in") > 0) & (degree(g, mode = "out") < 1), "id"])
  # intermediaire
  vertexdf[(degree(g, mode = "in") > 0) & (degree(g, mode = "out") > 0), "col"] <- "orange"
  vertexdf[(degree(g, mode = "in") > 0) & (degree(g, mode = "out") > 0), "size"] <- 4
  vertexdf[(degree(g, mode = "in") > 0) & (degree(g, mode = "out") > 0), "name"]<-
    as.character(vertexdf[(degree(g, mode = "in") > 0) & (degree(g, mode = "out") > 0), "id"])
  # Dominé
  vertexdf[(degree(g, mode = "in") < 1) & (degree(g, mode = "out") > 0), "col"] <- "yellow"
  vertexdf[(degree(g, mode = "in") < 1) & (degree(g, mode = "out") > 0), "size"] <- 2

  V(g)$color <- vertexdf$col
  V(g)$size <- vertexdf$size
  V(g)$names <- as.character(vertexdf$name)
  E(g)$color <- "black"
  E(g)$width <- ((E(g)$weight) * 8 / (max(E(g)$weight)-min(E(g)$weight)))+1
  #   lg <- layout.fruchterman.reingold(g)
  #   g <- set.graph.attribute(graph = g, name = "layout", value = lg)
  if(labels == TRUE){
    x <- igraph::plot.igraph(g, vertex.label = V(g)$names, vertex.label.cex = 1,
                             vertex.label.color = "black",
                             vertex.size = V(g)$size, edge.arrow.size = 0)
  }else{
    x <- igraph::plot.igraph(g, vertex.label = NA,
                             vertex.size = V(g)$size, edge.arrow.size = 0)
  }
  LegendPropLines(pos = legend.flows.pos, legTitle = legend.flows.title,
                  legTitleCex = 0.8, legValuesCex = 0.6,
                  varvect = c(min(E(g)$weight),max(E(g)$weight)),
                  sizevect = c(2, 10), col = "black",
                  frame = FALSE, round = 0)


  legend(x = legend.nodes.pos, legend = legend.node.txt,
         cex = c(0.8), pt.cex = c(2.8,2,1,0), bty = "n",
         pt.bg = c("red", "orange", "yellow", NA),
         pch = c(21,21,21,21))

}

#' @title Dominant Flows Map
#' @name plotMapDomFlows
#' @description This function displays a dominant flows map.
#' @param mat A square matrix of dominant flows (see \link{domflows}).
#' @param spdf A SpatialPolygonsDataFrame or a SpatialPointsDataFrame object of units.
#' @param spdfid Name of the 'id' variable in the spdf data.frame.
#' @param w A data.frame which contains the weight variable used to plot units sizes on the map.
#' @param wid Name of the 'id' variable in w.
#' @param wvar Name of the weight variable in w.
#' @param wcex Share of the surface of the map occupied by circles (0.02 is 2\%).
#' @param legend.flows.pos Position of the flows legend, one of "topleft", "top",
#' "topright", "left", "right", "bottomleft", "bottom", "bottomright".
#' @param legend.flows.title Title of the flows legend.
#' @param legend.nodes.pos Position of the nodes legend, one of "topleft", "top",
#' "topright", "left", "right", "bottomleft", "bottom", "bottomright".
#' @param legend.node.txt Text of the nodes legend.
#' @param add A boolean, if TRUE, add the layer to an existing plot.
#' @seealso \link{domflows}, \link{plotDomFlows}
#' @import sp
#' @examples
#' data(nav)
#' mat <- prepflows(mat = nav, i = "i", j = "j", fij = "fij")
#' diag(mat) <- 0
#' x <- domflows(mat = mat, wi = colSums(mat), wj = colSums(mat), k = 1)
#' firstx <- firstflows(mat = mat, method = "nfirst", ties.method = "first", k = 1)
#' hab <- mat * firstx * x
#' inflows <- data.frame(id = colnames(mat), w = colSums(mat))
#' par(mar = c(0,0,2,0))
#' sp::plot(GE, col = "#cceae7", border = NA)
#' plotMapDomFlows(mat = hab,
#'                 spdf = UA,
#'                 spdfid = "ID",
#'                 w = inflows,
#'                 wid = "id",
#'                 wvar = "w",
#'                 wcex = 0.05,
#'                 add = TRUE,
#'                 legend.flows.pos = "bottomleft",
#'                 legend.flows.title = "Residential flows\nintensity")
#' title("Dominant Residential Flows")
#' mtext(text = "INSEE, 2011", side = 4, line = -1, adj = 0.01, cex = 0.8)
#' @export
plotMapDomFlows <- function(mat, spdf,
                            spdfid, w,
                            wid, wvar,
                            wcex = 0.05,
                            legend.flows.pos = "topright",
                            legend.flows.title = "flow intensity",
                            legend.nodes.pos = "topleft",
                            legend.node.txt = c("Dominant", "Intermediary",
                                                "Dominated",
                                                "Size proportional\nto sum of inflows"),
                            add = FALSE){
  # points management
  pts <- data.frame(sp::coordinates(spdf), id  = spdf@data[,spdfid])
  names(pts)[1:2] <- c("long", "lat")
  w <- w[,c(wid, wvar)]
  names(w) <- c("id", "var")
  pts <- merge(pts, w, by.x = "id", by.y = "id", all.x = T)

  # points size
  bbbox <- sp::bbox(spdf)
  x1 <- bbbox[1]
  y1 <- bbbox[2]
  x2 <- bbbox[3]
  y2 <- bbbox[4]
  sfdc <- (x2-x1)*(y2-y1)
  sc <- sum(pts$var, na.rm=TRUE)
  pts$cex <- sqrt((pts$var * wcex * sfdc / sc) / pi)
  pts <- pts[order(pts$cex,decreasing=TRUE),]
  pts <- pts[pts$cex > 0, ]

  # Segment management
  colnames(mat) <- paste("X", colnames(mat), sep="")
  row.names(mat) <- paste("X", row.names(mat), sep="")
  fdom <- reshape2::melt(mat)
  names(fdom) <- c("i", "j", "fij")
  fdom <- fdom[fdom$fij > 0,]
  fdom$i <- substr(x = fdom$i, 2 , nchar(as.character(fdom$i)))
  fdom$j <- substr(x = fdom$j, 2 , nchar(as.character(fdom$j)))
  fdom <- merge(fdom, pts, by.x = "i", by.y = "id", all.x = T,
                suffixes = c("i","j"))
  fdom <- merge(fdom, pts, by.x = "j", by.y = "id", all.x = T,
                suffixes = c("i","j"))
  fdom$width <- (fdom$fij * 8 / (max(fdom$fij) - min(fdom$fij))) + 2

  # points color
  pts$col <- "green"
  pts[pts$id %in% fdom$j & !pts$id %in% fdom$i, "col"] <- "red"
  pts[pts$id %in% fdom$j & pts$id %in% fdom$i, "col"] <- "orange"
  pts[!pts$id %in% fdom$j & pts$id %in% fdom$i, "col"] <- "yellow"
  pts <- pts[pts$col != "green",]

  # Affichage points and segments
  if(add == FALSE){
    sp::plot(spdf, col = NA, border = NA, add = F)
  }
  segments(fdom$longi, fdom$lati, fdom$longj, fdom$latj,
           col="grey20", lwd = fdom$width)
  symbols(pts[,c("long","lat")],
          circles = pts$cex,
          add = TRUE,
          bg = pts$col,
          fg ="grey50",
          inches = F)
  segments(fdom$longi, fdom$lati, fdom$longj, fdom$latj,
           col="#00000010", lwd = fdom$width)

  # Affichage legend
  LegendPropLines(pos = legend.flows.pos, legTitle = legend.flows.title,
                  legTitleCex = 0.8, legValuesCex = 0.6,
                  varvect = c(min(fdom$fij),max(fdom$fij)),
                  sizevect = c(2, 10), col = "black",
                  frame = FALSE, round = 0)


  legend(x = legend.nodes.pos, legend = legend.node.txt,
         cex = c(0.8), pt.cex = c(2.8,2,1,0), bty = "n",
         pt.bg = c("red", "orange", "yellow", NA),
         pch = c(21,21,21,21))
}









#### Private
#' @title nfirst
#' @name nfirst
#' @noRd
nfirst <- function(x, k, ties.method){
  x <- x[x > 0]
  if (length(x) > 0){
    if (length(x) > k ){
      x <- x[rank(x, ties.method = ties.method) > (length(x) - k)]
      x <- names(x)
    }else{
      x <- names(x)
    }
  }
  return(x)
}

#' @title xfirst
#' @name xfirst
#' @noRd
xfirst <- function(x, k, ties.method){
  x <- x[x > 0]
  if (length(x) > 0){
    x <- x[x > k]
    x <- names(x)
  }else{
    x <- names(x)
  }
  return(x)
}

#' @title xsumfirst
#' @name xsumfirst
#' @noRd
xsumfirst <- function(x, k, ties.method){
  x <- x[x > 0]
  x <- x[order(x, decreasing = TRUE)]
  x <- cumsum(x = x)
  if (length(x) > 0){
    if (x[1] >= k){
      x <- names(x[1])
    }else{
      # at least k
      x <- x[1:(length(x[(x <= k)==TRUE]) + 1)]
      # less than k
      # x <- x[(x <= k)]
      x <- names(x)
    }
  }else{
    x <- names(x)
  }
  # pb return error if k > sum(mat) or k > sum(mat/w)
  return(x)
}


#' @title LegendPropLines
#' @name LegendPropLines
#' @noRd
LegendPropLines<- function(pos = "topleft", legTitle = "Title of the legend", legTitleCex = 0.8,
                           legValuesCex = 0.6, varvect, sizevect, col="red", frame=FALSE, round=0){


  positions <- c("bottomleft", "topleft", "topright", "bottomright",
                 "left", "right", "top", "bottom", "middle")
  if(pos %in% positions){

    # extent
    x1 <- par()$usr[1]
    x2 <- par()$usr[2]
    y1 <- par()$usr[3]
    y2 <- par()$usr[4]
    xextent <- x2 - x1
    yextent <- y2 - y1

    # variables internes
    paramsize1 <- 25
    paramsize2 <- 40
    width <- (x2 - x1) / paramsize1
    height <- width /1.5
    delta1 <- min((y2 - y1) / paramsize2, (x2 - x1) / paramsize2) # Gros eccart entre les objets
    delta2 <- (min((y2 - y1) / paramsize2, (x2 - x1) / paramsize2))/2 # Petit eccart entre les objets


    rValmax <- max(varvect,na.rm = TRUE)
    rValmin <- min(varvect,na.rm = TRUE)
    rValextent <- rValmax - rValmin
    rLegmax <- max(sizevect,na.rm = TRUE)
    rLegmin <- min(sizevect,na.rm = TRUE)
    rLegextent <- rLegmax - rLegmin

    rVal <- c(rValmax,rValmax - rValextent/3 , rValmax - 2*(rValextent/3),rValmin)
    rLeg <- c(rLegmax,rLegmax - rLegextent/3 , rLegmax - 2*(rLegextent/3),rLegmin)
    rVal <- round(rVal,round)

    # xsize & ysize

    longVal <- rVal[strwidth(rVal,cex=legValuesCex)==max(strwidth(rVal,cex=legValuesCex))][1]
    #if(!is.null(breakval)){if (strwidth(paste(">=",breakval),cex=legValuesCex)>strwidth(longVal,cex=legValuesCex)){longVal <- paste(">=",breakval)}}
    legend_xsize <- max(width+ strwidth(longVal,cex=legValuesCex)-delta2,strwidth(legTitle,cex = legTitleCex)-delta1)

    legend_ysize <-8*delta1 + strheight(legTitle,cex = legTitleCex)

    # Position
    if (pos == "bottomleft") {xref <- x1 + delta1 ; yref <- y1 + delta1}
    if (pos == "topleft") {xref <- x1 + delta1 ; yref <- y2 - 2*delta1 - legend_ysize}
    if (pos == "topright") {xref <- x2 - 2*delta1 - legend_xsize ; yref <- y2 -2*delta1 - legend_ysize}
    if (pos == "bottomright") {xref <- x2 - 2*delta1 - legend_xsize ; yref <- y1 + delta1}
    if (pos == "left") {xref <- x1 + delta1 ; yref <- (y1+y2)/2-legend_ysize/2 - delta2}
    if (pos == "right") {xref <- x2 - 2*delta1 - legend_xsize ; yref <- (y1+y2)/2-legend_ysize/2 - delta2}
    if (pos == "top") {xref <- (x1+x2)/2 - legend_xsize/2 ; yref <- y2 - 2*delta1 - legend_ysize}
    if (pos == "bottom") {xref <- (x1+x2)/2 - legend_xsize/2 ; yref <- y1 + delta1}
    if (pos == "middle") { xref <- (x1+x2)/2 - legend_xsize/2 ; yref <- (y1+y2)/2-legend_ysize/2 - delta2}


    # Frame
    if (frame==TRUE){
      rect(xref-delta1, yref-delta1, xref+legend_xsize + delta1*2, yref+legend_ysize + delta1 *2, border = "black",  col="white")
    }

    mycol <- col

    jump <- delta1
    for(i in 4:1){

      if (rLeg[i] < 0.2){rLeg[i] <- 0.2} # TAILLE DES LIGNE MINIMALES (A METTRE AUSSI SUR LES CARTES)

      segments(xref, yref + jump, xref + width, yref + jump, col=mycol, lwd=rLeg[i],lend=1)
      text(xref + width + delta2 ,y= yref + jump,rVal[i],adj=c(0,0.5),cex=legValuesCex)
      jump <- jump + 2*delta1 # ICI AMELIORER
    }
    text(x=xref ,y=yref + 9*delta1,legTitle,adj=c(0,0),cex=legTitleCex)
  }
}






# #' @title Plot Dominant Flows
# #' @name plotflowDom
# #' @description Plot a map of the Dominant Flows. It uses, as input, the output
# #' of the \code{\link{flowDom}} function.
# #' @param fdom A data.frame outputed by the \code{\link{flowDom}} function.
# #' @param spdf A SpatialPolygonsDataFrame to be linked to \code{fdom}.
# #' @param id A character giving the identifier field in \code{spdf} to be linked
# #'  to \code{i} and \code{j}.
# #' @param name A character giving the label field in \code{spdf} to be
# #' plotted. A click on a map unit will prompt a unit name. (interactive session
# #' only - optional)
# #' @details The output of the function is a plot of a map. The map shows which
# #' units are either "dominant", "dominated" or both. The darker a link is the
# #' higher the share of the flow is in its total outbound flows.
# #' @examples
# #'data(LoireAtlantique)
# #'dom1<- flowDom(mat = MRE44,
# #'               i = "DCRAN",
# #'               j = "CODGEO",
# #'               fij = "NBFLUX_C08_POP05P")
# #'if (interactive()){
# #'  plotflowDom(fdom = dom1, spdf = COM44, id = "INSEE_COM", name = "NOM_COM")
# #'}
# #' @export
# plotflowDom <- function(fdom, spdf, id, name = NULL ){
#
#   sumi <- unique(fdom[,c("i","sumInI")])
#   sumj <- unique(fdom[,c("j","sumInJ")])
#   names(sumj) <- c("i", "sumInI")
#   sumij <- unique(rbind(sumi,sumj))
#
#   pts <- data.frame(sp::coordinates(spdf),spdf@data)
#   names(pts)[1:2] <- c("X", "Y")
#   pts <- merge(pts, sumij[,c("i", "sumInI")], by.x = id, by.y = "i", all.x = T)
#
#   fdom <- merge(fdom, pts, by.x = "i", by.y = id, all.x = T,
#                 suffixes = c("i","j"))
#   fdom <- merge(fdom, pts, by.x = "j", by.y = id, all.x = T,
#                 suffixes = c("i","j"))
#   listI <- unique(fdom$i)
#   listJ <- unique(fdom$j)
#
#   x <- data.frame(pts, d = pts[,id] %in% listI, D = pts[,id] %in% listJ,
#                   col = NA, pch = NA, cex = pts$sumInI)
#
#   bbbox <- sp::bbox(spdf)
#   x1 <- bbbox[1]
#   y1 <- bbbox[2]
#   x2 <- bbbox[3]
#   y2 <- bbbox[4]
#   sfdc <- (x2-x1)*(y2-y1)
#   sc <- sum(x$sumInI,na.rm=TRUE)
#   x$cex <- sqrt((x$sumInI * 0.02 * sfdc / sc) / pi)
#   x <- x[order(x$cex,decreasing=TRUE),]
#   x[!x$d & x$D, "col"] <- "#cc2a36"
#   x[x$d & x$D, "col"] <- "#eb6841"
#   x[x$d & !x$D,"col"] <- "#edc951"
#
#   cl <- seq(min(fdom$dom), max(fdom$dom),length.out = 4)
#   fdom$col <- findInterval(fdom$dom, cl,all.inside = T)
#
#   fdom[fdom$col == 1,"col"] <- "#4d343440"
#   fdom[fdom$col == 2,"col"] <- "#4d343470"
#   fdom[fdom$col == 3,"col"] <- "#4d3434"
#   #   fdom[fdom$dom <= .1,"col"] <- "#4d343410"
#   #   fdom[fdom$dom > .1,"col"] <-
#   #     paste("#4d3434", round(fdom[fdom$dom >.1,"dom"]*100), sep="")
#   #   fdom[fdom$dom >= 1,"col"] <- "#4d3434"
#
#   fdom <- fdom[order(-fdom$dom),]
#
#   sp::plot(spdf, col = "#cceae7", border = "grey70")
#
#   segments(fdom$Xi, fdom$Yi, fdom$Xj, fdom$Yj, col=fdom$col, lwd = 4)
#
#   symbols(x[,c("X","Y")], circles = x$cex, add = TRUE, bg = x$col,
#           fg ="grey50",
#           inches = FALSE)
#
#   legend(x = "topleft",
#          legend =  c("Dominant", "Dominant-Dominated", "Dominated",
#                      "Share of the sent flows :",
#                      paste("high (",round(cl[3]*100,0),"-",round(cl[4]*100,0),
#                            ")",sep = ""),
#                      paste("medium (",round(cl[2]*100,0),"-",round(cl[3]*100,0),
#                            ")",sep = ""),
#                      paste("low (",round(cl[1]*100,0),"-",round(cl[2]*100,0),
#                            ")",sep = "")),
#          col= c(rep("grey50",3),rep(NA,4)),
#          cex = 0.7,
#          pch = c(21,21,21,16,22,22,22),
#          pt.bg = c("#cc2a36", "#eb6841","#edc951","#ffffff00","#4d3434",
#                    "#4d343470","#4d343440"),
#          pt.cex = c(2,1,0.5,2,2,2,2))
#   if (!is.null(name)){
#     if(interactive()){
#       x <- locator()
#       if (!is.null(x)){
#         X <- sp::SpatialPoints(data.frame(x), proj4string = spdf@proj4string)
#         text(x = x$x, y = x$y, labels = sp::over(X, spdf)[,name], cex = 0.6,
#              adj = c(0,0))
#       }
#     } else {
#       text(x[x$col == "#cc2a36",c("X","Y")],labels = x[x$col == "#cc2a36", name],
#            cex = 0.6)
#     }
#   }
# }
