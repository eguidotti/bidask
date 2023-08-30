#' Roll Estimator
#'
#' @keywords internal
#'
ROLL <- function(x, width = nrow(x), signed = FALSE, na.rm = FALSE){

  x <- log(x)
  
  C <- x$CLOSE
  C1 <- lag(C, 1)
  C2 <- lag(C, 2)
  
  R1 <- C - C1
  R2 <- C1 - C2
  
  N <- xts::xts(!is.na(R2), order.by = zoo::index(R2))[-(1:2)]
  
  m <- rmean(cbind(R1, R2, R1*R2)[-(1:2),], width = width-2, na.rm = na.rm)
  n <- rsum(N, width = width-2)
  
  S2 <- -4 * n/(n-1) * (m[,3] - m[,1]*m[,2])
  colnames(S2) <- "ROLL"
  
  S <- sign(S2) * sqrt(abs(S2))
  if(!signed) S <- abs(S)
  
  return(S)

}
