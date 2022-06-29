#' GMM Estimator
#'
#' @param x \code{xts} object with columns named \code{Open}, \code{High}, \code{Low}, \code{Close}, representing OHLC prices.
#' @param width integer width of the rolling window to use, or vector of endpoints defining the intervals to use.
#' @param signed a \code{logical} value indicating whether non-positive estimates should be preceded by the negative sign instead of being imputed. Default \code{FALSE}.
#' @param na.rm a \code{logical} value indicating whether \code{NA} values should be stripped before the computation proceeds. Default \code{FALSE}.
#'
#' @return Time series of spread estimates.
#'
#' @keywords internal
#'
GMM <- function(x, width = nrow(x), signed = FALSE, na.rm = FALSE){

  # to log
  x <- log(x)
  
  # GMM
  GMM <- function(x){
    
    # prices
    O <- x$OPEN
    H <- x$HIGH
    L <- x$LOW
    C <- x$CLOSE
    M <- (H+L)/2
    
    # first lag
    O1 <- lag(O, 1)[-1]
    H1 <- lag(H, 1)[-1]
    L1 <- lag(L, 1)[-1]
    C1 <- lag(C, 1)[-1]
    M1 <- lag(M, 1)[-1]
    
    # second lag
    O2 <- lag(O1, 1)[-1]
    C2 <- lag(C1, 1)[-1]
    
    # adjustments for infrequent trading
    V.OO  <- mean(O==O1, na.rm = na.rm)
    V.CC  <- mean(C==C1, na.rm = na.rm)
    V.OC  <- mean(O==C, na.rm = na.rm)
    V.OCC <- mean(O==C & C==C1, na.rm = na.rm)
    V.HLC <- mean(H==L & L==C1, na.rm = na.rm)
    V.OHL <- mean(((O==H)+(O==L))/2, na.rm = na.rm)
    V.CHL <- mean(((C==H)+(C==L))/2, na.rm = na.rm)
    
    # vectors derived from log-returns
    x$O    <- -4*(O-O1)*(O1-O2)/(1-V.OO)^2
    x$OC   <- -4*(C-O)*(O-C1)/(1-V.OC)
    x$OHL  <- -4*(M-O)*(O-M1)/(1-V.OHL)
    x$OHLC <- -4*(M-O)*(O-C1)/(1-V.OHL)
    x$C    <- -4*(C-C1)*(C1-C2)/(1-V.CC)^2
    x$CO   <- -4*(O-C1)*(C1-O1)/(1-V.OCC)/(1-V.OC)
    x$CHL  <- -4*(M-C1)*(C1-M1)/(1-V.HLC)/(1-V.CHL)
    x$CHLO <- -4*(O-C1)*(C1-M1)/(1-V.HLC)/(1-V.CHL)
    
    # pair-wise average
    x <- cbind((x$O+x$C)/2, (x$OC+x$CO)/2, (x$OHL+x$CHL)/2, (x$OHLC+x$CHLO)/2)
    x <- x[-c(1:2),]
    
    # compute squared spread and variances
    S2 <- colMeans(x, na.rm = na.rm)
    V <- stats::var(x, na.rm = na.rm)
    
    # compute optimal weights
    W <- solve(V)
    W <- rowSums(W)/sum(W)
    
    # return the squared spread    
    sum(W*S2)
    
  }
  
  # squared spread
  S2 <- rapply(x, width = width, FUN = GMM, by.column = FALSE)
  S2[is.infinite(S2)] <- NA
  
  # square root
  S <- sign(S2) * sqrt(abs(S2))
  
  # negative estimates
  if(!signed) S[S<0] <- 0

  # set names
  colnames(S) <- "GMM"

  # return
  return(S)

}
