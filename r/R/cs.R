#' Corwin-Schultz Estimator
#'
#' @keywords internal
#'
CS <- function(high, low, close, width, method, sign, na.rm){

  ok <- c("CS","CS2")
  if(length(ko <- setdiff(method, ok)))
    stop(sprintf("Method(s) '%s' not available. The available methods are '%s'.",
                 paste(ko, collapse = "', '"), paste(ok, collapse = "', '")))
  
  h <- log(high)
  l <- log(low)
  c <- log(close)
  
  c1 <- shift(c, 1)
  h1 <- shift(h, 1)
  l1 <- shift(l, 1)
  
  gap <- pmax(0, c1 - h) + pmin(0, c1 - l)
  ah <- h + gap
  al <- l + gap

  b <- (h - l)^2 + (h1 - l1)^2
  g <- (pmax(ah, h1) - pmin(al, l1))^2

  a <- (sqrt(2*b) - sqrt(b)) / (3 - 2*sqrt(2)) - sqrt(g / (3 - 2*sqrt(2)))
  s <- 2*(exp(a) - 1) / (1 + exp(a))
  
  shift <- 1
  cs <- cs2 <- NULL

  if("CS" %in% method) {
    cs <- rmean(s, width = width, shift = shift, na.rm = na.rm)
    if(!sign) cs <- abs(cs)
    cs <- list("CS" = cs)
  }

  if("CS2" %in% method){
    s[s < 0] <- 0
    cs2 <- rmean(s, width = width, shift = shift, na.rm = na.rm)
    cs2 <- list("CS2" = cs2)
  }

  return(c(cs, cs2))

}
