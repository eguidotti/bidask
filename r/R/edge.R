#' EDGE Estimator
#'
#' @param x \code{xts} object with columns named \code{Open}, \code{High}, \code{Low}, \code{Close}, representing OHLC prices.
#' @param width integer width of the rolling window to use, or vector of endpoints defining the intervals to use.
#' @param probs vector of probabilities to compute the critical values.
#' @param na.rm a \code{logical} value indicating whether \code{NA} values should be stripped before the computation proceeds.
#' @param trim the fraction (0 to 0.5) of observations to be trimmed from each end before the spread is computed. Values of trim outside that range are taken as the nearest endpoint.
#'
#' @return Time series of spread estimates.
#'
#' @keywords internal
#'
EDGE <- function(x, width = nrow(x), probs = c(0.025, 0.975), na.rm = FALSE, trim = 0){

  # to log
  x <- log(x)

  # prices
  O <- x$OPEN
  H <- x$HIGH
  L <- x$LOW
  C <- x$CLOSE
  M <- (H+L)/2

  # lag
  H1 <- lag(H, 1)[-1]
  L1 <- lag(L, 1)[-1]
  C1 <- lag(C, 1)[-1]
  M1 <- lag(M, 1)[-1]

  # vectors derived from log-returns
  X1 <- (M-O)*(O-M1)+(M-C1)*(C1-M1)
  X2 <- (M-O)*(O-C1)+(O-C1)*(C1-M1)

  # means
  X <- cbind(X1, X2, X1^2, X2^2, X1*X2)
  V <- cbind(((O==H)+(O==L))/2, ((C1==H1)+(C1==L1))/2, H==L & L==C1)
  E <- rmean(cbind(X, V[-1]), width = width-1, na.rm = na.rm, trim = trim)
  
  # number of observations
  N <- rsum(!is.na(X[,1]), width = width-1)
  N <- N - 2 * as.integer(N*trim)
  J <- N/(N-1)

  # variance
  V11 <- J*(E[,3]-E[,1]^2)
  V22 <- J*(E[,4]-E[,2]^2)
  V12 <- J*(E[,5]-E[,1]*E[,2])

  # weights
  W1 <- V22/(V11+V22)
  W2 <- 1-W1
  
  # adjustment for infrequent trading
  K <- 4*W1*W2
  D <- (1-K*E[,6])+(1-E[,8])*(1-K*E[,7])
  
  # compute the square spread
  S2 <- -4*(W1*E[,1]+W2*E[,2])/D
  S2[is.infinite(S2)] <- NA
  colnames(S2) <- "EDGE"

  # confidence intervals
  if(!is.null(probs)){
    stdev <- 4*sqrt(W1^2*V11+W2^2*V22+2*W1*W2*V12)/D
    for(p in probs) S2 <- cbind(S2, S2[,1]+stdev/sqrt(N)*qt(p = p, df = N-1))
    colnames(S2)[2:ncol(S2)] <- sprintf("EDGE_%s", probs*100)
  }

  # set negative spreads to zero
  S2[S2<0] <- 0
  
  # return the spread
  return(sqrt(S2))

}
