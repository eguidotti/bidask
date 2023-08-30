#' @keywords internal
"_PACKAGE"

#' @import xts
#' @importFrom stats lag rbinom rnorm
NULL

#' Rolling sum
#' 
#' @keywords internal
#' 
rsum <- function(x, width, na.rm = FALSE){
  
  if(length(width) == 1 && width == nrow(x))
    width <- c(0, width)
  
  if(length(width) > 1)
    return(xts::period.apply(x, INDEX = width[width>=0], FUN = colSums, na.rm = na.rm))

  return(zoo::rollsumr(x, k = width, na.rm = na.rm))

}

#' Rolling mean
#' 
#' @keywords internal
#' 
rmean <- function(x, width, na.rm = FALSE){

  if(length(width) == 1 && width == nrow(x))
    width <- c(0, width)
  
  if(length(width) > 1)
    return(xts::period.apply(x, INDEX = width[width>=0], FUN = colMeans, na.rm = na.rm))

  return(zoo::rollmeanr(x, k = width, na.rm = na.rm))

}
