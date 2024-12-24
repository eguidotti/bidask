#' Roll Estimator
#'
#' @keywords internal
#'
ROLL <- function(close, width, sign, na.rm){

  c <- log(close)
  c1 <- shift(c, 1)
  c2 <- shift(c, 2)
  
  r1 <- c - c1
  r2 <- c1 - c2
  
  shift <- 2
  x <- data.frame(r1, r2, r1*r2)
  m <- rmean(x, width = width, shift = shift, na.rm = na.rm)
  n <- rsum(!is.na(r2), width = width, shift = shift, na.rm = na.rm)
  
  s2 <- -4 * n/(n - 1) * (m[,3] - m[,1]*m[,2])
  s <- base::sign(s2) * sqrt(abs(s2))
  if(!sign) s <- abs(s)
  
  return(list("ROLL" = s))

}
