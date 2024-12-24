#' Abdi-Ranaldo Estimator
#'
#' @keywords internal
#'
AR <- function(high, low, close, width, method, sign, na.rm){

  ok <- c("AR","AR2")
  if(length(ko <- setdiff(method, ok)))
    stop(sprintf("Method(s) '%s' not available. The available methods are '%s'.",
                 paste(ko, collapse = "', '"), paste(ok, collapse = "', '")))

  h <- log(high)
  l <- log(low)
  c <- log(close)

  m2 <- (h + l) / 2
  m1 <- shift(m2, 1)
  c1 <- shift(c, 1)

  s2 <- 4 * (c1 - m1) * (c1 - m2)

  shift <- 1
  ar <- ar2 <- NULL
  
  if("AR" %in% method) {
    ar <- rmean(s2, width = width, shift = shift, na.rm = na.rm)
    ar <- sign(ar) * sqrt(abs(ar))
    if(!sign) ar <- abs(ar)
    ar <- list("AR" = ar)
  }

  if("AR2" %in% method){
    s2[s2 < 0] <- 0
    s <- sqrt(s2)
    ar2 <- rmean(s, width = width, shift = shift, na.rm = na.rm)
    ar2 <- list("AR2" = ar2)
  }

  return(c(ar, ar2))

}
