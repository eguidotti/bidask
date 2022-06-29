#' OHLC Estimators
#'
#' @param x \code{xts} object with columns named \code{Open}, \code{High}, \code{Low}, \code{Close}, representing OHLC prices.
#' @param width integer width of the rolling window to use, or vector of endpoints defining the intervals to use.
#' @param method one of \code{"O"}, \code{"OC"}, \code{"OHL"}, \code{"OHLC"}, \code{"C"}, \code{"CO"}, \code{"CHL"}, \code{"CHLO"}, or any combination of them, e.g. \code{"OHLC.CHLO"}.
#' @param signed a \code{logical} value indicating whether non-positive estimates should be preceded by the negative sign instead of being imputed. Default \code{FALSE}.
#' @param na.rm a \code{logical} value indicating whether \code{NA} values should be stripped before the computation proceeds. Default \code{FALSE}.
#'
#' @return Time series of spread estimates.
#'
#' @keywords internal
#'
OHLC <- function(x, width = nrow(x), method = "OHLC.CHLO", signed = FALSE, na.rm = FALSE){

  # methods
  methods <- strsplit(method, split = ".", fixed = TRUE)

  # unique methods and prices
  m <- unique(unlist(methods))
  p <- unique(unlist(strsplit(m, split = "")))

  # check
  ok <- c("O","OC","OHL","OHLC","C","CO","CHL","CHLO")
  if(length(ko <- setdiff(m, ok)))
    stop(sprintf("Method(s) '%s' not available. The available methods include '%s', or any combination of them, e.g. 'OHLC.CHLO'.",
                 paste(ko, collapse = "', '"), paste(ok, collapse = "', '")))

  # to log
  x <- log(x)

  # prices
  if("O" %in% p){
    O <- x$OPEN
    O1 <- lag(O, 1)[-1]
    O2 <- lag(O1,1)[-1]
  }
  if("C" %in% p){
    C <- x$CLOSE
    C1 <- lag(C, 1)[-1]
    C2 <- lag(C1,1)[-1]
  }
  if("H" %in% p & "L" %in% p){
    H <- x$HIGH
    L <- x$LOW
    M <- (H+L)/2
    H1 <- lag(H, 1)[-1]
    L1 <- lag(L, 1)[-1]
    M1 <- lag(M, 1)[-1]
  }

  # frequency
  if("O" %in% m)
    v.oo <- rmean(O==O1, width = width-1, na.rm = na.rm)
  if("C" %in% m)
    v.cc <- rmean(C==C1, width = width-1, na.rm = na.rm)
  if("OC" %in% m | "CO" %in% m)
    v.oc <- rmean(O==C, width = width, na.rm = na.rm)
  if("CO" %in% m)
    v.occ <- rmean(O==C & C==C1, width = width-1, na.rm = na.rm)
  if("CHL" %in% m | "CHLO" %in% m)
    v.hlc <- rmean(H==L & L==C1, width = width-1, na.rm = na.rm)
  if("OHL" %in% m | "OHLC" %in% m)
    v.ohl <- rmean((O==H)/2 + (O==L)/2, width = width, na.rm = na.rm)
  if("CHL" %in% m | "CHLO" %in% m)
    v.chl <- rmean((C1==H1)/2 + (C1==L1)/2, width = width-1, na.rm = na.rm)

  # open estimators
  if("O" %in% m)
    S2.O <- -4*rmean((O-O1)*(O1-O2), width = width-2, na.rm = na.rm)/(1-v.oo)^2
  if("OC" %in% m)
    S2.OC <- -4*rmean((C-O)*(O-C1), width = width-1, na.rm = na.rm)/(1-v.oc)
  if("OHL" %in% m)
    S2.OHL <- -4*rmean((M-O)*(O-M1), width = width-1, na.rm = na.rm)/(1-v.ohl)
  if("OHLC" %in% m)
    S2.OHLC <- -4*rmean((M-O)*(O-C1), width = width-1, na.rm = na.rm)/(1-v.ohl)

  # close estimators
  if("C" %in% m)
    S2.C <- -4*rmean((C-C1)*(C1-C2), width = width-2, na.rm = na.rm)/(1-v.cc)^2
  if("CO" %in% m)
    S2.CO <- -4*rmean((O-C1)*(C1-O1), width = width-1, na.rm = na.rm)/(1-v.occ)/(1-v.oc)
  if("CHL" %in% m)
    S2.CHL <- -4*rmean((M-C1)*(C1-M1), width = width-1, na.rm = na.rm)/(1-v.hlc)/(1-v.chl)
  if("CHLO" %in% m)
    S2.CHLO <- -4*rmean((O-C1)*(C1-M1), width = width-1, na.rm = na.rm)/(1-v.hlc)/(1-v.chl)

  # all estimators
  S2 <- NULL
  for(m in methods){
    expr <- sprintf("(%s)/%s", paste0("S2.", m, collapse = "+"), length(m))
    S2 <- cbind(S2, eval(parse(text = expr)))
  }
  
  # square root
  S <- sign(S2) * sqrt(abs(S2))
  
  # negative estimates
  if(!signed) S[S<0] <- 0
  
  # infinite estimates
  S[is.infinite(S)] <- NA
  
  # set names
  colnames(S) <- method

  # return
  return(S)

}
