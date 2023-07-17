#' EDGE Estimator
#'
#' @param x \code{xts} object with columns named \code{Open}, \code{High}, \code{Low}, \code{Close}, representing OHLC prices.
#' @param width integer width of the rolling window to use, or vector of endpoints defining the intervals to use.
#' @param signed a \code{logical} value indicating whether signed estimates should be returned.
#' @param na.rm a \code{logical} value indicating whether \code{NA} values should be stripped before the computation proceeds. Default \code{FALSE}.
#' 
#' @return Time series of spread estimates.
#'
#' @keywords internal
#'
EDGE <- function(x, width = nrow(x), signed = FALSE, na.rm = FALSE){

  # to log
  x <- log(x)

  # prices
  O <- x$OPEN
  H <- x$HIGH
  L <- x$LOW
  C <- x$CLOSE
  M <- (H+L)/2

  # lag
  H1 <- lag(H, 1)
  L1 <- lag(L, 1)
  C1 <- lag(C, 1)
  M1 <- lag(M, 1)

  # returns
  r1 <- M-O
  r2 <- O-M1
  r3 <- M-C1
  r4 <- C1-M1
  r5 <- O-C1
  
  # define z
  z1 <- r1*r2 + r3*r4
  z2 <- r1*r5 + r5*r4
  
  # define tau
  tau <- H!=L | L!=C1 
  
  # define phi
  phi1 <- O!=H & tau 
  phi2 <- O!=L & tau 
  phi3 <- C1!=H1 & tau 
  phi4 <- C1!=L1 & tau 

  # compute means
  x <- cbind(
    z1, z2, z1^2, z2^2,
    r1, tau*r2, r3, tau*r4, r5,
    tau, phi1, phi2, phi3, phi4
  )
  m <- rmean(x[-1], width = width-1, na.rm = na.rm)
  
  # number of observations
  n <- rsum(!is.na(z1[-1]), width = width-1)

  # variances
  v1 <- m[,3] - m[,1]^2
  v2 <- m[,4] - m[,2]^2
  
  # weights
  w1 <- v2 / (v1 + v2)
  w2 <- 1 - w1
  
  # compute pi
  pi1 <- -1/8 * (m[,11] + m[,12])
  pi2 <- -1/8 * (m[,13] + m[,14]) 
  
  # compute square spread
  S2 <- n/(n-1) * (
      w1 * (m[,1] - (m[,5]*m[,6] + m[,7]*m[,8]) / m[,10]) + 
      w2 * (m[,2] - (m[,9]*m[,5] + m[,8]*m[,9]) / m[,10])
    ) / (pi1 + pi2)
    
  # formatting
  S2[is.infinite(S2)] <- NA
  colnames(S2) <- "EDGE"

  # signed square root
  S <- sign(S2) * sqrt(abs(S2))
  
  # unsigned spreads
  if(!signed) S <- abs(S)
  
  # return the spread
  return(S)

}

#' Efficient Estimation of Bid-Ask Spreads from OHLC Prices
#' 
#' This function implements the efficient estimator of the
#' bid-ask spread from open, high, low, and close prices as proposed 
#' in \href{https://www.ssrn.com/abstract=3892335}{Ardia, Guidotti, Kroencke (2021)}.
#' Prices must be sorted in ascending order of the timestamp.
#'
#' @param open numeric vector of open prices.
#' @param high numeric vector of high prices.
#' @param low numeric vector of low prices.
#' @param close numeric vector of close prices.
#' @param signed a \code{logical} value indicating whether signed estimates should be returned. See details.
#' @param na.rm a \code{logical} value indicating whether \code{NA} values should be stripped before the computation proceeds. Default \code{FALSE}.
#'
#' @details 
#' This estimators is formally an estimator for the mean square spread. 
#' In finite samples, the estimate of the square spread may become negative.
#' If \code{signed=TRUE}, then the function returns the signed root of the square spread:
#' \deqn{\hat{S} = sign(\hat{S^2})\times\sqrt{|\hat{S^2}|}}
#' Otherwise, the sign is ignored.
#' 
#' @return The (percent) spread estimate.
#'
#' @note 
#' Please cite \href{https://www.ssrn.com/abstract=3892335}{Ardia, Guidotti, Kroencke (2021)} 
#' when using this package in publication. Hint: type \code{citation("bidask")}
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
edge <- function(open, high, low, close, signed = FALSE, na.rm = FALSE){
  
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
  
  r1 <- m-o
  r2 <- o-m1
  r3 <- m-c1
  r4 <- c1-m1
  r5 <- o-c1
  
  z1 <- r1*r2 + r3*r4
  z2 <- r1*r5 + r5*r4
  
  tau <- h!=l | l!=c1 
  
  phi1 <- o!=h & tau
  phi2 <- o!=l & tau
  phi3 <- c1!=h1 & tau
  phi4 <- c1!=l1 & tau
  
  m1 <- mean(z1, na.rm = na.rm)
  m2 <- mean(z2, na.rm = na.rm)
  m3 <- mean(z1^2, na.rm = na.rm)
  m4 <- mean(z2^2, na.rm = na.rm)
  m5 <- mean(r1, na.rm = na.rm)
  m6 <- mean(r2*tau, na.rm = na.rm)
  m7 <- mean(r3, na.rm = na.rm)
  m8 <- mean(r4*tau, na.rm = na.rm)
  m9 <- mean(r5, na.rm = na.rm)
  m10 <- mean(tau, na.rm = na.rm)
  m11 <- mean(phi1, na.rm = na.rm)
  m12 <- mean(phi2, na.rm = na.rm)
  m13 <- mean(phi3, na.rm = na.rm)
  m14 <- mean(phi4, na.rm = na.rm)
  
  n <- sum(!is.na(z1))
  
  v1 <- m3 - m1^2
  v2 <- m4 - m2^2
  
  w1 <- v2 / (v1 + v2)
  w2 <- 1 - w1

  p1 <- -1/8 * (m11 + m12)
  p2 <- -1/8 * (m13 + m14)
  
  s2 <- n/(n-1) * (
    w1 * (m1 - (m5*m6 + m7*m8) / m10) +
    w2 * (m2 - (m9*m5 + m8*m9) / m10)
  ) / (p1 + p2)
    
  if(is.infinite(s2))
    return(NA)
  
  if(!signed)
    return(sqrt(abs(s2)))
  
  return(sign(s2) * sqrt(abs(s2)))
  
}
