#' Roll Estimator
#'
#' @keywords internal
#'
ROLL <- function(x, width = nrow(x), signed = FALSE, na.rm = FALSE){

  R1 <- x$CLOSE/lag(x$CLOSE, 1) - 1
  R2 <- lag(R1, 1)

  R1 <- R1[-c(1:2)]
  R2 <- R2[-c(1:2)]

  E1 <- rmean(R1, width = width-2, na.rm = na.rm)
  E2 <- rmean(R2, width = width-2, na.rm = na.rm)
  E12 <- rmean(R1*R2, width = width-2, na.rm = na.rm)

  N <- rsum(!is.na(R2), width = width-2)
  
  S2 <- N / (N-1) * 4 * (E1*E2-E12)
  colnames(S2) <- "ROLL"
  
  S <- sign(S2) * sqrt(abs(S2))
  if(!signed) S <- abs(S)
  
  return(S)

}
