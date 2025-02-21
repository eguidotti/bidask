#' @keywords internal
"_PACKAGE"
.onLoad <- function(libname, pkgname) {
  if(Sys.getenv("_R_CHECK_LIMIT_CORES_", FALSE) == TRUE){
    setDTthreads(2)
  }
}

#' @import data.table
#' @importFrom stats rbinom rnorm
NULL

#' Rolling function
#' 
#' @keywords internal
#' 
rfun <- function(froll, x, width, shift, na.rm){
  
  nw <- length(width)
  nc <- ncol(x); nr <- nrow(x)
  if(is.null(nr)) nr <- length(x)
  
  n <- width - shift
  if(nw != 1 && nw != nr){
    n <- rep(0, nr)
    n[width[-1]] <- diff(pmax(1, width))
  }
  
  if(nw == 1 && n < 1){
    if(is.null(nc)) return(rep(NA, nr))
    return(as.data.frame(matrix(data = NA, nrow = nr, ncol = nc)))
  }
  
  y <- froll(x, n = n, na.rm = na.rm, adaptive = nw > 1, fill = NA)
  if(is.list(y)) setDF(y)
  
  if(nw == 1 && width > 1){
    if(is.data.frame(y)) y[1:(width-1),] <- NA
    else y[1:(width-1)] <- NA
  }

  return(y)
  
}

#' #' Rolling sum
#' 
#' @keywords internal
#' 
rsum <- function(x, width, shift, na.rm){
  
  rfun(frollsum, x, width, shift, na.rm)

}

#' Rolling mean
#' 
#' @keywords internal
#' 
rmean <- function(x, width, shift, na.rm){

  rfun(frollmean, x, width, shift, na.rm)
  
}
