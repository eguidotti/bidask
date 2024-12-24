#' OHLC Estimators
#'
#' @keywords internal
#'
OHLC <- function(open, high, low, close, width, method, sign, na.rm){

  splitmethods <- strsplit(method, split = ".", fixed = TRUE)
  uniquemethods <- unique(unlist(splitmethods))
  ok <- c("OHL","OHLC","CHL","CHLO")
  if(length(ko <- setdiff(uniquemethods, ok)))
    stop(sprintf(
      "Method(s) '%s' not available. The available methods include '%s', or any combination of them, e.g. 'OHLC.CHLO'.",
       paste(ko, collapse = "', '"), paste(ok, collapse = "', '")
    ))

  o <- log(open)
  h <- log(high)
  l <- log(low)
  c <- log(close)
  m <- (h + l) / 2
  
  c1 <- shift(c, 1)
  h1 <- shift(h, 1)
  l1 <- shift(l, 1)
  m1 <- shift(m, 1)

  if(length(c1) == 0) c1 <- rep(NA, length(h))
  tau <- ifelse(is.na(h) | is.na(l), NA, h != l | l != c1)
  tau[1] <- NA
  
  shift <- 1
  pt <- rmean(tau, width = width, shift = shift, na.rm = na.rm)
  nt <- rsum(tau, width = width, shift = shift, na.rm = TRUE)
  
  if("OHL" %in% uniquemethods | "OHLC" %in% uniquemethods){
    po1 <- rmean(tau * (o != h), width = width, shift = shift, na.rm = na.rm)
    po2 <- rmean(tau * (o != l), width = width, shift = shift, na.rm = na.rm)
    po <- po1 + po2
  }
  
  if("CHL" %in% uniquemethods | "CHLO" %in% uniquemethods){
    pc1 <- rmean(tau * (c1 != h1), width = width, shift = shift, na.rm = na.rm)
    pc2 <- rmean(tau * (c1 != l1), width = width, shift = shift, na.rm = na.rm)
    pc <- pc1 + pc2
  }
  
  s2 <- function(r1, r2, pi){
    x <- data.frame(r1*r2, r1, tau*r2); x[1,] <- NA
    m <- rmean(x, width = width, shift = shift, na.rm = na.rm)
    m[which(nt < 2 | pi == 0),] <- NA
    -8 / pi * (m[,1] - (m[,2] * m[,3]) / pt)
  }
  
  if("OHL" %in% uniquemethods)
    s2.OHL <- s2(m - o, o - m1, po)
  if("OHLC" %in% uniquemethods)
    s2.OHLC <- s2(m - o, o - c1, po)
  if("CHL" %in% uniquemethods)
    s2.CHL <- s2(m - c1, c1 - m1, pc)
  if("CHLO" %in% uniquemethods)
    s2.CHLO <- s2(o - c1, c1 - m1, pc)

  s <- lapply(splitmethods, function(m){
    expr <- sprintf("(%s)/%s", paste0("s2.", m, collapse = "+"), length(m))
    s2 <- eval(parse(text = expr))
    s <- sqrt(abs(s2))
    if(sign) s <- s * base::sign(s2)
    return(s)
  })
  
  names(s) <- method
  return(s)
  
}
