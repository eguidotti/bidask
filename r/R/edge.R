#' EDGE Estimator
#'
#' @keywords internal
#'
EDGE <- function(x, width = nrow(x), sign, na.rm){
  
  # compute log-prices
  x <- log(x)
  o <- x$OPEN
  h <- x$HIGH
  l <- x$LOW
  c <- x$CLOSE
  m <- (h + l) / 2
  
  # shift log-prices by one period
  h1 <- lag(h, 1)
  l1 <- lag(l, 1)
  c1 <- lag(c, 1)
  m1 <- lag(m, 1)

  # compute log-returns
  r1 <- m - o
  r2 <- o - m1
  r3 <- m - c1
  r4 <- c1 - m1
  r5 <- o - c1
  
  # compute indicator variables
  tau <- h != l | l != c1 
  po1 <- tau & o != h
  po2 <- tau & o != l
  pc1 <- tau & c1 != h1
  pc2 <- tau & c1 != l1

  # compute base products for rolling means
  r12 <- r1 * r2
  r15 <- r1 * r5
  r34 <- r3 * r4
  r45 <- r4 * r5
  tr1 <- tau * r1
  tr2 <- tau * r2
  tr4 <- tau * r4
  tr5 <- tau * r5
  
  # set up data frame for rolling means
  x <- cbind(
    r12,
    r34,
    r15,
    r45,
    tau,
    r1,
    tr2,
    r3,
    tr4,
    r5,
    r12^2,
    r34^2,
    r15^2,
    r45^2,
    r12 * r34,
    r15 * r45,
    tr2 * r2,
    tr4 * r4,
    tr5 * r5,
    tr2 * r12,
    tr4 * r34,
    tr5 * r15,
    tr4 * r45,
    tr4 * r12,
    tr2 * r34,
    tr2 * r4,
    tr1 * r45,
    tr5 * r45,
    tr4 * r5,
    tr5,
    po1,
    po2,
    pc1,
    pc2
  )
  
  # mask the first observation and decrement width by 1 before 
  # computing rolling means to account for lagged prices
  x <- x[-1]
  width = width - 1
  
  # compute rolling means
  m <- rmean(x, width = width, na.rm = na.rm)
  
  # compute probabilities
  pt <- m[,5]
  po <- m[,31] + m[,32]
  pc <- m[,33] + m[,34]
  
  # set to missing if there are less than two periods with tau=1
  # or po or pc is zero
  nt <- rsum(x[,5], width = width, na.rm = TRUE)
  m[nt < 2 | (!is.nan(po) & po == 0) | (!is.nan(pc) & pc == 0)] <- NaN
  
  # compute input vectors
  a1 <- -4. / po
  a2 <- -4. / pc
  a3 <- m[,6] / pt
  a4 <- m[,9] / pt
  a5 <- m[,8] / pt
  a6 <- m[,10] / pt
  a12 <- 2 * a1 * a2
  a11 <- a1^2
  a22 <- a2^2
  a33 <- a3^2
  a55 <- a5^2
  a66 <- a6^2
  
  # compute expectations
  e1 <- a1 * (m[,1] - a3*m[,7]) + a2 * (m[,2] - a4*m[,8])
  e2 <- a1 * (m[,3] - a3*m[,30]) + a2 * (m[,4] - a4*m[,10])
  
  # compute variances
  v1 <- - e1^2 + (
    a11 * (m[,11] - 2*a3*m[,20] + a33*m[,17]) +
    a22 * (m[,12] - 2*a5*m[,21] + a55*m[,18]) +
    a12 * (m[,15] - a3*m[,25] - a5*m[,24] + a3*a5*m[,26])
  )
  v2 <- - e2^2 + (
    a11 * (m[,13] - 2*a3*m[,22] + a33*m[,19]) + 
    a22 * (m[,14] - 2*a6*m[,23] + a66*m[,18]) +
    a12 * (m[,16] - a3*m[,28] - a6*m[,27] + a3*a6*m[,29]) 
  )
  
  # compute square spread by using a (equally) weighted 
  # average if the total variance is (not) positive
  vt <- v1 + v2
  s2 <- ifelse(!is.na(vt) & vt > 0, (v2*e1 + v1*e2) / vt, (e1 + e2) / 2.)
  colnames(s2) <- "EDGE"
  
  # compute signed root
  s <- sqrt(abs(s2))
  if(sign) 
    s <- s * base::sign(s2)
  
  # return the spread
  return(s)
  
}

#' Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices
#' 
#' Implements the efficient estimator of bid-ask spreads from open, high, low, 
#' and close prices described in Ardia, Guidotti, & Kroencke (JFE, 2024):
#' \doi{10.1016/j.jfineco.2024.103916}
#' 
#' @details
#' Prices must be sorted in ascending order of the timestamp.
#'
#' @param open numeric vector of open prices.
#' @param high numeric vector of high prices.
#' @param low numeric vector of low prices.
#' @param close numeric vector of close prices.
#' @param sign whether to return signed estimates.
#'
#' @return The spread estimate. A value of 0.01 corresponds to a spread of 1\%.
#'
#' @references 
#' Ardia, D., Guidotti, E., Kroencke, T.A. (2024). Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices. Journal of Financial Economics, 161, 103916. 
#' \doi{10.1016/j.jfineco.2024.103916}
#'
#' @examples
#' # simulate open, high, low, and close prices with spread 1%
#' x <- sim(spread = 0.01)
#'
#' # estimate the spread
#' edge(x$Open, x$High, x$Low, x$Close)
#'
#' @export
#' 
edge <- function(open, high, low, close, sign = FALSE){
  
  # check that the open, high, low, and close prices have the same length
  n <- length(open)
  if(length(high) != n | length(low) != n | length(close) != n)
    stop("open, high, low, close must have the same length")
  
  # return missing if there are less than 3 observations
  if(n < 3)
    return(NaN)
  
  # compute log-prices
  o <- log(as.numeric(open))
  h <- log(as.numeric(high))
  l <- log(as.numeric(low))
  c <- log(as.numeric(close))
  m <- (h + l) / 2
  
  # shift log-prices by one period
  h1 <- h[-n]; l1 <- l[-n]; c1 <- c[-n]; m1 <- m[-n]
  o <- o[-1]; h <- h[-1]; l <- l[-1]; c <- c[-1]; m <- m[-1]
  
  # compute log-returns
  r1 <- m - o
  r2 <- o - m1
  r3 <- m - c1
  r4 <- c1 - m1
  r5 <- o - c1
  
  # compute indicator variables
  tau <- h != l | l != c1 
  po1 <- tau & o != h
  po2 <- tau & o != l
  pc1 <- tau & c1 != h1
  pc2 <- tau & c1 != l1
  
  # compute probabilities
  pt <- mean(tau, na.rm = TRUE)
  po <- mean(po1, na.rm = TRUE) + mean(po2, na.rm = TRUE)
  pc <- mean(pc1, na.rm = TRUE) + mean(pc2, na.rm = TRUE)
  
  # return missing if there are less than two periods with tau=1 
  # or po or pc is zero
  nt <- sum(tau, na.rm = TRUE)
  if(nt < 2 | (!is.nan(po) & po == 0) | (!is.nan(pc) & pc == 0))
    return(NaN)
  
  # compute de-meaned log-returns
  d1 <- r1 - mean(r1, na.rm = TRUE)/pt*tau
  d3 <- r3 - mean(r3, na.rm = TRUE)/pt*tau
  d5 <- r5 - mean(r5, na.rm = TRUE)/pt*tau
  
  # compute input vectors
  x1 <- -4./po*d1*r2 + -4./pc*d3*r4 
  x2 <- -4./po*d1*r5 + -4./pc*d5*r4
  
  # compute expectations
  e1 <- mean(x1, na.rm = TRUE)
  e2 <- mean(x2, na.rm = TRUE)
  
  # compute variances
  v1 <- mean(x1^2, na.rm = TRUE) - e1^2
  v2 <- mean(x2^2, na.rm = TRUE) - e2^2

  # compute square spread by using a (equally) weighted 
  # average if the total variance is (not) positive
  vt = v1 + v2
  if(!is.na(vt) & vt > 0)
    s2 = (v2*e1 + v1*e2) / vt
  else
    s2 = (e1 + e2) / 2.
  
  # compute signed root
  s <- sqrt(abs(s2))
  if(sign) 
    s <- s * base::sign(s2)
  
  # return the spread
  return(s)
  
}
