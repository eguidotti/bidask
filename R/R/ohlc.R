#' OHLC Estimators
#'
#' @param x \code{xts} object with columns named \code{Open}, \code{High}, \code{Low}, \code{Close}, representing OHLC prices.
#' @param width integer width of the rolling window to use, or vector of endpoints defining the intervals to use.
#' @param method one of \code{"OHL"}, \code{"OHLC"}, \code{"CHL"}, \code{"CHLO"}, or any combination of them, e.g. \code{"OHLC.CHLO"}.
#' @param signed a \code{logical} value indicating whether signed estimates should be returned.
#' @param na.rm a \code{logical} value indicating whether \code{NA} values should be stripped before the computation proceeds. Default \code{FALSE}.
#'
#' @return Time series of spread estimates.
#'
#' @keywords internal
#'
OHLC <- function(x, width = nrow(x), method = "OHL.OHLC.CHL.CHLO", signed = FALSE, na.rm = FALSE){

  # methods
  methods <- strsplit(method, split = ".", fixed = TRUE)

  # unique methods and prices
  m <- unique(unlist(methods))
  p <- unique(unlist(strsplit(m, split = "")))

  # check
  ok <- c("OHL","OHLC","CHL","CHLO")
  if(length(ko <- setdiff(m, ok)))
    stop(sprintf("Method(s) '%s' not available. The available methods include '%s', or any combination of them, e.g. 'OHLC.CHLO'.",
                 paste(ko, collapse = "', '"), paste(ok, collapse = "', '")))

  # to log
  x <- log(x)

  # prices
  if("O" %in% p){
    O <- x$OPEN
  }
  if("C" %in% p){
    C <- x$CLOSE
    C1 <- lag(C)
  }
  if("H" %in% p & "L" %in% p){
    H <- x$HIGH
    L <- x$LOW
    M <- (H+L)/2
    H1 <- lag(H)
    L1 <- lag(L)
    M1 <- lag(M)
  }

  # tau
  tau <- (H!=L | L!=C1)[-1]
  pt <- rmean(tau, width = width-1, na.rm = na.rm)
  
  # phi
  if("CHL" %in% m | "CHLO" %in% m)
    pc <- -1/8 * rmean((C1!=H1 & tau) + (C1!=L1 & tau), width = width-1, na.rm = na.rm)
  if("OHL" %in% m | "OHLC" %in% m)
    po <- -1/8 * rmean((O!=H & tau) + (O!=L & tau), width = width-1, na.rm = na.rm)
  
  # function to compute square spread 
  s2 <- function(r1, r2, pi){
    z <- cbind(r1*r2, r1, tau*r2)[-1]
    n <- rsum(!is.na(z[,1]), width = width-1)
    m <- rmean(z, width = width-1, na.rm = na.rm)
    n / (n-1) * (m[,1] - (m[,2] * m[,3]) / pt) / pi
  }
  
  # open estimators
  if("OHL" %in% m)
    S2.OHL <- s2(M-O, O-M1, po)
  if("OHLC" %in% m)
    S2.OHLC <- s2(M-O, O-C1, po)

  # close estimators
  if("CHL" %in% m)
    S2.CHL <- s2(M-C1, C1-M1, pc)
  if("CHLO" %in% m)
    S2.CHLO <- s2(O-C1, C1-M1, pc)

  # all estimators
  S2 <- NULL
  for(m in methods){
    expr <- sprintf("(%s)/%s", paste0("S2.", m, collapse = "+"), length(m))
    S2 <- cbind(S2, eval(parse(text = expr)))
  }
  
  # square root
  S <- sign(S2) * sqrt(abs(S2))
  
  # negative estimates
  if(!signed) S <- abs(S)
  
  # infinite estimates
  S[is.infinite(S)] <- NA
  
  # set names
  colnames(S) <- method

  # return
  return(S)

}
