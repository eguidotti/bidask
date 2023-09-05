#' EDGE Estimator
#'
#' @keywords internal
#'
EDGE <- function(x, width = nrow(x), signed = FALSE, na.rm = FALSE){
  
  x <- log(x)

  O <- x$OPEN
  H <- x$HIGH
  L <- x$LOW
  C <- x$CLOSE
  M <- (H+L)/2
  
  H1 <- lag(H, 1)
  L1 <- lag(L, 1)
  C1 <- lag(C, 1)
  M1 <- lag(M, 1)

  r1 <- M-O
  r2 <- O-M1
  r3 <- M-C1
  r4 <- C1-M1
  r5 <- O-C1
  
  tau  <- H!=L | L!=C1 
  phi1 <- O!=H & tau 
  phi2 <- O!=L & tau 
  phi3 <- C1!=H1 & tau 
  phi4 <- C1!=L1 & tau 

  x <- cbind(
    r1*r2,        # 1
    r3*r4,        # 2
    r1*r5,        # 3
    r5*r4,        # 4
    tau,          # 5
    r1,           # 6
    tau*r2,       # 7
    r3,           # 8
    tau*r4,       # 9
    r5,           # 10
    r1^2*r2^2,    # 11
    r3^2*r4^2,    # 12
    r1^2*r5^2,    # 13
    r4^2*r5^2,    # 14
    r1*r2*r3*r4,  # 15
    r1*r4*r5^2,   # 16
    tau*r2^2,     # 17
    tau*r4^2,     # 18
    tau*r5^2,     # 19
    tau*r1*r2^2,  # 20
    tau*r3*r4^2,  # 21
    tau*r1*r5^2,  # 22
    tau*r5*r4^2,  # 23
    tau*r1*r2*r4, # 24
    tau*r2*r3*r4, # 25
    tau*r2*r4,    # 26
    tau*r1*r4*r5, # 27
    tau*r4*r5^2,  # 28
    tau*r4*r5,    # 29
    tau*r5,       # 30
    phi1,         # 31
    phi2,         # 32
    phi3,         # 33
    phi4          # 34
  )
  
  m <- rmean(x[-1], width = width-1, na.rm = na.rm)
  
  po <- -8 / (m[,31] + m[,32])
  pc <- -8 / (m[,33] + m[,34])
  
  e1 <- po/2 * (m[,1] - m[,6]*m[,7]/m[,5]) + 
    pc/2 * (m[,2] - m[,8]*m[,9]/m[,5])
  
  e2 <- po/2 * (m[,3] - m[,6]*m[,30]/m[,5]) + 
    pc/2 * (m[,4] - m[,10]*m[,9]/m[,5])
  
  v1 <- po^2/4 * (m[,11] + m[,6]^2*m[,17]/m[,5]^2 - 2*m[,20]*m[,6]/m[,5]) +
    pc^2/4 * (m[,12] + m[,8]^2*m[,18]/m[,5]^2 - 2*m[,21]*m[,8]/m[,5]) +
    po*pc/2 * (m[,15] - m[,24]*m[,8]/m[,5] - m[,6]*m[,25]/m[,5] + m[,6]*m[,8]*m[,26]/m[,5]^2) - 
    e1^2
  
  v2 <- po^2/4 * (m[,13] + m[,6]^2*m[,19]/m[,5]^2 - 2*m[,22]*m[,6]/m[,5]) +
    pc^2/4 * (m[,14] + m[,10]^2*m[,18]/m[,5]^2 - 2*m[,23]*m[,10]/m[,5]) +
    po*pc/2 * (m[,16] - m[,27]*m[,10]/m[,5] - m[,6]*m[,28]/m[,5] + m[,6]*m[,10]*m[,29]/m[,5]^2) -
    e2^2
  
  S2 <- (v2*e1 + v1*e2) / (v1 + v2)
  S2[is.infinite(S2)] <- NaN
  colnames(S2) <- "EDGE"

  S <- sign(S2) * sqrt(abs(S2))
  if(!signed) S <- abs(S)
  
  return(S)
  
}

#' Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices
#' 
#' Implements an efficient estimator of bid-ask spreads 
#' from open, high, low, and close prices as described in 
#' \href{https://www.ssrn.com/abstract=3892335}{Ardia, Guidotti, & Kroencke (2021)}.
#' 
#' @details
#' Prices must be sorted in ascending order of the timestamp.
#'
#' @param open numeric vector of open prices.
#' @param high numeric vector of high prices.
#' @param low numeric vector of low prices.
#' @param close numeric vector of close prices.
#' @param signed whether signed estimates should be returned.
#' @param na.rm whether missing values should be ignored.
#'
#' @return The spread estimate. A value of 0.01 corresponds to a spread of 1\%.
#'
#' @note 
#' Please cite \href{https://www.ssrn.com/abstract=3892335}{Ardia, Guidotti, & Kroencke (2021)} 
#' when using this package in publication.
#'
#' @references 
#' Ardia, D., Guidotti E., & Kroencke T. A. (2021). Efficient Estimation of Bid-Ask Spreads from Open, High, Low, and Close Prices. 
#' Available at SSRN: \url{https://www.ssrn.com/abstract=3892335}
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
  
  tau  <- h!=l | l!=c1 
  phi1 <- o!=h & tau
  phi2 <- o!=l & tau
  phi3 <- c1!=h1 & tau
  phi4 <- c1!=l1 & tau
  
  pt <- mean(tau, na.rm = na.rm)
  po <- mean(phi1, na.rm = na.rm) + mean(phi2, na.rm = na.rm)
  pc <- mean(phi3, na.rm = na.rm) + mean(phi4, na.rm = na.rm)
  
  if(is.na(pt) | is.na(po) | is.na(pc) | pt == 0 | po == 0 | pc == 0)
    return(NaN)
  
  r1 <- m-o
  r2 <- o-m1
  r3 <- m-c1
  r4 <- c1-m1
  r5 <- o-c1
  
  d1 <- r1 - tau * mean(r1, na.rm = na.rm) / pt
  d3 <- r3 - tau * mean(r3, na.rm = na.rm) / pt
  d5 <- r5 - tau * mean(r5, na.rm = na.rm) / pt
  
  x1 <- -4/po*d1*r2 -4/pc*d3*r4 
  x2 <- -4/po*d1*r5 -4/pc*d5*r4 
  
  e1  <- mean(x1, na.rm = na.rm)
  e2  <- mean(x2, na.rm = na.rm)
  
  v1 <- mean(x1^2, na.rm = na.rm) - e1^2
  v2 <- mean(x2^2, na.rm = na.rm) - e2^2

  s2 <- (v2*e1 + v1*e2) / (v1 + v2)
  
  s <- sqrt(abs(s2))
  if(signed)
    s <- s * sign(s2)
  
  return(s)
  
}
