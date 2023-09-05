#' OHLC Estimators
#'
#' @keywords internal
#'
OHLC <- function(x, width = nrow(x), method = "OHL.CHL.OHLC.CHLO", signed = FALSE, na.rm = FALSE){

  methods <- strsplit(method, split = ".", fixed = TRUE)

  m <- unique(unlist(methods))
  p <- unique(unlist(strsplit(m, split = "")))

  ok <- c("OHL","OHLC","CHL","CHLO")
  if(length(ko <- setdiff(m, ok)))
    stop(sprintf(
      "Method(s) '%s' not available. The available methods include '%s', or any combination of them, e.g. 'OHLC.CHLO'.",
       paste(ko, collapse = "', '"), paste(ok, collapse = "', '")
    ))

  x <- log(x)

  O <- x$OPEN
  C <- x$CLOSE
  H <- x$HIGH
  L <- x$LOW
  M <- (H+L)/2
  
  C1 <- lag(C)
  H1 <- lag(H)
  L1 <- lag(L)
  M1 <- lag(M)

  tau <- (H!=L | L!=C1)[-1]
  pt <- rmean(tau, width = width-1, na.rm = na.rm)
  
  if("OHL" %in% m | "OHLC" %in% m)
    po <- rmean((O!=H & tau) + (O!=L & tau), width = width-1, na.rm = na.rm)
  if("CHL" %in% m | "CHLO" %in% m)
    pc <- rmean((C1!=H1 & tau) + (C1!=L1 & tau), width = width-1, na.rm = na.rm)
  
  s2 <- function(r1, r2, pi){
    x <- cbind(r1*r2, r1, tau*r2)[-1]
    m <- rmean(x, width = width-1, na.rm = na.rm)
    -8 / pi * (m[,1] - (m[,2] * m[,3]) / pt)
  }
  
  if("OHL" %in% m)
    S2.OHL <- s2(M-O, O-M1, po)
  if("OHLC" %in% m)
    S2.OHLC <- s2(M-O, O-C1, po)
  if("CHL" %in% m)
    S2.CHL <- s2(M-C1, C1-M1, pc)
  if("CHLO" %in% m)
    S2.CHLO <- s2(O-C1, C1-M1, pc)

  S2 <- NULL
  for(m in methods){
    expr <- sprintf("(%s)/%s", paste0("S2.", m, collapse = "+"), length(m))
    S2 <- cbind(S2, eval(parse(text = expr)))
  }
  
  S2[is.infinite(S2)] <- NaN
  colnames(S2) <- method
  
  S <- sign(S2) * sqrt(abs(S2))
  if(!signed) S <- abs(S)
  
  return(S)
  
}
