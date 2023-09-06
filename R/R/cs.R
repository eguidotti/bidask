#' Corwin-Schultz Estimator
#'
#' @keywords internal
#'
CS <- function(x, width = nrow(x), method, sign, na.rm){

  ok <- c("CS","CS2")
  if(length(ko <- setdiff(method, ok)))
    stop(sprintf("Method(s) '%s' not available. The available methods are '%s'.",
                 paste(ko, collapse = "', '"), paste(ok, collapse = "', '")))
  
  x <- log(x)
  
  H <- x$HIGH[-1]
  L <- x$LOW[-1]
  
  C1 <- lag(x$CLOSE, 1)[-1]
  H1 <- lag(x$HIGH, 1)[-1]
  L1 <- lag(x$LOW, 1)[-1]
  
  GAP <- pmax(0, C1-H) + pmin(0, C1-L)
  AH <- H + GAP
  AL <- L + GAP

  B <- (H-L)^2 + (H1-L1)^2
  G <- (pmax(AH, H1) - pmin(AL, L1))^2

  A <- (sqrt(2*B)-sqrt(B))/(3-2*sqrt(2)) - sqrt(G/(3-2*sqrt(2)))
  S <- 2*(exp(A)-1)/(1+exp(A))
  
  cs <- cs2 <- NULL

  if("CS" %in% method) {
    cs <- rmean(S, width = width-1, na.rm = na.rm)
    if(!sign) cs <- abs(cs)
    colnames(cs) <- "CS"
  }

  if("CS2" %in% method){
    S[S<0] <- 0
    cs2 <- rmean(S, width = width-1, na.rm = na.rm)
    colnames(cs2) <- "CS2"
  }

  return(cbind(cs, cs2))

}
