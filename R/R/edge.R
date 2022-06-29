#' EDGE Estimator
#'
#' @param x \code{xts} object with columns named \code{Open}, \code{High}, \code{Low}, \code{Close}, representing OHLC prices.
#' @param width integer width of the rolling window to use, or vector of endpoints defining the intervals to use.
#' @param probs vector of probabilities to compute the critical values.
#' @param signed a \code{logical} value indicating whether non-positive estimates should be preceded by the negative sign instead of being imputed. Default \code{FALSE}.
#' @param na.rm a \code{logical} value indicating whether \code{NA} values should be stripped before the computation proceeds. Default \code{FALSE}.
#' 
#' @return Time series of spread estimates.
#'
#' @keywords internal
#'
EDGE <- function(x, width = nrow(x), probs = NULL, signed = FALSE, na.rm = FALSE){

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
  E <- rmean(cbind(X, V[-1]), width = width-1, na.rm = na.rm)
  
  # number of observations
  N <- rsum(!is.na(X[,1]), width = width-1)
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

  # square root
  S <- sign(S2) * sqrt(abs(S2))
  
  # set negative spreads to zero
  if(!signed) S[S<0] <- 0
  
  # return the spread
  return(S)

}

#' Efficient Estimation of Bid-Ask Spreads from OHLC Prices
#' 
#' This function implements an efficient estimator of the
#' effective bid-ask spread from open, high, low, and close prices as proposed 
#' in \href{https://www.ssrn.com/abstract=3892335}{Ardia, Guidotti, Kroencke (2021)}.
#'
#' @param open numeric vector of open prices.
#' @param high numeric vector of high prices.
#' @param low numeric vector of low prices.
#' @param close numeric vector of close prices.
#' @param na.rm a \code{logical} value indicating whether \code{NA} values should be stripped before the computation proceeds. Default \code{FALSE}.
#'
#' @details Prices must be sorted in ascending order of the timestamp.
#'
#' @return The (percent) spread estimate.
#'
#' @note 
#' \itemize{
#' \item Please cite \href{https://www.ssrn.com/abstract=3892335}{Ardia, Guidotti, Kroencke (2021)} 
#' when using this package in publication. Hint: type \code{citation("bidask")}
#' \item Place the URL \url{https://github.com/eguidotti/bidask} 
#' in a footnote when using this package in other online material.
#' }
#'
#' @references 
#' Ardia, D., Guidotti E., & Kroencke T. A. (2021). Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices. 
#' Available at SSRN: \url{https://www.ssrn.com/abstract=3892335}
#'
#' @examples
#' # simulate a price process with spread 1%
#' x <- sim(spread = 0.01)
#'
#' # estimate the spread
#' edge(x$Open, x$High, x$Low, x$Close)
#'
#' @export
#' 
edge <- function(open, high, low, close, na.rm = FALSE){
  
  n <- length(open)
  if(length(high) != n | length(low) != n | length(close) != n)
    stop("open, high, low, close must have the same length")
    
  o <- log(as.numeric(open))
  h <- log(as.numeric(high))
  l <- log(as.numeric(low))
  c <- log(as.numeric(close))
  m <- (h + l) / 2
  
  h1 <- h[-n]
  l1 <- l[-n]
  c1 <- c[-n]
  m1 <- m[-n]
  
  o <- o[-1]
  h <- h[-1]
  l <- l[-1]
  c <- c[-1]
  m <- m[-1]
  
  x1 <- (m-o)*(o-m1) + (m-c1)*(c1-m1)
  x2 <- (m-o)*(o-c1) + (o-c1)*(c1-m1)
  
  e1 <- mean(x1, na.rm = na.rm)
  e2 <- mean(x2, na.rm = na.rm)
  
  v1 <- var(x1, na.rm = na.rm)
  v2 <- var(x2, na.rm = na.rm)
  
  w1 <- v2/(v1+v2)
  w2 <- v1/(v1+v2)
  k <- 4 * w1 * w2
  
  n1 <- mean(o==h, na.rm = na.rm)
  n2 <- mean(o==l, na.rm = na.rm)
  n3 <- mean(c1==h1, na.rm = na.rm)
  n4 <- mean(c1==l1, na.rm = na.rm)
  n5 <- mean(h==l & l==c1, na.rm = na.rm)
  
  s2 <- -4*(w1*e1+w2*e2)/((1-k*(n1+n2)/2)+(1-n5)*(1-k*(n3+n4)/2))
  
  return(sqrt(max(0, s2)))
  
}
