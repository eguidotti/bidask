#' Roll Estimator
#'
#' @param x \code{xts} object with a column named \code{Close}, representing closing prices.
#' @param width integer width of the rolling window to use, or vector of endpoints defining the intervals to use.
#' @param signed a \code{logical} value indicating whether non-positive estimates should be preceded by the negative sign instead of being imputed. Default \code{FALSE}.
#' @param na.rm a \code{logical} value indicating whether \code{NA} values should be stripped before the computation proceeds. Default \code{FALSE}.
#'
#' @return Time series of spread estimates.
#'
#' @references
#' Roll, R. (1984). A simple implicit measure of the effective bid-ask spread in an efficient market. The Journal of Finance, 39 (4), 1127-1139.
#' \doi{10.1111/j.1540-6261.1984.tb03897.x}
#'
#' @keywords internal
#'
ROLL <- function(x, width = nrow(x), signed = FALSE, na.rm = FALSE){

  # compute returns
  R1 <- x$CLOSE/lag(x$CLOSE, 1) - 1
  R2 <- lag(R1, 1)

  # drop leading NA
  R1 <- R1[-1]
  R2 <- R2[-c(1:2)]

  # expectations
  E1 <- rmean(R1, width = width-1, na.rm = na.rm)
  E2 <- rmean(R2, width = width-2, na.rm = na.rm)
  E12 <- rmean(R1*R2, width = width-2, na.rm = na.rm)

  # squared spread
  S2 <- 4 * (E1*E2-E12)
  
  # square root
  S <- sign(S2) * sqrt(abs(S2))
  
  # negative estimates
  if(!signed) S[S<0] <- 0
  
  # set names
  colnames(S) <- "ROLL"

  # return
  return(S)

}
